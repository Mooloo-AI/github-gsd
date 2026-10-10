# Start

Pick the issue, mark it in progress, and create its branch.

## 1. Pick the issue

If the user named an issue, use it. Otherwise pick the highest-priority issue
in the ready `Status` option that is not blocked:

```bash
gh project item-list <project> --owner <owner> --format json --limit 500 \
  --query 'status:"<ready option>"'
gh issue view <N> --json title,body,state,labels,milestone,blockedBy,subIssues,projectItems
```

Before starting, check that:

- the issue is open, scoped (it has Requirements and Acceptance criteria, in
  its body or its Specification comment), and in the right repository;
- no open issue blocks it (`blockedBy` is empty or all closed). If one does,
  tell the user and stop, or start the blocker instead if they agree;
- it is not a tracking issue. For a tracking issue, start one of its
  sub-issues.

If the issue is not scoped, go to [triage.md](triage.md) first.

## 2. Set Status to In progress

Look up the IDs; do not hard-code them.

```bash
project_id=$(gh project view <project> --owner <owner> --format json --jq .id)
# item-add returns the existing item when the issue is already on the Project.
item_id=$(gh project item-add <project> --owner <owner> --url <issue-url> --format json --jq .id)
gh project field-list <project> --owner <owner> --format json \
  --jq '.fields[] | select(.name == "<Status field>") | {id, options}'
gh project item-edit --project-id "$project_id" --id "$item_id" \
  --field-id <status field id> --single-select-option-id <in-progress option id>
```

Use the same commands later for In review (ship) and any other Status change.
If the repository has no Project configured, skip this and say so.

## 3. Create the branch

Start from the up-to-date default branch and use the configured pattern
(default `<type>/<issue>-<slug>`, for example `feat/42-csv-export`):

```bash
git fetch origin
git switch -c <branch> origin/<default-branch>
```

If a branch for the issue already exists (yours or the user's), continue on it
instead.

## 4. Choose the path

- **Small path** ([small.md](small.md)): a typo, a config change, or a
  contained fix whose solution is obvious, with no open questions and no
  design choices. No workflow comments.
- **Normal path:** everything else. Continue with
  [research.md](research.md) if it is needed, otherwise
  [discuss.md](discuss.md). If the issue already has workflow comments, resume
  at the step the routing table in `SKILL.md` gives.

When in doubt, take the normal path.
