#!/bin/bash
# SessionStart — short repo summary into context, plus housekeeping of the
# session anchors the other hooks rely on. git runs under LC_ALL=C: the system
# locale is not English and localized output breaks parsing.
#
# The key lesson of this file: SessionStart also fires IN THE MIDDLE of work,
# not only at the start. Anything this hook wipes unconditionally is an anchor
# that disappears under your feet. It happened four times in one evening
# before the rule below was written: never wipe an anchor unconditionally —
# keep it by freshness.
INPUT=$(cat)
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}
[ -n "$ROOT" ] || exit 0
cd "$ROOT" 2>/dev/null || exit 0
export LC_ALL=C

# Per-run markers: a forgotten failure counter let the Stop hook release the
# turn on the first red run of a new session, and a forgotten "src touched"
# marker ran the whole suite where src/ was never edited.
rm -f "$ROOT/.claude/.session-touched-src" "$ROOT/.claude/.session-test-fails"

# stop-research reminder counter — the only guard against an endless loop (the
# hook asks three times, then goes quiet). Wiping it on every start DISABLED
# that guard: the counter reset mid-work and the threshold was never reached.
NAG="$ROOT/.claude/.session-research-nag"
if [ -f "$NAG" ] && [ -z "$(find "$NAG" -mmin -360 2>/dev/null)" ]; then
  rm -f "$NAG"
fi

# Sandbox DB branches created this session — guard-neon-sql's only trust
# anchor. Wiping it on every start made the normal migration path (create a
# branch → run there) IMPOSSIBLE: the branch exists, the guard forgot it.
# Kept by freshness: a branch recorded more than 6 h ago may have been merged
# into main and must not be trusted any more.
NEON_LIST="$ROOT/.claude/.session-neon-branches"
if [ -f "$NEON_LIST" ] && [ -z "$(find "$NEON_LIST" -mmin -360 2>/dev/null)" ]; then
  rm -f "$NEON_LIST"
fi

# Active spec marker. Unconditional wiping made a filled spec written ten
# minutes ago stop authorising its own edit — three times in one session. The
# temptation to "just fix it by hand" is how a guard becomes a formality.
# Rule: the marker survives if the spec exists, is filled (no TBD/TODO) and was
# edited within a day. Yesterday's spec still does not authorise today's edit.
SPEC_MARKER="$ROOT/.claude/current-spec"
if [ -f "$SPEC_MARKER" ]; then
  SPEC_REL=$(tr -d '\n\r' < "$SPEC_MARKER")
  case "$SPEC_REL" in
    /*) SPEC_ABS=$SPEC_REL ;;
    *)  SPEC_ABS="$ROOT/$SPEC_REL" ;;
  esac
  SPEC_KEEP=no
  if [ -n "$SPEC_REL" ] && [ -f "$SPEC_ABS" ] \
     && ! grep -qE '(^|[^A-Za-z])(TBD|TODO)([^A-Za-z]|$)' "$SPEC_ABS" \
     && [ -n "$(find "$SPEC_ABS" -mtime -1 2>/dev/null)" ]; then
    SPEC_KEEP=yes
  fi
  [ "$SPEC_KEEP" = yes ] || rm -f "$SPEC_MARKER"
fi

# Session start stamp: stop-research.sh uses it to tell research written in
# this session from files that were already there. NOT rewritten while fresh —
# moving the reference point made already-written research "not exist".
mkdir -p "$ROOT/.claude"
STAMP="$ROOT/.claude/.session-started"
if [ ! -f "$STAMP" ] || [ -z "$(find "$STAMP" -mmin -360 2>/dev/null)" ]; then
  : > "$STAMP"
fi

printf 'Repository state\n'
printf 'Branch: %s\n' "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(not git)')"
STATUS=$(git status --short 2>/dev/null)
if [ -n "$STATUS" ]; then
  printf 'Uncommitted:\n%s\n' "$STATUS"
else
  printf 'Nothing uncommitted.\n'
fi
printf 'Last commits:\n%s\n' "$(git log --oneline -3 2>/dev/null)"
exit 0
