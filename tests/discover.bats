#!/usr/bin/env bats
# Tests for skills/github-gsd/scripts/discover.sh with a mocked gh.

bats_require_minimum_version 1.5.0

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../skills/github-gsd/scripts/discover.sh"
  export MOCK_DIR="$BATS_TEST_TMPDIR/mock"
  mkdir -p "$MOCK_DIR"
  : >"$MOCK_DIR/calls.log"
  export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
  unset GH_REPO MOCK_FAIL MOCK_REPO

  cat >"$MOCK_DIR/repo.json" <<'EOF'
{"nameWithOwner": "acme/widgets", "owner": {"id": "O_1", "login": "acme"},
 "defaultBranchRef": {"name": "main"},
 "projectsV2": {"Nodes": [{"number": 3, "title": "Board"}]},
 "milestones": [{"number": 1, "title": "v1.0", "dueOn": "2026-12-01T00:00:00Z"},
                {"number": 2, "title": "Someday"}]}
EOF
  cat >"$MOCK_DIR/projects.json" <<'EOF'
{"projects": [
  {"number": 3, "title": "Board", "url": "https://github.com/orgs/acme/projects/3", "closed": false},
  {"number": 4, "title": "Roadmap", "url": "https://github.com/orgs/acme/projects/4", "closed": false},
  {"number": 5, "title": "Old", "url": "https://github.com/orgs/acme/projects/5", "closed": true}
], "totalCount": 3}
EOF
  cat >"$MOCK_DIR/fields-3.json" <<'EOF'
{"fields": [
  {"id": "F1", "name": "Title", "type": "ProjectV2Field"},
  {"id": "F2", "name": "Status", "type": "ProjectV2SingleSelectField",
   "options": [{"id": "a", "name": "Todo"}, {"id": "b", "name": "Doing"}, {"id": "c", "name": "Done"}]},
  {"id": "F3", "name": "Priority", "type": "ProjectV2SingleSelectField",
   "options": [{"id": "p", "name": "High"}, {"id": "q", "name": "Low"}]}
], "totalCount": 3}
EOF
  echo '{"fields": [], "totalCount": 0}' >"$MOCK_DIR/fields-4.json"
  cat >"$MOCK_DIR/labels.json" <<'EOF'
[{"name": "bug", "description": "Something isn't working", "color": "d73a4a"},
 {"name": "area: api", "description": "", "color": "ffffff"}]
EOF

  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  cd "$REPO"
  git init -q
  git config user.name test
  git config user.email test@example.com
  git config commit.gpgsign false
}

# commits SUBJECT... -> one empty commit per subject
commits() {
  for subject in "$@"; do
    git commit -q --allow-empty -m "$subject"
  done
}

# Runs the script and keeps stdout and stderr apart.
discover() {
  run --separate-stderr "$SCRIPT"
}

@test "--help prints usage" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]] || return 1
}

@test "an unknown argument is a usage error" {
  run "$SCRIPT" --repo acme/widgets
  [ "$status" -eq 2 ]
  [[ "$output" == *"unexpected argument: --repo"* ]] || return 1
}

@test "outside a git checkout it fails" {
  cd "$BATS_TEST_TMPDIR"
  mkdir plain
  cd plain
  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not inside a git checkout"* ]] || return 1
}

@test "it fails when the GitHub repository cannot be read" {
  MOCK_FAIL=repo run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot read the GitHub repository"* ]] || return 1
}

@test "reports the repository, milestones, and labels" {
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .repository <<<"$output")" = "acme/widgets" ]
  [ "$(jq -r .owner <<<"$output")" = "acme" ]
  [ "$(jq -r .default_branch <<<"$output")" = "main" ]
  [ "$(jq -c .milestones <<<"$output")" = '[{"title":"v1.0","due_on":"2026-12-01T00:00:00Z"},{"title":"Someday","due_on":null}]' ]
  [ "$(jq -c .labels <<<"$output")" = '[{"name":"bug","description":"Something isn'"'"'t working"},{"name":"area: api","description":""}]' ]
}

