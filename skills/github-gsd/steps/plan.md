# Plan

Write the **Implementation plan** comment: the tasks that deliver the
acceptance criteria within the decisions.

## 1. Prepare

- Read the issue body, the Context and decisions comment
  (`issue-comment.sh --get <N> context`), and any Research comment.
- Read the code you will change and its tests. Find the patterns to follow.
- If a plan comment exists, start from it: `issue-comment.sh --get <N> plan`.

## 2. Write the plan

Use [templates/plan.md](../templates/plan.md):

- **Status line:** `Status: 🛠️ In progress`. [ship.md](ship.md) changes it.
- **Approach:** two to five sentences. Reference decisions by number (D-01).
- **Tasks** as checkboxes, in order. Each task is one reviewable step that
  leaves the code working, names its files or modules, and ends with how it is
  checked. Include migrations, tests, and docs as tasks, not afterthoughts.
- **Verification:** the required checks and how each acceptance criterion
  will be checked (test, command, or browser check).
- **Risks:** what could go wrong and how it is contained (rollback,
  feature flag, data migration safety).

Check the plan against the issue before posting: every acceptance criterion
is covered by a task and a verification step, every decision is respected, and
nothing outside the scope is included.

```bash
issue-comment.sh <N> plan plan.md
```

There is exactly one plan comment per issue, edited in place. If the plan
changes later, edit it; never post "Plan v2". Write it directly; there is no
approval step.

## 3. ADR (when needed)

When a decision has lasting architectural impact (it constrains future work,
picks a technology, or changes a cross-cutting pattern), add an Architecture
Decision Record in the configured directory (default `docs/adr/`) using
[templates/adr.md](../templates/adr.md). Number it after the highest existing
one (`NNNN-short-title.md`), set its status to Accepted, link the issue, and
make writing it a task in the plan. If the directory has no README, add one
from [templates/adr-readme.md](../templates/adr-readme.md).

## 4. Continue

Go to [execute.md](execute.md).
