# Triage

Bring an issue that someone wrote by hand, without the github-gsd sections,
into the workflow. The reporter's text is never edited: the agent adds a
**Specification** comment (`<!-- workflow:spec -->`) that holds the
requirements and acceptance criteria from then on.

An issue needs triage when it is open, has no Specification comment, and its
body lacks **Requirements** or **Acceptance criteria**. The triage label is
the configured **Triage label** (default `needs-triage`).

## 1. Find and label

To list the issues that need triage:

```bash
gh issue list --label "<triage label>" --state open
gh issue list --state open --limit 100 --json number,title,body,labels
```

From the second list, pick the issues that need triage and lack the label.
Label each one, creating the label once if the repository does not have it:

```bash
gh label create "<triage label>" --color FBCA04 \
  --description "Filed by hand; needs a github-gsd specification" 2>/dev/null || true
gh issue edit <N> --add-label "<triage label>"
```

Stop here if the user only asked for the list.

## 2. Write the Specification comment

Read the body and all comments. Then write the comment with
[templates/spec.md](../templates/spec.md):

- Restate only what the reporter and later commenters asked for. Do not add
  requirements of your own; put guesses and gaps under **Open questions**.
- Make each acceptance criterion checkable. When the report gives none, derive
  them from the requirements and say so under **Open questions**.
- Do not copy the reporter's text into the comment; it stays in the body.

```bash
issue-comment.sh <N> spec spec.md
```

There is exactly one Specification comment per issue, edited in place. If the
work is too large for one PR, write the Specification as a tracking issue's
goal and planned children, then create them as in
[intake.md](intake.md#2c-tracking-issue).

## 3. Label and place it

```bash
gh issue edit <N> --add-label "<type label>" --remove-label "<triage label>"
```

Then do the Project steps of [intake.md](intake.md#2b-issue): add the issue to
the Project, set its planning fields, and set `Status`. Skip them when no
Project is configured.

## Done when

The issue has a Specification comment, its type label, and no triage label,
and you have given the user its URL. If the user asked to work on the issue,
continue with [start.md](start.md); discuss settles the open questions.
