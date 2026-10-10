# Verify

Prove the issue is done: the checks pass and every acceptance criterion holds.

## 1. Run the checks

- Run every **required check** from the configuration, on the final code.
- Run the **workflow checks** that apply to the change (for example
  `actionlint` for workflow files, or a deployment dry run for infrastructure
  changes). Never run a real deployment unless the user asked for it.
- Check the **PR size** against the configured limit (default 1500 changed
  lines):

  ```bash
  git diff --numstat origin/<default-branch>...HEAD
  ```

  Add up the first two columns, leaving out lockfiles and generated files
  (name any you left out). If the total is over the limit, the check fails:
  move the part that can ship later to a sub-issue (back to
  [plan.md](plan.md#3-check-the-size)) instead of opening an oversized PR.
- Record each command and its result. A check you could not run is reported
  as not run, with the reason; never as passed.

## 2. Check each acceptance criterion

For each criterion in the issue body (or its Specification comment), check
it directly and record the evidence:

- behavior: a test that covers it, or a command and its output;
- UI: open it in a browser, use it, and note what you saw (attach a
  screenshot when it helps);
- docs or config: the file and section.

Also review the full diff (`git diff origin/<default-branch>...HEAD`) against
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

Add a new Verification comment for a new run (for example after fixing a
failure), so the history stays visible.

## 4. Continue

- **Failed:** fix the problem (back to [execute.md](execute.md), adding a plan
  task if it is real work), then verify again.
- **Passed:** go to [ship.md](ship.md).
