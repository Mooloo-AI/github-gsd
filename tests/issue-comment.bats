#!/usr/bin/env bats
# Tests for scripts/issue-comment.sh with a mocked gh.

bats_require_minimum_version 1.5.0

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/issue-comment.sh"
  export MOCK_DIR="$BATS_TEST_TMPDIR/mock"
  mkdir -p "$MOCK_DIR"
  : >"$MOCK_DIR/calls.log"
  echo '[]' >"$MOCK_DIR/pages.json"
  export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
  unset GH_REPO MOCK_FAIL MOCK_REPO
}

# comment ID CREATED_AT BODY -> one comment object
comment() {
  jq -n --argjson id "$1" --arg created "$2" --arg body "$3" \
    '{ id: $id, created_at: $created, body: $body,
       html_url: ("https://github.com/acme/widgets/issues/7#issuecomment-" + ($id | tostring)) }'
}

# pages PAGE... -> write the concatenated pages, each PAGE a JSON array
pages() {
  printf '%s\n' "$@" >"$MOCK_DIR/pages.json"
}

payload_body() {
  jq -r .body "$MOCK_DIR/payload.json"
}

@test "--help prints usage" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "creates the comment when none carries the marker" {
  pages "[$(comment 1 2026-01-01T00:00:00Z 'hello')]"
  run --separate-stderr "$SCRIPT" 7 plan - <<<"## Implementation plan"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/acme/widgets/issues/7#issuecomment-999" ]
  grep -q '^api --method POST repos/acme/widgets/issues/7/comments' "$MOCK_DIR/calls.log"
  [ "$(payload_body)" = $'<!-- workflow:plan -->\n## Implementation plan' ]
}

@test "the creation message goes to stderr" {
  run --separate-stderr "$SCRIPT" 7 plan - <<<"body"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/acme/widgets/issues/7#issuecomment-999" ]
  [[ "$stderr" == *"created a plan comment on acme/widgets#7"* ]]
}

@test "updates the single marked comment in place" {
  pages "[$(comment 1 2026-01-01T00:00:00Z 'other'), $(comment 42 2026-01-02T00:00:00Z $'<!-- workflow:context -->\nold')]"
  run --separate-stderr "$SCRIPT" 7 context - <<<"new decisions"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/updated#issuecomment-42" ]
  grep -q '^api --method PATCH repos/acme/widgets/issues/comments/42' "$MOCK_DIR/calls.log"
  ! grep -q 'POST' "$MOCK_DIR/calls.log"
  [ "$(payload_body)" = $'<!-- workflow:context -->\nnew decisions' ]
}

@test "finds the marked comment on a later page" {
  pages \
    "[$(comment 1 2026-01-01T00:00:00Z 'a'), $(comment 2 2026-01-02T00:00:00Z 'b')]" \
    "[$(comment 300 2026-01-03T00:00:00Z $'<!-- workflow:plan -->\nold plan')]"
  run "$SCRIPT" 7 plan - <<<"new plan"
  [ "$status" -eq 0 ]
  grep -q 'PATCH repos/acme/widgets/issues/comments/300' "$MOCK_DIR/calls.log"
  grep -q -- '--paginate repos/acme/widgets/issues/7/comments?per_page=100' "$MOCK_DIR/calls.log"
}

@test "refuses to edit when two comments carry the marker" {
  pages \
    "[$(comment 10 2026-01-01T00:00:00Z '<!-- workflow:plan --> one')]" \
    "[$(comment 11 2026-01-02T00:00:00Z '<!-- workflow:plan --> two')]"
  run "$SCRIPT" 7 plan - <<<"new plan"
  [ "$status" -eq 3 ]
  [[ "$output" == *"2 comments on acme/widgets#7 carry <!-- workflow:plan -->"* ]]
  [[ "$output" == *"issuecomment-10"* ]]
  [[ "$output" == *"issuecomment-11"* ]]
  ! grep -qE 'PATCH|POST' "$MOCK_DIR/calls.log"
}

@test "does not match a different marker" {
  pages "[$(comment 5 2026-01-01T00:00:00Z '<!-- workflow:planning -->')]"
  run "$SCRIPT" 7 plan - <<<"plan"
  [ "$status" -eq 0 ]
  grep -q 'POST' "$MOCK_DIR/calls.log"
}