@test "reports open Projects with their single-select fields and which are linked" {
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.projects[] | {number, linked}]' <<<"$output")" = '[{"number":3,"linked":true},{"number":4,"linked":false}]' ]
  [ "$(jq -c '.projects[0].single_select_fields' <<<"$output")" = '[{"name":"Status","options":["Todo","Doing","Done"]},{"name":"Priority","options":["High","Low"]}]' ]
  [ "$(jq -r '.projects[0].url' <<<"$output")" = "https://github.com/orgs/acme/projects/3" ]
  [ "$(jq -c '.projects[1].single_select_fields' <<<"$output")" = '[]' ]
}

@test "reads linked Projects under projectsV2.nodes too" {
  jq '.projectsV2 = {nodes: [{number: 4}]}' "$MOCK_DIR/repo.json" >"$MOCK_DIR/repo2.json"
  mv "$MOCK_DIR/repo2.json" "$MOCK_DIR/repo.json"
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.projects[] | select(.linked) | .number]' <<<"$output")" = '[4]' ]
}

@test "a user-owned repository has no issue fields" {
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .owner_type <<<"$output")" = "User" ]
  [ "$(jq -c .issue_fields <<<"$output")" = "null" ]
  ! grep -q graphql "$MOCK_DIR/calls.log" || return 1
}

@test "reports an organization's issue fields" {
  jq '.isInOrganization = true' "$MOCK_DIR/repo.json" >"$MOCK_DIR/repo2.json"
  mv "$MOCK_DIR/repo2.json" "$MOCK_DIR/repo.json"
  cat >"$MOCK_DIR/graphql.json" <<'EOF'
{"data": {"organization": {"issueFields": {"nodes": [
  {"name": "Priority", "dataType": "SINGLE_SELECT", "options": [{"name": "High"}, {"name": "Low"}]},
  {"name": "Target date", "dataType": "DATE"},
  {}
]}}}}
EOF
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .owner_type <<<"$output")" = "Organization" ]
  [ "$(jq -c .issue_fields <<<"$output")" = '[{"name":"Priority","type":"SINGLE_SELECT","options":["High","Low"]},{"name":"Target date","type":"DATE","options":[]}]' ]
  grep -q '^api graphql -f owner=acme' "$MOCK_DIR/calls.log"
}

@test "when an organization's issue fields cannot be read, issue_fields is null" {
  jq '.isInOrganization = true' "$MOCK_DIR/repo.json" >"$MOCK_DIR/repo2.json"
  mv "$MOCK_DIR/repo2.json" "$MOCK_DIR/repo.json"
  MOCK_FAIL=graphql discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .issue_fields <<<"$output")" = "null" ]
  [[ "$stderr" == *"cannot read the issue fields of acme"* ]] || return 1
}

@test "makes only read calls" {
  discover
  [ "$status" -eq 0 ]
  ! grep -qE 'POST|PATCH|DELETE|create|edit|item-add' "$MOCK_DIR/calls.log" || return 1
}

@test "without the project scope, projects is null and stderr says how to fix it" {
  MOCK_FAIL=project discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .projects <<<"$output")" = "null" ]
  [ "$(jq -r .repository <<<"$output")" = "acme/widgets" ]
  [[ "$stderr" == *"gh auth refresh -s project"* ]] || return 1
}

@test "a Project whose fields cannot be read has no fields" {
  MOCK_FAIL=fields discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.projects[].single_select_fields]' <<<"$output")" = '[[],[]]' ]
  [[ "$stderr" == *"cannot read the fields of Project 3"* ]] || return 1
}

@test "when labels cannot be read, labels is null" {
  MOCK_FAIL=label discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .labels <<<"$output")" = "null" ]
  [[ "$stderr" == *"cannot list the labels"* ]] || return 1
}

@test "an empty repository has empty or null local settings" {
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '{agent_files, templates, checks, commits, adr_directory, codebase_docs}' <<<"$output")" = \
    '{"agent_files":[],"templates":{"issue_forms":[],"pr_template":null},"checks":[],"commits":{"sampled":0,"conventional":0,"style":null},"adr_directory":null,"codebase_docs":null}' ]
}

