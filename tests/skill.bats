#!/usr/bin/env bats
# Checks on the skill's SKILL.md frontmatter.

bats_require_minimum_version 1.5.0

setup() {
  SKILL_MD="$BATS_TEST_DIRNAME/../skills/github-gsd/SKILL.md"
}

@test "the frontmatter has the skill name" {
  [ "$(sed -n 2p "$SKILL_MD")" = "name: github-gsd" ]
}

@test "the description is single-quoted, so ' #' does not start a YAML comment" {
  line=$(grep '^description: ' "$SKILL_MD")
  [[ "$line" == "description: '"*"'" ]] || return 1
  # Inside single quotes only '' is special; the text has no quote to escape.
  inner=${line#description: \'}
  inner=${inner%\'}
  [[ "$inner" != *"'"* ]] || return 1
}

@test "the description keeps its trigger for unannounced change requests" {
  grep -q '^description: .*even when no issue is mentioned.*Do not use for repositories' "$SKILL_MD"
}

@test "the description is at most 1024 characters" {
  line=$(grep '^description: ' "$SKILL_MD")
  inner=${line#description: \'}
  inner=${inner%\'}
  [ "$(printf '%s' "$inner" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')" -le 1024 ]
}
