# github-gsd

An agent skill that runs a **discuss → plan → execute → verify → ship** workflow directly on **GitHub Issues, Projects, and milestones**, with no local planning files. It works with Claude Code and Codex through the [Agent Skills](https://agentskills.io) format (`SKILL.md`) and needs only `gh` and `jq`.

## How it works

GitHub is the only source of truth:

| What | Where |
|---|---|
| Priority, status, roadmap | Project fields and `Status`, milestones, tracking issues, sub-issues, blocked-by links |
| Unscoped ideas | Project draft items |
| Requirements and acceptance criteria | The issue body, or for an issue filed by hand, an issue comment marked `<!-- workflow:spec -->`, **one per issue, edited in place** |
| Research (optional) | Issue comment marked `<!-- workflow:research -->` |
| Context and decisions | Issue comment marked `<!-- workflow:context -->`, **one per issue, edited in place** |
| Implementation plan | Issue comment marked `<!-- workflow:plan -->`, **one per issue, edited in place**, tasks as checkboxes |
| Verification | Issue comment marked `<!-- workflow:verification -->`, plus PR checks |
| Summary | The pull request, with `Closes #N` |
| Lasting architecture decisions | ADRs in the repository (default `docs/adr/`) |

The workflow for one issue:

```
intake ─┐
triage ─┴► start ─┬─► small path: change → checks → PR
                  │
                  └─► (research) ─► discuss ─► plan ─► execute ─► verify ─► ship ─► PR ─► Done
```

Pull requests stay small: one reviewable concern, within a configurable size limit (default 1500 changed lines, additions plus deletions). The plan step estimates the size before any code is written. Work that is too large becomes a tracking issue whose sub-issues are ordered, independently shippable slices, much like phases in GSD Core. Each slice gets its own issue, branch, and PR.

| Step | What the agent does |
|---|---|
| [Init](skills/github-gsd/steps/init.md) | Once per repository: discovers its settings with `discover.sh`, writes the github-gsd configuration section, offers optional setup (templates, labels, ADR directory), and opens a PR. |
| [Intake](skills/github-gsd/steps/intake.md) | Files a draft item, an issue (Requirements, Acceptance criteria, Open questions), or, for work too large for one small PR, a tracking issue with ordered sub-issues linked by blocked-by; sets labels, planning fields, and milestone. |
| [Triage](skills/github-gsd/steps/triage.md) | For an issue filed by hand: labels it `needs-triage`, then writes a Specification comment with Requirements, Acceptance criteria, and Open questions, leaving the reporter's text unchanged. |
| [Start](skills/github-gsd/steps/start.md) | Picks a ready, unblocked issue, sets `Status` to In progress, creates `<type>/<issue>-<slug>`. |
| [Small path](skills/github-gsd/steps/small.md) | For a typo, config, or contained fix: implement, run checks, open the PR. No workflow comments. |
| [Research](skills/github-gsd/steps/research.md) | Optional. Writes a Research comment with findings, sources, and a recommendation. |
| [Discuss](skills/github-gsd/steps/discuss.md) | Settles open questions with the owner and writes the Context and decisions comment (D-01, D-02, …). Deferred items become new issues. |
| [Plan](skills/github-gsd/steps/plan.md) | Writes the Implementation plan comment: estimated size, tasks, verification, risks. Splits an oversized issue into sub-issues before posting. Adds an ADR when a decision has lasting impact. |
| [Execute](skills/github-gsd/steps/execute.md) | Commits with `Refs #N`, ticks plan tasks in place, and opens a sub-issue when scope grows. |
| [Verify](skills/github-gsd/steps/verify.md) | Runs the required checks and the PR size check, checks each acceptance criterion, and writes a Verification comment. |
| [Ship](skills/github-gsd/steps/ship.md) | Opens the PR with `Closes #N` and links to the comments, sets `Status` to In review. |

The agent writes the workflow comments directly, with no approval step; the owner edits them afterward if needed. The entry point for the agent is [SKILL.md](skills/github-gsd/SKILL.md).

## Requirements

- [GitHub CLI](https://cli.github.com) (`gh`), authenticated with the `project` scope for Project updates: `gh auth refresh -s project`. Sub-issue and blocked-by flags need a recent `gh`.
- [`jq`](https://jqlang.org) 1.6 or later.
- Bash 3.2 or later (the macOS system bash works).

## Install

The skill lives in [`skills/github-gsd/`](skills/github-gsd). Install it with the [skills.sh](https://skills.sh) CLI, which works for Claude Code, Codex, and other agents:

```bash
npx skills add Mooloo-AI/github-gsd
```

The CLI asks which agents to install for and whether to install for this project or globally. To skip the questions:

```bash
# This project only. Commit .agents/skills/ (and .claude/skills/) to share it with your team.
npx skills add Mooloo-AI/github-gsd -a claude-code -a codex -y

# All your projects
npx skills add Mooloo-AI/github-gsd -g -a claude-code -a codex -y
```

To update, run `npx skills update`.

### Manual install

Clone the repository anywhere and link the skill directory into your agent's skills directory:

```bash
git clone https://github.com/Mooloo-AI/github-gsd.git ~/src/github-gsd
ln -s ~/src/github-gsd/skills/github-gsd ~/.claude/skills/github-gsd   # Claude Code
ln -s ~/src/github-gsd/skills/github-gsd ~/.agents/skills/github-gsd   # Codex
```

To update, run `git pull` in the clone.

Whichever way you install it, keep the directory name `github-gsd`. Don't use a `gsd-` prefix: GSD Core's install, update, and uninstall delete every `gsd-*` entry in the skills directory, whoever installed it. That's why this skill was renamed from `gsd-github`.

### Moving from an older install

Before the skill moved to `skills/github-gsd/`, the install was a clone of the whole repository at `~/.claude/skills/github-gsd` (or `~/.agents/skills/github-gsd`). After a `git pull`, that clone no longer has a `SKILL.md` at its top level. Remove it and install again:

```bash
rm -rf ~/.claude/skills/github-gsd
npx skills add Mooloo-AI/github-gsd -g -a claude-code -y
```

## Configure

The recommended way is to ask the agent: "Set up github-gsd here." The [init step](skills/github-gsd/steps/init.md):

- checks that `gh` is authenticated and `jq` is installed;
- runs [`discover.sh`](#the-discovery-helper) to read the repository's Projects, `Status` options, labels, milestones, CI checks, and commit style;
- asks you once about what it can't settle, such as which Project to use;
- writes a **github-gsd configuration** section to `AGENTS.md` (or `CLAUDE.md`) and opens a PR. If the section already exists, init updates it in place.

Init also offers optional setup: copying the GitHub templates below, creating missing labels, and creating the ADR directory. It does each one only if you agree.

To write the section by hand instead, include the workflow rule, the Project owner and number, the `Status` option names, labels, planning fields, required checks, PR size limit, and branch naming. The format and defaults are in [templates/config.md](skills/github-gsd/templates/config.md). For example:

```markdown
## github-gsd configuration

- **Workflow:** use the github-gsd skill for every change: file or pick an issue and create its branch before changing any file
- **Project:** owner `acme`, number `3`
- **Status field:** `Status`, with options Backlog → Ready → In progress → In review → Done
- **Area labels:** `area: api`, `area: web`
- **Required checks:** `npm run typecheck`, `npm test`, `npm run build`
```

Repository-specific rules stay in the repository; the skill contains none.

Optionally copy the GitHub templates into the repository (adjust the path to where you installed the skill):

```bash
cp -R ~/.claude/skills/github-gsd/templates/github/. .github/
```

This adds **Task**, **Tracking issue**, and **Request** issue forms and a pull request template with decision, plan, and verification links. The Request form is free text for people who don't follow the workflow; it applies the `needs-triage` label so the agent triages it.

## Use

Ask the agent in plain words, for example:

- "Set up github-gsd here."
- "File an issue: export invoices as CSV."
- "Work on #42."
- "Which issues need triage?" / "Triage #57."
- "Plan #42." / "Verify #42." / "Ship it."

In Claude Code you can also invoke it as `/github-gsd work on #42`.

## The comment helper

[`issue-comment.sh`](skills/github-gsd/scripts/issue-comment.sh) writes the marked comments:

```bash
issue-comment.sh 42 context decisions.md               # create or update in place
echo "..." | issue-comment.sh 42 plan -                # body from stdin
issue-comment.sh --append 42 verification run2.md      # add another comment
issue-comment.sh --get 42 plan > plan.md               # read the current body
issue-comment.sh --url 42 context                      # print the comment URL
issue-comment.sh --repo acme/widgets 42 plan plan.md   # another repository
```

- It finds the marked comment across all comment pages, creates it if missing, and edits it in place otherwise.
- It refuses to edit when two comments carry the same marker (exit status 3) and lists them.
- `spec`, `context`, and `plan` are single comments: `--append` is refused for them.
- It adds the marker as the first line when the body does not contain it, and rejects a body that carries a different marker.
- It prints the comment URL. Run it with `--help` for details.

## The discovery helper

[`discover.sh`](skills/github-gsd/scripts/discover.sh) prints a repository's settings as one JSON object, so the configuration can be built from what the repository actually has: Projects and their single-select fields, labels, milestones, issue forms and PR template, candidate checks from CI workflows and build files, the commit style, the ADR directory, and codebase docs. Run it inside a checkout; it changes nothing.

```bash
discover.sh | jq '.projects'
```

If the Projects or labels cannot be read (for example, without the `project` scope), that key is `null` and a hint goes to stderr. Run it with `--help` for the full output format.

## Develop

```bash
shellcheck skills/github-gsd/scripts/issue-comment.sh skills/github-gsd/scripts/discover.sh tests/mocks/gh
bats tests/
```

The tests use a mocked `gh` ([tests/mocks/gh](tests/mocks/gh)) and need [bats-core](https://github.com/bats-core/bats-core) 1.5 or later. CI runs them on Linux and on macOS with the system bash 3.2.

End every `[[ ]]`, `(( ))`, and `! …` assertion in a test with `|| return 1`: bash 3.2 ignores such a check when it fails and is not the test's last command, and every bash ignores a failing `!` command. [`tests/style.bats`](tests/style.bats) enforces it.

### Releases

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org). On every push to `main`, [release-please](https://github.com/googleapis/release-please) updates a release pull request; merging it bumps [VERSION](VERSION), adds the changes to [CHANGELOG.md](CHANGELOG.md), tags `vX.Y.Z`, and creates a GitHub Release. Installs follow `main`, so a release records what changed and doesn't gate what users get.

## Credit and affiliation

This project adapts the workflow ideas of [GSD Core](https://github.com/open-gsd/gsd-core) ("Get Shit Done") to a GitHub-native setup. **It is not affiliated with, endorsed by, or maintained by open-gsd or the GSD Core authors.** GSD Core is MIT-licensed; any adapted text keeps its copyright notice.

## License

[MIT](LICENSE)
