#!/bin/bash
# PreToolUse:mcp__neon__* — this is the production database. Reads are free;
# writes go only into a sandbox branch created in THIS session. Writing to main
# happens on the owner's explicit command, never in the middle of reasoning.
#
# Every comment below that mentions an audit is a hole that existed in an
# earlier version of this guard and has a deny-*.json fixture now.
INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty')}

decide() {
  jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

# Someone else's MCP (a browser, docs search) must not fall under this guard.
# Some clients call the hook with tool_name like `MCP:browser_navigate`; the
# catch-all below then rejected it as "unknown write to production".
# Fixture: allow-non-neon-mcp.json.
case "$TOOL" in
  *neon*|*Neon*) ;;
  *) exit 0 ;;
esac

# Tools that write past branchId and therefore past the SQL check below.
case "$TOOL" in
  *complete_database_migration)
    # Applies the accumulated SQL to the parent branch, i.e. main. Cannot be
    # denied — that breaks the migration skill itself; the owner decides.
    decide ask 'This applies a migration to main (production schema). Show the owner the SQL and the sandbox run result; proceed only on their explicit "apply".' ;;
  *complete_query_tuning)
    # Applies suggested statements — arbitrary DDL — to the parent branch.
    # Was outside the matcher entirely until an audit.
    decide ask 'This applies tuned indexes to main (production schema). Show the owner each statement; proceed only on their explicit "apply".' ;;
  *delete_project)
    decide deny 'Deleting the Neon project is the whole system. The owner does that by hand in the console, not an agent.' ;;
  *reset_from_parent)
    decide deny 'Resetting a branch from its parent wipes the branch data without warning. If the branch is done — delete it and create a fresh one.' ;;
esac

SQL=$(printf '%s' "$INPUT" | jq -r '[(.tool_input.sql // ""), (.tool_input.sqlStatements // [] | join("; ")), (.tool_input.sql_statements // [] | join("; "))] | join("; ")')
# Both spellings: the Neon MCP server accepts branch_id, while the guard used
# to read only branchId — the sandbox exception NEVER fired, and the normal
# migration path was impossible. The guard looked healthy: it honestly denied,
# just everything. Fixture: allow-sandbox-branch-snake-case.json.
BRANCH=$(printf '%s' "$INPUT" | jq -r '.tool_input.branchId // .tool_input.branch_id // empty')

# An earlier version had `[ -n "$BRANCH" ] && exit 0` here. main has a branchId
# too, and the migration skill itself puts the agent where that id is in
# context — so a filled field proved nothing. A branch counts as sandbox only
# if record-neon-branch.sh saw it being created in this session, or the owner
# named it in NEON_SANDBOX_BRANCHES. Fixture: deny-write-with-any-branchid.json.
if [ -n "$BRANCH" ]; then
  case ",${NEON_SANDBOX_BRANCHES:-}," in
    *",$BRANCH,"*) exit 0 ;;
  esac
  if [ -n "$ROOT" ] && [ -f "$ROOT/.claude/.session-neon-branches" ] \
     && grep -Fxq "$BRANCH" "$ROOT/.claude/.session-neon-branches"; then
    exit 0
  fi
fi

# Destructive Neon tools WITHOUT an sql field are invisible to the SQL check.
# They used to be listed by name — and the list fell behind the server (one
# audit closed one missing item, the next found eight more). So: a CLASS of
# verbs, and a new destructive tool is covered on the day it appears.
#
# Placed AFTER the sandbox check: deleting this session's finished branch is
# routine cleanup.
case "$TOOL" in
  *__delete_*|*__reset_*|*__restore_*|*__disable_*|*__suspend_*|*__restart_*|*__set_default_branch|*__update_project)
    decide deny 'Destructive Neon tool on a production branch. If this is cleanup of a sandbox branch — create_branch in this session first (record-neon-branch.sh remembers its id); otherwise the owner does it by hand.' ;;
esac

