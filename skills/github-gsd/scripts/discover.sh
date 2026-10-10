#!/usr/bin/env bash
# discover.sh: print a repository's github-gsd settings as JSON.
#
# Reads the git checkout in the current directory and the GitHub repository it
# belongs to, and changes nothing. The init step turns the output into the
# repository's github-gsd configuration section.
#
# Requires: gh (authenticated; the project scope to read Projects), jq, and
# git. Works with bash 3.2 or later.

set -euo pipefail

PROG=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  $PROG          print the settings of the repository in the current directory
  $PROG --help   show this help

Run it inside a git checkout whose GitHub repository gh can read. It prints
one JSON object to stdout and changes nothing:

  repository       "OWNER/REPO"
  owner            "OWNER"
  default_branch   "main"
  agent_files      [{path, has_config}] for AGENTS.md and CLAUDE.md, when present;
                   has_config is true when the file has a
                   "github-gsd configuration" heading at any level
  projects         [{number, title, url, linked, single_select_fields: [{name, options}]}]
                   for the owner's open Projects; linked is true for Projects
                   linked to the repository. null when they cannot be read.
  labels           [{name, description}], or null when they cannot be read
  milestones       [{title, due_on}] for open milestones
  templates        {issue_forms: [path], pr_template: path or null}
  checks           [{command, source}]: candidate required checks from workflow
                   run steps, package.json scripts, Makefile targets, and
                   pyproject.toml tool sections
  commits          {sampled, conventional, style}: of the last 50 non-merge
                   commits, how many follow Conventional Commits; style is
                   "conventional" (80% or more), "other", or null (no commits)
  adr_directory    path of an existing ADR directory, or null
  codebase_docs    {directory, files} for docs/codebase/, or null

When the Projects or labels cannot be read, the key is null and a hint goes to
stderr; the exit status is still 0.

Exit status: 0 success, 1 error, 2 usage error.
EOF
}

die() {
  echo "$PROG: $*" >&2
  exit 1
}

warn() {
  echo "$PROG: $*" >&2
}

usage_error() {
  echo "$PROG: $*" >&2
  echo "Run '$PROG --help' for usage." >&2
  exit 2
}

case "${1:-}" in
  "") ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) usage_error "unexpected argument: $1" ;;
esac

command -v gh >/dev/null 2>&1 || die "gh is not installed"
command -v jq >/dev/null 2>&1 || die "jq is not installed"
command -v git >/dev/null 2>&1 || die "git is not installed"

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git checkout"
cd "$root"

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/discover.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

# lines FILE -> a JSON array of FILE's lines
lines() {
  jq -Rn '[inputs]' <"$1"
}

# GitHub: the repository, its default branch, linked Projects, open milestones.
gh repo view --json nameWithOwner,owner,defaultBranchRef,projectsV2,milestones \
  >"$tmpdir/repo.json" || die "cannot read the GitHub repository of this checkout"
owner=$(jq -r .owner.login "$tmpdir/repo.json")

