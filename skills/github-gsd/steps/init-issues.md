# Init: bring in open issues

Run this from [init.md](init.md) step 6 once the repository has a Project
and the owner agreed. It puts the open issues that are not on the Project
yet on it, with a `Status`. Pull requests, closed issues, and issues already
on the Project are left alone. It changes GitHub right away; list what
changed in the PR. Look up every ID; never hard-code one.

## 1. Look up the IDs

```bash
project_id=$(gh project view <project number> --owner <owner> --format json --jq .id)
status_field=$(gh project field-list <project number> --owner <owner> --format json \
  --jq '.fields[] | select(.name == "<Status field>")')
field_id=$(jq -r .id <<<"$status_field")
first_option=$(jq -r '.options[0].id' <<<"$status_field")
ready_option=$(jq -r --arg name "<ready option>" \
  '.options[] | select(.name == $name) | .id' <<<"$status_field")
```

## 2. List and classify

An issue gets the ready option when it is scoped (its body has
Requirements and Acceptance criteria headings), has no open blocker, and is
not a tracking issue (the `tracking` label, or sub-issues). Every other
issue gets the first option. Unscoped issues that are not tracking issues
also get the triage label.

```bash
on_project=$(gh project item-list <project number> --owner <owner> --format json \
  --limit 1000 --jq '[.items[].content.url | select(.)]')
issues=$(gh issue list --state open --limit 1000 \
  --json number,title,url,body,labels,blockedBy,subIssuesSummary |
  jq --argjson on "$on_project" '
    [ .[] | select(.url as $u | $on | index($u) | not)
      | ((.body // "") | test("(^|\n)#+ *Requirements"; "i")
          and test("(^|\n)#+ *Acceptance criteria"; "i")) as $scoped
      | (([.labels[].name] | index("tracking")) != null
          or .subIssuesSummary.total > 0) as $tracking
      | ([.blockedBy.nodes[] | select(.state == "OPEN")] | length > 0) as $blocked
      | { number, title, url,
          column: (if $scoped and ($blocked | not) and ($tracking | not)
                   then "ready" else "first" end),
          triage: (($scoped | not) and ($tracking | not)) } ]')
```

## 3. Show the plan and ask

Show the owner each issue with the `Status` it will get and whether it gets
the triage label, with the totals. If there are 1000 open issues, say that
only the first 1000 are covered. Change nothing until the owner agrees.

```bash
jq -r '.[] | "#\(.number) \(.title) → \(.column)\(if .triage then " + triage label" else "" end)"' <<<"$issues"
```

Offer one alternative: putting every issue in the first option, for owners
who move issues to ready by hand
(`issues=$(jq 'map(.column = "first")' <<<"$issues")`).

Also tell the owner: if the Project's built-in "Auto-add sub-issues to
project" workflow is on (it is by default), adding a tracking issue also
adds its sub-issues, closed ones included, and the "Item closed" workflow
sets those to Done.

## 4. Apply

Create the triage label if it is missing and some issue needs it, as in
[triage.md](triage.md). Then:

```bash
jq -r '.[] | [.url, .number, .column, .triage] | @tsv' <<<"$issues" |
  while IFS=$'\t' read -r url issue column triage; do
    item_id=$(gh project item-add <project number> --owner <owner> --url "$url" \
      --format json --jq .id)
    option=$ready_option
    if [ "$column" = first ]; then option=$first_option; fi
    gh project item-edit --project-id "$project_id" --id "$item_id" \
      --field-id "$field_id" --single-select-option-id "$option" >/dev/null
    if [ "$triage" = true ]; then
      gh issue edit "$issue" --add-label "<triage label>" >/dev/null
    fi
    echo "#$issue → $column"
  done
```

## 5. Continue

Go back to [init.md](init.md) step 6. Report what changed to the owner, and
list it in the PR.
