# github-gsd

An agent skill that runs a **discuss → plan → execute → verify → ship** workflow directly on **GitHub Issues, Projects, and milestones**, with no local planning files. It works with Claude Code and Codex through the [Agent Skills](https://agentskills.io) format (`SKILL.md`) and needs only `gh` and `jq`.

## How it works

GitHub is the only source of truth:

| What | Where |
|---|---|
| Priority, status, roadmap | Project fields and `Status`, milestones, tracking issues, sub-issues, blocked-by links |
| Unscoped ideas | Project draft items |
| Requirements and acceptance criteria | The issue body |
| Research (optional) | Issue comment marked `<!-- workflow:research -->` |
| Context and decisions | Issue comment marked `<!-- workflow:context -->`, **one per issue, edited in place** |
| Implementation plan | Issue comment marked `<!-- workflow:plan -->`, **one per issue, edited in place**, tasks as checkboxes |
| Verification | Issue comment marked `<!-- workflow:verification -->`, plus PR checks |
| Summary | The pull request, with `Closes #N` |
| Lasting architecture decisions | ADRs in the repository (default `docs/adr/`) |

The workflow for one issue:

```
intake ─► start ─┬─► small path: change → checks → PR
                 │
                 └─► (research) ─► discuss ─► plan ─► execute ─► verify ─► ship ─► PR ─► Done
```

| Step | What the agent does |
|---|---|
| [Intake](skills/github-gsd/steps/intake.md) | Files a draft item, an issue (Requirements, Acceptance criteria, Open questions), or a tracking issue with sub-issues; sets labels, planning fields, and milestone. |
| [Start](skills/github-gsd/steps/start.md) | Picks a ready, unblocked issue, sets `Status` to In progress, creates `<type>/<issue>-<slug>`. |
| [Small path](skills/github-gsd/steps/small.md) | For a typo, config, or contained fix: implement, run checks, open the PR. No workflow comments. |
| [Research](skills/github-gsd/steps/research.md) | Optional. Writes a Research comment with findings, sources, and a recommendation. |
| [Discuss](skills/github-gsd/steps/discuss.md) | Settles open questions with the owner and writes the Context and decisions comment (D-01, D-02, …). Deferred items become new issues. |
| [Plan](skills/github-gsd/steps/plan.md) | Writes the Implementation plan comment: tasks, verification, risks. Adds an ADR when a decision has lasting impact. |
| [Execute](skills/github-gsd/steps/execute.md) | Commits with `Refs #N`, ticks plan tasks in place, and opens a sub-issue when scope grows. |
| [Verify](skills/github-gsd/steps/verify.md) | Runs the required checks, checks each acceptance criterion, and writes a Verification comment. |
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

Add a **github-gsd configuration** section to the repository's `AGENTS.md` (or `CLAUDE.md`) with the Project owner and number, the `Status` option names, labels, planning fields, required checks, and branch naming. The format and defaults are in [templates/config.md](skills/github-gsd/templates/config.md). For example:

```markdown
## github-gsd configuration

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

This adds a **Task** and a **Tracking issue** issue form and a pull request template with decision, plan, and verification links.

## Use

Ask the agent in plain words, for example:

- "File an issue: export invoices as CSV."
- "Work on #42."
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
- `context` and `plan` are single comments: `--append` is refused for them.
- It adds the marker as the first line when the body does not contain it, and rejects a body that carries a different marker.
- It prints the comment URL. Run it with `--help` for details.

## Develop

```bash
shellcheck skills/github-gsd/scripts/issue-comment.sh tests/mocks/gh
bats tests/
```

The tests use a mocked `gh` ([tests/mocks/gh](tests/mocks/gh)) and need [bats-core](https://github.com/bats-core/bats-core) 1.5 or later. CI runs them on Linux and on macOS with the system bash 3.2.

## Credit and affiliation

This project adapts the workflow ideas of [GSD Core](https://github.com/open-gsd/gsd-core) ("Get Shit Done") to a GitHub-native setup. **It is not affiliated with, endorsed by, or maintained by open-gsd or the GSD Core authors.** GSD Core is MIT-licensed; any adapted text keeps its copyright notice.

## License

[MIT](LICENSE)
