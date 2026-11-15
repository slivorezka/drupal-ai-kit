# Changelog

All notable changes to this project are documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `CONTRIBUTING.md`, issue templates and a vhs script for the demo GIF.

### Changed

- Remove the `export-ignore` rules from `.gitattributes`: the Claude plugin directory refuses repositories whose
  archive differs from the repository.
- `generate-agents-md` points to `vendor/bin/drupal-ai-kit init` when `AGENTS.md` is missing.

## [1.0.0] - 2026-11-15

### Added

- One tool-neutral source in `AGENTS.md` and `.ai-kit/`; `.ai-kit/install.sh` generates the settings of
  Claude Code, Codex and GitHub Copilot from it.
- Topic guides: Drupal, PHP, Twig, JS, Git.
- Skills: `create-drupal-service`, `create-drupal-plugin`, `drupal-performance-review`, `drupal-refactor-to-di`,
  `git-commit`, `generate-agents-md`.
- Subagents: `drupal-backend`, `theme-frontend`, `e2e-tester`, `drupal-ops`, `seo-analytics`, `code-reviewer`.
- Composer package `slivorezka/drupal-ai-kit` with `vendor/bin/drupal-ai-kit init|update`.
- Claude Code plugin and marketplace (`/plugin marketplace add slivorezka/drupal-ai-kit`).
- CI: shellcheck, `composer validate`, plugin manifest checks and an install smoke test.

[Unreleased]: https://github.com/slivorezka/drupal-ai-kit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/slivorezka/drupal-ai-kit/releases/tag/v1.0.0
