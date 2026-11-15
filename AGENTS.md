# AGENTS.md

Instructions for AI coding agents working in this repository (Codex, Claude Code and others).
Codex reads this file automatically; Claude Code loads it through `.claude/CLAUDE.md`.

## Project Overview

**Vitasana** — a Drupal 10.5 website (PHP 8.4) using Composer-managed dependencies. The Drupal webroot is `public/`, not the repo root.

- **Local dev**: Both DDEV and Lando configs exist. DDEV is configured as `drupal10` type with nginx-fpm and MariaDB 11.8.
- **Base theme**: `cruftless` (from `matone/cruftless` package)
- **Content architecture**: Paragraphs-based with Layout Paragraphs for flexible page building
- **Frontend**: Alpine.js for interactivity, Vite for SCSS compilation, BEM CSS naming
- **CI/CD**: GitLab CI (`.gitlab-ci.yml`) — builds container images and deploys via Kustomize manifests

## Development Commands

### DDEV (primary local environment)
```bash
ddev start                          # Start containers
ddev drush cr                       # Clear Drupal cache
ddev drush cim -y                   # Import config
ddev drush cex -y                   # Export config
ddev drush updb -y                  # Run database updates
ddev composer install                # Install PHP dependencies
ddev composer require drupal/foo     # Add a module
```

### Lando (alternative)
```bash
lando start
lando drush cr
lando npm-install                   # npm ci in theme dir
lando vite-watch                    # Vite watch mode (npm run dev:vite)
lando vite-compile                  # Vite production build (npm run build:vite)
```

### Theme build (SCSS → CSS via Vite)
```bash
# From public/themes/vitasana/
npm ci                              # Install node dependencies
npm run build                       # Production build (vite build)
npm run dev:vite                    # Watch mode (vite build --watch)
```
Vite discovers all `scss/*.scss` entry files and outputs to `css/`. Config: `public/themes/vitasana/vite.config.js`.

### Testing
```bash
ddev exec vendor/bin/phpunit -c phpunit.xml.dist                    # Run all tests
ddev exec vendor/bin/phpunit -c phpunit.xml.dist --filter=TestName  # Run single test
```

### Linting (if phpcs available)
```bash
ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice public/modules/vitasana/
ddev exec vendor/bin/phpcbf --standard=Drupal,DrupalPractice public/modules/vitasana/  # Auto-fix
```

## Architecture

### Directory layout
- `public/` — Drupal webroot
- `public/modules/vitasana/` — Custom modules (4 modules: `general`, `language_switcher`, `vitasana_config_ignore`, `vs_layout_builder`)
- `public/themes/vitasana/` — Custom theme (extends `cruftless` base theme)
- `public/themes/vitasana/templates/` — Twig templates organized as: `base/`, `components/`, `paragraphs/`, `layouts/`, `field/`, `navigation/`, `pages/`, `form/`, `includes/`
- `public/themes/vitasana/scss/` — SCSS source files (compiled by Vite to `css/`)
- `config/sync/` — Drupal config export directory
- `helpers/functions.php` — Autoloaded helper functions
- `patches/` — Local patches applied via composer-patches

### Custom modules
- **general** — General site functionality and hooks
- **language_switcher** — Custom language switcher block plugin
- **vitasana_config_ignore** — Config filter plugin for ignoring specific config on import
- **vs_layout_builder** — Custom Layout Paragraphs layouts with background options

### Theme architecture
- Base theme `cruftless` provides the foundation; `vitasana` overrides and extends it
- Layout Paragraphs drives page structure with custom layouts (one/two/three/four column) defined in `vitasana.layouts.yml`
- `vitasana.theme` contains preprocess functions that set paragraph view modes based on layout context
- Component Twig templates (`templates/components/`) are reused by paragraph templates (`templates/paragraphs/`)
- JS uses Drupal Behaviors pattern with `once()`, plus Alpine.js for modals/interactive elements
- Libraries defined in `vitasana.libraries.yml`: `global-styling`, `polyfills`, `language-switch`, `faq`, `alpine`

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
