/**
 * One place for mouse capture (pointer lock) state.
 *
 * The idea (a lock/unlock helper with events, raw mouse input) follows three.js's
 * PointerLockControls; the code here is our own.
 *
 * - isLocked: true while the mouse is captured for looking.
 * - lock(el): asks for raw (unaccelerated) mouse input when the setting is on and the browser
 *   supports it, falling back to a plain lock. Failures (e.g. the browser's re-lock cooldown right
 *   after Esc) raise a "Click to look around" hint instead of being swallowed.
 * - unlock({ quiet }): frees the mouse; a quiet unlock tells listeners not to pause the ride.
 * - subscribe(fn): called on every lock change with { locked, quiet }.
 */
import { settings } from '../settings';

export interface LockChange {
  locked: boolean;
  /** The game freed the mouse itself (route selector, evidence log, PA board): don't pause. */
  quiet: boolean;
}

type Listener = (c: LockChange) => void;

class PointerLock {
  private listeners = new Set<Listener>();
  private hintListeners = new Set<() => void>();
  /** Upcoming unlocked `pointerlockchange` events produced by our own quiet unlock. */
  private quietRemaining = 0;
  /** True after `lock()` until a locked `pointerlockchange` arrives or the request ends. */
  private lockEventPending = false;
  /** True when `unlock()` ran while an async `requestPointerLock` was still in flight. */
  private cancelInFlight = false;
  /** Monotonic token incremented on every `lock()` / `unlock()` to ignore stale async callbacks. */
  private lockGen = 0;
  /** Expected `pointerlockerror` events from `{ unadjustedMovement: true }` attempts that fall back to plain lock. */
  private rawErrorExpected = 0;
  private started = false;
  /** "Click to look around" is showing (a lock request failed). */
  public hint = false;

  public get isLocked(): boolean {
    return typeof document !== 'undefined' && !!document.pointerLockElement;
  }

  private start() {
    if (this.started || typeof document === 'undefined') return;
    this.started = true;
    document.addEventListener('pointerlockchange', () => {
      const locked = this.isLocked;
      if (locked) {
        this.lockEventPending = false;
        this.quietRemaining = 0;
        if (this.cancelInFlight) {
          // An in-flight lock resolved after `unlock()` was already called: release it quietly.
          this.cancelInFlight = false;
          this.unlock({ quiet: true });
          return;
        }
        this.setHint(false);
        this.listeners.forEach((fn) => fn({ locked: true, quiet: false }));
        return;
      }
      let quiet = false;
      if (this.quietRemaining > 0) {
        this.quietRemaining--;
        quiet = true;
      }
      this.listeners.forEach((fn) => fn({ locked: false, quiet }));
    });
    document.addEventListener('pointerlockerror', () => {
      if (this.rawErrorExpected > 0) {
        this.rawErrorExpected--;
        return;
      }
      this.setHint(true);
    });
  }

  private setHint(on: boolean) {
    if (this.hint === on) return;
    this.hint = on;
    this.hintListeners.forEach((fn) => fn());
  }

  public subscribe = (fn: Listener) => {
    this.start();
    this.listeners.add(fn);
    return () => {
      this.listeners.delete(fn);
    };
  };

  public subscribeHint = (fn: () => void) => {
    this.start();
    this.hintListeners.add(fn);
    return () => {
      this.hintListeners.delete(fn);
    };
  };

  /** Hide the hint (e.g. the ride ended or paused). */
  public clearHint() {
    this.setHint(false);
  }

  public lock(el: Element | null | undefined) {
    this.start();
    if (!el || this.isLocked || typeof el.requestPointerLock !== 'function') return;
    const gen = ++this.lockGen;
    this.quietRemaining = 0;
    this.cancelInFlight = false;
    this.lockEventPending = true;
    const fail = () => {
      if (gen !== this.lockGen) return;
      if (!this.isLocked) {
        this.lockEventPending = false;
        this.setHint(true);
      }
    };
    const onResolved = () => {
      if (gen !== this.lockGen) {
        if (this.isLocked) this.unlock({ quiet: true });
        else this.lockEventPending = false;
      }
    };
    const plain = () => {
      if (gen !== this.lockGen) return;
      try {
        const p = el.requestPointerLock() as unknown as Promise<void> | undefined;
        if (p && typeof p.then === 'function') {
          p.then(onResolved, fail);
        } else if (!this.isLocked) {
          this.lockEventPending = false;
        }
      } catch {
        fail();
      }
    };
    if (!settings.get().rawMouse) return plain();
    let p: Promise<void> | undefined;
    this.rawErrorExpected++;
    try {
      const req = el as unknown as { requestPointerLock(o?: { unadjustedMovement?: boolean }): Promise<void> | undefined };
      p = req.requestPointerLock({ unadjustedMovement: true });
    } catch {
      this.rawErrorExpected = Math.max(0, this.rawErrorExpected - 1);
      return plain();
    }
    if (!p || typeof p.then !== 'function') {
      // Older browsers return nothing and ignore the option: that's a plain lock already.
      this.rawErrorExpected = Math.max(0, this.rawErrorExpected - 1);
      if (!this.isLocked) this.lockEventPending = false;
      return;
    }
    // A rejection means raw input isn't available (or the cooldown): try a plain lock once.
    p.then(
      () => {
        this.rawErrorExpected = Math.max(0, this.rawErrorExpected - 1);
        onResolved();
      },
      () => {
        if (gen !== this.lockGen) {
          this.lockEventPending = false;
          return;
        }
        if (!this.isLocked) plain();
      }
    );
  }

  public unlock(opts: { quiet?: boolean } = {}) {
    this.start();
    this.lockGen++;
    if (!this.isLocked) {
      if (this.lockEventPending) this.cancelInFlight = true;
      return;
    }
    if (opts.quiet) {
      // If `lock()`'s own `pointerlockchange` has not been delivered yet, browsers can queue
      // two unlocked `pointerlockchange` events back-to-back (the stale lock event + this exit).
      this.quietRemaining += this.lockEventPending ? 2 : 1;
    }
    this.lockEventPending = false;
    this.cancelInFlight = false;
    document.exitPointerLock();
  }
}

export const pointerLock = new PointerLock();
