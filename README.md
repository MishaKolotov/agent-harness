# agent-harness

The Claude Code setup I run my own projects with, extracted from a private one. Hooks that block what already broke production once, a test that checks the hooks actually block, a few subagents, a prompt skill, and the CLAUDE.md shape.

The private project is a job-search pipeline I built and use every day: Next.js on Vercel, Neon Postgres, a Telegram bot, a worker on my Mac that does all model work through `claude -p`. Since June 2026: 1,091 commits, 5,041 tests, 91 specs, 171 research notes. Almost all of the code was written by agents; my job is deciding what to build, setting up the guardrails, and checking the results.

## How I work

- **Several sessions at once.** Usually 2–4 Claude Code sessions in separate git worktrees: one implements, one reviews or tests, one does research. Each one commits as soon as its tests pass, because splitting work across files just moves the bugs to the boundary between them. I've seen it happen.
- **Spec before contract changes.** Anything that changes behaviour (gates, prompts, output schemas, validators, DB schema) needs a filled spec first. A hook enforces it, not my memory.
- **Red test before any fix.** A dedicated subagent writes the failing test and returns the run output as proof.
- **Adversarial verification.** A finding counts only after a subagent that is trying to *disprove* it fails to. Same after a fix: did we fix that exact thing, and did anything next to it break.
- **Lessons turn into checks.** When something breaks, it becomes a hook, a fixture, or a line in CLAUDE.md that links to the code. The hook comments in this repo are that history.
- **Knowledge goes to files.** Whatever an agent finds on the web lands in `docs/research/`. A Stop hook won't let the turn end until it does.

## What's here

```
.claude/
  settings.json            hook wiring + permission allow/deny
  hooks/
    guard-edit.sh          spec gate on Edit/Write; path canonicalisation (//, ./, ..)
    guard-bash.sh          same gate against shell writes (sed -i, tee, >, interpreters); proven-broken commands; secrets in commands
    guard-neon-sql.sh      production DB: reads free, writes only into a sandbox branch created this session
    record-neon-branch.sh  remembers sandbox branches created this session
    after-edit.sh          post-edit checks for known platform pitfalls + tsc
    stop-tests.sh          the turn can't end on red tests if src/ changed
    stop-research.sh       the turn can't end while web/agent findings aren't written down
    session-start.sh       repo summary + session anchors kept by freshness, not wiped
    lib/contract-paths.sh  the one list of contract files, shared by both guards
  agents/                  adversarial-verifier, red-test-writer, test-gap-hunter, cv-jury-fact-checker
  skills/promptcraft/      how I write prompts for strong models
tests/hooks/               meta-test + 38 allow/deny fixtures, executed against the real scripts
CLAUDE.example.md          project instructions: platform pitfalls, conventions, iteration ritual
```

```bash
npm install && npm test
```

The hooks need `bash` and `jq`. Point `lib/contract-paths.sh` at your own contract files.

## Things that bit me

- **A guard that blocks everything looks like it works.** `guard-neon-sql` read `branchId` while the Neon MCP sends `branch_id`, so the sandbox exception never fired. It denied every write, which looked like protection. That's why every deciding hook needs an `allow-*` fixture too, not only `deny-*`.
- **Blocklists fall behind.** The Neon guard used to list destructive tools by name. One audit found one missing, the next found eight more, then `rotate_credential` and `create_trigger` slipped through. Now it lists only read verbs, and everything else is denied by default.
- **`SessionStart` also fires mid-session.** Five incidents with the same cause: a hook wiped a marker another hook depended on. Session anchors now expire by age; nothing gets wiped unconditionally.
- **The guard caught me while I was building this repo.** The heredoc that generated these fixtures mentioned a contract path, and `guard-bash` blocked it. Small false positive, but the right trade-off: a false deny is visible right away, a missed write isn't.

## Beyond this repo

In the private project there's more I can't publish as is: a 10-agent jury that reviews every generated CV until all of them APPROVE (fact-checker against a facts file and my git history, ATS parser, recruiter, hiring manager, voice, and others); a long-running Mac worker on `claude -p` that falls back to HTTP providers (Gemini first) when the subscription hits its limit; and an unattended `claude -p --chrome` session that fills job application forms with a fixed allowlist of 13 tools.

MIT.
