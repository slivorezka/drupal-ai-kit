# Contributing

Thanks for helping to improve Drupal AI Kit. Questions and ideas go to
[Discussions](https://github.com/slivorezka/drupal-ai-kit/discussions); bugs go to
[issues](https://github.com/slivorezka/drupal-ai-kit/issues).

## Ground rules

- **One source.** Every rule, skill and subagent lives once in `AGENTS.md` or `.ai-kit/`. Never edit the generated
  copies in `.claude/`, `.codex/`, `.agents/skills/` or `.github/`: `.ai-kit/install.sh` overwrites them.
- **Tool-neutral first.** Write for every assistant. Put a file in `.ai-kit/tools/<tool>/` only when one tool needs it.
- **Drupal 10.3+ and 11, PHP 8.3+.** Code examples follow the guides in `.ai-kit/instructions/`: dependency
  injection instead of `\Drupal::`, OOP hooks (`#[Hook]`) for Drupal 11.2+, two-space indentation, no secrets in
  config examples.
- **Plain, short English.** Instructions are read by models and people; say exactly what to do.

## Set up

```bash
git clone git@github.com:slivorezka/drupal-ai-kit.git
cd drupal-ai-kit
.ai-kit/install.sh claude      # or codex, copilot: the tool you test with
```

Run `.ai-kit/install.sh` again after every change in `.ai-kit/`.

## Add a skill

1. Create `.ai-kit/skills/<name>/SKILL.md`. The folder name and the `name:` in the frontmatter must match:

   ```markdown
   ---
   name: <name>
   description: <one line: what it does and when to use it>
   argument-hint: <what to pass>
   ---
   ```

2. Write the body as a procedure: numbered steps, what to read first, what to report at the end.
3. Optional files go next to `SKILL.md` (`scripts/`, `assets/`). `agents/` is Codex-only metadata and is not
   copied to Claude Code.
4. To offer it as a Copilot prompt, add `.ai-kit/tools/copilot/prompts/<name>.prompt.md` that points to the
   skill — copy an existing prompt file.
5. Add it to the Skills table in `README.md` and to `CHANGELOG.md` under `[Unreleased]`.

## Add a subagent

1. Create `.ai-kit/agents/<name>.md` with a one-line `description` (no YAML block scalar: Codex needs one line):

   ```markdown
   ---
   name: <name>
   description: <one line: area, when to use it>
   tools: Read, Grep, Glob, Edit, Write, Bash
   model: inherit
   codex: |
     model_reasoning_effort = "medium"
   ---
   ```

   `codex: |` is optional: TOML lines for Codex only, without blank lines. The body must not contain `'''`.
2. Add `"./.ai-kit/agents/<name>.md"` to `agents` in `.claude-plugin/plugin.json` — CI fails without it.
3. Add it to the Subagents tables in `README.md` and `AGENTS.md`, and to `CHANGELOG.md`.

## Add a tool

Create `.ai-kit/tools/<tool>/`, name its folder in `roots_of()` in `.ai-kit/install.sh`, and add a case to `build()`
if something has to be generated. Add the tool to `README.md` (Supported Tools) and to the smoke test in
`.github/workflows/ci.yml`.

## Check before a pull request

```bash
shellcheck .ai-kit/install.sh bin/drupal-ai-kit
composer validate --strict
claude plugin validate --strict .
.ai-kit/install.sh --all && .ai-kit/install.sh --remove claude codex copilot
```

CI runs the same checks and an install smoke test.

## Commits and pull requests

- Branch: `<type>/<issue-number>-<description>`, for example `feature/12-cursor-support`.
- Commit message: `#<issue-number>: <Description>.` — see `.ai-kit/instructions/git.md`.
- One logical change per pull request. Describe what changed and how you tested it with an assistant.

## Releases

The maintainer releases: update `CHANGELOG.md`, raise `version` in `.claude-plugin/plugin.json`, tag `vX.Y.Z`.
CI fails a tag whose version differs from `plugin.json`. Packagist picks the tag up by itself.
