# Coding Conventions

_Mapped against `373f336` on 2026-10-11._

## Naming Patterns

Shell functions and variables are lowercase with underscores (`usage_error`,
`issue_fields_query`). Marker names are lowercase letters, digits, and `-`.

## Code Style

- shellcheck-clean; a rare `# shellcheck disable=` carries its reason.
- Explicit character lists instead of ranges such as `[a-z]`, which match
  other characters in some locales (`issue-comment.sh`).
- Step files: short imperative prose, numbered sections, one command block
  per action, placeholders in `<angle brackets>`, and links between steps.
  Recent work trimmed them for token cost (#19, #23).

## Import Organization

None: there are no modules to import. Scripts depend only on `gh`, `jq`, and
git, checked with `command -v` at start.

## Error Handling

`die`, `warn`, and `usage_error` helpers in each script; the exit statuses
are documented in `--help`.

## Logging

Status messages go to stderr, results to stdout, so callers can pipe the
output.

## Comments

A header comment states each script's purpose and requirements; inline
comments explain why (for example the gh `projectsV2.Nodes` quirk).

## Function and Module Design

Each script is one file with a `usage` heredoc, argument parsing, and a
`tmpdir` removed by an `EXIT` trap. Commands in step files must run in bash
and zsh (no `status` variable).
