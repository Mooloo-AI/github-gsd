# Architecture Decision Records

An Architecture Decision Record (ADR) records one decision that matters beyond
a single issue: it constrains future work, picks a technology, or changes a
cross-cutting pattern. Decisions that only affect one issue stay in that
issue's Context and decisions comment.

## Writing one

1. Copy the template to `NNNN-short-title.md`, numbering after the highest
   existing record (`0001`, `0002`, …).
2. Fill in Context, Decision, Consequences, and Alternatives, and link the
   issue or PR.
3. Set the status:
   - **Proposed:** written, not yet agreed.
   - **Accepted:** in effect.
   - **Superseded:** replaced by a later record; link it.

Do not rewrite an accepted record. To change a decision, write a new record
and mark the old one Superseded.

## Records

- <NNNN. Title> — <status>
