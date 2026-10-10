# github-gsd configuration

Copy this section into the repository's `AGENTS.md` (or `CLAUDE.md`) and edit
the values. Leave a line out to use its default. Keep secrets out of it.

The values shown are the defaults.

```markdown
## github-gsd configuration

- **Workflow:** use the github-gsd skill for every change: file or pick an issue and create its branch before changing any file
- **Project:** owner `<org-or-user>`, number `<n>`
- **Status field:** `Status`, with options Backlog → Ready → In progress → In review → Done
- **Planning fields:** none
- **Type labels:** `bug`, `enhancement`, `documentation`, `tracking`
- **Area labels:** none
- **Triage label:** `needs-triage`
- **Milestones:** releases; assign every issue that belongs to one
- **Branch naming:** `<type>/<issue>-<slug>`, where type is the Conventional Commits type
- **Commit messages:** Conventional Commits with a `Refs #<issue>` footer
- **Required checks:** none configured; ask the owner
- **PR size limit:** 1500 changed lines (additions + deletions)
- **Workflow checks:** none
- **ADR directory:** `docs/adr/`
- **PR template:** `.github/pull_request_template.md` if present
```

## Settings

| Setting | Meaning |
|---|---|
| Workflow | The rule every agent in the repository follows, including agents that do not load the skill on their own. Keep this line even when you leave others out. |
| Project | The GitHub Project (v2) that holds the board. No default: without it, skip Project updates and say so. |
| Status field | The single-select field for the workflow state and the names of its five options in order: not ready, ready, in progress, in review, done. If a repository uses other names, map them here. |
| Planning fields | Fields to set at intake, for example `Priority` and `Effort` as Project fields or organization issue fields, and how to set them. A free-form description, including the command to use, is fine. |
| Type labels | Labels for the kind of work. `tracking` marks tracking issues. |
| Area labels | Labels for the product, component, or team, for example `area: api`. Each issue gets one. |
| Triage label | Marks issues filed by hand without the standard sections, until the agent writes their Specification comment. The Request issue form applies it; change the form's `labels` too if you rename it. |
| Milestones | How milestones are used, and whether there is a tracking issue per milestone. |
| Branch naming | Pattern for work branches. |
| Commit messages | Commit convention. |
| Required checks | Commands that must pass before a PR, for example `npm test` and `npm run build`. |
| PR size limit | The most lines (additions plus deletions) one pull request may change, against the default branch. Lockfiles and generated files do not count. Planned in the plan step and checked in verify; work that is larger is split into sub-issues. |
| Workflow checks | Extra checks for some kinds of change, for example `actionlint` for workflow files or a deployment dry run for infrastructure changes. |
| ADR directory | Where Architecture Decision Records live. |
| PR template | The pull request template to fill in. |

## Example

```markdown
## github-gsd configuration

- **Workflow:** use the github-gsd skill for every change: file or pick an issue and create its branch before changing any file
- **Project:** owner `acme`, number `3`
- **Status field:** `Status`, with options Todo → Ready → Doing → Review → Done
- **Planning fields:** organization issue fields `Priority` (Urgent, High, Medium, Low)
  and `Effort` (High, Medium, Low); set with the `setIssueFieldValue` GraphQL mutation
- **Area labels:** `area: api`, `area: web`, `area: shared`
- **Required checks:** `npm run typecheck`, `npm test`, `npm run build`
- **Workflow checks:** `actionlint .github/workflows/*.yml` for workflow changes
```
