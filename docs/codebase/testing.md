# Testing Patterns

_Mapped against `373f336` on 2026-10-11._

## Test Framework

bats-core 1.5+. Run `bats tests/` (60 tests). CI runs them on Ubuntu and on
macOS with the system bash 3.2.

## Test File Organization

`tests/<script>.bats` per helper script, `tests/skill.bats` for the
`SKILL.md` frontmatter, `tests/style.bats` for the tests themselves.

## Test Structure

`setup()` points `PATH` at `tests/mocks`, creates `MOCK_DIR` under
`$BATS_TEST_TMPDIR`, and writes fixtures. Tests use `run --separate-stderr`
and compare JSON with `jq -c` (see `tests/discover.bats`).

## Mocking

`tests/mocks/gh` replaces `gh`: it logs each call to `$MOCK_DIR/calls.log`,
returns fixture files (`pages.json`, `repo.json`, `projects.json`,
`fields-<n>.json`, `labels.json`, `graphql.json`), and fails a call kind
named in `MOCK_FAIL`.

## Fixtures and Factories

Helpers inside the bats files: `comment` and `pages` build comment JSON;
`commits` makes empty commits in a temporary git repository.

## Test Types

Unit tests of the scripts against the mock. The step files have no
automated tests; they are checked by dry runs recorded in Verification
comments. CI also runs shellcheck, `cmp LICENSE skills/github-gsd/LICENSE`,
and a skills.sh install into an empty directory.

## Coverage

Not measured. `[[ ]]`, `(( ))`, and `!` assertions must end with
`|| return 1`, which `tests/style.bats` enforces.
