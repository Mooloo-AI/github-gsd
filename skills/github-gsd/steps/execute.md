# Execute

Implement the plan task by task on the issue branch.

## For each task

1. Implement it, following the decisions and the code's existing patterns.
2. Run the checks that cover it (the relevant tests at least).
3. Commit with the repository's convention (Conventional Commits by default)
   and a `Refs #N` footer:

   ```text
   feat(export): add CSV writer for invoices

   Refs #42
   ```

4. Tick the task in the plan comment:

   ```bash
   issue-comment.sh --get <N> plan > plan.md
   # change "- [ ] <task>" to "- [x] <task>" in plan.md
   issue-comment.sh <N> plan plan.md
   ```

   Tick tasks as they are done, not all at the end, so the issue shows
   progress.

Commit and push regularly (`git push -u origin <branch>`) so the work is not
only local.

## When reality differs from the plan

- **The plan needs a small fix** (a missed file, a different order): edit the
  plan comment and go on.
- **A decision turns out wrong or a new question comes up:** stop, go back to
  [discuss.md](discuss.md), update the Context and decisions comment, then
  update the plan.
- **Scope grows** (new behavior, a separate bug, a refactor the task does not
  need): do not expand the issue silently. Open a sub-issue
  (`gh issue create … --parent <N>`) or a separate issue, link it from the
  plan, and leave it out of this branch unless it blocks the work.
- **You are blocked** (missing access, failing infrastructure, an owner
  decision): say so to the user and record the blocker in an issue comment.

## Continue

When every task is ticked, go to [verify.md](verify.md).
