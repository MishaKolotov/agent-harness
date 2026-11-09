#!/bin/bash
# PreToolUse:Edit|Write — blocks edits that have already cost production once,
# and holds the spec gate: the behaviour contract does not change without a
# written spec.
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# An applied migration is already in the migrations journal together with its
# hash: editing the file breaks the checksum and the migrator dies on it.
case "$FILE" in
  */drizzle/[0-9][0-9][0-9][0-9]_*.sql)
    deny 'Applied migrations are never edited — their hash is already in the migrations journal. Change the schema in src/lib/db/schema.ts and generate a new migration.' ;;
esac

# ── Spec gate ────────────────────────────────────────────────────────────────
# Tests are excluded on purpose: the repo rule is "red test first, then the
# fix", and the gate must not demand a spec before the test exists.
[ -n "$ROOT" ] || exit 0

# The path is normalised BEFORE matching. Plain prefix stripping let three
# spellings of the same file through — `$ROOT//src/...`, `$ROOT/./src/...` and
# `$ROOT/src/lib/gates/../gates/...`: REL did not match the list and a contract
# edit slipped past the gate (found by an audit; fixtures deny-*-path.json).
canon() {
  local p=$1
  while [ "${p%%//*}" != "$p" ]; do p=${p//\/\//\/}; done
  while [ "${p%%/./*}" != "$p" ]; do p=${p//\/.\//\/}; done
  p=${p#./}
  while [ "${p%%/../*}" != "$p" ] || [ "${p%/..}" != "$p" ]; do
    local before=$p
    p=$(printf '%s' "$p" | sed -E 's%(^|/)[^/]+/\.\.(/|$)%\1%')
    [ "$p" = "$before" ] && break
  done
  printf '%s' "$p"
}
FILE=$(canon "$FILE")
ROOT=$(canon "$ROOT")
REL=${FILE#"$ROOT"/}
REL=$(canon "$REL")

case "$REL" in
  *.test.ts|*.test.tsx) exit 0 ;;
esac

# shellcheck source=./lib/contract-paths.sh
. "$(dirname "$0")/lib/contract-paths.sh"
is_contract_path "$REL" || exit 0

HINT='Order: describe the decision in a spec, then edit. Scaffold one in docs/specs/ and put its path into .claude/current-spec.'
if ! spec_active "$ROOT"; then
  deny "$REL changes the behaviour contract, but $SPEC_DENY_REASON. $HINT"
fi

exit 0
