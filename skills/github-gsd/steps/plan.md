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
- **Size:** the estimated additions plus deletions for the whole PR, and the
  limit, for example `about 400 changed lines (limit 1500)`. Estimate per
  task and add up; leave out lockfiles and generated files.
- **Tasks** as checkboxes, in order. Each task is one reviewable step that
  leaves the code working, names its files or modules, and ends with how it is
  checked. Include migrations, tests, and docs as tasks, not afterthoughts.
- **Verification:** the required checks and how each acceptance criterion
  will be checked (test, command, or browser check).
- **Risks:** what could go wrong and how it is contained (rollback,
  feature flag, data migration safety).

Check the plan against the issue: every acceptance criterion is covered by a
task and a verification step, every decision is respected, and nothing outside
the scope is included.

## 3. Check the size

Before posting, check that the plan fits in one small PR (the size rule in
`SKILL.md`). It is too large when any of these holds:

- the estimated size is over the configured PR size limit (default 1500
  changed lines);
- it has more than about 7 tasks;
- it changes several unrelated areas, or holds more than one reviewable
  concern.

If it fits, go on. If it does not, split it before any code is written:

1. Turn this issue into the tracking issue: add the `tracking` label and
   rewrite its body from
   [templates/tracking-issue.md](../templates/tracking-issue.md). Keep its
   Context and decisions comment as the decisions every slice shares.
2. File the slices as sub-issues, ordered and linked with blocked-by, as in
   [intake.md §2c](intake.md#2c-tracking-issue). Move each requirement and
   acceptance criterion to the slice that delivers it.
3. Delete this issue's branch, which has no commits yet
   (`git switch <default-branch> && git branch -D <branch>`, and
   `git push origin --delete <branch>` if it was pushed).
4. Tell the user the slices, then start the first unblocked one with
   [start.md](start.md). Its discuss step reads the tracking issue's decisions
   and records only what is new for the slice.

Do not post a plan comment on the tracking issue.

## 4. Post the plan

```bash
issue-comment.sh <N> plan plan.md
```

There is exactly one plan comment per issue, edited in place. If the plan
changes later, edit it; never post "Plan v2". Write it directly; there is no
approval step.

## 5. ADR (when needed)

When a decision has lasting architectural impact (it constrains future work,
picks a technology, or changes a cross-cutting pattern), add an Architecture
Decision Record in the configured directory (default `docs/adr/`) using
[templates/adr.md](../templates/adr.md). Number it after the highest existing
one (`NNNN-short-title.md`), set its status to Accepted, link the issue, and
make writing it a task in the plan. If the directory has no README, add one
from [templates/adr-readme.md](../templates/adr-readme.md).

## 6. Continue

Go to [execute.md](execute.md).
