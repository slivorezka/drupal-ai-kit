---
name: drupal
description: Generates a composable AGENTS.md file for Drupal projects by detecting the development environment (DDEV, Docker Compose, or vanilla) and Drupal version, then assembling modular content sections accordingly.
disable-model-invocation: true
---

# Drupal AGENTS.md Generator

This skill generates a customized `AGENTS.md` file for Drupal projects by detecting the development environment and composing appropriate sections from modular content.

All paths below are relative to this skill's directory (`.agents/skills/drupal/`) unless they start with the project root.

## How to Use This Skill

1. **Detect Environment**: Run the detection script with the Bash tool **from the project root** (the script uses the current working directory as the project root):

   ```bash
   php .agents/skills/drupal/scripts/detect-environment.php
   ```

   If the host has no PHP, run it inside DDEV instead:

   ```bash
   ddev exec php .agents/skills/drupal/scripts/detect-environment.php
   ```

   The script prints JSON with the detected environment, Drupal version, and PHP requirement.

2. **Check Supported Environment**: Only DDEV reference content is bundled (`references/environments/ddev/`).
   If the script reports `docker-compose` or `vanilla`, stop and tell the user that environment-specific sections are missing rather than inventing them.

3. **Check Existing Files**: Look for existing agent instructions (`AGENTS.md`, `.agents/AGENTS.md`, `CLAUDE.md`).
   If one exists, ask the user whether to create a new root `AGENTS.md`, update the existing file, or only show the result.
   Never overwrite an existing file without confirmation.

4. **Compose AGENTS.md**: Follow the structure guide in `assets/structure.md` and assemble the document by:

- Including shared sections from `references/sections/`
- Inserting environment-specific content from `references/environments/ddev/`
- Replacing placeholders with the detected values (Drupal version, PHP version, DDEV project type)

5. **Write Output**: Write the final file where the user chose in step 3.

## Detection Script Output

The script detects:

- Development environment (`ddev`, `docker-compose`, or `vanilla`)
- Drupal version from `composer.json` (`drupal/core` or `drupal/core-recommended`)
- PHP version requirement from `composer.json` (and `.ddev/config.yaml` for DDEV)

For Docker Compose projects, it also outputs a `docker_compose` object (compose command, file, service names, database credentials).
These values are only useful once `references/environments/docker-compose/` exists.

## Content Structure

- **Shared Sections** (`references/sections/`): Content that applies to all environments
  - Code style and standards
  - Drupal development patterns (Entity API, Plugins, Hooks, Routes and Controllers)
  - Security guidelines
  - Testing and quality assurance
  - Advanced patterns (Batch, Queue, AJAX)

- **Environment Sections** (`references/environments/ddev/`): DDEV-specific content
  - `overview.md` — Project overview snippet
  - `setup.md` — Setup instructions
  - `commands.md` — Command syntax (`ddev drush`, `ddev exec`)
  - `debugging.md` — Debugging tools and techniques
  - `troubleshooting.md` — Troubleshooting guide

## Version Handling

Use the Drupal and PHP versions reported by the detection script. When composing:

- **Drupal 11.1+**: prefer OOP hooks (`#[Hook]` classes in `src/Hook/`) over procedural `.module` hooks
- **Drupal 10.x**: hooks stay procedural in `.module`; do not suggest `#[Hook]`
- **Drupal 10.2+ / 11**: prefer PHP attributes over docblock annotations for plugins
- Drop anything that does not apply to the detected Drupal/PHP version

## Output Format

The generated `AGENTS.md` follows the structure defined in `assets/structure.md`:

1. Header with AI Agent Instructions notice
2. Project Overview (with detected environment/version)
3. Environment Setup
4. Code Style and Standards
5. Drupal Development Patterns
6. Security Guidelines
7. Development Workflow (environment-specific commands)
8. Debugging
9. Testing & Quality Assurance
10. Advanced Patterns
11. Troubleshooting
12. Additional Resources
