#!/bin/bash
# Stop — the turn does not end on red tests if src/ was edited in the session.
# A full run costs ~10 s on 1,500+ tests: cheap for the guarantee.
INPUT=$(cat)
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}
[ -n "$ROOT" ] || exit 0

# We were already re-invoked because of our own block — no second run,
# otherwise the hook loops with itself.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

MARK="$ROOT/.claude/.session-touched-src"
FAILS="$ROOT/.claude/.session-test-fails"
[ -f "$MARK" ] || exit 0

CMD=${HARNESS_TEST_CMD:-npx vitest run --reporter=dot}
OUT=$(cd "$ROOT" && eval "$CMD" 2>&1)
CODE=$?

if [ "$CODE" -eq 0 ]; then
  rm -f "$MARK" "$FAILS"
  exit 0
fi

# The counter is the only protection from an endless loop, so garbage in the
# file is treated as zero instead of crashing the arithmetic.
N=$(cat "$FAILS" 2>/dev/null)
case "$N" in
  ''|*[!0-9]*) N=0 ;;
esac
N=$((N + 1))
printf '%s' "$N" > "$FAILS"

# Three red runs in a row — let go, but loudly.
if [ "$N" -ge 3 ]; then
  rm -f "$MARK" "$FAILS"
  printf 'Tests failed three times in a row — not holding the turn any more. Investigate separately: %s\n%s\n' "$CMD" "$(printf '%s' "$OUT" | tail -40)" >&2
  exit 0
fi

printf 'Tests are red and src/ was edited in this session. Fix and run again: %s\n%s\n' "$CMD" "$(printf '%s' "$OUT" | tail -40)" >&2
exit 2
