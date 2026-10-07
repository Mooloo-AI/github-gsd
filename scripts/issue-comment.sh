#!/usr/bin/env bash
# issue-comment.sh: create, update, or read a marked workflow comment on a GitHub issue.
#
# A marked comment carries a hidden marker line such as <!-- workflow:plan -->.
# The context and plan comments are single comments edited in place. Other
# markers (research, verification, ...) may have several comments; --append
# adds another one.
#
# Requires: gh (authenticated) and jq. Works with bash 3.2 or later.

set -euo pipefail

PROG=$(basename "$0")
SINGLE_MARKERS="context plan"

usage() {
  cat <<EOF
Usage:
  $PROG [options] <issue> <marker> [<file>|-]   create or update the marked comment
  $PROG [options] --append <issue> <marker> [<file>|-]
                                                 add another marked comment
  $PROG [options] --get <issue> <marker>         print the marked comment's body
  $PROG [options] --url <issue> <marker>         print the marked comment's URL

Arguments:
  <issue>    Issue number, or an issue URL (https://github.com/OWNER/REPO/issues/N).
  <marker>   Marker name: context, plan, research, verification, or another
             lowercase name. The comment is marked with <!-- workflow:<marker> -->.
  <file>     File with the comment body. Omit it or pass - to read from stdin.

Options:
  -R, --repo OWNER/REPO   Repository (default: from the issue URL, \$GH_REPO, or
                          the current directory's repository).
  --append                Always add a new comment. Not allowed for context or plan.
  --get                   Print the body of the marked comment (the newest one
                          for markers that allow several comments).
  --url                   Print the URL of the marked comment (the newest one
                          for markers that allow several comments).
  -h, --help              Show this help.

Without --append or --get, the script updates the single comment that carries
the marker, or creates it if there is none. It refuses to edit when more than
one comment carries the marker. The body gets the marker as its first line if
it does not already contain it.

On success it prints the comment URL (or, with --get, the body) to stdout.
Status messages go to stderr.

Exit status: 0 success, 1 error, 2 usage error, 3 duplicate marked comments.
EOF
}

die() {
  echo "$PROG: $*" >&2
  exit 1
}

usage_error() {
  echo "$PROG: $*" >&2
  echo "Run '$PROG --help' for usage." >&2
  exit 2
}

is_single_marker() {
  case " $SINGLE_MARKERS " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

repo=""
mode="upsert"
positional=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -R | --repo)
      [ $# -ge 2 ] || usage_error "$1 needs a value"
      repo=$2
      shift 2
      ;;
    --repo=*)
      repo=${1#--repo=}
      shift
      ;;
    --append | --get | --url)
      [ "$mode" = "upsert" ] || usage_error "use only one of --append, --get, and --url"
      mode=${1#--}
      shift
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        positional+=("$1")
        shift
      done
      ;;
    -?*)
      usage_error "unknown option: $1"
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if [ "$mode" = "get" ] || [ "$mode" = "url" ]; then
  [ ${#positional[@]} -eq 2 ] || usage_error "--$mode takes <issue> <marker>"
else
  if [ ${#positional[@]} -lt 2 ] || [ ${#positional[@]} -gt 3 ]; then
    usage_error "expected <issue> <marker> [<file>|-]"
  fi
fi

issue_arg=${positional[0]}
marker=${positional[1]}
source_file=${positional[2]:--}

command -v gh >/dev/null 2>&1 || die "gh is not installed"
command -v jq >/dev/null 2>&1 || die "jq is not installed"

# Marker name. Explicit character lists, not ranges such as [a-z], which match
# uppercase letters in some locales.
lower=abcdefghijklmnopqrstuvwxyz
digits=0123456789
case "$marker" in
  *[!$lower$digits-]* | "" | -* | [$digits]*)
    usage_error "invalid marker '$marker' (use lowercase letters, digits, and '-', starting with a letter)"
    ;;
esac
marker_text="<!-- workflow:$marker -->"

if [ "$mode" = "append" ] && is_single_marker "$marker"; then
  usage_error "the $marker comment is edited in place; --append is not allowed"
fi

# Issue number and repository.
case "$issue_arg" in
  https://github.com/*/*/issues/* | http://github.com/*/*/issues/*)
    path=${issue_arg#*://github.com/}
    url_repo=$(echo "$path" | cut -d/ -f1-2)
    issue=$(echo "$path" | cut -d/ -f4 | sed 's/[#?].*//')
    if [ -n "$repo" ] && [ "$repo" != "$url_repo" ]; then
      usage_error "--repo $repo does not match the issue URL ($url_repo)"
    fi
    repo=$url_repo
    ;;
  *)
    issue=${issue_arg#\#}
    ;;
esac
case "$issue" in
  "" | *[!$digits]*) usage_error "invalid issue '$issue_arg'" ;;
esac

if [ -z "$repo" ]; then
  repo=${GH_REPO:-}
fi
if [ -z "$repo" ]; then
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) ||
    die "cannot determine the repository; pass --repo OWNER/REPO"
fi
case "$repo" in
  */* ) ;;
  *) usage_error "invalid repository '$repo' (expected OWNER/REPO)" ;;
esac
# Accept HOST/OWNER/REPO from GH_REPO by keeping the last two parts.
repo=$(echo "$repo" | awk -F/ '{ print $(NF-1) "/" $NF }')

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/issue-comment.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

# Find the comments that carry the marker, oldest first.
gh api --paginate "repos/$repo/issues/$issue/comments?per_page=100" >"$tmpdir/pages.json" ||
  die "cannot list comments on $repo#$issue"
jq -s --arg m "$marker_text" \
  '[ (add // [])[] | select((.body // "") | contains($m)) ]
   | sort_by(.created_at)
   | map({ id, html_url, body })' \
  "$tmpdir/pages.json" >"$tmpdir/matches.json" ||
  die "cannot parse the comment list"
count=$(jq 'length' "$tmpdir/matches.json")

duplicate_error() {
  echo "$PROG: $count comments on $repo#$issue carry $marker_text:" >&2
  jq -r '.[].html_url' "$tmpdir/matches.json" | sed 's/^/  /' >&2
  echo "$PROG: merge them into one by hand, then delete the others." >&2
  exit 3
}

if [ "$mode" = "get" ] || [ "$mode" = "url" ]; then
  [ "$count" -gt 0 ] || die "no comment on $repo#$issue carries $marker_text"
  if [ "$count" -gt 1 ] && is_single_marker "$marker"; then
    duplicate_error
  fi
  if [ "$mode" = "get" ]; then
    jq -j '.[-1].body' "$tmpdir/matches.json"
  else
    jq -r '.[-1].html_url' "$tmpdir/matches.json"
  fi
  exit 0
fi

# Read the body.
if [ "$source_file" = "-" ]; then
  cat >"$tmpdir/body.md"
else
  [ -f "$source_file" ] || die "no such file: $source_file"
  cat -- "$source_file" >"$tmpdir/body.md"
fi
if ! grep -q '[^[:space:]]' "$tmpdir/body.md"; then
  die "the comment body is empty"
fi

other_markers=$(LC_ALL=C grep -o '<!-- workflow:[a-z0-9-]* -->' "$tmpdir/body.md" | grep -vxF "$marker_text" || true)
if [ -n "$other_markers" ]; then
  die "the body carries another marker: $(echo "$other_markers" | head -n 1)"
fi
if ! grep -qF "$marker_text" "$tmpdir/body.md"; then
  { echo "$marker_text"; cat "$tmpdir/body.md"; } >"$tmpdir/marked.md"
  mv "$tmpdir/marked.md" "$tmpdir/body.md"
fi
jq -n --rawfile body "$tmpdir/body.md" '{ body: $body }' >"$tmpdir/payload.json"

if [ "$mode" = "upsert" ] && [ "$count" -gt 1 ]; then
  duplicate_error
fi

if [ "$mode" = "upsert" ] && [ "$count" -eq 1 ]; then
  id=$(jq -r '.[0].id' "$tmpdir/matches.json")
  url=$(gh api --method PATCH "repos/$repo/issues/comments/$id" \
    --input "$tmpdir/payload.json" --jq .html_url) ||
    die "cannot update comment $id on $repo#$issue"
  echo "$PROG: updated the $marker comment on $repo#$issue" >&2
else
  url=$(gh api --method POST "repos/$repo/issues/$issue/comments" \
    --input "$tmpdir/payload.json" --jq .html_url) ||
    die "cannot create a comment on $repo#$issue"
  echo "$PROG: created a $marker comment on $repo#$issue" >&2
fi
echo "$url"
