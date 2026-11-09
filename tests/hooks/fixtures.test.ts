import { describe, expect, it } from 'vitest';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { decision, runHook } from './run-hook';

// Meta-test against a guard that silently stopped guarding — the defect class
// an audit found in an unrelated checker (it collected 7 refs out of 22 and
// stayed green). Every hook that makes a decision MUST have both fixtures: an
// input that must pass and an input that must be blocked. Fixtures don't just
// exist — they are executed, so "the guard got weaker" shows up immediately.
//
// A guard without a negative fixture is not a guard.
//
// Fixture format:
//   { "files": { "relative/path": "content" },   // sandbox root
//     "env":   { "VAR": "value" },
//     "payload": { … hook event; {{ROOT}} is replaced with the sandbox path } }

type Fixture = {
  files?: Record<string, string>;
  env?: Record<string, string>;
  payload: unknown;
};

const HOOKS_DIR = join('.claude', 'hooks');
const FIXTURES_DIR = join('tests', 'hooks', 'fixtures');

/** A hook decides if it can deny a tool call or hold the turn. */
function decides(script: string): boolean {
  // Comments are dropped: after-edit.sh explains in its header why exit 2 does
  // not block on its event, and the comment text alone made it "deciding".
  const body = readFileSync(join(HOOKS_DIR, script), 'utf8')
    .split('\n')
    .filter((l) => !/^\s*#/.test(l))
    .join('\n');
  return /permissionDecision/.test(body) || /\bexit 2\b/.test(body);
}

const scripts = readdirSync(HOOKS_DIR).filter((f) => f.endsWith('.sh'));
const deciding = scripts.filter(decides);

// Each fixture runs in its own mkdtemp root. A hook test that writes into the
// REAL .claude/ flakes: SessionStart fires mid-work and wipes markers between
// the write and the hook call (caught once: green 5 runs out of 6).
function sandbox(fx: Fixture) {
  const root = mkdtempSync(join(tmpdir(), 'harness-fx-'));
  mkdirSync(join(root, '.claude'), { recursive: true });
  for (const [rel, body] of Object.entries(fx.files ?? {})) {
    const file = join(root, rel);
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, body);
  }
  return root;
}

function run(fx: Fixture & { hook: string }) {
  const root = sandbox(fx);
  try {
    const payload = JSON.parse(JSON.stringify(fx.payload).split('{{ROOT}}').join(root));
    return runHook(fx.hook, payload, { ...fx.env, CLAUDE_PROJECT_DIR: root });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

describe('guard fixtures', () => {
  it('found some deciding hooks — otherwise this test checks nothing', () => {
    expect(deciding.length).toBeGreaterThanOrEqual(4);
  });

  it.each(deciding.map((s) => [s]))('%s — has both fixture kinds', (script) => {
    const dir = join(FIXTURES_DIR, script.replace(/\.sh$/, ''));
    expect(existsSync(dir), `missing ${dir}`).toBe(true);
    const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
    expect(files.filter((f) => f.startsWith('allow-')).length, 'no allow fixture').toBeGreaterThan(0);
    expect(files.filter((f) => f.startsWith('deny-')).length, 'no deny fixture').toBeGreaterThan(0);
  });
});

type Case = { script: string; file: string; kind: 'allow' | 'deny'; fx: Fixture & { hook: string } };

const cases: Case[] = [];
for (const script of deciding) {
  const dir = join(FIXTURES_DIR, script.replace(/\.sh$/, ''));
  if (!existsSync(dir)) continue;
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.json'))) {
    const fx = JSON.parse(readFileSync(join(dir, file), 'utf8')) as Fixture;
    cases.push({
      script,
      file,
      kind: file.startsWith('deny-') ? 'deny' : 'allow',
      fx: { ...fx, hook: script },
    });
  }
}

describe('fixtures execute', () => {
  it.each(cases.map((c) => [`${c.script} / ${c.file}`, c] as const))('%s', (_label, c) => {
    const r = run(c.fx);
    const blocked = decision(r) === 'deny' || decision(r) === 'ask' || r.status === 2;
    expect(blocked, blocked ? 'blocked' : `let through: ${r.stdout}${r.stderr}`).toBe(c.kind === 'deny');
  });
});
