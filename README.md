# Drupal AI Kit

A ready-to-use set of AI coding assistant configurations for Drupal 10/11 projects. It gives **GitHub Copilot**,
**Codex** and **Claude Code** the same project rules, coding standards, reusable skills and specialised subagents, so
every assistant on the team writes Drupal code the same way.

## Why

AI assistants produce much better Drupal code when they know the project's conventions: where code lives, how services
are wired, how commits are named. Writing those rules separately for every tool leads to drift. This kit keeps one
shared source of truth; the settings of a tool are generated from it on the machine of the developer who uses that
tool.

## Features

- **One set of rules for all tools** — everything lives once in `AGENTS.md` and `.ai-kit/`.
- **Install only your tool** — `.ai-kit/install.sh claude` (or `codex`, `copilot`) generates the settings that tool
  reads. The repository carries no `.claude/`, `.codex/` or Copilot files.
- **Drupal-focused standards** — Drupal Coding Standards, PHP 8.3+ with strict types, dependency injection,
  logic-free Twig, Drupal Behaviors JS and a consistent Git workflow.
- **Reusable skills** — scaffold services and plugins, review performance, refactor to DI, write commit messages.
- **Specialised subagents** — back end, theme/front end, e2e testing, ops/deploy, SEO/analytics and code review.
- **Safe defaults** — `.env` files are off-limits; no commits, pushes or production changes without explicit request.

## Install

**Composer** (recommended) — from the Drupal project root:

```bash
composer require --dev slivorezka/drupal-ai-kit
vendor/bin/drupal-ai-kit init claude      # or codex, copilot; several names at once work too
```

`init` copies `AGENTS.md` (only if the project has none) and `.ai-kit/` into the project, adds the generated folders
to `.gitignore` and installs the named tools. Commit `AGENTS.md`, `.ai-kit/` and `.gitignore`. After
`composer update`, run `vendor/bin/drupal-ai-kit update`: it refreshes `.ai-kit/` and the installed tools and never
touches `AGENTS.md`, so keep project rules there, not in `.ai-kit/`.

**Claude Code plugin** — only the skills and subagents, without `AGENTS.md` and the topic guides:

```
/plugin marketplace add slivorezka/drupal-ai-kit
/plugin install drupal-ai-kit@drupal-ai-kit
```

