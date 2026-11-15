# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@../AGENTS.md

## Claude Code

Always loaded for Claude (other agents read them on demand via the links in AGENTS.md):

@../.agents/instructions/php.md

@../.agents/instructions/git.md

- Subagents: `.claude/agents/*.md`.
- Skills: `.claude/skills` is a generated mirror of `.agents/skills` (shared with Codex); invoke them as `/<name>`.
  Add or edit a skill in `.agents/skills/`, then run `.agents/sync.sh` (it also regenerates `.codex/agents/*.toml` from
  `.claude/agents/*.md`).
- Settings: `.claude/settings.json` (shared), `.claude/settings.local.json` (personal, not committed).
- Subagent runs are logged to `.claude/agents.log` (PostToolUse hook in `settings.json`, git-ignored).
