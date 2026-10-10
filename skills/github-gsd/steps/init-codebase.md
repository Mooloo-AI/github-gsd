# Init: codebase docs

Run this from [init.md](init.md) step 6 when the owner agreed. Codebase docs
are a map of the code as it is today, written so that discuss and plan start
from facts instead of rereading the whole repository. They describe the
code; they hold no plans, task lists, or secrets.

## 1. New docs

When `codebase_docs` is `null`, create `docs/codebase/` with one file per
template in this skill's `templates/codebase/`: `README.md`, `stack.md`,
`architecture.md`, `structure.md`, `conventions.md`, `testing.md`,
`integrations.md`, and `concerns.md`.

- Read the code before writing: the build files, entry points, main
  modules, tests, CI workflows, and configuration.
- Fill each section from what you read, naming file paths. Write "None" for a
  section that does not apply, and leave out what you could not confirm
  rather than guess.
- Name environment variables and secrets, never their values.
- Set the mapped-against line in every doc to the current commit
  (`git rev-parse --short HEAD`) and today's date. In `README.md`, give each
  doc a one-line summary and link the ADR directory.
- Keep each doc short enough to read in a few minutes.

## 2. Concerns

Write what you found (tech debt, known bugs, risks, fragile areas, test
gaps) in `concerns.md`. For each concern that needs work, offer the owner an
issue ([intake.md](intake.md)), or a draft item if it is not scoped yet. Link
each issue you file from its entry.

## 3. Existing docs

When `codebase_docs` lists files, never overwrite them. Compare each doc with
the code, and list the ones that are out of date with what changed. Offer to
update them one at a time, keeping their structure, and move each one's
mapped-against line to the current commit. Keep a different set of files as
it is.

## 4. Continue

Go back to [init.md](init.md) step 6. Set **Codebase docs** in the section to
`docs/codebase/`, and list the docs in the PR. The concerns you filed as
issues take effect on GitHub right away.