**Manually** — copy the files as described in [Getting Started](#getting-started).

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
AGENTS.md            # Shared project rules, read in place by every tool
.ai-kit/
├── instructions/    # Topic guides: drupal, php, twig, js, git
├── skills/          # Skills
├── agents/          # Subagents
├── tools/           # Files only one tool needs
│   ├── claude/      #   -> .claude/   CLAUDE.md, settings.json
│   ├── codex/       #   -> .codex/    config.toml
│   └── copilot/     #   -> .github/   pointers to AGENTS.md, the guides and the skills
└── install.sh       # Generates the settings of a tool from everything above
bin/drupal-ai-kit    # Composer entry point: copies the kit into a project, runs install.sh
.claude-plugin/      # Claude Code plugin and marketplace manifests
composer.json        # Composer package slivorezka/drupal-ai-kit
CHANGELOG.md
```

`.claude/`, `.codex/`, `.agents/skills/` and the Copilot files in `.github/` are not in the repository.
`.ai-kit/install.sh` creates them on your machine, and `.gitignore` keeps them out of Git.

The kit lives in `.ai-kit/` and not in `.agents/`, so a project's own `.agents/` folder stays the project's. The
only thing installed there is the kit's skills, because Codex reads skills from `.agents/skills/` and nowhere else.

## Supported Tools

| Tool           | Install                      | Entry point                                    | Docs                                                                                                                        |
|----------------|------------------------------|------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Claude Code    | `.ai-kit/install.sh claude`  | `.claude/CLAUDE.md`                            | [Memory and instructions](https://docs.claude.com/en/docs/claude-code/memory)                                               |
| Codex          | `.ai-kit/install.sh codex`   | `AGENTS.md`, `.codex/config.toml`              | [AGENTS.md](https://agents.md/)                                                                                             |
| GitHub Copilot | `.ai-kit/install.sh copilot` | `AGENTS.md`, `.github/copilot-instructions.md` | [Custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) |

Copilot has no project subagents in this kit. Its `.github/instructions/*.instructions.md` files carry an `applyTo`
pattern and point at the guide for that file type; `.github/prompts/` exposes the skills as prompts;
`.github/git-commit-instructions.md` drives commit message generation in JetBrains IDEs.

## Getting Started

Once per project:

1. Copy `AGENTS.md` and `.ai-kit/` into your Drupal project root (`vendor/bin/drupal-ai-kit init` does steps 1–2).
2. Add the kit's entries to the project's `.gitignore`:

   ```
   .ai-kit/.installed/
   .claude/
   .codex/
   .agents/skills/
   .github/copilot-instructions.md
   .github/git-commit-instructions.md
   .github/instructions/
   .github/prompts/
   ```

   A project that commits its own skills in `.agents/skills/` lists the kit's skill folders by name instead of the
   whole folder (`.agents/skills/create-drupal-service/`, …).

3. Adapt `AGENTS.md` to your project. The `generate-agents-md` skill does the mechanical part — webroot, versions,
   hook style, theme, CI, commands; hosting and deploy details are yours to add. Install a tool first (below) to run
   the skill.

Every developer, after cloning the project:

```bash
.ai-kit/install.sh claude            # or codex, copilot; several names at once work too
```

Then open the project in the assistant and start working — the rules load automatically. Skills run as `/<name>` in
Claude Code and `$<name>` in Codex. Codex applies project `.codex/` settings only after you mark the project as
trusted.

The installed files are copies, so refresh them after `git pull` and after editing anything in `.ai-kit/`:

```bash
.ai-kit/install.sh                   # refresh the tools you installed
.ai-kit/install.sh --list            # the tools, and which of them are installed
.ai-kit/install.sh --remove codex    # delete the files installed for a tool
```

A team where everybody uses the same tool can commit its settings instead: leave that tool's lines out of
`.gitignore` and commit the installed folder.

### Requirements

- The commands in the guides assume [DDEV](https://ddev.com/); `generate-agents-md` tells you what to change for
  another setup.
- Bash for `.ai-kit/install.sh` (on Windows: Git Bash or WSL).
- `jq` on the host: the Claude Code hook that logs subagent runs to `.claude/agents.log` uses it.
- `drupal/coder` (`phpcs`) in the project; PHPStan and Playwright are used when the project has them.

## Maintenance

Each rule has one source in `.ai-kit/`. `.ai-kit/install.sh` turns it into what a tool reads:

| Source                  | Claude Code           | Codex                  | Copilot                    |
|-------------------------|-----------------------|------------------------|----------------------------|
| `.ai-kit/tools/<tool>/` | `.claude/`            | `.codex/`              | `.github/`                 |
| `.ai-kit/agents/*.md`   | `.claude/agents/*.md` | `.codex/agents/*.toml` | —                          |
| `.ai-kit/skills/`       | `.claude/skills/`     | `.agents/skills/`      | through `.github/prompts/` |

Edit the source, never an installed copy: the next run of `.ai-kit/install.sh` overwrites the copy. The script
records what it installed in `.ai-kit/.installed/` and deletes only files from that list — a skill or subagent
removed from `.ai-kit/` disappears from the tool, while personal files (`.claude/settings.local.json`) and the rest
of `.github/` stay. For the same reason it stops when a file it would write already exists with other content and
is not on that list, such as a project's own `.github/copilot-instructions.md`: move the file into
`.ai-kit/tools/<tool>/` to keep it, or run the script with `--force` to overwrite it. A project skill in
`.agents/skills/` with the name of a kit skill stops `install.sh codex` the same way: rename one of the two.

A file in `.ai-kit/tools/<tool>/` is copied as it is, so it is written for the place it lands in: the links in
`copilot-instructions.md` and the `@` imports in `CLAUDE.md` resolve from `.github/` and `.claude/`. Such a file wins
over a generated one with the same path — `.ai-kit/tools/claude/agents/<name>.md` is a subagent only Claude Code
gets.

Codex-only settings: `<skill>/agents/openai.yaml` is not copied to Claude Code, and a subagent keeps its Codex
settings as TOML lines in a `codex: |` block of its frontmatter, which Claude Code's copy leaves out:

```yaml
---
name: code-reviewer
description: Independent read-only review of the uncommitted changes.
tools: Read, Grep, Glob, Bash
model: sonnet
codex: |
  model_reasoning_effort = "medium"
---
```

Codex takes model settings (`model`, `model_reasoning_effort`) and `features.*` switches from that block.
`sandbox_mode` and `approval_policy` set there do not override the session, so a read-only subagent is read-only
through its instructions alone.

To support another tool, create `.ai-kit/tools/<tool>/`, name its folder in `roots_of()` in `.ai-kit/install.sh`,
and add a case to `build()` if the tool needs generated files.

`.ai-kit/tools/copilot/git-commit-instructions.md` repeats the commit format from `.ai-kit/instructions/git.md`
because commit message generation reads only that file — change both together.

## License

[MIT](LICENSE)
