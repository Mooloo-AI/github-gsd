# Start

Pick the issue, mark it in progress, and create its branch.

## 1. Pick the issue

Use the issue the user named. Otherwise pick the highest-priority unblocked
issue in the ready `Status` option:

```bash
gh project item-list <project> --owner <owner> --format json --limit 500 \
  --query 'status:"<ready option>"'
gh issue view <N> --json title,body,state,labels,milestone,blockedBy,subIssues,projectItems
```

Check that:

- the issue is open, in the right repository, and scoped (it has
  Requirements and Acceptance criteria); if not, go to
  [intake.md](intake.md) first;
- no open issue blocks it (`blockedBy` is empty or all closed). If one does,
  tell the user and stop, or start the blocker if they agree;
- it is not a tracking issue; for one, start one of its sub-issues.

## 2. Set Status to In progress

Skip this, and say so, when no Project is configured. Look up the IDs:

```bash
project_id=$(gh project view <project> --owner <owner> --format json --jq .id)
# item-add returns the existing item when the issue is already on the Project.
item_id=$(gh project item-add <project> --owner <owner> --url <issue-url> --format json --jq .id)
gh project field-list <project> --owner <owner> --format json \
  --jq '.fields[] | select(.name == "<Status field>") | {id, options}'
gh project item-edit --project-id "$project_id" --id "$item_id" \
  --field-id <status field id> --single-select-option-id <in-progress option id>
```

Use the same commands for every other `Status` change.

## 3. Create the branch

Branch from the up-to-date default branch with the configured pattern
(default `<type>/<issue>-<slug>`, for example `feat/42-csv-export`), or
continue on the issue's branch if one already exists:

```bash
git fetch origin
git switch -c <branch> origin/<default-branch>
```

## 4. Choose the path

- **Small path** ([small.md](small.md)): a typo, a config change, or a
  contained fix with an obvious solution, no open questions, and no design
  choices. No workflow comments.
- **Normal path:** everything else, and whenever in doubt. If the issue
  already has workflow comments, resume where the routing table in `SKILL.md`
  says.
