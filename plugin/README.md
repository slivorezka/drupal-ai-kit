# Drupal AI Kit — Claude plugin

Skills and role-based subagents for Drupal 10/11 projects. This plugin is the Claude part of
[Drupal AI Kit](https://github.com/slivorezka/drupal-ai-kit), which also gives Codex and GitHub Copilot the same rules.

## Install

```
/plugin marketplace add slivorezka/drupal-ai-kit
/plugin install drupal-ai-kit@drupal-ai-kit
```

## What you get

**Skills** — run them as `/drupal-ai-kit:<name>`:

| Skill                       | Purpose                                     |
|-----------------------------|---------------------------------------------|
| `create-drupal-service`     | Create a service class and register it      |
| `create-drupal-plugin`      | Create a plugin (Block, FieldWidget, etc.)  |
| `drupal-performance-review` | Find query, caching and rendering issues    |
| `drupal-refactor-to-di`     | Replace `\Drupal::` calls with DI           |
| `git-commit`                | Write a commit message in the project format |

**Subagents** — Claude hands work to them, or you ask for one by name (`drupal-ai-kit:code-reviewer`):

| Subagent         | Area                                                  |
|------------------|-------------------------------------------------------|
| `drupal-backend` | Custom modules, hooks, services, plugins, Drush       |
| `theme-frontend` | Twig, SCSS, JS, libraries, responsive styling         |
| `e2e-tester`     | Playwright end-to-end tests                           |
| `drupal-ops`     | Config sync, environments, CI/CD, production issues   |
| `seo-analytics`  | Metatag, sitemap, structured data, GTM/GA4, consent   |
| `code-reviewer`  | Read-only review of changes against the standards     |

The skills and subagents follow the kit's topic guides for Drupal, PHP, Twig, JS and Git, which ship inside the plugin.

## Plugin or the full kit

The plugin adds skills and subagents to Claude. The full kit, installed with Composer, also puts the project rules in
`AGENTS.md`, sets up Codex and Copilot, and adds the `generate-agents-md` skill that adapts the rules to your project:

```bash
composer require --dev slivorezka/drupal-ai-kit
vendor/bin/drupal-ai-kit init claude
```

## Data

The plugin has no hooks, MCP servers or scripts. It collects nothing and sends nothing anywhere; the skills and
subagents work on the files of your project through Claude Code's own tools.

## Support

Questions and ideas: [Discussions](https://github.com/slivorezka/drupal-ai-kit/discussions).
Bugs: [issues](https://github.com/slivorezka/drupal-ai-kit/issues). License: MIT.

<!-- Generated parts of this folder (skills/, agents/, instructions/, LICENSE) come from .ai-kit/ via
scripts/build-plugin.sh. Edit the source there, never the copies here. -->
