# Research (optional)

Research when the issue depends on something the codebase alone cannot
settle: an unfamiliar API or provider, a library choice, or competing
technical options. Skip it for work on familiar code.

## 1. Investigate

- Read the issue, its linked issues and PRs, and the code it touches.
- Use primary sources (official docs, API references, changelogs, source
  code), and note the version and date of what you read.
- Try things when it is cheap: a short script, a dry run, a sandbox request.
- Stay on the question; note unrelated findings as follow-up issues.

## 2. Write the Research comment

Use [templates/research.md](../templates/research.md): the questions,
findings with sources, the options compared, a recommendation, and what is
still unknown.

```bash
issue-comment.sh <N> research research.md
```

## 3. Continue

Go to [discuss.md](discuss.md). The recommendation is an input to the
decisions there, not a decision itself.
