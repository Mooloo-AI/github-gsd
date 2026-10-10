# Ship

Open the pull request and hand the issue over for review.

## 1. Final review

- Review the diff once more as a reviewer would. Bring the branch up to date
  with the default branch, and make sure the checks still pass after any
  merge.
- Push the branch: `git push -u origin <branch>`.

## 2. Open the pull request

Fill in the repository's PR template, or else
[templates/github/pull_request_template.md](../templates/github/pull_request_template.md).
The description is the summary of the work:

- **Summary:** what changed and why, in a few bullets.
- `Closes #N`, so merging closes the issue.
- Links to the **Context and decisions**, **Implementation plan**, and any
  **Research** comment (`issue-comment.sh --url <N> context`, and so on).
- **Verification:** a link to the latest Verification comment
  (`issue-comment.sh --url <N> verification`), or, on the small path, each
  acceptance criterion and how it was checked.
- **Checks:** the commands run and their results.

Title it with the commit convention, for example
`feat(export): add CSV export for invoices`. Add `--draft` if the user asked
for a draft or something is still open.

```bash
gh pr create --base <default-branch> --title "<title>" --body-file pr.md
```

## 3. Update the issue

- Set `Status` to the in-review option ([start.md](start.md) has the
  commands).
- On the normal path, set the plan comment's status line with
  `issue-comment.sh`:

  ```text
  Status: 🔍 In review — PR #<pr>
  ```

## 4. After merge

When the PR is merged:

- the issue closes through `Closes #N`, and the Project moves it to Done (set
  `Status` to Done by command if the Project has no such workflow);
- set the plan comment's status line to `Status: ✅ Completed — PR #<pr>`.

Tell the user the PR URL and what is left (review, merge).
