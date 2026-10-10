# Intake

Turn an idea, request, or bug report into the right GitHub item.

## 1. Decide what it is

| It is… | Create |
|---|---|
| An idea, an ambiguous roadmap candidate, or work without a clear scope or owning repository | A **Project draft item** |
| Concrete work with a clear scope, an owning repository, and checkable acceptance criteria | An **issue** |
| Work too large for one small PR, in one repository or several, or product-level work made of several issues | A **tracking issue** with sub-issues |

Search first, and update a matching issue or draft instead of filing a
duplicate:

```bash
gh issue list --state all --search "<keywords>" --limit 20
gh project item-list <project> --owner <owner> --format json --limit 500 \
  --jq '.items[] | select(.content.type == "DraftIssue") | .title'
```

## 2a. Draft item

```bash
gh project item-create <project> --owner <owner> --title "<title>" --body "<notes>"
```

Keep the notes short: the idea, why it matters, and what is unclear. Once it
is scoped, convert it to an issue in its owning repository: in the Project
UI, or by creating the issue as in 2b and deleting the draft with
`gh project item-delete <project> --owner <owner> --id <item-id>`.

## 2b. Issue

Write the body with [templates/issue.md](../templates/issue.md): **Summary**,
**Requirements**, **Acceptance criteria** (checkboxes, each checkable), and
**Open questions**. If the repository has its own task issue template, follow
its sections instead. Title it with a plain outcome ("Export invoices as
CSV"), not a task number or phase name.

```bash
gh issue create --title "<title>" --body-file body.md \
  --label "<type label>" --label "<area label>" \
  [--milestone "<milestone>"] [--parent <tracking-issue>] [--blocked-by <issue>,...]
```

Then:

1. Add it to the Project:
   `gh project item-add <project> --owner <owner> --url <issue-url>`.
2. Set the configured planning fields by command; issue templates cannot
   set them.
3. Set `Status` to the ready option if the issue is scoped and unblocked,
   otherwise leave the first option ([start.md](start.md) has the command).
4. Add any blocker you did not pass with `--blocked-by`:
   `gh issue edit <N> --add-blocked-by <blocker>`.

## 2c. Tracking issue

Create the parent with the type label `tracking` and a body from
[templates/tracking-issue.md](../templates/tracking-issue.md): the goal, the
planned children, and what is out of scope.

Split the work into ordered slices. Each slice delivers a working, verifiable
increment that can ship even if later slices never do, fits in one small PR,
and has its own acceptance criteria and its own discuss → plan → execute →
verify → ship cycle.

Create each child as in 2b with `--parent <tracking-issue>`, or attach an
existing issue. Link a slice that depends on an earlier one with blocked-by,
so the order is visible and [start.md](start.md) picks them in order:

```bash
gh issue edit <child> --parent <tracking-issue>
gh issue edit <child> --add-blocked-by <earlier-child>
```

Close the tracking issue when its last sub-issue closes. If it belongs to a
milestone, put the parent and every child in that milestone.

## Done when

The item exists with its labels and planning fields, is on the Project, and
the user has its URL. If the user asked for the change itself ("add …",
"fix …"), not only to record it, continue with [start.md](start.md).
