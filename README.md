# Drupal AI Development Kit

A ready-to-use set of AI coding assistant configurations for Drupal 10/11 projects. It gives **GitHub Copilot**,
**Codex** and **Claude Code** the same project rules, coding standards, reusable skills and specialised subagents, so
every assistant on the team writes Drupal code the same way.

## Why

AI assistants produce much better Drupal code when they know the project's conventions: where code lives, how services
are wired, how commits are named. Writing those rules separately for every tool leads to drift. This kit keeps one
shared source of truth and thin tool-specific layers on top of it.

## Features

- **One set of rules for all tools** — `AGENTS.md` and `.agents/` are shared by Codex and Claude Code; Copilot gets
  equivalent files in `.github/`.
- **Drupal-focused standards** — Drupal Coding Standards, PHP 8.3+ with strict types, dependency injection,
  logic-free Twig, Drupal Behaviors JS and a consistent Git workflow.
- **Reusable skills** — scaffold services and plugins, review performance, refactor to DI, write commit messages.
- **Specialised subagents** — back end, theme/front end, e2e testing, ops/deploy, SEO/analytics and code review.
- **Safe defaults** — `.env` files are off-limits; no commits, pushes or production changes without explicit request.

## What's Included

### Topic Guides

| Topic  | Covers                                       |
|--------|----------------------------------------------|
| Drupal | Module development, hooks, plugins, entities |
| PHP    | PHP 8.3+ coding standards and best practices |
| Twig   | Templating rules and preprocess patterns     |
| JS     | Drupal Behaviors, AJAX API, `once()` usage   |
| Git    | Branch naming, commit message format         |

### Skills

| Skill                       | Purpose                                         |
|-----------------------------|-------------------------------------------------|
| `create-drupal-service`     | Scaffold a service class and its `services.yml` |
| `create-drupal-plugin`      | Scaffold a plugin (Block, FieldWidget, etc.)    |
| `drupal-performance-review` | Find query, caching and rendering issues        |
| `drupal-refactor-to-di`     | Replace `\Drupal::` calls with DI               |
| `git-commit`                | Write a commit message in the project format    |
| `drupal`                    | Generate an `AGENTS.md` for a Drupal project    |

### Subagents

| Subagent         | Area                                                     |
|------------------|----------------------------------------------------------|
| `drupal-backend` | Custom modules, hooks, services, plugins, Drush          |
| `theme-frontend` | Twig, SCSS, JS, libraries, responsive styling            |
| `e2e-tester`     | Playwright end-to-end tests                              |
| `drupal-ops`     | Config sync, environments, CI/CD, production issues      |
| `seo-analytics`  | Metatag, sitemap, structured data, GTM/GA4, consent      |
| `code-reviewer`  | Read-only review of changes against project standards    |

## Repository Layout

```
AGENTS.md            # Shared project rules (Codex, Claude Code)
.agents/
├── instructions/    # Topic guides: drupal, php, twig, js, git
└── skills/          # Skills — source of truth
.claude/             # Claude Code: CLAUDE.md, settings, subagents, skills copy
.codex/              # Codex: config.toml, subagents
.github/             # GitHub Copilot: instructions and prompts
```

## Supported Tools

| Tool           | Entry point                       | Docs                                                                                                                        |
|----------------|-----------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Claude Code    | `.claude/CLAUDE.md`               | [Memory and instructions](https://docs.claude.com/en/docs/claude-code/memory)                                               |
| Codex          | `AGENTS.md`, `.codex/config.toml` | [AGENTS.md](https://agents.md/)                                                                                             |
| GitHub Copilot | `.github/copilot-instructions.md` | [Custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) |

## Getting Started

1. Copy `AGENTS.md`, `.agents/` and the folders for the tools you use (`.claude/`, `.codex/`, `.github/`) into your
   Drupal project root.
2. Adapt `AGENTS.md` to your project: modules, theme, local environment, commands.
3. Open the project in your assistant and start working — the rules load automatically. Skills run as `/<name>` in
   Claude Code and `$<name>` in Codex.

Codex applies project `.codex/` settings only after you mark the project as trusted.

## Maintenance

Skills are edited in `.agents/skills/` and copied to Claude Code (it reads only `.claude/skills/`):

```bash
rsync -a --delete --delete-excluded --exclude='/*/agents/' .agents/skills/ .claude/skills/
```

Codex-only skill metadata (`<skill>/agents/openai.yaml`) stays in `.agents/skills/` and is not copied.

Subagents and settings use tool-specific formats (`.claude/agents/*.md` and `.codex/agents/*.toml`) — when you change
one side, update the other.

## License

MIT
