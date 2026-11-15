# AGENTS.md

Instructions for AI coding agents working in this repository (Codex, Claude Code and others).
Codex reads this file automatically; Claude Code loads it through `.claude/CLAUDE.md`.

## Project Overview

A Drupal 10/11 website (PHP 8.3+) with Composer-managed dependencies. Before changing code, check the project itself:

- **Webroot**: `web/` or `public/` (see `extra.drupal-scaffold.locations.web-root` in `composer.json`), not the repo root.
- **Versions**: Drupal core in `composer.lock`, PHP and database in the local environment config.
- **Local dev**: DDEV (`.ddev/`).
- **Theme**: the custom theme in `<webroot>/themes/custom/` and its base theme (`base theme:` in `<theme>.info.yml`).
- **CI/CD**: the pipeline config in the repo root (`.gitlab-ci.yml`, `.github/workflows/`, `bitbucket-pipelines.yml`).

Prefer what the code shows over assumptions; when something is unclear, ask.

## Development Commands

```bash
ddev start                          # Start containers
ddev drush cr                       # Clear Drupal cache
ddev drush cim -y                   # Import config
ddev drush cex -y                   # Export config
ddev drush updb -y                  # Run database updates
ddev composer install               # Install PHP dependencies
ddev composer require drupal/foo    # Add a module
```

### Theme build

Run from the custom theme directory; check `package.json` `scripts` for the actual names:

```bash
npm ci                              # Install node dependencies
npm run build                       # Production build
```

Edit source files (e.g. SCSS), not the compiled output.

### Testing

```bash
ddev exec vendor/bin/phpunit -c phpunit.xml.dist                    # Run all tests
ddev exec vendor/bin/phpunit -c phpunit.xml.dist --filter=TestName  # Run single test
```

### Linting

```bash
ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice <webroot>/modules/custom/
ddev exec vendor/bin/phpcbf --standard=Drupal,DrupalPractice <webroot>/modules/custom/  # Auto-fix
```

## Architecture

### Directory layout

- `<webroot>/modules/custom/` — custom modules
- `<webroot>/themes/custom/` — custom theme(s); Twig templates in `templates/`, styles and JS sources inside the theme
- `config/sync/` (or `$settings['config_sync_directory']`) — Drupal config export
- `patches/` — local patches applied via `cweagans/composer-patches`
- Contrib code (`<webroot>/core/`, `modules/contrib/`, `themes/contrib/`, `vendor/`) — never edit; patch it instead

### Theme

- Override the base theme instead of copying it wholesale; keep the overrides in the custom theme.
- Preprocess functions live in `<theme>.theme`; libraries in `<theme>.libraries.yml`; layouts in `<theme>.layouts.yml`.
- Reuse component templates instead of duplicating markup.
- JS uses Drupal Behaviors with `once()`.

## Coding Standards

- Every PHP file **must** start with `declare(strict_types=1);`
- Use typed properties and return types everywhere
- All classes, methods, and functions need PHPDoc blocks
- Always use dependency injection — never `\Drupal::service()` in classes
- Follow Drupal Coding Standards (see [`php.md`](.agents/instructions/php.md), [`drupal.md`](.agents/instructions/drupal.md))
- Twig: logic-free templates, use preprocess functions (see [`twig.md`](.agents/instructions/twig.md))
- JS: Drupal Behaviors with `once()`, scoped to component (see [`js.md`](.agents/instructions/js.md))

## Agent Guides and Skills

Shared by every agent — read the guide for the area you touch before changing code:

- Guides: [`.agents/instructions/`](.agents/instructions/) — `drupal.md`, `php.md`, `twig.md`, `js.md`, `git.md`.
- Skills: [`.agents/skills/`](.agents/skills/) (source of truth; `.claude/skills/` is a copy for Claude Code) — `create-drupal-service`, `create-drupal-plugin`,
  `drupal-performance-review`, `drupal-refactor-to-di`, `git-commit`, `drupal` (AGENTS.md generator, explicit use only).

### Safety

- Never read or edit `.env` / `.env.*` files; ask the user for the values you need.
- Do not commit, push or touch production unless the user asks.

### Subagents

Both tools ship the same project subagents: `drupal-backend`, `theme-frontend`, `e2e-tester`, `drupal-ops`,
`code-reviewer`, `seo-analytics` (Claude Code: `.claude/agents/*.md`; Codex: `.codex/agents/*.toml`).

- After finishing a code change and before `git commit`: run `code-reviewer` on the diff.
- After changing Twig, CSS, JS or page content: run `e2e-tester` (in the background if you keep working); when CI e2e
  fails, hand the artifacts to `e2e-tester`.
- Deploy, CI or config-drift problems: `drupal-ops`.
- Fixing findings from an SEO audit, GTM/GA4 or consent issues: `seo-analytics`.
- Give each subagent the goal and the relevant paths, and ask for a short answer with file:line.

## Git Conventions

See [`git.md`](.agents/instructions/git.md) for full rules.

- **Branch naming**: `<type>/<ticket-number>-<description>` (e.g., `feature/329-search-styling`)
- **Commit format**: `#<TICKET>: <Description>.` — present tense imperative, max 72 chars, ends with period
- Extract ticket number from branch name (e.g., branch `feature/329-foo` → commit `#329: Add foo.`)
