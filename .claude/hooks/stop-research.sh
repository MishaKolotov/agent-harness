#!/bin/bash
# Stop — the turn does not end until knowledge fetched from the network or by
# agents is written into the repo.
#
# Routing rule (CLAUDE.md, "Where knowledge goes"): network and agents →
# docs/research/. This used to rely on memory, and the same thing got
# researched twice: knowledge left in chat dies in the scrollback.
INPUT=$(cat)
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}
[ -n "$ROOT" ] || exit 0

# We were already re-invoked because of our own block — no second pass.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

# The start stamp is set by session-start.sh. Without it there is nothing to
# compare "newer than the session" against — stay silent rather than guess.
STAMP="$ROOT/.claude/.session-started"
[ -f "$STAMP" ] || exit 0

# How many times this session went out or launched agents. Threshold 3: a
# single link check is not research and is no reason to hold the turn.
CALLS=$(grep -oE '"name":[[:space:]]*"(WebSearch|WebFetch|Task|Agent)"' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ')
case "$CALLS" in ''|*[!0-9]*) CALLS=0 ;; esac
[ "$CALLS" -ge 3 ] || exit 0

# Did at least one research file appear (new or appended) in this session?
if [ -d "$ROOT/docs/research" ] \
   && [ -n "$(find "$ROOT/docs/research" -type f -name '*.md' -newer "$STAMP" -print -quit 2>/dev/null)" ]; then
  exit 0
fi

# The counter is the only protection from an endless loop, so garbage in the
# file is treated as zero instead of crashing the arithmetic.
NAG="$ROOT/.claude/.session-research-nag"
N=$(cat "$NAG" 2>/dev/null)
case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N + 1))
printf '%s' "$N" > "$NAG"

if [ "$N" -ge 3 ]; then
  rm -f "$NAG"
  printf 'Asked three times — not holding the turn any more. The session made %s network/agent calls and nothing appeared in docs/research/.\n' "$CALLS" >&2
  exit 0
fi

printf 'The session made %s network or agent calls, and nothing appeared in docs/research/. Where did it go?
Rule: network and agents → docs/research/YYYY-MM-DD-<topic>.md + a line in docs/research/README.md; a reproduced code defect → docs/research/AUDIT.md; a platform pitfall → a line in CLAUDE.md.
If what you found really is throwaway — say so out loud and end the turn; I will ask twice more.\n' "$CALLS" >&2
exit 2
