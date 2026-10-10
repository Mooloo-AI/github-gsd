---
name: github-gsd
description: 'GitHub-only issue workflow: discuss → plan → execute → verify → ship, with no local planning files. Use to file, triage, plan, implement, or ship a GitHub issue ("work on #12", "turn this idea into an issue", "ship it"), and for any change request in a repository whose AGENTS.md or CLAUDE.md has a "github-gsd configuration" section, even when no issue is mentioned; load it before editing any file. Do not use for repositories that keep plans in local files such as .planning/.'
---

# github-gsd

GitHub is the only source of truth for planning. Never create local planning
files (`PLAN.md`, `STATE.md`, `.planning/`, …).

| What | Where |
|---|---|
| Priority, status, roadmap | The GitHub Project (`Status` and the configured planning fields), milestones, tracking issues, sub-issues, blocked-by links |
| Unscoped ideas | Project draft items |
| Requirements and acceptance criteria | The issue body, or the **Specification** comment (`<!-- workflow:spec -->`) for an issue filed by hand |
| Research (optional) | **Research** comment (`<!-- workflow:research -->`) |
| Context and decisions | **Context and decisions** comment (`<!-- workflow:context -->`) |
| Implementation plan | **Implementation plan** comment (`<!-- workflow:plan -->`) |
| Verification | **Verification** comment (`<!-- workflow:verification -->`) and PR checks |
| Summary | The pull request description |
| Lasting architecture decisions | Architecture Decision Records in the repository |

## Before you change any file

In a repository with a github-gsd configuration, every change (feature, fix,
docs edit, refactor) goes through this workflow, whether or not the user
mentions an issue:

1. **Issue first.** Find the issue, or file it
   ([steps/intake.md](steps/intake.md)) with your remaining questions under
   **Open questions**.
2. **Branch second** ([steps/start.md](steps/start.md)).
3. **Then change files**, on the small path or after discuss and plan.

Reading code, read-only commands, and duplicate searches are fine before
that. Never implement first and file the issue afterward; a typo fix gets an
issue too.

The configuration section is the owner's standing permission to file issues,
post workflow comments, create and push issue branches, and open pull
requests. It does not cover merging, deploying, or pushing to the default
branch. If your environment requires confirmation for GitHub actions, ask
once, at the start, before any file change; never after the work is done.

Ask your questions in discuss, once the issue exists. Answers you needed in
chat to scope the issue become decisions in the Context and decisions
comment.

### Work started outside the workflow

If files were already changed with no issue (by you or earlier in the
session):

1. Stop changing files.
2. File the issue ([steps/intake.md](steps/intake.md)), create its branch,
   and move the changes onto it.
3. Write the Context and decisions comment, including the choices already
   made, and the Implementation plan with the finished tasks ticked.
4. Verify and ship as usual.

## Comment rule

- **Context and decisions**, **Implementation plan**, and **Specification**:
  exactly one of each per issue, **edited in place** so it is always current.
  Never post a "Plan v2" or a correction comment. When the work ships, a
  `Status: ✅ Completed — PR #N` line on the plan comment replaces a separate
  summary.
- **Research** and **Verification**: add another one (`--append`) for a new
  round or run. To correct one, edit it; the script allows that only while
  there is one, so `--append` once there are several.
- Other discussion comments are free-form.
- Write workflow comments directly; there is no approval step. The owner edits
  them afterward if needed.

Always write marked comments with `scripts/issue-comment.sh` (in this skill's
directory). It finds the comment by its marker across all pages, creates or
edits it, and prints its URL:

```bash
issue-comment.sh <issue> context body.md         # create or edit (- reads stdin)
issue-comment.sh --append <issue> verification body.md
issue-comment.sh --get <issue> plan > plan.md    # current body
issue-comment.sh --url <issue> context           # comment URL
```

Exit status 3 means duplicates of a one-per-issue comment: merge them by hand
(or ask the owner) before going on. See `--help` for more.

## Configuration

Before acting, read the **github-gsd configuration** section of `AGENTS.md`
(or `CLAUDE.md`); its format is in [templates/config.md](templates/config.md).
It sets the Project and its `Status` options, planning fields, labels,
required checks, PR size limit, branch naming, ADR directory, and milestone
usage.

Without such a section, use the defaults in
[templates/config.md](templates/config.md), say which you used, and offer to
add the section. Never guess a Project number: run
`gh project list --owner <owner>` and ask if it is unclear.

Repository instructions win over this skill when they conflict.

## Routing

Pick the step from the request and the issue's state, then read and follow
its file.

| Situation | Step |
|---|---|
| An idea or bug report to record ("file an issue: …") | [steps/intake.md](steps/intake.md), then give the user its URL |
| A change request ("add …", "fix …") with no issue yet | [steps/intake.md](steps/intake.md), then [steps/start.md](steps/start.md), then continue below |
| Files already changed, with no issue | [Work started outside the workflow](#work-started-outside-the-workflow) |
| An issue filed by hand without the standard sections, or "triage #N" | [steps/triage.md](steps/triage.md) |
| "Work on #N" and the issue is not in progress | [steps/start.md](steps/start.md), then continue below |
| A small issue ([criteria](steps/start.md#4-choose-the-path)) | [steps/small.md](steps/small.md) |
| Unfamiliar API, provider, or technical options, and no Research comment | [steps/research.md](steps/research.md) |
| No Context and decisions comment, or open questions remain | [steps/discuss.md](steps/discuss.md) |
| Context exists but no Implementation plan comment | [steps/plan.md](steps/plan.md) |
| The plan has unticked tasks | [steps/execute.md](steps/execute.md) |
| All tasks ticked, no passing Verification comment for the current code | [steps/verify.md](steps/verify.md) |
| Verification passed, no open PR | [steps/ship.md](steps/ship.md) |

See an issue's state with `gh issue view <N> --comments` and
`gh issue view <N> --json title,body,labels,milestone,state,projectItems`.

A normal issue runs start → (research) → discuss → plan → execute → verify →
ship. Go on to the next step without stopping unless a step says to wait for
the owner or the user asked for only one step.

## Rules for every step

- **One issue, one branch, one small PR.** A small PR holds one reviewable
  concern that a reviewer can read in one sitting, and its additions plus
  deletions stay within the configured PR size limit (default 1500 lines).
  Plan the size up front ([steps/plan.md](steps/plan.md#3-check-the-size)).
  Split larger work into a tracking issue with ordered, independently
  shippable sub-issues, each with its own branch and PR. If scope grows during
  the work, open a sub-issue instead of silently expanding the issue.
- **Record follow-up work as an issue** (or a draft item if unscoped), never
  as a `TODO` in code.
- **Keep the issue body current.** When requirements or acceptance criteria
  change, edit the body, not only a comment. For an issue with a
  Specification comment, "the issue body" in every step means that comment:
  read and edit it, and never edit the reporter's text.
- **Project updates use plain `gh` commands** with looked-up IDs, never
  hard-coded ones ([steps/start.md](steps/start.md) has the commands).
- **Commits** follow the repository's convention (Conventional Commits by
  default) with a `Refs #N` footer.
- **Never** commit secrets, push to the default branch, merge, or deploy
  unless the user asked for it.
