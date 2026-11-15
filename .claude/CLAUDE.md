# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@../AGENTS.md

## Claude Code

Always loaded for Claude (other agents read them on demand via the links in AGENTS.md):

@../.agents/instructions/php.md

@../.agents/instructions/git.md

- Subagents: `.claude/agents/*.md`.
- Skills: `.claude/skills` is a copy of `.agents/skills` (shared with Codex); invoke them as `/<name>`. Edit skills in
  `.agents/skills/`, then sync: `rsync -a --delete .agents/skills/ .claude/skills/`.
- Settings: `.claude/settings.json` (shared), `.claude/settings.local.json` (personal, not committed).
- Subagent runs are logged to `.claude/agents.log` (PostToolUse hook in `settings.json`, git-ignored).
