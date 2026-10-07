# gsd-github

An agent skill that runs a **discuss → plan → execute → verify → ship** workflow directly on **GitHub Issues, Projects, and milestones**, with no local planning files.

> **Status:** planning. The skill isn't implemented yet. See the issues for scope.

## Idea

- **GitHub is the only source of truth.** The Project holds priority and status, milestones are releases, and issues are units of work.
- **Issue body:** requirements and acceptance criteria.
- **Marked issue comments:** *Context and decisions* and *Implementation plan* (one each, edited in place), plus *Research* and *Verification* comments.
- **Pull request:** the summary, with `Closes #N`.
- Works with Claude Code and Codex through the Agent Skills format (`SKILL.md`). Requires only `gh` and `jq`.

## Credit and affiliation

This project adapts the workflow ideas of [GSD Core](https://github.com/open-gsd/gsd-core) ("Get Shit Done") to a GitHub-native setup. **It is not affiliated with, endorsed by, or maintained by open-gsd or the GSD Core authors.** GSD Core is MIT-licensed; any adapted text keeps its copyright notice.

## License

[MIT](LICENSE)
