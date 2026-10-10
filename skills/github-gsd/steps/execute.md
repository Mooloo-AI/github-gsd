# Execute

Implement the plan task by task on the issue branch.

## For each task

1. Implement it, following the decisions and the code's existing patterns.
2. Run the checks that cover it (at least the relevant tests).
3. Commit with a `Refs #N` footer.
4. Tick the task in the plan comment as soon as it is done, not all at the
   end:

   ```bash
   issue-comment.sh --get <N> plan > plan.md
   # change "- [ ] <task>" to "- [x] <task>" in plan.md
   issue-comment.sh <N> plan plan.md
   ```

Push regularly (`git push -u origin <branch>`) so the work is not only local.

## When reality differs from the plan

- **The plan needs a small fix** (a missed file, a different order): edit the
  plan comment and go on.
- **A decision turns out wrong or a new question comes up:** stop, go back to
  [discuss.md](discuss.md), update the Context and decisions comment, then
  the plan.
- **Scope grows** (new behavior, a separate bug, an unneeded refactor): open a
  sub-issue (`gh issue create … --parent <N>`) or a separate issue, link it
  from the plan, and keep it off this branch unless it blocks the work.
- **The work outgrows one small PR:** stop, finish the slice that already
  works, and move the rest to sub-issues as in
  [plan.md](plan.md#3-check-the-size), shrinking this issue's plan and
  acceptance criteria to match.
- **You are blocked** (missing access, failing infrastructure, an owner
  decision): tell the user and record the blocker in an issue comment.

## Continue

When every task is ticked, go to [verify.md](verify.md).
