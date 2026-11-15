#!/usr/bin/env bash
#
# Installs the settings of an AI coding tool into the project.
#
# The repository holds one tool-neutral source in `.ai-kit/`. The folders the
# tools read are generated from it on each developer's machine, so the project
# carries no settings for tools nobody uses.
#
#   Source                   claude            codex                  copilot
#   .ai-kit/tools/<tool>/    .claude/          .codex/                .github/
#   .ai-kit/agents/*.md      .claude/agents/   .codex/agents/*.toml   -
#   .ai-kit/skills/          .claude/skills/   .agents/skills/        -
#
# `AGENTS.md` and `.ai-kit/instructions/` are read in place by every tool.
# `.agents/skills/` is the only place Codex reads skills from; the kit's skills
# are installed next to the skills a project already keeps there.
#
# Usage:
#   .ai-kit/install.sh <tool>...            install or refresh these tools
#   .ai-kit/install.sh                      refresh the tools installed earlier
#   .ai-kit/install.sh --all                install every tool
#   .ai-kit/install.sh --remove <tool>...   delete what was installed for them
#   .ai-kit/install.sh --list               show the tools and their state
#
# Add --force to overwrite files that are in the way (see below).
#
# The installed files are copies: run the script again after `git pull` and
# after editing anything in `.ai-kit/`. Do not edit the copies; the next run
# overwrites them.
#
# What was installed is recorded in `.ai-kit/.installed/<tool>`. The script
# deletes only files from that list, so personal files next to them
# (`.claude/settings.local.json`) and the rest of `.github/` stay. For the
# same reason it stops when a file it would write exists with other content
# and is not on the list: that file is somebody's own. --force overwrites it.
#
# A file in `.ai-kit/tools/<tool>/` is written for the place it is installed
# to (relative links, `@` imports) and wins over a generated file with the
# same path. A subagent keeps its Codex-only settings as TOML lines, without
# blank lines, in a `codex: |` block of its frontmatter. `<skill>/agents/` is
# Codex-only and is not copied to Claude Code.
#
# To add a tool: create `.ai-kit/tools/<tool>/`, name its folder in
# roots_of(), and add a case to build() if something has to be generated.

set -euo pipefail

cd "$(dirname "$0")/.."

sources=.ai-kit/tools
state=.ai-kit/.installed

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Prints the folders a tool gets files in, one per line. The first one is the
# tool's own folder: `.ai-kit/tools/<tool>/` is installed there.
roots_of() {
  case "$1" in
    claude) echo .claude ;;
    codex)
      echo .codex
      echo .agents/skills
      ;;
    copilot) echo .github ;;
    *) return 1 ;;
  esac
}

# Prints the own folder of a tool.
target_of() {
  local roots
  roots="$(roots_of "$1")" || return 1
  echo "${roots%%$'\n'*}"
}

# Prints the folders of a tool as text: `.codex/, .agents/skills/`.
folders_of() {
  local root text=""
  for root in $(roots_of "$1"); do
    text="${text:+$text, }$root/"
  done
  echo "${text:-?}"
}