# The verb class above is still a list, just a short one — and it fell behind:
# rotate_credential (revokes access, the app loses its DATABASE_URL),
# create_trigger (changes the behaviour of EVERY write in the pipeline),
# deploy_function, create_postgres_role reached production as ALLOW. Meanwhile
# delete_branch was caught, so the hole looked closed.
#
# So from here on the list is INVERTED: read verbs are enumerated, everything
# else is denied by default. Same trade-off: a false deny on a read is visible
# at once and fixed with one line; a missed write to production is not.
# Fixtures: deny-rotate-credential, deny-create-trigger, deny-create-role,
# deny-deploy-function.
case "$TOOL" in
  *__list_*|*__get_*|*__describe_*|*__search|*__fetch|*__explain_*|*__inspect_*|*__query_logs|*__compare_*|*__presign_*)
    exit 0 ;;
  *__run_sql|*__run_sql_transaction) ;;
  # The migration skill's normal path: the tool creates a temp branch and works
  # there; applying to main asks the owner separately above.
  *__prepare_*|*__create_branch|*__create_snapshot)
    exit 0 ;;
  *)
    decide deny "Neon tool \"${TOOL##*__}\" changes the production project (or is not recognised as read-only), and the request has no sandbox branch of this session. Order: create_branch → work there → show the owner → main only on their \"apply\". If the tool really only reads — add its verb to the allowlist in guard-neon-sql.sh." ;;
esac

# Normalisation before the check; order matters:
#  1. line comments go before joining lines, or "-- delete" would eat the query;
#  2. block comments — they hide INSERT/**/INTO;
#  3. string literals are blanked: searching text for '%create %' is a read;
#  4. newlines collapse: grep is line-based, and a keyword at the end of a line
#     escaped the "word + separator" check.
#
# The old block-comment pattern `/\*[^*]*\*/` stopped at the FIRST inner star,
# so `UPDATE/*a*b*/jobs SET …` reached production as ALLOW. Now the full
# C-comment pattern with a loop. Fixture: deny-block-comment-star.json.
SQL=$(printf '%s' "$SQL" \
  | sed 's/--.*$//' \
  | sed -E -e ':a' -e 's|/\*[^*]*\*+([^/*][^*]*\*+)*/| |g' -e 'ta' \
  | sed "s/'[^']*'/''/g" \
  | tr '\n\r\t' '   ')

# A keyword is a command only if a separator follows and no letter precedes:
# otherwise a column named created_at reads as CREATE.
#
# The separator is not only a space. Postgres needs no space before a quoted
# identifier or a paren: `UPDATE"jobs" SET …` and `TRUNCATE"jobs"` went through
# as ALLOW, while `DROP TABLE"jobs"` was caught — so the hole looked closed.
#
# do/execute/into/call: blanking literals (above, against false positives)
# became a write channel itself — `DO $$ BEGIN EXECUTE 'DROP TABLE jobs'; END $$`
# reached the DB as ALLOW because the dangerous word lived inside quotes. Same
# for `SELECT * INTO backup FROM jobs`. Catch the wrapper, not its content.
if printf '%s' "$SQL" | grep -qiE '(^|[^a-zA-Z_])(insert|update|delete|drop|alter|truncate|create|grant|revoke|copy|merge|do|execute|into|call)([[:space:]"(;/]|$)'; then
  decide deny 'Write to the production DB without a sandbox branch. Order: create_branch → run there → show the owner the SQL and result → main only on their "apply".'
fi

# Side effects without a write keyword. In Postgres a plain SELECT can do it:
# setval moves a table's id sequence, pg_terminate_backend kills other sessions
# (including a running cron), lo_import/pg_read_file touch the server's disk.
# Fixture: deny-select-side-effect.json.
if printf '%s' "$SQL" | grep -qiE '(^|[^a-zA-Z_])(setval|pg_terminate_backend|pg_cancel_backend|pg_sleep|lo_import|lo_export|pg_read_file|pg_write_file|pg_logical_emit_message)[[:space:]]*\('; then
  decide deny 'Side effect on the production DB without a sandbox branch: setval moves an id sequence, pg_terminate_backend kills sessions, lo_import/pg_read_file read server files. Needs a sandbox branch of this session or the owner.'
fi

exit 0
