# External Integrations

_Mapped against `373f336` on 2026-10-11._

## APIs and External Services

- GitHub REST API through `gh api`: issue comments (`issue-comment.sh`).
- GitHub GraphQL API through `gh api graphql`: organization issue fields
  (`discover.sh`); `updateProjectV2Field`, `createIssueField`, and
  `createProjectV2IssueField` (`steps/init-project.md`).
- `gh` subcommands: `issue`, `pr`, `project`, `label`, `repo view`.

## Data Storage

None local. Issues, marked comments, Projects, and PRs on GitHub.

## Authentication and Identity

The user's `gh` login. Scopes: `repo`; `project` for Projects; `admin:org`
only to create organization issue fields.

## Monitoring and Observability

None.

## CI/CD and Deployment

- `.github/workflows/ci.yml`: shellcheck, bats on Ubuntu and macOS
  (bash 3.2), and an install job running `npx --yes skills@1.7.1 add` into an
  empty directory.
- `.github/workflows/release.yml`: release-please updates a release PR; merging it
  tags `vX.Y.Z`. Users install from `main` with `npx skills add
  Mooloo-AI/github-gsd`.

## Environment Configuration

`GH_REPO` (repository for `issue-comment.sh`), `TMPDIR`, and in tests
`MOCK_DIR`, `MOCK_REPO`, and `MOCK_FAIL`. CI sets `DISABLE_TELEMETRY` for the
skills CLI.

## Webhooks and Callbacks

None.
