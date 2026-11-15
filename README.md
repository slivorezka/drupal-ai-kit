# Drupal AI Development Kit

A ready-to-use set of AI coding assistant configurations for Drupal 10/11 projects. It gives **GitHub Copilot**,
**Codex** and **Claude Code** the same project rules, coding standards, reusable skills and specialised subagents, so
every assistant on the team writes Drupal code the same way.

## Why

AI assistants produce much better Drupal code when they know the project's conventions: where code lives, how services
are wired, how commits are named. Writing those rules separately for every tool leads to drift. This kit keeps one
shared source of truth and thin tool-specific layers on top of it.

## Features

- **One set of rules for all tools** — `AGENTS.md` and `.agents/` are read by Codex, Claude Code and Copilot;
  `.github/` only maps file types and prompts to them.
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
| Twig   | Templating rules, components, preprocess     |
| JS     | Drupal Behaviors, AJAX API, `once()` usage   |
| Git    | Branch naming, commit message format         |

### Skills

| Skill                       | Purpose                                                  |
|-----------------------------|----------------------------------------------------------|
| `create-drupal-service`     | Create a service class and register it                   |
| `create-drupal-plugin`      | Create a plugin (Block, FieldWidget, etc.)               |
| `drupal-performance-review` | Find query, caching and rendering issues                 |
| `drupal-refactor-to-di`     | Replace `\Drupal::` calls with DI                        |
| `git-commit`                | Write a commit message in the project format             |
| `generate-agents-md`        | Fill `AGENTS.md` with the project's real values          |

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
AGENTS.md            # Shared project rules (Codex, Claude Code, Copilot)
.agents/
├── instructions/    # Topic guides: drupal, php, twig, js, git
├── skills/          # Skills — source of truth
└── sync.sh          # Regenerates the tool-specific copies
.claude/             # Claude Code: CLAUDE.md, settings, subagents (source), skills (copy)
.codex/              # Codex: config.toml, subagents (generated)
.github/             # Copilot: pointers to AGENTS.md, the guides and the skills
```

## Supported Tools

| Tool           | Entry point                                    | Docs                                                                                                                        |
|----------------|------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Claude Code    | `.claude/CLAUDE.md`                            | [Memory and instructions](https://docs.claude.com/en/docs/claude-code/memory)                                               |
| Codex          | `AGENTS.md`, `.codex/config.toml`              | [AGENTS.md](https://agents.md/)                                                                                             |
| GitHub Copilot | `AGENTS.md`, `.github/copilot-instructions.md` | [Custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) |

Copilot has no project subagents in this kit. Its `.github/instructions/*.instructions.md` files carry an `applyTo`
pattern and point at the guide for that file type; `.github/prompts/` exposes the skills as prompts;
`.github/git-commit-instructions.md` drives commit message generation in JetBrains IDEs.

## Getting Started

1. Copy `AGENTS.md`, `.agents/` and the folders for the tools you use (`.claude/`, `.codex/`, `.github/`) into your
   Drupal project root. `.github/workflows/kit-check.yml` is optional: it checks that the generated copies are in
   sync.
2. Add the kit's entries to the project's `.gitignore`:

   ```
   .claude/agents.log
   .claude/settings.local.json
   ```

3. Adapt `AGENTS.md` to your project. The `generate-agents-md` skill does the mechanical part — webroot, versions,
   hook style, theme, CI, commands; hosting and deploy details are yours to add.
4. Open the project in your assistant and start working — the rules load automatically. Skills run as `/<name>` in
   Claude Code and `$<name>` in Codex.

Codex applies project `.codex/` settings only after you mark the project as trusted.

### Requirements

- The commands in the guides assume [DDEV](https://ddev.com/); `generate-agents-md` tells you what to change for
  another setup.
- `jq` on the host: the Claude Code hook that logs subagent runs to `.claude/agents.log` uses it.
- `rsync` on the host for `.agents/sync.sh`.
- `drupal/coder` (`phpcs`) in the project; PHPStan and Playwright are used when the project has them.

## Maintenance

Each rule has one source; the copies other tools need are generated:

| Source                | Generated copy         | Why                                         |
|-----------------------|------------------------|---------------------------------------------|
| `.agents/skills/`     | `.claude/skills/`      | Claude Code reads only `.claude/skills/`    |
| `.claude/agents/*.md` | `.codex/agents/*.toml` | Codex subagents use TOML                    |

```bash
.agents/sync.sh          # after editing a skill or a subagent
.agents/sync.sh --check  # exits 1 when a copy is out of date (runs in CI)
```

`.claude/skills/` is a mirror: `.agents/sync.sh` deletes a skill that exists only there, so a project's own skills
go to `.agents/skills/` as well.

Codex-only settings stay where they are: `<skill>/agents/openai.yaml` is not copied to Claude Code, and the lines
above `developer_instructions` in a `.codex/agents/*.toml` file (`model_reasoning_effort`, `sandbox_mode`) survive
regeneration.

`.github/git-commit-instructions.md` repeats the commit format from `.agents/instructions/git.md` because commit
message generation reads only that file — change both together.

## License

[MIT](LICENSE)
