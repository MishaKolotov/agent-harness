#!/bin/bash
# PreToolUse:Bash — blocks commands that are proven not to work in this
# project or that leak a secret. The decision goes out as JSON with exit 0:
# that way the reason lands in the model's context, not in a log.
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Example of a "proven broken" command: the stock drizzle-kit migrator needs a
# websocket driver this machine does not have; a working HTTP migrator exists.
MIGRATE_HINT='The stock drizzle-kit migrator does not work here (its driver needs a websocket). Apply migrations with: npm run db:migrate:http'

# Direct call. A version specifier (drizzle-kit@latest) and flags before the
# subcommand used to slip past — both forms were found in review.
if printf '%s' "$CMD" | grep -qE 'drizzle-kit[^[:space:]]*([[:space:]]+-[^[:space:]]+)*[[:space:]]+migrate'; then
  deny "$MIGRATE_HINT"
fi

# The same command behind an npm script name: package.json has
# "db:migrate": "drizzle-kit migrate", and the forbidden text is not in the
# command at all. The tail ([^:]|$) separates db:migrate from db:migrate:http.
if printf '%s' "$CMD" | grep -qE '(npm|pnpm|yarn)([[:space:]]+run)?[[:space:]]+db:migrate([^:[:alnum:]]|$)'; then
  deny "$MIGRATE_HINT"
fi

# The spec gate lives on the Edit|Write tools, but the same contract file can
# be rewritten from a shell — redirect, `sed -i`, `tee`, an interpreter with a
# heredoc. This hole was reproduced UNINTENTIONALLY during the very audit that
# looked for it: a contract edit via python in Bash went straight past the gate.
#
# The signal is a write, not any mention of the file: reading contract files
# from a shell must stay free, or the guard makes work impossible (fixture
# allow-read-contract). Residual hole, stated honestly: an interpreter that
# assembles the path from pieces is not caught — this check is about ordinary
# write forms, not deliberate evasion.
# shellcheck source=./lib/contract-paths.sh
. "$(dirname "$0")/lib/contract-paths.sh"
# A write is either a redirect STRAIGHT into a contract file, or an in-place
# editor / interpreter next to a mention of one. "There is a > in the command"
# is not enough: `2>&1` is everywhere, and reading a contract file became
# impossible — caught on the very first command after the check went live.
NEEDS_GATE=no
if printf '%s' "$CMD" | grep -qE ">>?[[:space:]]*['\"]?(\./)?($CONTRACT_BODY)([\"';[:space:]]|\$)"; then
  NEEDS_GATE=yes
fi
if printf '%s' "$CMD" | grep -qE '(sed[[:space:]]+-i|tee[[:space:]]|python3?[[:space:]]|perl[[:space:]]|node[[:space:]]+-e|ruby[[:space:]])'; then
  NEEDS_GATE=maybe
fi
if [ "$NEEDS_GATE" != no ]; then
  # `set -f` is mandatory: without it bash does PATHNAME EXPANSION on tokens
  # from $(...). A pattern like `[^A-Za-z]` or `*` in the command (a regex, a
  # grep argument) expands into a list of repo files — and the guard accuses
  # the command of writing a file it never mentioned. Caught immediately: the
  # first command after enabling got a deny for a file it did not contain.
  set -f
  for TOKEN in $(printf '%s' "$CMD" | tr -s " \t'\"<>|&;()" '\n'); do
    TOKEN=${TOKEN#./}
    if is_contract_path "$TOKEN" && ! spec_active "$ROOT"; then
      set +f
      deny "The command writes the contract file $TOKEN from a shell, but $SPEC_DENY_REASON. This is exactly how the Edit/Write spec gate used to be bypassed. Write the spec first, then edit."
    fi
  done
  set +f
fi

# A bot token typed into a command ends up in shell history and logs.
if printf '%s' "$CMD" | grep -qE 'api\.telegram\.org/bot[0-9]{6,}:'; then
  deny 'Bot token in plain text in the command. Take it from the environment: curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/..." — a token already leaked into platform logs once via error messages.'
fi

exit 0
