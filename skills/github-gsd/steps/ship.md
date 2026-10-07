# Ship

Open the pull request and hand the issue over for review.

## 1. Final review

- Review the diff once more as a reviewer would. Make sure the branch is up
  to date with the default branch and the checks still pass after any merge.
- Push the branch: `git push -u origin <branch>`.

## 2. Open the pull request

Fill in the repository's PR template if it has one; otherwise use
[templates/github/pull_request_template.md](../templates/github/pull_request_template.md). The PR description
is the summary of the work, so include:

- **Summary:** what changed and why, in a few bullets.
- `Closes #N`, so merging closes the issue (and moves it to Done when the
  Project's workflow does that).
- Links to the **Context and decisions** and **Implementation plan** comments
  (and Research if there is one). Get the URLs with
  `issue-comment.sh --url <N> context` (and `plan`, `research`).
- **Verification:** a link to the latest Verification comment
  (`issue-comment.sh --url <N> verification`), or, on the
  small path, each acceptance criterion and how it was checked.
- **Checks:** the commands run and their results.

Title it with the repository's commit convention, for example
`feat(export): add CSV export for invoices`.

```bash
gh pr create --base <default-branch> --title "<title>" --body-file pr.md
```

Create it as a draft (`--draft`) if the user asked for one or something is
still open.

## 3. Update the issue

- Set `Status` to the in-review option (commands in [start.md](start.md)).
- On the normal path, change the plan comment's `Status:` line and save it
  with `issue-comment.sh`:

  ```text
  Status: 🔍 In review — PR #<pr>
  ```

## 4. After merge

Do not merge unless the user asks. When the PR is merged:

- the issue closes through `Closes #N` and the Project moves it to Done (set
  `Status` to Done by command if the Project has no such workflow);
- change the plan comment's status line to
  `Status: ✅ Completed — PR #<pr>`. It replaces a separate summary.

Tell the user the PR URL and what is left (review, merge).
