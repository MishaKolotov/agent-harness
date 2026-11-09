#!/bin/bash
# PostToolUse:Edit|Write — exit 2 does not block on this event, so everything
# found goes into the model's context instead. Also leaves a "src/ was touched
# in this session" marker that the Stop hook uses to decide whether to run
# the test suite.
#
# Each check below is a platform pitfall that already bit the project once.
# Replace them with your own — the point is that a lesson becomes a check,
# not a paragraph someone has to remember.
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}
[ -n "$ROOT" ] || exit 0

case "$FILE" in
  "$ROOT"/src/*.ts|"$ROOT"/src/*.tsx) ;;
  *) exit 0 ;;
esac

mkdir -p "$ROOT/.claude"
: > "$ROOT/.claude/.session-touched-src"

NOTES=""
add() { NOTES="$NOTES
- $1"; }

# waitUntil / after: on this deployment post-response code is frozen.
if grep -qE 'waitUntil\(|unstable_after|(^|[^.[:alnum:]_])after\(' "$FILE" 2>/dev/null; then
  add "Found waitUntil/after. On this deployment post-response code is frozen — long work only goes through a DB queue and a separate invocation."
fi

# A bare SQL parameter without a typed operand is inferred as text → 42883.
# Only positional params ($1) are caught, not drizzle interpolation (${col}) —
# that one IS the recommended column operand. Comment lines are skipped.
if grep -nE '(LEAST|GREATEST)\(\$[0-9]|THEN[[:space:]]+\$[0-9]' "$FILE" 2>/dev/null \
   | grep -qvE '^[0-9]+:[[:space:]]*(//|\*|/\*)'; then
  add "Bare SQL parameter without a typed operand: Postgres infers it as text — error 42883. Keep arithmetic in JS, put the parameter opposite a column."
fi

# A secret in a platform log is a leak. An earlier version used `[^)]*` and
# stopped at the first closing paren, while secrets here are always read via
# env() — the detector was blind to exactly the project's idiom (audit).
if grep -qE 'console\.(log|error|warn|info|debug)\(.*(BOT_TOKEN|API_KEY|CRON_SECRET|WEBHOOK_SECRET|DATABASE_URL)' "$FILE" 2>/dev/null; then
  add "A secret goes to a log. Platform logs are readable, so this is a leak — a bot token already leaked once through error messages."
fi

# Local binary, not npx: npx in a dir without node_modules would try to
# install typescript from the network, and the hook must be offline and fast.
if [ -x "$ROOT/node_modules/.bin/tsc" ]; then
  TSC=$(cd "$ROOT" && ./node_modules/.bin/tsc --noEmit 2>&1)
  if [ -n "$TSC" ]; then
    add "tsc --noEmit is not clean:
$TSC"
  fi
fi

[ -z "$NOTES" ] && exit 0

jq -n --arg c "Post-edit check:$NOTES" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
