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
| [Intake](steps/intake.md) | Files a draft item, an issue (Requirements, Acceptance criteria, Open questions), or a tracking issue with sub-issues; sets labels, planning fields, and milestone. |
| [Start](steps/start.md) | Picks a ready, unblocked issue, sets `Status` to In progress, creates `<type>/<issue>-<slug>`. |
| [Small path](steps/small.md) | For a typo, config, or contained fix: implement, run checks, open the PR. No workflow comments. |
| [Research](steps/research.md) | Optional. Writes a Research comment with findings, sources, and a recommendation. |
| [Discuss](steps/discuss.md) | Settles open questions with the owner and writes the Context and decisions comment (D-01, D-02, …). Deferred items become new issues. |
| [Plan](steps/plan.md) | Writes the Implementation plan comment: tasks, verification, risks. Adds an ADR when a decision has lasting impact. |
| [Execute](steps/execute.md) | Commits with `Refs #N`, ticks plan tasks in place, and opens a sub-issue when scope grows. |
| [Verify](steps/verify.md) | Runs the required checks, checks each acceptance criterion, and writes a Verification comment. |
| [Ship](steps/ship.md) | Opens the PR with `Closes #N` and links to the comments, sets `Status` to In review. |

The agent writes the workflow comments directly, with no approval step; the owner edits them afterward if needed. The entry point for the agent is [SKILL.md](SKILL.md).

## Requirements

- [GitHub CLI](https://cli.github.com) (`gh`), authenticated with the `project` scope for Project updates: `gh auth refresh -s project`. Sub-issue and blocked-by flags need a recent `gh`.
- [`jq`](https://jqlang.org) 1.6 or later.
- Bash 3.2 or later (the macOS system bash works).

## Install

The skill is this whole repository. Clone it into a skills directory named `github-gsd`.

Don't name the directory with a `gsd-` prefix. GSD Core's install, update, and uninstall delete every `gsd-*` entry in the skills directory, whoever installed it. That's why this skill was renamed from `gsd-github`.

### Claude Code

For all your projects:

```bash
git clone https://github.com/Mooloo-AI/github-gsd.git ~/.claude/skills/github-gsd
```

For one repository (shared with everyone who works on it):

```bash
git submodule add https://github.com/Mooloo-AI/github-gsd.git .claude/skills/github-gsd
```

### Codex

For all your projects:

```bash
git clone https://github.com/Mooloo-AI/github-gsd.git ~/.agents/skills/github-gsd
```

For one repository:

```bash
git submodule add https://github.com/Mooloo-AI/github-gsd.git .agents/skills/github-gsd
```

To update, run `git pull` in the clone (or `git submodule update --remote`).

## Configure

Add a **github-gsd configuration** section to the repository's `AGENTS.md` (or `CLAUDE.md`) with the Project owner and number, the `Status` option names, labels, planning fields, required checks, and branch naming. The format and defaults are in [templates/config.md](templates/config.md). For example:

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

[`scripts/issue-comment.sh`](scripts/issue-comment.sh) writes the marked comments:

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
shellcheck scripts/issue-comment.sh tests/mocks/gh
bats tests/
```

The tests use a mocked `gh` ([tests/mocks/gh](tests/mocks/gh)) and need [bats-core](https://github.com/bats-core/bats-core) 1.5 or later. CI runs them on Linux and on macOS with the system bash 3.2.

## Credit and affiliation

This project adapts the workflow ideas of [GSD Core](https://github.com/open-gsd/gsd-core) ("Get Shit Done") to a GitHub-native setup. **It is not affiliated with, endorsed by, or maintained by open-gsd or the GSD Core authors.** GSD Core is MIT-licensed; any adapted text keeps its copyright notice.

## License

[MIT](LICENSE)
