# Intake

Turn an idea, request, or bug report into the right GitHub item.

## 1. Decide what it is

| It is… | Create |
|---|---|
| An idea, an ambiguous roadmap candidate, unscoped product work, or work without a clear owning repository | A **Project draft item** |
| Concrete work with a clear scope, an owning repository, and checkable acceptance criteria | An **issue** |
| Product-level or cross-repository work made of several issues | A **tracking issue** with sub-issues |

Search first so you do not file a duplicate:

```bash
gh issue list --state all --search "<keywords>" --limit 20
gh project item-list <project> --owner <owner> --format json --limit 500 \
  --jq '.items[] | select(.content.type == "DraftIssue") | .title'
```

If a matching issue or draft exists, update it instead.

## 2a. Draft item

```bash
gh project item-create <project> --owner <owner> --title "<title>" --body "<notes>"
```

Keep the notes short: the idea, why it matters, and what is unclear. When it
becomes scoped, convert it to an issue in its owning repository (in the
Project UI, or by creating the issue with section 2b and deleting the draft
with `gh project item-delete <project> --owner <owner> --id <item-id>`).

## 2b. Issue

Write the body with [templates/issue.md](../templates/issue.md): **Summary**,
**Requirements**, **Acceptance criteria** (checkboxes, each one checkable),
and **Open questions**. If the repository has its own task issue template,
follow its sections instead.

Title: a plain outcome ("Export invoices as CSV"), not a task number or phase
name.

```bash
gh issue create --title "<title>" --body-file body.md \
  --label "<type label>" --label "<area label>" \
  [--milestone "<milestone>"] [--parent <tracking-issue>] [--blocked-by <issue>,...]
```

Then:

1. Add it to the Project:
   `gh project item-add <project> --owner <owner> --url <issue-url>`.
2. Set the planning fields from the configuration (for example Priority and
   Effort). Issue templates cannot set them, so always do this by command.
3. Set `Status` to the ready option if the issue is scoped and unblocked,
   otherwise leave it at the first option. See [start.md](start.md) for the
   command.
4. If another issue blocks it and you did not pass `--blocked-by`, add the
   link now: `gh issue edit <N> --add-blocked-by <blocker>`.

## 2c. Tracking issue

Create the parent with the type label `tracking` and a body from
[templates/tracking-issue.md](../templates/tracking-issue.md): the goal, the
planned children, and what is out of scope. Create each child as in 2b with
`--parent <tracking-issue>`, or attach an existing issue:

```bash
gh issue edit <child> --parent <tracking-issue>
```

Close the tracking issue when its last sub-issue closes. If it belongs to a
milestone, put the parent and every child in that milestone.

## Done when

The item exists, has its labels and planning fields, is on the Project, and
you have given the user its URL.