@test "--append adds a verification comment even when one exists" {
  pages "[$(comment 5 2026-01-01T00:00:00Z '<!-- workflow:verification --> first run')]"
  run "$SCRIPT" --append 7 verification - <<<"second run"
  [ "$status" -eq 0 ]
  grep -q 'POST repos/acme/widgets/issues/7/comments' "$MOCK_DIR/calls.log"
  ! grep -q 'PATCH' "$MOCK_DIR/calls.log"
  [ "$(payload_body)" = $'<!-- workflow:verification -->\nsecond run' ]
}

@test "--append adds a research comment when there are several already" {
  pages "[$(comment 5 2026-01-01T00:00:00Z '<!-- workflow:research --> a'), $(comment 6 2026-01-02T00:00:00Z '<!-- workflow:research --> b')]"
  run "$SCRIPT" 7 research - --append <<<"c"
  [ "$status" -eq 0 ]
  grep -q 'POST' "$MOCK_DIR/calls.log"
}

@test "--append is refused for the context and plan comments" {
  run "$SCRIPT" --append 7 context - <<<"x"
  [ "$status" -eq 2 ]
  [[ "$output" == *"edited in place"* ]]
  run "$SCRIPT" --append 7 plan - <<<"x"
  [ "$status" -eq 2 ]
  [ ! -s "$MOCK_DIR/calls.log" ]
}

@test "reads the body from a file" {
  printf 'line one\nline two\n' >"$BATS_TEST_TMPDIR/body.md"
  run "$SCRIPT" 7 research "$BATS_TEST_TMPDIR/body.md"
  [ "$status" -eq 0 ]
  [ "$(payload_body)" = $'<!-- workflow:research -->\nline one\nline two' ]
}

@test "keeps the body as is when it already carries the marker" {
  run "$SCRIPT" 7 plan - <<<$'## Plan\n<!-- workflow:plan -->\n- [ ] task'
  [ "$status" -eq 0 ]
  [ "$(payload_body)" = $'## Plan\n<!-- workflow:plan -->\n- [ ] task' ]
}

@test "keeps special characters in the body" {
  body=$'Quotes " and \\ backslash, $HOME, `code`, tab\there, émoji ✅'
  run "$SCRIPT" 7 context - <<<"$body"
  [ "$status" -eq 0 ]
  [ "$(payload_body)" = "<!-- workflow:context -->"$'\n'"$body" ]
}

@test "rejects a body that carries another workflow marker" {
  run "$SCRIPT" 7 plan - <<<$'<!-- workflow:context -->\nwrong'
  [ "$status" -eq 1 ]
  [[ "$output" == *"another marker: <!-- workflow:context -->"* ]]
  ! grep -qE 'PATCH|POST' "$MOCK_DIR/calls.log"
}

@test "rejects an empty body" {
  run "$SCRIPT" 7 plan - <<<$'  \n\t'
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty"* ]]
}

@test "rejects a missing body file" {
  run "$SCRIPT" 7 plan "$BATS_TEST_TMPDIR/missing.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no such file"* ]]
}

@test "accepts an issue URL and takes the repository from it" {
  run "$SCRIPT" https://github.com/other/repo/issues/12 plan - <<<"x"
  [ "$status" -eq 0 ]
  grep -q 'repos/other/repo/issues/12/comments' "$MOCK_DIR/calls.log"
  ! grep -q 'repo view' "$MOCK_DIR/calls.log"
}

@test "rejects --repo that does not match the issue URL" {
  run "$SCRIPT" --repo acme/widgets https://github.com/other/repo/issues/12 plan - <<<"x"
  [ "$status" -eq 2 ]
}

@test "uses --repo, then GH_REPO, then the current repository" {
  run "$SCRIPT" --repo one/two 7 plan - <<<"x"
  [ "$status" -eq 0 ]
  grep -q 'repos/one/two/issues/7' "$MOCK_DIR/calls.log"

  : >"$MOCK_DIR/calls.log"
  GH_REPO=github.com/three/four run "$SCRIPT" 7 plan - <<<"x"
  [ "$status" -eq 0 ]
  grep -q 'repos/three/four/issues/7' "$MOCK_DIR/calls.log"

  : >"$MOCK_DIR/calls.log"
  MOCK_REPO=five/six run "$SCRIPT" '#7' plan - <<<"x"
  [ "$status" -eq 0 ]
  grep -q 'repo view' "$MOCK_DIR/calls.log"
  grep -q 'repos/five/six/issues/7' "$MOCK_DIR/calls.log"
}

