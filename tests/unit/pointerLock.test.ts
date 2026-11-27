import { afterEach, describe, expect, test } from 'bun:test';
import { PointerLock, type LockChange } from '../../src/input/pointerLock';

type Handler = () => void;

function installFakeDocument() {
  const listeners = new Map<string, Set<Handler>>();
  let lockedEl: unknown = null;
  const queuedUnlockEvents: Array<() => void> = [];
  let queueEvents = false;

  const dispatch = (type: string) => {
    for (const fn of listeners.get(type) ?? []) fn();
  };

  const fakeDoc = {
    get pointerLockElement() {
      return lockedEl;
    },
    addEventListener(type: string, fn: Handler) {
      let set = listeners.get(type);
      if (!set) {
        set = new Set();
        listeners.set(type, set);
      }
      set.add(fn);
    },
    exitPointerLock() {
      lockedEl = null;
      if (queueEvents) queuedUnlockEvents.push(() => dispatch('pointerlockchange'));
      else dispatch('pointerlockchange');
    },
  };

  const prevDoc = (globalThis as { document?: unknown }).document;
  (globalThis as { document?: unknown }).document = fakeDoc;

  return {
    setLocked(el: unknown) {
      lockedEl = el;
    },
    setQueueEvents(on: boolean) {
      queueEvents = on;
    },
    queueChange() {
      queuedUnlockEvents.push(() => dispatch('pointerlockchange'));
    },
    drain() {
      while (queuedUnlockEvents.length) queuedUnlockEvents.shift()!();
    },
    dispatch,
    restore() {
      if (prevDoc === undefined) delete (globalThis as { document?: unknown }).document;
      else (globalThis as { document?: unknown }).document = prevDoc;
    },
  };
}

let cleanup: (() => void) | null = null;
afterEach(() => {
  cleanup?.();
  cleanup = null;
});

describe('PointerLock stale async callbacks', () => {
  test('a stale raw-mouse rejection does not clear pending-event state of a newer lock', async () => {
    const env = installFakeDocument();
    cleanup = env.restore;

    const pl = new PointerLock();
    const events: LockChange[] = [];
    pl.subscribe((c) => events.push(c));

    let rejectFirstRaw!: (err: unknown) => void;
    let rawCalls = 0;
    const el = {
      requestPointerLock(opts?: { unadjustedMovement?: boolean }) {
        if (opts?.unadjustedMovement) {
          rawCalls++;
          if (rawCalls === 1) {
            return new Promise<void>((_, rej) => {
              rejectFirstRaw = rej;
            });
          }
          // Second lock acquires pointerLockElement before Chromium delivers its pointerlockchange.
          env.setLocked(el);
          env.queueChange();
          return Promise.resolve();
        }
        throw new Error('plain fallback should not run for stale first lock');
      },
    } as unknown as Element;

    env.setQueueEvents(true);
    // Lock 1 starts raw request, then is unlocked before it settles.
    pl.lock(el);
    pl.unlock({ quiet: true });

    // Lock 2 starts and acquires pointerLockElement with its pointerlockchange still queued.
    pl.lock(el);

    // Stale lock 1 raw promise rejects now: must not clear lock 2's lockEventPending.
    rejectFirstRaw(new Error('NotSupportedError'));
    await Promise.resolve();
    await Promise.resolve();

    // Quiet unlock for lock 2 runs before lock 2's queued pointerlockchange drains.
    pl.unlock({ quiet: true });
    env.drain();

    expect(pl.isLocked).toBe(false);
    expect(events.length).toBe(2);
    expect(events.every((e) => !e.locked && e.quiet)).toBe(true);
  });

  test('a stale lock resolution does not unlock or clear state of a newer lock', async () => {
    const env = installFakeDocument();
    cleanup = env.restore;

    const pl = new PointerLock();
    const events: LockChange[] = [];
    pl.subscribe((c) => events.push(c));

    let resolveFirstRaw!: () => void;
    let rawCalls = 0;
    const el = {
      requestPointerLock(opts?: { unadjustedMovement?: boolean }) {
        if (opts?.unadjustedMovement) {
          rawCalls++;
          if (rawCalls === 1) {
            return new Promise<void>((res) => {
              resolveFirstRaw = res;
            });
          }
          env.setLocked(el);
          return Promise.resolve();
        }
        return Promise.resolve();
      },
    } as unknown as Element;

    pl.lock(el);
    pl.unlock({ quiet: true });
    pl.lock(el);

    // Stale lock 1 resolves while lock 2 owns the lock: must not exit lock 2.
    resolveFirstRaw();
    await Promise.resolve();
    await Promise.resolve();

    expect(pl.isLocked).toBe(true);
    env.dispatch('pointerlockchange');
    expect(events).toEqual([{ locked: true, quiet: false }]);
  });

  test('a cancelled raw lock rejection clears stale cancellation state when no newer lock exists', async () => {
    const env = installFakeDocument();
    cleanup = env.restore;

    const pl = new PointerLock();
    const events: LockChange[] = [];
    pl.subscribe((c) => events.push(c));

    let rejectFirstRaw!: (err: unknown) => void;
    let rawCalls = 0;
    const el = {
      requestPointerLock(opts?: { unadjustedMovement?: boolean }) {
        if (opts?.unadjustedMovement) {
          rawCalls++;
          if (rawCalls === 1) {
            return new Promise<void>((_, rej) => {
              rejectFirstRaw = rej;
            });
          }
          env.setLocked(el);
          env.dispatch('pointerlockchange');
          return Promise.resolve();
        }
        throw new Error('plain fallback should not run after unlock');
      },
    } as unknown as Element;

    pl.lock(el);
    pl.unlock({ quiet: true });
    rejectFirstRaw(new Error('NotSupportedError'));
    await Promise.resolve();
    await Promise.resolve();

    // A later lock must succeed cleanly without being cancelled by stale state.
    pl.lock(el);
    expect(pl.isLocked).toBe(true);
    expect(events).toEqual([{ locked: true, quiet: false }]);
  });
});
