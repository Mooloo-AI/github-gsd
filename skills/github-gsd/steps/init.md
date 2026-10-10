# Init

Set up github-gsd in an existing repository: discover its real settings,
write the **github-gsd configuration** section, and open a PR. Run it when
the user asks to set up, initialize, or onboard github-gsd, or when a step
needs the configuration, there is none, and the user agrees to set it up.

Until the section is merged, the repository grants no standing permission:
init acts only because the user asked for it.

## 1. Check the prerequisites

```bash
gh auth status     # logged in to github.com
command -v jq      # jq 1.6 or later
```

If one is missing, tell the user how to fix it (`gh auth login`, install
`jq`) and stop.

## 2. Discover

Run `scripts/discover.sh` (in this skill's directory) from the repository's
checkout. It prints JSON to stdout; `--help` describes it. Don't save the
output inside the repository.

```bash
discover.sh | jq .
```

If `projects` is `null`, the token cannot read Projects: ask the user to run
`gh auth refresh -s project` and run discovery again, unless they do not use
a Project.

Build each setting from the output:

| Setting | From |
|---|---|
| Workflow | The standard line in [templates/config.md](../templates/config.md), always |
| Project | The one Project with `linked: true`. With several linked, or none linked but some open, ask; never guess. With no Project, `none` |
| Status field | The chosen Project's `Status` single-select field. Map its options in order to not ready, ready, in progress, in review, done; ask if the count or meaning is unclear |
| Planning fields | The Project's other single-select fields (for example `Priority`, `Effort`) with their options, set with `gh project item-edit`; otherwise `none` |
| Type labels | `labels` that name a kind of work (`bug`, `enhancement`, `documentation`, `tracking`, …) |
| Area labels | `labels` with an area prefix (`area:`, `component:`, `team:`, …); otherwise `none` |
| Triage label | An existing label for unscoped reports, otherwise `needs-triage` |
| Milestones | `none` when `milestones` is empty; otherwise how they are used, asking if unclear |
| Branch naming, PR size limit | The defaults, unless the owner says otherwise |
| Commit messages | The default when `commits.style` is `conventional`; otherwise describe the style in `git log` |
| Required checks | The `checks` that test, lint, type-check, or build. Leave out setup steps (installs, `mkdir`, version prints). If none fit, ask |
| Workflow checks | `checks` that apply only to some changes, for example a workflow linter; otherwise `none` |
| ADR directory | `adr_directory`, otherwise the default `docs/adr/` |
| PR template | `templates.pr_template`, otherwise this skill's `templates/github/pull_request_template.md` |

Write every line, including those that match the defaults, so the section is
complete on its own.

## 3. Ask once

Ask the owner in one batch, each question with your recommendation: the
Project when it is not clear, any value discovery could not settle, and the
optional setup in step 5. Then wait for the answers.

## 4. Write the section

Create the branch from the up-to-date default branch:

```bash
git fetch origin
git switch -c chore/setup-github-gsd origin/<default_branch>
```

If the repository already has a section, updating it is a change like any
other: file an issue ([intake.md](intake.md)) and use its branch
([start.md](start.md)) instead.

Pick the file: the one in `agent_files` with `has_config: true`; otherwise
`AGENTS.md` if it exists, then `CLAUDE.md`; otherwise create `AGENTS.md`.

- **No section yet:** add `## github-gsd configuration` with the lines from
  step 2 at the end of the file.
- **Section exists:** replace only the lines from its heading up to the next
  `## ` heading or the end of the file. Keep values that discovery cannot
  see or confirm (planning field commands, workflow checks, milestone usage,
  notes on a line). Change a value only when the repository contradicts it,
  and list each change in the PR.

Nothing outside the section changes. Check with `git diff`.

## 5. Optional setup

Offer each one, and do it only if the owner agreed in step 3. Never overwrite
an existing file or label.

- **GitHub templates:** copy the files from this skill's `templates/github/`
  into `.github/` that the repository does not have yet. Then point
  **PR template** at `.github/pull_request_template.md`.
- **Labels:** create the missing type labels (such as `tracking`) and the
  triage label. This takes effect on GitHub right away, not through the PR:
  `gh label create "<name>" --color <hex> --description "<text>"`.
- **ADR directory:** create it, with a `README.md` from
  [templates/adr-readme.md](../templates/adr-readme.md).

## 6. Open the PR

Commit in the repository's style (`chore: set up github-gsd` for
Conventional Commits), push the branch, and open the PR, with `Closes #N`
when there is an issue. Never push to the default branch. In the
description, list:

- the discovered settings;
- each answer the owner gave;
- each value changed in an existing section;
- the labels created on GitHub.

```bash
git push -u origin chore/setup-github-gsd
gh pr create --base <default_branch> --title "chore: set up github-gsd" --body-file pr.md
```

## Done when

The PR is open and the user has its URL. Once it is merged, the section is
the standing configuration, and the other steps follow it.