@test "--get prints the marked comment's body" {
  pages "[$(comment 1 2026-01-01T00:00:00Z $'<!-- workflow:plan -->\n- [ ] task')]"
  run "$SCRIPT" --get 7 plan
  [ "$status" -eq 0 ]
  [ "$output" = $'<!-- workflow:plan -->\n- [ ] task' ]
}

@test "--get prints the newest of several verification comments" {
  pages "[$(comment 2 2026-01-02T00:00:00Z '<!-- workflow:verification --> new'), $(comment 1 2026-01-01T00:00:00Z '<!-- workflow:verification --> old')]"
  run "$SCRIPT" --get 7 verification
  [ "$status" -eq 0 ]
  [ "$output" = "<!-- workflow:verification --> new" ]
}

@test "--get prints the body exactly, so a round trip does not change it" {
  pages "[$(comment 1 2026-01-01T00:00:00Z $'<!-- workflow:plan -->\n- [ ] task\n')]"
  "$SCRIPT" --get 7 plan >"$BATS_TEST_TMPDIR/plan.md"
  [ "$(od -c "$BATS_TEST_TMPDIR/plan.md" | tail -n 2 | head -n 1 | awk '{print $NF}')" = '\n' ]
  run "$SCRIPT" 7 plan "$BATS_TEST_TMPDIR/plan.md"
  [ "$status" -eq 0 ]
  [ "$(jq .body "$MOCK_DIR/payload.json")" = '"<!-- workflow:plan -->\n- [ ] task\n"' ]
}

@test "--url prints the marked comment's URL" {
  pages "[$(comment 1 2026-01-01T00:00:00Z 'x'), $(comment 4 2026-01-02T00:00:00Z '<!-- workflow:context -->')]"
  run "$SCRIPT" --url 7 context
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/acme/widgets/issues/7#issuecomment-4" ]
}

@test "--get and --url cannot be combined with --append" {
  run "$SCRIPT" --get --append 7 research
  [ "$status" -eq 2 ]
  run "$SCRIPT" --url --get 7 research
  [ "$status" -eq 2 ]
}

@test "--get refuses duplicate plan comments" {
  pages "[$(comment 1 2026-01-01T00:00:00Z '<!-- workflow:plan --> a'), $(comment 2 2026-01-02T00:00:00Z '<!-- workflow:plan --> b')]"
  run "$SCRIPT" --get 7 plan
  [ "$status" -eq 3 ]
}

@test "--get fails when no comment carries the marker" {
  run "$SCRIPT" --get 7 context
  [ "$status" -eq 1 ]
  [[ "$output" == *"no comment"* ]]
}

@test "rejects invalid markers and issues" {
  run "$SCRIPT" 7 Plan - <<<"x"
  [ "$status" -eq 2 ]
  LC_ALL=en_US.UTF-8 run "$SCRIPT" 7 pLAN - <<<"x"
  [ "$status" -eq 2 ]
  run "$SCRIPT" 7 9plan - <<<"x"
  [ "$status" -eq 2 ]
  run "$SCRIPT" 7 'plan -->' - <<<"x"
  [ "$status" -eq 2 ]
  run "$SCRIPT" abc plan - <<<"x"
  [ "$status" -eq 2 ]
  run "$SCRIPT" 7
  [ "$status" -eq 2 ]
  run "$SCRIPT" --get 7 plan extra
  [ "$status" -eq 2 ]
  run "$SCRIPT" --nope 7 plan
  [ "$status" -eq 2 ]
}

@test "reports gh failures" {
  MOCK_FAIL=list run "$SCRIPT" 7 plan - <<<"x"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot list comments on acme/widgets#7"* ]]

  MOCK_FAIL=create run "$SCRIPT" 7 plan - <<<"x"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot create a comment"* ]]

  pages "[$(comment 9 2026-01-01T00:00:00Z '<!-- workflow:plan -->')]"
  MOCK_FAIL=update run "$SCRIPT" 7 plan - <<<"x"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot update comment 9"* ]]

  MOCK_FAIL=repo run "$SCRIPT" 7 plan - <<<"x"
  [ "$status" -eq 1 ]
  [[ "$output" == *"pass --repo"* ]]
}
