---
name: generate-agents-md
description: Adapts this kit's AGENTS.md to the current Drupal project — replaces its generic wording (webroot, Drupal and PHP versions, hook style, theme, CI, commands) with values detected from the code. Run once after copying the kit into a project and again after a Drupal core upgrade.
disable-model-invocation: true
---

# Adapt AGENTS.md to this project

The kit ships a generic `AGENTS.md` ("`web/` or `public/`", `<webroot>`, `<theme>`). This skill replaces the generic
parts with what the project actually uses. Detected values are facts; everything else stays generic and is reported.

## Steps

1. **Detect.** From the project root run:

   ```bash
   php .ai-kit/skills/generate-agents-md/scripts/detect-environment.php
   ```

   No PHP on the host: `ddev exec php .ai-kit/skills/generate-agents-md/scripts/detect-environment.php`.

   The script prints JSON. `null`, `false` or an empty list means "not detected".

2. **Read** the root `AGENTS.md`. If it has uncommitted changes (`git status --short AGENTS.md`), ask before editing.
   If it is missing, stop and tell the user to copy it from the kit.

3. **Rewrite** each generic part that has a detected value, following the table below. Keep the file's structure,
   the Safety, Subagents and Git sections, and every link to `.ai-kit/instructions/`.

4. **Report**: the values written, the parts left generic because nothing was detected, and the questions only the
   user can answer (hosting, deploy process, ticket tracker).

Done when every generic placeholder in `AGENTS.md` is either replaced by a detected value or named in the report.

## What to rewrite

| In `AGENTS.md`                           | Source in the JSON                 | Write                                                                                                        |
|------------------------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------------|
| "`web/` or `public/`", every `<webroot>` | `webroot`                          | The real directory.                                                                                          |
| "Drupal 10/11", **Versions**             | `drupal.installed`, `php`, `drush` | Installed core version, PHP version (`environment.php_version` first, else `php.constraint`), Drush version. |
| **Local dev**                            | `environment`                      | DDEV project name, local URL, web server and database. See "Other environments" when the type is not `ddev`. |
| **Theme**, every `<theme>`               | `themes`                           | Theme name, path and base theme. Several themes: list them and ask which one is active.                      |
| Theme build commands                     | `themes[].npm_scripts`             | The real script names. No `package.json`: replace the section with "The theme has no build step."            |
| **CI/CD**                                | `ci`                               | The pipeline file that exists. Empty: "No CI configured."                                                    |
| Testing commands                         | `tools.phpunit_config`             | The detected config path. `tools.phpunit` is `null`: say PHPUnit is not installed.                           |
| Linting commands                         | `tools`                            | With `phpcs_config`: plain `vendor/bin/phpcs` (the config sets the standard). Add PHPStan when installed.    |
| `config/sync/`                           | `config_sync`                      | The real directory.                                                                                          |
| `patches/` line                          | `patches`                          | Remove the line when `false`.                                                                                |
| Coding Standards                         | `drupal.hooks`                     | One line stating the hook style (below).                                                                     |
| Theme → "Reuse component templates"      | `themes[].sdc`                     | `true`: say components are Single Directory Components in `<theme>/components/`.                             |

## Hook style

- `oop` — Drupal 11.2+: all hooks, preprocess included, are `#[Hook]` methods in `src/Hook/`.
- `oop_without_preprocess` — Drupal 11.1: `#[Hook]` classes in `src/Hook/`; preprocess hooks stay procedural in
  `.module`.
- `procedural` — Drupal 10.x: hooks are functions in `.module` that delegate to services.

Install-time hooks (`.install`) are procedural in every case, and themes keep their preprocess functions in
`<theme>.theme`.

## Other environments

`environment.type` is `docker-compose` or `none`: the `ddev …` commands in `AGENTS.md` do not apply. Ask the user how
Drush, Composer and PHPUnit run in this project, then rewrite the command blocks with their answer.
