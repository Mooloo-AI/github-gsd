# Codebase Concerns

_Mapped against `373f336` on 2026-10-11._

Concerns that need work are tracked as GitHub issues; each entry links its
issue when there is one. None of the concerns below has an issue yet: each
is contained, so file one if it starts causing trouble (#36).

## Tech Debt

- `discover.sh` reads workflow `run:` steps with awk, not a YAML parser, so
  unusual YAML is missed (#24 D-05).

## Known Bugs

None known.

## Security Considerations

The configuration section grants standing permission to write issues,
comments, branches, and PRs; it excludes merging and the default branch.

## Performance Bottlenecks

`discover.sh` makes one `gh project field-list` call per open Project of the
owner (up to 30).

## Fragile Areas

- Step files have no automated tests; a broken command shows up only in a
  dry run.
- Organization issue fields and their mutations are a newer GitHub API; the
  create path was checked against the schema but not run.

## Dependencies at Risk

gh JSON quirks, such as `projectsV2.Nodes`, may change between versions.

## Test Coverage Gaps

- No tests for the commands in `steps/*.md`.
- `discover.sh` with real gh output is checked only by manual runs.
