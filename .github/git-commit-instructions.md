## Commit message rules

Format: `#<TICKET_NUMBER>: <Description>.`

- The ticket number comes from the current branch name: `feature/329-search-styling` → `#329: Update search styling.`
- A branch without a ticket number (`main`, `develop`) uses the same sentence without the prefix:
  `Update API documentation.`
- The description starts with a capital letter, uses the present-tense imperative ("Add", "Fix", "Update",
  "Remove") and ends with a period.
- The first line is at most 72 characters.
- One logical change per commit.

These rules repeat `.agents/instructions/git.md`, "Commit messages" — change them there first.
