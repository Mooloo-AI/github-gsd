---
name: github-gsd
description: 'Run a discuss → plan → execute → verify → ship workflow on GitHub Issues, Projects, and milestones, with no local planning files. Use when the user asks to file, scope, start, discuss, plan, implement, verify, or ship a GitHub issue ("work on #12", "plan issue 40", "turn this idea into an issue", "ship it") in a repository that tracks its work on GitHub. Also use for any request to change a repository whose AGENTS.md or CLAUDE.md has a "github-gsd configuration" section (a feature, fix, docs change, or refactor), even when no issue is mentioned, and load it before editing any file. Do not use for repositories that keep plans in local files such as .planning/.'
---

# github-gsd

GitHub is the only source of truth for planning. Do not create local planning
files (`PLAN.md`, `STATE.md`, `.planning/`, and so on).

| What | Where |
|---|---|
| Priority, status, roadmap | The GitHub Project (`Status` and the repository's planning fields), milestones, tracking issues, sub-issues, and blocked-by links |
| Ideas that are not yet scoped | Project draft items |
| Requirements and acceptance criteria | The issue body |
| Research (optional) | Issue comment **Research** (`<!-- workflow:research -->`) |
| Context and decisions | Issue comment **Context and decisions** (`<!-- workflow:context -->`) |
| Implementation plan | Issue comment **Implementation plan** (`<!-- workflow:plan -->`) |
| Verification | Issue comment **Verification** (`<!-- workflow:verification -->`) and PR checks |
| Summary | The pull request description |
| Lasting architecture decisions | Architecture Decision Records in the repository |

## Before you change any file

In a repository with a github-gsd configuration, every change goes through
this workflow, whether or not the user mentions an issue: a feature, a fix, a
docs edit, or a refactor.

1. **Issue first.** Find the issue for the work, or file it
   ([steps/intake.md](steps/intake.md)) with the questions you still have
   under **Open questions**.
2. **Branch second.** Create the issue branch
   ([steps/start.md](steps/start.md)).
3. **Then change files**, on the small path or after discuss and plan.

Reading code, running read-only commands, and searching for duplicates are
fine before that. Implementing first and filing the issue afterward is the
wrong order, however small the change; a typo fix gets an issue too.

The configuration section is the owner's standing permission to file issues,
post workflow comments, create and push issue branches, and open pull
requests in that repository. It does not cover merging, deploying, or pushing
to the default branch. If your environment requires confirmation for actions
on GitHub, ask once, at the start, before any file change; never after the
work is done.

Ask your questions in discuss, once the issue exists. If you had to ask some
in chat to scope the issue at all, record the answers as decisions in the
Context and decisions comment.

### Work started outside the workflow

If files were already changed with no issue, by you or earlier in the
session:

1. Stop changing files.
2. File the issue for the work ([steps/intake.md](steps/intake.md)), create
   its branch, and move the changes onto it.
3. Write the Context and decisions comment, including the choices already
   made, and the Implementation plan with the finished tasks ticked.
4. Verify and ship as usual.

## Comment rule

- **Context and decisions** and **Implementation plan**: exactly one of each
  per issue, **edited in place**, so each is always the current version. Never
  post a "Plan v2" or a correction comment. When the work ships, a
  `Status: ✅ Completed — PR #N` line on the plan comment replaces a separate
  summary.
- **Research** and **Verification**: marked so they are easy to find. Add
  another one when needed, for example a new verification run after a fix.
- Other discussion comments are free-form.
- Write the workflow comments directly. There is no approval step; the owner
  edits them afterward if something is wrong.

Always write marked comments with the helper script. It finds the comment by
its marker (across all comment pages), creates it if missing, edits it in
place, and refuses to edit when two comments carry the same marker.

```bash
# The script is scripts/issue-comment.sh in this skill's directory
# (the directory that contains this SKILL.md).
issue-comment.sh <issue> context body.md             # create or update
issue-comment.sh <issue> plan - <<'EOF'              # body from stdin
...
EOF
issue-comment.sh --append <issue> verification body.md   # add another one
issue-comment.sh --get <issue> plan > plan.md        # read the current body
issue-comment.sh --url <issue> context              # print the comment URL
```

It prints the comment URL. Exit status 3 means duplicate marked comments:
merge them by hand (or ask the owner) before going on. Run the script with
`--help` for all options.

## Configuration

Before acting, read the repository's settings from the **github-gsd
configuration** section of `AGENTS.md` (or `CLAUDE.md`). The section format
is in [templates/config.md](templates/config.md). It sets:

- the Project owner and number, the `Status` field and its option names;
- planning fields (priority, effort, dates) and how to set them;
- labels (type and area labels);
- the required checks, PR size limit, branch naming, ADR directory, and
  milestone usage.

If there is no such section, use the defaults in
[templates/config.md](templates/config.md), say which defaults you used, and
offer to add the section. Never guess a Project number: list the projects
(`gh project list --owner <owner>`) and ask if it is unclear.

Repository instructions win over this skill when they conflict.

## Routing

Pick the step from the request and the issue's state, then read and follow
that step's file.

| Situation | Step |
|---|---|
| An idea or bug report to record ("file an issue: …"), with no issue yet | [steps/intake.md](steps/intake.md), then give the user its URL |
| A request to change the repository ("add …", "fix …"), with no issue yet | [steps/intake.md](steps/intake.md), then [steps/start.md](steps/start.md), then continue below |
| Files already changed, with no issue | [Work started outside the workflow](#work-started-outside-the-workflow) |
| "Work on #N" and the issue is not in progress | [steps/start.md](steps/start.md), then continue below |
| Small issue: typo, config, contained fix with an obvious solution | [steps/small.md](steps/small.md) |
| Unfamiliar API, provider, or technical options, and no Research comment | [steps/research.md](steps/research.md) |
| No Context and decisions comment, or open questions remain | [steps/discuss.md](steps/discuss.md) |
| Context exists but there is no Implementation plan comment | [steps/plan.md](steps/plan.md) |
| The plan has unticked tasks | [steps/execute.md](steps/execute.md) |
| All tasks ticked, no passing Verification comment for the current code | [steps/verify.md](steps/verify.md) |
| Verification passed, no open PR | [steps/ship.md](steps/ship.md) |

To see an issue's state:

```bash
gh issue view <N> --json title,body,labels,milestone,state,projectItems
gh issue view <N> --comments
```

Steps run in order for a normal issue: start → (research) → discuss → plan →
execute → verify → ship. Continue to the next step without stopping unless the
step says to wait for the owner (open questions in discuss) or the user asked
for only one step.

## Rules for every step

- **One issue, one branch, one PR, and keep the PR small**, so a reviewer can
  review it well. A small PR covers one reviewable concern that a reviewer can
  read in one sitting, and its additions plus deletions stay within the
  configured PR size limit (default 1500 lines). Plan the size up front
  ([steps/plan.md](steps/plan.md#3-check-the-size)). Split work that is too
  large into a tracking issue whose sub-issues are ordered, independently
  shippable slices, each with its own branch and PR. If scope grows during the
  work, stop and open a sub-issue instead of expanding the current issue
  silently.
- **Record follow-up work as an issue** (or a draft item if it is not scoped),
  never as a `TODO` comment in code.
- **Keep the issue body current.** When requirements or acceptance criteria
  change, edit the body; do not leave the change only in a comment.
- **Project updates use plain `gh` commands.** Look up IDs, do not hard-code
  them; see [steps/start.md](steps/start.md) for the commands.
- **Commits** follow the repository's commit convention (Conventional Commits
  by default) and carry a `Refs #N` footer.
- **Never** commit secrets, push to the default branch, merge, or deploy unless
  the user asked for it.
