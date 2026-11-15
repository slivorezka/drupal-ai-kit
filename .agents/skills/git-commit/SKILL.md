---
name: git-commit
description: Generate a commit message in the project format (#329: Description.)
argument-hint: [ context ]
---

Write a commit message for the current changes. Extra context from the user: $ARGUMENTS

The format is defined in `.agents/instructions/git.md`, "Commit messages" — read it first.

## Steps

1. **Ticket.** `git branch --show-current`; the ticket number is the digits right after `<type>/`
   (`feature/329-search-styling` → `329`). No digits there: the message has no `#<n>: ` prefix.
2. **Changes.** `git diff --staged`. Nothing staged: read `git status --short` and `git diff` instead, and say that
   nothing is staged yet.
3. **Message.** One sentence naming what the change does, in the format from `git.md`. Add a bulleted body when
   the diff has several parts that one line cannot name.
4. **Split.** A diff holding more than one logical change gets one message per commit, each with the files that
   belong to it.
5. **Check** the first line: at most 72 characters, capital letter after the prefix, imperative verb, final period.

Output the message in a code block. Run `git commit` only when the user asked for the commit itself.
