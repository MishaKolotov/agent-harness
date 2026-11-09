import { spawnSync } from 'node:child_process';
import { join } from 'node:path';

export type HookResult = {
  status: number;
  stdout: string;
  stderr: string;
  json: { hookSpecificOutput?: Record<string, unknown> } | null;
};

/**
 * Runs a hook exactly the way Claude Code does: the script as a process, the
 * event as JSON on stdin. Returns both raw output and the parsed decision.
 */
export function runHook(
  script: string,
  payload: unknown,
  env: Record<string, string> = {},
): HookResult {
  const r = spawnSync(join(process.cwd(), '.claude', 'hooks', script), {
    input: JSON.stringify(payload),
    encoding: 'utf8',
    env: { ...process.env, ...env },
  });
  const stdout = r.stdout ?? '';
  let json: HookResult['json'] = null;
  if (stdout.trim().startsWith('{')) {
    try {
      json = JSON.parse(stdout);
    } catch {
      json = null;
    }
  }
  return { status: r.status ?? -1, stdout, stderr: r.stderr ?? '', json };
}

export function decision(r: HookResult): string | null {
  const d = r.json?.hookSpecificOutput?.permissionDecision;
  return typeof d === 'string' ? d : null;
}
