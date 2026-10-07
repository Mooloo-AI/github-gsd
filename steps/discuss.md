# Discuss

Settle the open questions and record the result in the **Context and
decisions** comment, the single source for what was decided.

## 1. Gather context

- Read the issue body, all comments (including any Research comment), linked
  issues and PRs, and the parent tracking issue.
- Read the code, docs, and ADRs the work touches. Note the files and modules.
- If a Context and decisions comment already exists, start from it:
  `issue-comment.sh --get <N> context`.

## 2. Settle the open questions

List every open question: the ones in the issue body and the ones you found
(gray areas, edge cases, behavior the requirements do not cover).

- Answer what the code, docs, or existing decisions already answer. Record
  the source.
- Ask the owner the rest, in one batch, each with options and your
  recommendation. Wait for the answers. Do not ask about things with a
  conventional default; choose it and record it as a decision.
- If the owner is not available and the user asked you to go on, take your
  recommendation and mark the decision "(proposed)" so it is easy to review.

## 3. Write the Context and decisions comment

Use [templates/context.md](../templates/context.md):

- **Decisions**, numbered `D-01`, `D-02`, … Each is one locked statement, with
  the reason when it is not obvious. Keep numbers stable: when a decision
  changes, edit it in place and note the date; do not renumber.
- **Constraints** that bind the implementation.
- **References**: code paths, docs, ADRs, issues, and PRs.
- **Deferred**: what is out of scope, each with a link to its issue or draft
  item.

```bash
issue-comment.sh <N> context context.md
```

There is exactly one Context and decisions comment per issue. Always edit it
with the script; never post a second one or a correction comment. Write it
directly; there is no approval step.

## 4. Follow up

- **Deferred items:** create an issue (or a draft item if it is not scoped)
  for each one, following [intake.md](intake.md), and link it in the comment.
- **Issue body:** if the decisions change the requirements or acceptance
  criteria, edit the body (`gh issue edit <N> --body-file body.md`) and move
  answered questions out of **Open questions**.
- **Architecture:** if a decision matters beyond this issue, note "ADR needed"
  next to it; the ADR is written in [plan.md](plan.md).

## 5. Continue

Go to [plan.md](plan.md) once no open question blocks the plan.