# Projects. gh 2.97 returns linked Projects under projectsV2.Nodes.
linked=$(jq -c '[ (.projectsV2.Nodes // .projectsV2.nodes // [])[] | .number ]' "$tmpdir/repo.json")
if gh project list --owner "$owner" --format json --limit 30 >"$tmpdir/project-list.json"; then
  : >"$tmpdir/projects.ndjson"
  for number in $(jq -r '.projects[] | select(.closed | not) | .number' "$tmpdir/project-list.json"); do
    if ! gh project field-list "$number" --owner "$owner" --format json --limit 100 \
      >"$tmpdir/fields.json"; then
      warn "cannot read the fields of Project $number"
      echo '{"fields": []}' >"$tmpdir/fields.json"
    fi
    jq -c --argjson n "$number" --argjson linked "$linked" --slurpfile f "$tmpdir/fields.json" '
      .projects[] | select(.number == $n)
      | { number, title, url,
          linked: ($linked | index($n) != null),
          single_select_fields: [ $f[0].fields[]
            | select(.type == "ProjectV2SingleSelectField")
            | { name, options: [ (.options // [])[].name ] } ] }' \
      "$tmpdir/project-list.json" >>"$tmpdir/projects.ndjson"
  done
  jq -s . "$tmpdir/projects.ndjson" >"$tmpdir/projects.json"
else
  warn "cannot list the Projects of $owner; to read Projects, run: gh auth refresh -s project"
  echo null >"$tmpdir/projects.json"
fi

if gh label list --json name,description --limit 500 >"$tmpdir/labels.json"; then
  jq 'map({ name, description })' "$tmpdir/labels.json" >"$tmpdir/labels.out.json"
else
  warn "cannot list the labels"
  echo null >"$tmpdir/labels.out.json"
fi

# Agent instruction files.
: >"$tmpdir/agent-files.ndjson"
for file in AGENTS.md CLAUDE.md; do
  [ -f "$file" ] || continue
  has_config=false
  if grep -qE '^#{1,6} github-gsd configuration[[:space:]]*$' "$file"; then
    has_config=true
  fi
  jq -nc --arg path "$file" --argjson has "$has_config" '{ path: $path, has_config: $has }' \
    >>"$tmpdir/agent-files.ndjson"
done

# Issue forms and the PR template.
: >"$tmpdir/issue-forms.txt"
for file in .github/ISSUE_TEMPLATE/*; do
  [ -f "$file" ] || continue
  case "$file" in
    */config.yml | */config.yaml) ;;
    *.yml | *.yaml | *.md) echo "$file" >>"$tmpdir/issue-forms.txt" ;;
  esac
done
pr_template=$(for dir in .github . docs; do
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 1 -type f -iname pull_request_template.md
  fi
done | sed 's|^\./||' | head -n 1)

# Candidate checks, one per line as SOURCE<TAB>COMMAND. Lines of a multi-line
# command are joined with the RS character (octal 036).
: >"$tmpdir/checks.tsv"
for file in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$file" ] || continue
  awk -v src="$file" '
    function indent(s) { match(s, /^ */); return RLENGTH }
    function flush() {
      if (cmd != "") print src "\t" cmd
      cmd = ""; inblock = 0
    }
    inblock {
      if ($0 ~ /^[[:space:]]*$/) next
      if (indent($0) > keyindent) {
        if (bodyindent < 0) bodyindent = indent($0)
        line = substr($0, bodyindent + 1)
        cmd = (cmd == "") ? line : cmd "\036" line
        next
      }
      flush()
    }
    /^[[:space:]]*(- )?run:/ {
      keyindent = indent($0)
      value = $0
      sub(/^[[:space:]]*(- )?run:[[:space:]]*/, "", value)
      sub(/[[:space:]]+$/, "", value)
      if (value ~ /^[|>][-+]?$/) { inblock = 1; bodyindent = -1; cmd = ""; next }
      if (value ~ /^".*"$/ || value ~ /^'\''.*'\''$/) value = substr(value, 2, length(value) - 2)
      if (value != "") print src "\t" value
    }
    END { flush() }
  ' "$file" >>"$tmpdir/checks.tsv"
done

if [ -f package.json ]; then
  pm=npm
  if [ -f pnpm-lock.yaml ]; then
    pm=pnpm
  elif [ -f yarn.lock ]; then
    pm=yarn
  elif [ -f bun.lockb ] || [ -f bun.lock ]; then
    pm=bun
  fi
  jq -r --arg pm "$pm" '(.scripts // {}) | keys_unsorted[] | "package.json\t\($pm) run \(.)"' \
    package.json >>"$tmpdir/checks.tsv" || warn "cannot parse package.json"
fi

if [ -f Makefile ]; then
  LC_ALL=C grep -E '^[A-Za-z0-9][A-Za-z0-9_.-]*:([^=]|$)' Makefile | cut -d: -f1 |
    awk '!seen[$0]++ { print "Makefile\tmake " $0 }' >>"$tmpdir/checks.tsv" || true
fi

if [ -f pyproject.toml ]; then
  while read -r section command; do
    if grep -qE "^\\[tool\\.${section}[].]" pyproject.toml; then
      printf 'pyproject.toml\t%s\n' "$command" >>"$tmpdir/checks.tsv"
    fi
  done <<'EOF'
pytest pytest
ruff ruff check .
mypy mypy .
black black --check .
EOF
fi

jq -Rn '[ inputs | index("\t") as $i
          | { command: (.[$i + 1:] | gsub("\u001e"; "\n")), source: .[:$i] } ]' \
  <"$tmpdir/checks.tsv" >"$tmpdir/checks.json"

# Commit style.
git log -n 50 --no-merges --format=%s >"$tmpdir/subjects.txt" 2>/dev/null || : >"$tmpdir/subjects.txt"
sampled=$(grep -c . "$tmpdir/subjects.txt" || true)
conventional=$(LC_ALL=C grep -cE '^[a-z]+(\([^)]*\))?!?: .' "$tmpdir/subjects.txt" || true)

# ADR directory and codebase docs.
adr_directory=""
for dir in docs/adr docs/adrs docs/decisions docs/architecture/decisions doc/adr adr; do
  if [ -d "$dir" ]; then
    adr_directory=$dir
    break
  fi
done
if [ -d docs/codebase ]; then
  find docs/codebase -maxdepth 1 -type f -name '*.md' | sed 's|.*/||' | sort >"$tmpdir/codebase.txt"
fi

jq -n \
  --slurpfile repo "$tmpdir/repo.json" \
  --slurpfile projects "$tmpdir/projects.json" \
  --slurpfile labels "$tmpdir/labels.out.json" \
  --argjson agent_files "$(jq -s . "$tmpdir/agent-files.ndjson")" \
  --argjson issue_forms "$(lines "$tmpdir/issue-forms.txt")" \
  --arg pr_template "$pr_template" \
  --slurpfile checks "$tmpdir/checks.json" \
  --argjson sampled "$sampled" \
  --argjson conventional "$conventional" \
  --arg adr_directory "$adr_directory" \
  --argjson codebase_files "$(if [ -f "$tmpdir/codebase.txt" ]; then lines "$tmpdir/codebase.txt"; else echo null; fi)" \
  '$repo[0] as $r
   | { repository: $r.nameWithOwner,
       owner: $r.owner.login,
       default_branch: $r.defaultBranchRef.name,
       agent_files: $agent_files,
       projects: $projects[0],
       labels: $labels[0],
       milestones: [ ($r.milestones // [])[] | { title, due_on: (.dueOn // null) } ],
       templates: { issue_forms: $issue_forms,
                    pr_template: (if $pr_template == "" then null else $pr_template end) },
       checks: $checks[0],
       commits: { sampled: $sampled, conventional: $conventional,
                  style: (if $sampled == 0 then null
                          elif $conventional * 100 >= $sampled * 80 then "conventional"
                          else "other" end) },
       adr_directory: (if $adr_directory == "" then null else $adr_directory end),
       codebase_docs: (if $codebase_files == null then null
                       else { directory: "docs/codebase", files: $codebase_files } end) }'
