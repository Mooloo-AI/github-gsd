# Architecture

_Mapped against `373f336` on 2026-10-11._

## System Overview

github-gsd is an agent skill: instructions an agent reads and follows, plus
two helper scripts. It keeps no local state. GitHub holds everything:

```
user request ─► SKILL.md (routing) ─► steps/<step>.md ─► gh / helper scripts ─► GitHub
                                                          (issues, comments, Projects, PRs)
```

## Component Responsibilities

- `skills/github-gsd/SKILL.md`: where state lives, the comment rule, the
  configuration lookup, and the routing table from a request to a step.
- `skills/github-gsd/steps/`: one file per step (intake, triage, start,
  small, research, discuss, plan, execute, verify, ship, init) and the init
  sub-steps (`init-project.md`, `init-issues.md`, `init-codebase.md`).
- `skills/github-gsd/templates/`: issue, comment, ADR, configuration,
  codebase-doc, and GitHub templates that steps fill in.
- `scripts/issue-comment.sh`: creates, edits, and reads the marked workflow
  comments (`<!-- workflow:<marker> -->`).
- `scripts/discover.sh`: prints a repository's settings as JSON for init.

## Data Flow

A normal issue runs start → (research) → discuss → plan → execute → verify
→ ship. Each step reads the issue and its marked comments, then writes its
result back: the Context and decisions and Implementation plan comments are
edited in place; Research and Verification comments may repeat. The PR
description is the summary.

## Key Abstractions

- The marked comment: one per marker for `spec`, `context`, and `plan`,
  found across all comment pages by `issue-comment.sh`.
- The configuration section in `AGENTS.md` or `CLAUDE.md`: the owner's
  settings and standing permission.

## Entry Points

- The agent loads `SKILL.md` from its description triggers ("work on #12",
  "set up github-gsd here", or any change request in a configured
  repository).
- `issue-comment.sh <issue> <marker> [file]` and `discover.sh` run from the
  skill directory.

## Architectural Constraints

- No local planning files; GitHub is the only source of truth.
- Only `gh`, `jq`, and git as dependencies; Bash 3.2 compatible.
- Repository-specific rules stay in the repository, never in the skill.

## Error Handling

Scripts use `set -euo pipefail`, print `<prog>: <message>` to stderr, and
exit 1 for errors, 2 for usage errors, and 3 for duplicate marked comments
(`issue-comment.sh`). `discover.sh` turns unreadable optional sources into
`null` with a hint and still exits 0.

## Cross-Cutting Concerns

Permission: the configuration section allows filing issues, comments,
branches, and PRs, never merging or pushing to the default branch. Actions
that take effect on GitHub immediately (labels, Projects, issue fields) need
the owner's agreement in init.
