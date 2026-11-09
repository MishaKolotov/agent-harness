#!/bin/bash
# Single source of truth for which files define the BEHAVIOUR CONTRACT of the
# system. Sourced by both guard-edit.sh (Edit/Write tools) and guard-bash.sh
# (the same file rewritten from a shell).
#
# Why one file and not two lists: in the original project a duplicated list
# fell behind reality twice — a tool outside the matcher, then eight tools
# outside the matcher. A copy of the list in a sibling hook is the same bug,
# just about files.
#
# EDIT THIS for your project. The example below is the shape of a real one:
# gates and thresholds, everything that talks to a model (prompts + output
# schemas), truth validators, the DB schema, and a config document the scorer
# reads (profile.md looks like prose but drives a hard cap in the scorer —
# that makes it configuration, not text).
CONTRACT_BODY='src/lib/gates/[^/]+\.ts|src/lib/ai/[^/]+\.ts|src/lib/validators/[^/]+\.(ts|json)|src/lib/db/schema\.ts|profile\.md'
CONTRACT_RE="^($CONTRACT_BODY)$"

is_contract_path() {
  printf '%s' "$1" | grep -qE "$CONTRACT_RE"
}

# A spec is active when the marker exists, points at an existing file, and the
# file has no holes left. The check is identical in both hooks — hence here.
# Returns 0 — editing allowed, 1 — denied (reason in $SPEC_DENY_REASON).
SPEC_DENY_REASON=''
spec_active() {
  local root=$1
  local marker="$root/.claude/current-spec"
  SPEC_DENY_REASON='there is no active spec'
  [ -f "$marker" ] || return 1
  local spec
  spec=$(tr -d '\n\r' < "$marker")
  SPEC_DENY_REASON='the .claude/current-spec marker is empty'
  [ -n "$spec" ] || return 1
  local path
  case "$spec" in
    /*) path=$spec ;;
    *)  path="$root/$spec" ;;
  esac
  SPEC_DENY_REASON="the marker points at $spec, which does not exist"
  [ -f "$path" ] || return 1
  SPEC_DENY_REASON="the spec $spec still has TBD/TODO — it is not a decision yet"
  grep -qE '(^|[^A-Za-z])(TBD|TODO)([^A-Za-z]|$)' "$path" && return 1
  SPEC_DENY_REASON=''
  return 0
}
