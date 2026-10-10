# Codebase Structure

_Mapped against `373f336` on 2026-10-11._

## Directory Layout

- `skills/github-gsd/`: the installable skill (what skills.sh copies).
  - `SKILL.md`, `LICENSE` (a copy of the root `LICENSE`).
  - `steps/`: step instructions.
  - `scripts/`: `issue-comment.sh`, `discover.sh` (executable).
  - `templates/`: Markdown templates; `templates/github/` holds issue forms
    and the PR template; `templates/codebase/` the codebase-doc templates.
- `tests/`: bats suites and `tests/mocks/gh`.
- `docs/codebase/`: this map.
- `.github/workflows/`: `ci.yml` (shellcheck, tests, install check) and
  `release.yml` (release-please).
- Root: `README.md`, `AGENTS.md`, `CHANGELOG.md`, `VERSION`, release-please
  config.

## Key Modules

See [architecture.md](architecture.md#component-responsibilities).

## Tests

One bats file per script (`issue-comment.bats`, `discover.bats`), plus
`skill.bats` (frontmatter) and `style.bats` (test style).

## Naming Conventions

Step files are named after the step (`plan.md`); init sub-steps use an
`init-` prefix. Templates are named after what they produce (`plan.md` is the
plan comment). The skill directory must stay `github-gsd`, never `gsd-*`.

## Where to Add New Code

- A new workflow step: `steps/<step>.md`, a routing row in `SKILL.md`, and
  the step table in `README.md`.
- A new helper: `scripts/<name>.sh`, its tests in `tests/<name>.bats`, and
  the shellcheck command in CI and `AGENTS.md`.
- A new template: `templates/`, referenced from the step that fills it.

## Generated and Ignored

`CHANGELOG.md` and `VERSION` are maintained by release-please; don't edit
them by hand.
