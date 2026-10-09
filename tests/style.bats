#!/usr/bin/env bats
# Style checks on the tests themselves.

bats_require_minimum_version 1.5.0

# Bash 3.2 ignores a failing [[ ]] or (( )) that is not the last command of a
# test, and every bash ignores a failing command negated with !. Such an
# assertion only counts when it ends with || return 1.
@test "every [[ ]], (( )), and ! assertion ends with || return 1" {
  bad=$(grep -nE '^[[:space:]]*(\[\[|\(\(|! )' "$BATS_TEST_DIRNAME"/*.bats | grep -vE '\|\| return 1$' || true)
  if [ -n "$bad" ]; then
    echo "Add '|| return 1' to these assertions:"
    echo "$bad"
    return 1
  fi
}
