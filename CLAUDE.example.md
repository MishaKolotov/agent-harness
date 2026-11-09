# CLAUDE.md — example (de-personalised excerpt)

This is the shape of the project instructions file from the private project this harness was extracted from (a personal job-search pipeline: Next.js on Vercel, Neon Postgres, a Telegram bot, a local Mac worker running `claude -p`). Product details are cut; the working rules are kept as they are. In the original every pitfall line ends with a `file:line` link to the code that encodes it.

## How it ships
- No Git integration on the host. `git push` stores code, it does not deploy. Deploy is a manual `vercel --prod` from the owner's machine only.
- No cron in `vercel.json` on purpose: the platform cron produced a second parallel run (double model spend, then duplicate messages). An external scheduler calls the endpoint with a bearer secret.
- Cheap liveness check after deploy: the cron endpoint without a token must answer `401`, not `500`.

## Platform pitfalls

Each one is verified at the linked line. Do not take on faith and do not rewrite from memory.

- `waitUntil` / `after` are dead on this deployment: post-response code is frozen. Long work only through a DB queue and a separate invocation.
- neon-http has no interactive transactions → atomicity only via `INSERT … ON CONFLICT DO NOTHING` (claims, locks) plus idempotent updates.
- `rowCount` does not exist anywhere: drizzle over neon-http returns an array. "How many rows did the UPDATE touch" is `.returning({ id })` + `.length`. A habitual `res.rowCount` gives `undefined`, `undefined > 0` is `false`, and the atomic claim silently starts failing every time.
- A bare SQL parameter without a typed operand (`LEAST($1,$2)`, `CASE … THEN $1`) is inferred as text → `42883`. Arithmetic in JS, parameter opposite a column.
- In zod, call order matters: `.optional().describe(x)` puts the description on the wrapper, `z.toJSONSchema` emits `{description, $ref}`, and the SDK transformer returns on `$ref` BEFORE copying the description — the field reaches the model with no instruction at all. Only `.describe(x).optional()`.
- `\b` in JS is an ASCII word boundary, so an alternative that starts or ends with Cyrillic or Polish diacritics NEVER matches. Write boundaries as `(?<![\p{L}\p{N}])…(?![\p{L}\p{N}])` with the `u` flag.
- Postgres `numeric` comes back from neon-http as a STRING (no parser for OID 1700); `sql<number>` is only an annotation. Cast `::float8` in SQL or `Number()` on the way out. Tests on pg-proxy don't catch it — they return numbers.
- `vi.mock(...)` factories without `importOriginal`: a new export the route starts importing must be added to EVERY factory, otherwise vitest throws inside the route's `try/catch`, the error goes to `errors[]`, and the test stays green (found by mutation testing).
- An extensionless import resolves to `foo.mts` if `foo.ts` sits next to it: the test got the CLI wrapper instead of the library, and the wrapper executed on import. Library and CLI get different names.
- vitest's CLI `--exclude` REPLACES the config's `exclude` instead of extending it — a run with it picked up parallel sessions' worktrees.
- `claude -p --chrome` sees no Chrome tools when `CLAUDE_CODE_OAUTH_TOKEN` is in env: it needs the keychain login.
- `--safe-mode` does not remove `permissions.allow` from user settings: an unlisted command ran with no permission denial. Only `--setting-sources ''` (empty string as a separate argument) closes it.
- Bash permission rules do not bound reads and writes: an allowed `git log` writes anywhere via `--output`, and the deny is bypassed with quotes. So the unattended CV pipeline steps have no Bash at all; the orchestrator hands them files.
- Chrome renders model-written HTML from `file://`, and `<iframe src="file://…">` would put a secret into the PDF past every Read rule. Two layers: a tag allowlist before rendering and a request router that only serves the file itself and `fonts/`, with JS off.
- `SessionStart` fires in the MIDDLE of work too. Anything a hook wipes on that event is an anchor that vanishes under your feet. Rule: never wipe an anchor unconditionally — keep it by freshness. (Five incidents from one root cause before the rule.)
- A hook test that writes into the REAL `.claude/` flakes for the same reason. Hook tests run in their own `mkdtemp` root.

## Conventions
- Tests are offline: no network in `tests/`, everything networked lives in `scripts/`.
- **Every fix starts with a test that is red before the fix.**
- Model-facing rules live in the cached system prefix; schema `.describe()` holds only type and allowed values (the schema is sent at full price on every call).
- Any write of a state column in a multi-step flow is conditional (`UPDATE … WHERE state = <expected>`): while one step runs, another may have already moved the row. Caught three times by adversarial review in one day.

## Iteration ritual
- **Changing the behaviour contract → spec first.** Contract = gates, everything in `src/lib/ai/`, validators, DB schema, source registry, the scoring profile. While the spec still has `TBD`, the guard won't let the edit through; there is no bypass flag on purpose. (`.claude/hooks/guard-edit.sh`)
- **A bugfix within an existing contract needs no spec** — only a red test first.
- **Where knowledge goes.** Network or agents → `docs/research/YYYY-MM-DD-<topic>.md` + a line in `docs/research/README.md`. A reproduced code defect → `docs/research/AUDIT.md` as invariant → violation → reproduction → fix. A platform pitfall → a line in the section above with a `file:line` link. Enforced by `.claude/hooks/stop-research.sh`.
- **Writes to the production DB only into a branch created in this same session.** A filled `branchId` is not enough: main has one too, and the guard once let `DELETE FROM jobs` through on exactly that.
- **A guard without a negative fixture is not a guard.** Every deciding hook has `tests/hooks/fixtures/<hook>/allow-*.json` and `deny-*.json`; a meta-test executes them.
