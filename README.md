# AI-Powered Drupal Development Instructions

A collection of AI coding assistant configurations for Drupal 10 projects. This repository provides structured instructions, coding standards, and reusable commands for **GitHub Copilot**, **Codex** and **Claude Code** to ensure consistent, high-quality Drupal development.

## What's Inside

### Shared Standards

Both tools enforce the same Drupal development rules:

- **Drupal 10.x** on a LAMP stack with **PHP 8.3**
- Strict [Drupal Coding Standards](https://www.drupal.org/docs/develop/standards)
- `declare(strict_types=1);` in all PHP files
- Dependency injection everywhere (no `\Drupal::` in classes)
- Comprehensive PHPDoc blocks, typed properties, and return types
- Business logic in services, not controllers
- Security best practices (input sanitization, output escaping, permission checks)
- PHPUnit testing for custom services and business logic
- Git commit conventions: `#<TICKET>: <Description>.`

### Topic-Specific Instructions

| Topic   | Description                                  |
|---------|----------------------------------------------|
| Drupal  | Module development, hooks, plugins, entities |
| PHP     | PHP 8.3 coding standards and best practices  |
| Twig    | Templating rules and preprocess patterns     |
| JS      | Drupal Behaviors, AJAX API, `once()` usage   |
| Git     | Branch naming, commit message format         |

### Reusable Commands / Prompts

| Command                      | Description                                   |
|------------------------------|-----------------------------------------------|
| Create Drupal Service        | Scaffold a new Drupal service class           |
| Create Drupal Plugin         | Scaffold a new Drupal plugin class            |
| Drupal Performance Review    | Analyze code for performance issues           |
| Drupal Refactor to DI        | Refactor static calls to dependency injection |
| Git Commit                   | Generate a commit message per branch rules    |

## GitHub Copilot

Configuration lives in `.github/`:

```
.github/
├── copilot-instructions.md                        # Main instructions (auto-loaded)
├── git-commit-instructions.md                     # Git commit conventions
├── instructions/                                  # Topic-specific instruction files
│   ├── drupal.instructions.md
│   ├── php.instructions.md
│   ├── js.instructions.md
│   ├── twig.instructions.md
│   └── git.instructions.md
└── prompts/                                       # Reusable prompt templates
    ├── create-drupal-service.prompt.md
    ├── create-drupal-plugin.prompt.md
    ├── drupal-performance-review.prompt.md
    └── drupal-refactor-to-di.prompt.md
```

See the official [GitHub Copilot documentation](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) about custom instructions.

## Shared Layer (Codex + Claude Code)

Everything that does not depend on the tool lives in one place:

```
AGENTS.md                                          # Project rules (Codex reads it natively, Claude imports it)
.agents/
├── instructions/                                  # Topic guides: drupal, php, twig, js, git
└── skills/                                        # Skills — source of truth (Codex reads it natively)
    ├── create-drupal-service/SKILL.md
    ├── create-drupal-plugin/SKILL.md
    ├── drupal-performance-review/SKILL.md
    ├── drupal-refactor-to-di/SKILL.md
    ├── git-commit/SKILL.md
    └── drupal/                                    # AGENTS.md generator (explicit use only)
```

## Claude Code

```
.claude/
├── CLAUDE.md                                      # Imports ../AGENTS.md + php/git guides, Claude-only notes
├── settings.json                                  # Model, language, .env deny rules, subagent log hook
├── settings.local.json                            # Personal permissions (not committed)
├── agents/*.md                                    # Subagents
└── skills/                                        # Copy of .agents/skills (Claude reads only .claude/skills)
```

Invoke skills as slash commands:

```
/create-drupal-service UserProfileService in user_profiles module — manages user profile CRUD operations
/create-drupal-plugin MyCustomBlock as Block plugin in my_module
/drupal-performance-review src/Service/DataProcessor.php
/drupal-refactor-to-di src/Controller/MyController.php
/git-commit
```

See the official [Claude Code documentation](https://docs.claude.com/en/docs/claude-code/memory) about memory and custom instructions.

## Codex

```
.codex/
├── config.toml                                    # Sandbox, approvals, response language (trusted projects only)
└── agents/*.toml                                  # Custom agents — counterparts of .claude/agents/*.md
```

Codex loads `AGENTS.md` and `.agents/skills/` on its own. Invoke skills with `$create-drupal-service …`, `$git-commit`, etc.
Project `.codex/` settings apply only after you trust the project.

## Keeping the Tools in Sync

| What                | Shared (edit here)            | Claude Code                    | Codex                         |
|---------------------|-------------------------------|--------------------------------|-------------------------------|
| Project rules       | `AGENTS.md`                   | `@../AGENTS.md` in `CLAUDE.md` | read natively                 |
| Topic guides        | `.agents/instructions/*.md`   | imported / linked              | linked from `AGENTS.md`       |
| Skills              | `.agents/skills/*`            | `.claude/skills` copy          | read natively                 |
| Subagents           | —                             | `.claude/agents/*.md`          | `.codex/agents/*.toml`        |
| Settings & safety   | —                             | `.claude/settings.json`        | `.codex/config.toml`          |

Subagents and settings are tool-specific formats: when you change one side, update the other.

Skills are edited in `.agents/skills/` and copied to Claude Code (no symlinks):

```bash
rsync -a --delete .agents/skills/ .claude/skills/
```

## How to Use

1. **Copy** `AGENTS.md`, `.agents/` and the tool folders you use (`.claude/`, `.codex/`) into your Drupal project root
2. **Customize** `AGENTS.md` to match your project's specific needs (module names, services, etc.)
3. Start coding with your AI assistant — it will automatically follow the configured standards

## License

MIT
