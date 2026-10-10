# Init: create a Project

Run this from [init.md](init.md) step 4, only when no Project fits and the
owner agreed. It takes effect on GitHub right away; list what you created in
the PR. Look up every ID; never hard-code one.

## 1. Create and link

```bash
project=$(gh project create --owner <owner> --title "<title>" --format json)
number=$(jq -r .number <<<"$project"); project_id=$(jq -r .id <<<"$project")
gh project link "$number" --owner <owner> --repo <owner>/<repo>
```

## 2. Set the Status options

Replace the default `Status` options (Todo, In Progress, Done) with the five
workflow states. Keep the existing option IDs, so the built-in workflows
that set Done still work:

```bash
status_field=$(gh project field-list "$number" --owner <owner> --format json \
  --jq '.fields[] | select(.name == "Status")')
jq -n --argjson f "$status_field" '
  def opt($old; $name; $color; $text):
    { name: $name, color: $color, description: $text }
    + ([ $f.options[] | select(.name == $old) | { id } ] | first // {});
  { query: "mutation($input: UpdateProjectV2FieldInput!) { updateProjectV2Field(input: $input) { clientMutationId } }",
    variables: { input: { fieldId: $f.id, singleSelectOptions: [
      opt("Todo"; "Backlog"; "GRAY"; "Not ready to start"),
      opt(""; "Ready"; "BLUE"; "Scoped and unblocked"),
      opt("In Progress"; "In progress"; "YELLOW"; "Being worked on"),
      opt(""; "In review"; "PURPLE"; "Pull request open"),
      opt("Done"; "Done"; "GREEN"; "Merged or closed") ] } } }' |
  gh api graphql --input -
```

## 3. Add the planning fields

Add the planning fields Priority (Urgent, High, Medium, Low) and Effort
(High, Medium, Low), if the owner agreed:

- **User owner:** Project fields.

  ```bash
  gh project field-create "$number" --owner <owner> --name Priority \
    --data-type SINGLE_SELECT --single-select-options "Urgent,High,Medium,Low"
  gh project field-create "$number" --owner <owner> --name Effort \
    --data-type SINGLE_SELECT --single-select-options "High,Medium,Low"
  ```

- **Organization owner:** organization issue fields. Reuse those in
  `issue_fields`. Creating a missing one needs an organization admin and the
  `admin:org` scope (`gh auth refresh -s admin:org`); if that's not possible,
  ask the owner to create it, or fall back to Project fields. Then add each
  issue field to the Project:

  ```bash
  org_id=$(gh api graphql -f login=<owner> --jq .data.organization.id \
    -f query='query($login: String!) { organization(login: $login) { id } }')
  jq -n --arg org "$org_id" '
    { query: "mutation($input: CreateIssueFieldInput!) { createIssueField(input: $input) { clientMutationId } }",
      variables: { input: { ownerId: $org, name: "Priority", dataType: "SINGLE_SELECT",
        options: [ ["Urgent", "PINK"], ["High", "RED"], ["Medium", "YELLOW"], ["Low", "GREEN"] ]
          | to_entries | map({ name: .value[0], color: .value[1], priority: (.key + 1) }) } } }' |
    gh api graphql --input -
  # Effort: [["High", "RED"], ["Medium", "YELLOW"], ["Low", "GREEN"]]
  gh api graphql -f login=<owner> --jq '.data.organization.issueFields.nodes[] | select(.name) | [.name, .id] | @tsv' \
    -f query='query($login: String!) { organization(login: $login) { issueFields(first: 100) { nodes { ... on IssueFieldSingleSelect { id name } } } } }'
  gh api graphql -f project="$project_id" -f field=<issue field id> \
    -f query='mutation($project: ID!, $field: ID!) { createProjectV2IssueField(input: { projectId: $project, issueFieldId: $field }) { clientMutationId } }'
  ```

## 4. Continue

Go back to [init.md](init.md) step 5 and write the new Project's owner
and number, the five `Status` options, and the planning fields into the
section.
