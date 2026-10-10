# Discuss

Settle the open questions and record the result in the **Context and
decisions** comment, the single source for what was decided.

## 1. Gather context

- Read the issue body, all comments (including any Research comment), linked
  issues and PRs, and the parent tracking issue.
- Read the configured codebase docs, if any, then the code, docs, and ADRs
  the work touches, and note the files and modules.
- Start from an existing Context and decisions comment, if any:
  `issue-comment.sh --get <N> context`.

## 2. Settle the open questions

List every open question: those in the issue body and those you found (gray
areas, edge cases, behavior the requirements do not cover).

- Answer what the code, docs, or existing decisions already answer, and
  record the source.
- Record every answer the owner gave in chat, before or after the issue was
  filed, as a dated decision; an answer left only in chat is lost.
- Ask the owner the rest in one batch, each with options and your
  recommendation, and wait for the answers. For things with a conventional
  default, choose it and record it as a decision instead of asking.
- If the owner is not available and the user asked you to go on, take your
  recommendation and mark the decision "(proposed)".

## 3. Write the Context and decisions comment

Use [templates/context.md](../templates/context.md):

- **Decisions**, numbered `D-01`, `D-02`, …: each one locked statement, with
  the reason when it is not obvious. When a decision changes, edit it in
  place and note the date; never renumber.
- **Constraints** that bind the implementation.
- **References**: code paths, docs, ADRs, issues, and PRs.
- **Deferred**: what is out of scope, each linked to its issue or draft item.

```bash
issue-comment.sh <N> context context.md
```

## 4. Follow up

- **Deferred items:** file an issue (or a draft item if unscoped) for each,
  as in [intake.md](intake.md), and link it in the comment.
- **Issue body:** if the decisions change the requirements or acceptance
  criteria, edit the body (`gh issue edit <N> --body-file body.md`) and move
  answered questions out of **Open questions**.
- **Architecture:** mark a decision that matters beyond this issue "ADR
  needed"; [plan.md](plan.md) writes the ADR.

## 5. Continue

Go to [plan.md](plan.md) once no open question blocks the plan.
