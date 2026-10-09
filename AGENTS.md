# AGENTS.md

## github-gsd configuration

- **Workflow:** use the github-gsd skill for every change: file or pick an issue and create its branch before changing any file
- **Project:** none. This repository has no GitHub Project: skip Project and `Status` updates, and track work with issues, labels, and pull requests.
- **Status field:** none (no Project)
- **Planning fields:** none
- **Type labels:** `bug`, `enhancement`, `documentation`
- **Area labels:** none
- **Milestones:** none
- **Branch naming:** `<type>/<issue>-<slug>`, where type is the Conventional Commits type
- **Commit messages:** Conventional Commits with a `Refs #<issue>` footer. Pull request titles follow the same convention, because squash merges use the title as the commit message.
- **Required checks:** `shellcheck skills/github-gsd/scripts/issue-comment.sh tests/mocks/gh`, `bats tests/`, `cmp LICENSE skills/github-gsd/LICENSE`
- **Workflow checks:** `actionlint` for changes in `.github/workflows/`; for changes to the skill's layout or frontmatter, install it into an empty directory with `npx --yes skills@1.7.1 add <repo-path> -a claude-code -a codex -y`, as the CI `install` job does
- **ADR directory:** `docs/adr/`
- **PR template:** none in this repository; use `skills/github-gsd/templates/github/pull_request_template.md`
