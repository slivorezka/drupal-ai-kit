# Git Conventions

## Branches

- `main` / `master` is production and protected; `develop` is the integration branch.
- Work happens on `<type>/<ticket-number>-<description>`, created from the latest `develop` (`hotfix/*` from `main`):
  `feature/329-search-styling`, `bugfix/456-fix-header-mobile`.
- Types: `feature`, `bugfix`, `hotfix`, `docs`, `refactor`.
- Names are lowercase, hyphen-separated, imperative ("add", "fix") and under 50 characters.

## Commit messages

```
#<TICKET_NUMBER>: <Description>.
```

- The ticket number comes from the branch name: `feature/329-search-styling` → `#329: Update search styling.`
- A branch without a ticket number (`main`, `develop`, `docs/api-update`) uses the same sentence without the prefix:
  `Update API documentation.`
- The description starts with a capital letter, uses the present-tense imperative ("Add", "Fix", "Update",
  "Remove") and ends with a period.
- The first line is at most 72 characters.
- One logical change per commit.

```
# Good
#329: Update search feature styling.
#445: Add user profile avatar upload.

# Bad
updates the search styling          # no ticket, lowercase, no period
Fixed header on mobile              # past tense, no ticket
#329 search styling updates         # no colon, no period
329: search styling                 # no hash, no capital, no period
```

A change that needs explaining gets a body after a blank line:

```
#329: Add search feature styling.

- Update search input styling
- Add loading indicator
- Fix form label accessibility
```

## Before committing

- Stage files by name and read `git diff --staged`; the commit holds only the change it describes.
- Config changed in the UI or through Drush: `ddev drush cex -y`, and commit `config/sync` together with the code
  that needs it.
- The diff is free of debug output, commented-out code, credentials and environment-specific values.

## Sharing work

- Update a branch with `git fetch origin && git rebase origin/develop`. After a rebase push with
  `--force-with-lease`, and only to your own branch.
- `main` and `develop` receive changes through pull requests only.
- Before opening a pull request: the branch is rebased on `develop`, and `phpcs`, `phpunit` (and `phpstan` when the
  project has it) pass. The description says what changed and why, links the ticket, and says how it was tested.

## Destructive commands

`git reset --hard`, `git checkout -- <path>`, `git restore`, `git clean`, `git stash drop`, deleting a branch and any
force-push discard work that may belong to someone else. Ask the user before running one.
