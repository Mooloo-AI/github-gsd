# Technology Stack

_Mapped against `373f336` on 2026-10-11._

## Languages

- Markdown: the skill itself (`skills/github-gsd/SKILL.md`, `steps/*.md`,
  `templates/**`).
- Bash, compatible with 3.2 (the macOS system bash):
  `skills/github-gsd/scripts/issue-comment.sh`,
  `skills/github-gsd/scripts/discover.sh`, and `tests/mocks/gh`.
- `jq` filters inside the scripts and the step files' commands.

## Runtime

The agent's shell on the user's machine. CI runs Ubuntu (bash 5) and macOS
with `/bin/bash` 3.2 put first on `PATH` (`.github/workflows/ci.yml`).

## Frameworks

- Agent Skills format: `SKILL.md` with `name` and `description`
  frontmatter, loaded by Claude Code and Codex.
- bats-core 1.5 or later for tests (`bats_require_minimum_version 1.5.0`).

## Key Dependencies

- GitHub CLI `gh`: every GitHub read and write; recent versions for
  sub-issue and blocked-by flags.
- `jq` 1.6 or later: JSON parsing and building.
- git: `discover.sh` reads the checkout and its history.

## Configuration

- `AGENTS.md`: this repository's own github-gsd configuration section.
- `release-please-config.json` and `.release-please-manifest.json`: the
  `simple` release type with `VERSION` as the version file.

## Platform Requirements

`gh` authenticated (the `project` scope for Projects; `admin:org` only to
create organization issue fields), `jq`, git, and Bash 3.2+. Development
also needs bats, shellcheck, and actionlint; the install check needs Node.js
for `npx skills@1.7.1`.