@test "reports agent files and whether they have the configuration section" {
  printf '# Agents\n\n## github-gsd configuration\n\n- **Project:** none\n' >AGENTS.md
  printf '# Claude\n\nSee AGENTS.md. Not ## github-gsd configuration.\n' >CLAUDE.md
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .agent_files <<<"$output")" = '[{"path":"AGENTS.md","has_config":true},{"path":"CLAUDE.md","has_config":false}]' ]
}

@test "finds the configuration section under a heading of another level" {
  printf '# Agents\n\n## Task tracking\n\n### github-gsd configuration\n\n- **Project:** none\n' >AGENTS.md
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .agent_files <<<"$output")" = '[{"path":"AGENTS.md","has_config":true}]' ]
}

@test "reports issue forms, without the chooser config, and the PR template" {
  mkdir -p .github/ISSUE_TEMPLATE
  touch .github/ISSUE_TEMPLATE/bug.yml .github/ISSUE_TEMPLATE/config.yml \
    .github/ISSUE_TEMPLATE/feature.md .github/ISSUE_TEMPLATE/notes.txt \
    .github/pull_request_template.md
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .templates <<<"$output")" = '{"issue_forms":[".github/ISSUE_TEMPLATE/bug.yml",".github/ISSUE_TEMPLATE/feature.md"],"pr_template":".github/pull_request_template.md"}' ]
}

@test "finds a PR template at the top level" {
  touch PULL_REQUEST_TEMPLATE.md
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .templates.pr_template <<<"$output")" = "PULL_REQUEST_TEMPLATE.md" ]
}

@test "lists workflow run steps as checks, single-line, quoted, and block" {
  mkdir -p .github/workflows
  cat >.github/workflows/ci.yml <<'EOF'
name: CI
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - run: npm test
      - name: Lint
        run: "npm run lint"
      - name: Build
        run: |
          npm ci

          npm run build
        env:
          CI: "true"
      - run: >-
          echo done
EOF
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.checks[] | select(.source == ".github/workflows/ci.yml") | .command]' <<<"$output")" = \
    '["npm test","npm run lint","npm ci\nnpm run build","echo done"]' ]
}

@test "lists package.json scripts with the package manager from the lockfile" {
  echo '{"scripts": {"test": "vitest", "build": "tsc"}}' >package.json
  touch pnpm-lock.yaml
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.checks[] | select(.source == "package.json") | .command]' <<<"$output")" = '["pnpm run test","pnpm run build"]' ]
}

@test "lists Makefile targets but not special targets or variables" {
  cat >Makefile <<'EOF'
.PHONY: test lint
CC := cc
VERSION ?= 1
test: build
	./run-tests
lint:
	shellcheck *.sh
test: extra
EOF
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.checks[] | select(.source == "Makefile") | .command]' <<<"$output")" = '["make test","make lint"]' ]
}

@test "lists checks for the pyproject.toml tool sections" {
  cat >pyproject.toml <<'EOF'
[project]
name = "widgets"

[tool.pytest.ini_options]
addopts = "-q"

[tool.ruff]
line-length = 100

[tool.mypy]
strict = true
EOF
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c '[.checks[] | select(.source == "pyproject.toml") | .command]' <<<"$output")" = '["pytest","ruff check .","mypy ."]' ]
}

@test "recognizes Conventional Commits" {
  commits "feat: add export" "fix(api): handle empty body" "feat!: drop v1" "docs: fix typo" "update readme"
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .commits <<<"$output")" = '{"sampled":5,"conventional":4,"style":"conventional"}' ]
}

@test "reports another commit style" {
  commits "Add export" "Fix bug" "feat: one"
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -c .commits <<<"$output")" = '{"sampled":3,"conventional":1,"style":"other"}' ]
}

@test "reports the ADR directory and codebase docs" {
  mkdir -p docs/decisions docs/codebase
  touch docs/codebase/stack.md docs/codebase/architecture.md docs/codebase/notes.txt
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .adr_directory <<<"$output")" = "docs/decisions" ]
  [ "$(jq -c .codebase_docs <<<"$output")" = '{"directory":"docs/codebase","files":["architecture.md","stack.md"]}' ]
}

@test "works from a subdirectory of the checkout" {
  mkdir -p docs/adr src/lib
  cd src/lib
  discover
  [ "$status" -eq 0 ]
  [ "$(jq -r .adr_directory <<<"$output")" = "docs/adr" ]
}
