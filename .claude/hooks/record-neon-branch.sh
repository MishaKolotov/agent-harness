#!/bin/bash
# PostToolUse:mcp__neon__create_branch — keeps the list of this session's
# sandbox branches.
#
# guard-neon-sql.sh lets writes through only to a branch created here and now:
# PreToolUse cannot see the tool's response, so the id is captured after the
# call. The file is session-scoped (session-start.sh expires it): a branch
# created yesterday may already be merged into main today.
INPUT=$(cat)
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}
[ -n "$ROOT" ] || exit 0

# The response arrives either as a parsed object or as an MCP envelope
# content[].text with JSON inside. Take the first branch id found in either.
ID=$(printf '%s' "$INPUT" | jq -r '
  def ids: [.. | objects | select(has("id")) | .id | select(type == "string")];
  ( .tool_response // {} ) as $r
  | ( [$r | ids]
      + [ $r.content // [] | .[]? | .text? // empty
          | try fromjson catch empty | ids ]
    )
  | flatten | map(select(startswith("br-"))) | first // empty
')
[ -n "$ID" ] || exit 0

LIST="$ROOT/.claude/.session-neon-branches"
mkdir -p "$ROOT/.claude"
touch "$LIST"
grep -Fxq "$ID" "$LIST" || printf '%s\n' "$ID" >> "$LIST"
exit 0
