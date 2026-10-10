# Codebase map

Reference documents that describe how the code is organized today. They were
mapped against commit `373f336` on 2026-10-11; each document shows its own
date. Update a document in the same change that makes it wrong.

- [Architecture](architecture.md): a Markdown skill with two Bash helpers;
  how an agent moves through the steps, and where state lives (GitHub only).
- [Structure](structure.md): the skill directory, tests, and release files.
- [Stack](stack.md): Bash 3.2+, `gh`, `jq`, bats, and release-please.
- [Integrations](integrations.md): the GitHub REST and GraphQL APIs through
  `gh`, the skills.sh installer, and CI.
- [Conventions](conventions.md): step-file prose, script style, and test
  rules.
- [Testing](testing.md): bats tests against a mocked `gh`.
- [Concerns](concerns.md): untested step files, awk workflow parsing, and
  preview APIs. Concerns that need work are tracked as GitHub issues.

The configured ADR directory is `docs/adr/`; it has no records yet.