# Prints the tools that have a folder in .ai-kit/tools/.
available() {
  local dir
  for dir in "$sources"/*/; do
    if [[ -d "$dir" ]]; then
      basename "$dir"
    fi
  done
}

# Prints the tools installed earlier.
installed() {
  local file
  for file in "$state"/*; do
    if [[ -f "$file" ]]; then
      basename "$file"
    fi
  done
}

# Prints the usage.
usage() {
  cat << 'EOF'
Usage:
  .ai-kit/install.sh <tool>...            install or refresh these tools
  .ai-kit/install.sh                      refresh the tools installed earlier
  .ai-kit/install.sh --all                install every tool
  .ai-kit/install.sh --remove <tool>...   delete what was installed for them
  .ai-kit/install.sh --list               show the tools and their state

  --force   overwrite files that exist and were not installed by this script
EOF
}

# Prints every tool with whether it is installed and its folders.
list() {
  local tool mark
  echo "Tools:"
  for tool in $(available); do
    mark="-"
    if [[ -f "$state/$tool" ]]; then
      mark="installed"
    fi
    printf '  %-8s %-10s %s\n' "$tool" "$mark" "$(folders_of "$tool")"
  done
}

# Prints the value of a frontmatter key of a subagent file, unquoted. The value
# is one line, plain or in double quotes; escapes inside the quotes are not
# resolved.
frontmatter() {
  awk -v key="$2" '
    /^---$/ { n++; next }
    n == 1 && index($0, key ": ") == 1 {
      value = substr($0, length(key) + 3)
      if (value ~ /^".*"$/) { value = substr(value, 2, length(value) - 2) }
      print value
      exit
    }
  ' "$1"
}

# Prints the body of a subagent file (everything after the frontmatter).
body() {
  awk 'n >= 2 { print } /^---$/ { n++ }' "$1" | sed '/./,$!d'
}

# Prints the Codex-only TOML lines of a subagent file: its `codex: |` block.
codex_settings() {
  awk '
    /^---$/ { if (++n == 2) { exit } next }
    n == 1 && $0 == "codex: |" { block = 1; next }
    block && /^  / { print substr($0, 3); next }
    { block = 0 }
  ' "$1"
}

# Prints a subagent file as Claude Code reads it: without the `codex: |` block.
claude_agent() {
  awk '
    /^---$/ { n++ }
    n == 1 && $0 == "codex: |" { block = 1; next }
    block && /^  / { next }
    { block = 0; print }
  ' "$1"
}

# Prints the Codex agent file of a subagent file.
codex_agent() {
  local md="$1" description
  description="$(frontmatter "$md" description | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

  printf '%s\n' "# Generated from $md by .ai-kit/install.sh: edit that file, then run the script again."
  printf '%s\n' "name = \"$(basename "$md" .md)\""
  printf '%s\n' "description = \"$description\""
  codex_settings "$md"
  printf '%s\n' "developer_instructions = '''"
  body "$md"
  printf '%s\n' "'''"
}

# Stages a file under the path it gets in the project.
stage() {
  mkdir -p "$staged/$(dirname "$2")"
  cp "$1" "$staged/$2"
}

# Stages every file of a folder under another folder.
stage_tree() {
  local from="$1" to="$2" file
  if [[ ! -d "$from" ]]; then
    return
  fi
  find "$from" -type f ! -name .DS_Store > "$tmp/found"
  while IFS= read -r file; do
    stage "$file" "$to/${file#"$from"/}"
  done < "$tmp/found"
}

# Stages everything a tool gets. Nothing in the project changes here, so an
# invalid source stops the run before a single file is written.
build() {
  local tool="$1" target="$2" md file path failed=0

  case "$tool" in
    claude)
      mkdir -p "$staged/$target/agents"
      for md in .ai-kit/agents/*.md; do
        if [[ -f "$md" ]]; then
          claude_agent "$md" > "$staged/$target/agents/$(basename "$md")"
        fi
      done

      : > "$tmp/found"
      if [[ -d .ai-kit/skills ]]; then
        find .ai-kit/skills -type f ! -name .DS_Store > "$tmp/found"
      fi
      while IFS= read -r file; do
        # <skill>/<path inside the skill>.
        path="${file#.ai-kit/skills/}"
        case "${path#*/}" in
          agents/*) continue ;;
        esac
        stage "$file" "$target/skills/$path"
      done < "$tmp/found"
      ;;

    codex)
      mkdir -p "$staged/$target/agents"
      for md in .ai-kit/agents/*.md; do
        if [[ ! -f "$md" ]]; then
          continue
        fi
        # Through a file: under pipefail a grep that stops at the first match
        # can fail the pipe.
        body "$md" > "$tmp/body"
        if grep -q "'''" "$tmp/body"; then
          echo "Error: $md contains ''' and cannot be written as a TOML literal string." >&2
          failed=1
        fi
        case "$(frontmatter "$md" description)" in
          '' | '>'* | '|'*)
            echo "Error: $md needs a one-line description (no YAML block scalar)." >&2
            failed=1
            ;;
        esac
        codex_agent "$md" > "$staged/$target/agents/$(basename "$md" .md).toml"
      done
      if [[ $failed -eq 1 ]]; then
        exit 1
      fi

      # With <skill>/agents/: those files are Codex settings of a skill.
      stage_tree .ai-kit/skills .agents/skills
      ;;
  esac

  stage_tree "$sources/$tool" "$target"
}

# Deletes the listed files that lie inside the folders of a tool, then the
# folders this leaves empty. Prints how many files it deleted.
delete_listed() {
  local list="$1" tool="$2" path root inside count=0
  while IFS= read -r path; do
    inside=0
    for root in $(roots_of "$tool"); do
      case "$path" in
        */../*) ;;
        "$root"/*) inside=1 ;;
      esac
    done
    if [[ $inside -eq 0 ]]; then
      continue
    fi
    if [[ -f "$path" ]]; then
      rm -f "$path"
      count=$((count + 1))
    fi
    rmdir -p "$(dirname "$path")" 2> /dev/null || true
  done < "$list"
  echo "$count"
}

# Installs or refreshes one tool.
install_tool() {
  local tool="$1" target path written=0 removed=0 foreign=0
  target="$(target_of "$tool")"
  staged="$tmp/$tool"
  mkdir -p "$staged"
  build "$tool" "$target"

  (cd "$staged" && find . -type f) | sed 's#^\./##' | LC_ALL=C sort > "$tmp/new"
  : > "$tmp/old"
  if [[ -f "$state/$tool" ]]; then
    LC_ALL=C sort "$state/$tool" > "$tmp/old"
  fi

  # A file that is in the way and was not installed by an earlier run is
  # somebody's own: overwriting it now would also delete it on --remove.
  if [[ $force -eq 0 ]]; then
    while IFS= read -r path; do
      if [[ -e "$path" ]] && ! cmp -s "$staged/$path" "$path" && ! grep -qxF -- "$path" "$tmp/old"; then
        if [[ $foreign -eq 0 ]]; then
          echo "Error: $tool is not installed. These files exist and did not come from this script:" >&2
        fi
        echo "  $path" >&2
        foreign=1
      fi
    done < "$tmp/new"
    if [[ $foreign -eq 1 ]]; then
      echo "Move them out of the way, or overwrite them with --force." >&2
      exit 1
    fi
  fi

  # Recorded before the first copy: an interrupted run leaves no unlisted file.
  mkdir -p "$state"
  cat "$tmp/old" "$tmp/new" | LC_ALL=C sort -u > "$state/$tool"

  while IFS= read -r path; do
    if [[ ! -f "$path" ]] || ! cmp -s "$staged/$path" "$path"; then
      mkdir -p "$(dirname "$path")"
      cp "$staged/$path" "$path"
      written=$((written + 1))
    fi
  done < "$tmp/new"

  # Files installed by an earlier run whose source is gone.
  LC_ALL=C comm -23 "$tmp/old" "$tmp/new" > "$tmp/stale"
  removed="$(delete_listed "$tmp/stale" "$tool")"

  cp "$tmp/new" "$state/$tool"
  echo "$tool: $(wc -l < "$tmp/new" | tr -d ' ') files in $(folders_of "$tool") ($written written, $removed removed)."
}

# Deletes what was installed for one tool.
remove_tool() {
  local tool="$1" removed
  if [[ ! -f "$state/$tool" ]]; then
    echo "$tool: not installed."
    return
  fi
  removed="$(delete_listed "$state/$tool" "$tool")"
  rm -f "$state/$tool"
  rmdir "$state" 2> /dev/null || true
  echo "$tool: removed $removed files from $(folders_of "$tool")."
}

mode=install
force=0
all=0
tools=()
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --list)
      list
      exit 0
      ;;
    --all) all=1 ;;
    --remove) mode=remove ;;
    --force) force=1 ;;
    -*)
      usage >&2
      exit 2
      ;;
    *) tools+=("$arg") ;;
  esac
done

# Tool names hold no spaces, so the unquoted lists below split into arguments.
if [[ $all -eq 1 ]]; then
  # shellcheck disable=SC2046
  set -- $(available)
elif [[ ${#tools[@]} -gt 0 ]]; then
  set -- "${tools[@]}"
elif [[ $mode == install ]]; then
  # shellcheck disable=SC2046
  set -- $(installed)
else
  set --
fi

if [[ $# -eq 0 ]]; then
  usage >&2
  list >&2
  exit 2
fi

for tool in "$@"; do
  if ! target_of "$tool" > /dev/null || [[ $mode == install && ! -d "$sources/$tool" ]]; then
    echo "Unknown tool: $tool" >&2
    list >&2
    exit 2
  fi
done

for tool in "$@"; do
  if [[ $mode == remove ]]; then
    remove_tool "$tool"
  else
    install_tool "$tool"
  fi
done
