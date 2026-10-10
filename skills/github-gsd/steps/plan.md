# Plan

Write the **Implementation plan** comment: the tasks that deliver the
acceptance criteria within the decisions.

## 1. Prepare

- Read the issue body, the Context and decisions comment
  (`issue-comment.sh --get <N> context`), and any Research comment.
- Read the code you will change and its tests, and find the patterns to
  follow. The configured codebase docs (structure, conventions, testing)
  point to them.
- Start from an existing plan comment, if any:
  `issue-comment.sh --get <N> plan`.

## 2. Write the plan

Use [templates/plan.md](../templates/plan.md):

- **Status line:** `Status: 🛠️ In progress` ([ship.md](ship.md) changes it).
- **Approach:** two to five sentences, referencing decisions by number
  (D-01).
- **Size:** the estimated additions plus deletions for the whole PR, and the
  limit, for example `about 400 changed lines (limit 1500)`. Estimate per
  task and add up, leaving out lockfiles and generated files.
- **Tasks** as ordered checkboxes. Each is one reviewable step that leaves
  the code working, names its files or modules, and ends with how it is
  checked. Migrations, tests, and docs are tasks, not afterthoughts,
  including a codebase doc the change makes wrong.
- **Verification:** the required checks and how each acceptance criterion
  will be checked (test, command, or browser check).
- **Risks:** what could go wrong and how it is contained (rollback, feature
  flag, data migration safety).

Check the plan against the issue: every acceptance criterion has a task and
a verification step, every decision is respected, and nothing is out of
scope.

## 3. Check the size

Before posting, check that the plan fits in one small PR (the size rule in
`SKILL.md`). It is too large when:

- the estimated size is over the configured PR size limit;
- it has more than about 7 tasks; or
- it changes several unrelated areas, or holds more than one reviewable
  concern.

If it is too large, split it before any code is written:

1. Turn this issue into the tracking issue: add the `tracking` label and
   rewrite its body from
   [templates/tracking-issue.md](../templates/tracking-issue.md). Its Context
   and decisions comment stays as the decisions every slice shares.
2. File the slices as ordered sub-issues linked with blocked-by, as in
   [intake.md §2c](intake.md#2c-tracking-issue), and move each requirement and
   acceptance criterion to the slice that delivers it.
3. Delete this issue's branch, which has no commits yet
   (`git switch <default-branch> && git branch -D <branch>`, plus
   `git push origin --delete <branch>` if it was pushed).
4. Tell the user the slices, then start the first unblocked one with
   [start.md](start.md). Its discuss step reads the tracking issue's decisions
   and records only what is new for the slice.

Do not post a plan comment on the tracking issue.

## 4. Post the plan

```bash
issue-comment.sh <N> plan plan.md
```

## 5. ADR (when needed)

When a decision has lasting architectural impact (it constrains future work,
picks a technology, or changes a cross-cutting pattern), add an Architecture
Decision Record to the configured directory (default `docs/adr/`) from
[templates/adr.md](../templates/adr.md), and make writing it a plan task.
Number it after the highest existing one (`NNNN-short-title.md`), set its
status to Accepted, and link the issue. If the directory has no README, add
one from [templates/adr-readme.md](../templates/adr-readme.md).

## 6. Continue

Go to [execute.md](execute.md).
