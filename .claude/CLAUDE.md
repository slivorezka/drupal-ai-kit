# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- Follow Drupal Coding Standards (see `@.claude/instructions/php.md`, `@.claude/instructions/drupal.md`)
- Twig: logic-free templates, use preprocess functions (see `@.claude/instructions/twig.md`)
- JS: Drupal Behaviors with `once()`, scoped to component (see `@.claude/instructions/js.md`)

## Git Conventions

See `@.claude/instructions/git.md` for full rules.

- **Branch naming**: `<type>/<ticket-number>-<description>` (e.g., `feature/329-search-styling`)
- **Commit format**: `#<TICKET>: <Description>.` — present tense imperative, max 72 chars, ends with period
- Extract ticket number from branch name (e.g., branch `feature/329-foo` → commit `#329: Add foo.`)
