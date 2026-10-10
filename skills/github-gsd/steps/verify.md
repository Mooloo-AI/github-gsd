# Verify

Prove the issue is done: the checks pass and every acceptance criterion holds.

## 1. Run the checks

- Run every **required check** on the final code.
- Run the **workflow checks** that apply (for example `actionlint` for
  workflow files, or a deployment dry run for infrastructure).
- Check the **PR size** against the configured limit:

  ```bash
  git diff --numstat origin/<default-branch>...HEAD
  ```

  Add up the first two columns, leaving out lockfiles and generated files
  (name any you left out). Over the limit, the check fails: move the part
  that can ship later to a sub-issue ([plan.md](plan.md#3-check-the-size))
  instead of opening an oversized PR.
- Record each command and its result. Report a check you could not run as
  not run, with the reason, never as passed.

## 2. Check each acceptance criterion

Check each acceptance criterion directly and record the evidence:

- behavior: a test that covers it, or a command and its output;
- UI: use it in a browser and note what you saw (with a screenshot when it
  helps);
- docs or config: the file and section.

Then review the full diff (`git diff origin/<default-branch>...HEAD`) against
the decisions and the plan: nothing missing, nothing extra, no debug code or
secrets.

## 3. Write the Verification comment

Use [templates/verification.md](../templates/verification.md): the commit
checked, the result (Passed, or Failed with what failed), the checks, and each
acceptance criterion with its evidence.

```bash
issue-comment.sh <N> verification verification.md            # first run
issue-comment.sh --append <N> verification verification.md   # a later run
```

## 4. Continue

- **Failed:** fix it (back to [execute.md](execute.md), with a new plan task
  if it is real work), then verify again.
- **Passed:** go to [ship.md](ship.md).
