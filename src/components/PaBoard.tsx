/**
 * PA Board — the HUD panel version of the Last Local alert board.
 *
 * A slide-over panel (B, or the HUD's PA Board button) driven entirely by live game state:
 * the route strip reads the active route and the segment the train is on, the feed reads the
 * engine's PA history (recorded verbatim in setPA), the suspicion meter reads G.sus, and the
 * flag button is the same hold-to-flag as the HUD's FLAG button.
 *
 * Deliberate limits, carried over from the prototype with the game's rules in mind:
 * - The panel never names a live anomaly. Flags are private and never say whether you were
 *   right, so naming (or counting) what's showing would tell the player something is wrong
 *   before they've spotted it. It shows only the flags the player has placed this stretch;
 *   catches and misses are scored when the train arrives, as always.
 * - The suspicion stage names (CALM / UNEASY / WATCHED / IT KNOWS) are display labels only.
 *   The real mechanic is SUS.intervene (60): at 60 a parent intervenes. Suspicion clamps at
 *   0–100 and nothing in the game ends the run at 100.
 * - The feed records announcements verbatim, including a false stop's lie, which the board
 *   never labels as one.
 * - "Last noticed" repeats the engine's own suspicion-log string (the same words the report
 *   lists at the end of a run). It is not a new reason and it is not an anomaly name.
 */
import React, { useEffect, useRef } from 'react';
import { GameEngine } from '../game/gameState';
import { routeManager } from '../game/routeManager';
import { TIER_NAMES, CFG, SUS } from '../constants';
import { evp } from '../game/evpManager';
import { polaroidManager } from '../game/polaroidManager';
import { X, Megaphone, Flag } from 'lucide-react';
import { useEscape } from '../ui/escape';
import { atStop, nextStopIndex, susStage } from '../ui/paBoardModel';

/** The HUD's one glass surface over the 3D view (same as HUD.tsx: no backdrop blur). */
const GLASS = 'bg-black/60 border border-white/10 shadow-lg';

/** Ride time (GT, seconds) as mm:ss. */
function fmtClock(gt: number): string {
  const s = Math.max(0, Math.floor(gt));
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
}

interface PaBoardProps {
  engine: GameEngine;
  open: boolean;
  /** Announcements made while the panel was closed; 0 while it is open. */
  unread: number;
  onToggle: () => void;
  onFlagDown: () => void;
  onFlagUp: () => void;
}

export const PaBoard: React.FC<PaBoardProps> = ({ engine, open, unread, onToggle, onFlagDown, onFlagUp }) => {
  const G = engine;
  const panelRef = useRef<HTMLElement>(null);
  const routeRef = useRef<HTMLOListElement>(null);
  // True only while this button is the thing holding the flag, so closing the panel
  // releases that hold and a keyboard F hold is left alone. The pointer id keeps a
  // second finger (the walk stick, a tap elsewhere) from cancelling the hold.
  const holdingRef = useRef(false);
  const holdingIdRef = useRef<number | null>(null);
  const onFlagUpRef = useRef(onFlagUp);
  onFlagUpRef.current = onFlagUp;

  // Esc closes the board first (same stack as the evidence log and the route lines).
  // It does not take Esc while the camera is up: that key still pauses the ride.
  useEscape(onToggle, open && !polaroidManager.isViewfinderOpen);

  useEffect(() => {
    if (!open) return;
    panelRef.current?.focus();
    return () => {
      const toggle = document.getElementById('pa-board-toggle');
      if (toggle) toggle.focus();
    };
  }, [open]);

  // Keep HERE in the route list. The list has its own scroll so the suspicion meter and the
  // announcements stay on screen under it (a 13-stop strip would otherwise fill the panel).
  const hereStop = open ? atStop(engine) : 0;
  useEffect(() => {
    if (!open) return;
    const list = routeRef.current;
    const here = list?.querySelector<HTMLElement>('[data-state="at"]');
    if (!list || !here) return;
    list.scrollTop = Math.max(0, here.offsetTop - list.clientHeight / 2 + here.clientHeight / 2);
  }, [open, hereStop]);

  const endHold = (e?: { pointerId?: number }) => {
    if (!holdingRef.current) return;
    if (e && e.pointerId != null && holdingIdRef.current != null && e.pointerId !== holdingIdRef.current) return;
    holdingRef.current = false;
    holdingIdRef.current = null;
    onFlagUpRef.current();
  };

  // Releasing anywhere (including off the button, or a touch cancel) ends the hold.
  // Unmounting while the finger is down does too, so closing the panel can't leave a flag stuck.
  useEffect(() => {
    if (!open) return;
    const up = () => endHold();
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);
    return () => {
      window.removeEventListener('pointerup', up);
      window.removeEventListener('pointercancel', up);
      endHold();
    };
  }, [open]);

  // The recorder coming up takes your hands, the same as the HUD hiding its FLAG button.
  useEffect(() => {
    if (evp.raised) endHold();
  });

  if (!open) return null;

  const route = routeManager.activeRoute;
  const stops = route.stops.slice(1); // index 0 is the empty placeholder; 1..13 are the stops
  const at = atStop(G);
  const next = nextStopIndex(at, stops.length);
  const lastSus = G.susLog.length ? G.susLog[G.susLog.length - 1] : null;
  const flagRatio = Math.max(0, Math.min(1, G.flagLock ? 1 : G.flagProg / CFG.flagHold));
  const feed = [...G.paFeed].reverse(); // latest first
  const handsBusy = evp.raised;

  return (
    <section
      ref={panelRef}
      role="dialog"
      aria-label="PA board"
      data-testid="pa-board"
      tabIndex={-1}
      className={`${GLASS} absolute right-3 top-[calc(var(--hud-h,6rem)+0.5rem)] bottom-[6.75rem] z-10 w-[min(92vw,380px)] max-[540px]:w-[calc(100%-9.5rem)] flex flex-col overflow-hidden rounded-xl text-cream pointer-events-auto`}
    >
      {/* Header: line bullet, title, ride clock, close */}
      <header className="shrink-0 flex flex-wrap items-center gap-x-2 gap-y-1 px-3 py-2.5 bg-black/70 border-b border-white/10">
        <span
          className="shrink-0 w-6 h-6 rounded-full font-extrabold flex items-center justify-center text-xs shadow"
          style={{ backgroundColor: route.bulletColor, color: route.bulletTextColor }}
        >
          {route.id}
        </span>
        <span className="flex items-center gap-1.5 font-extrabold tracking-[0.14em] text-sm whitespace-nowrap">
          <Megaphone className="w-4 h-4 text-warn" />
          PA BOARD
        </span>
        {unread > 0 && (
          <span data-testid="pa-board-unread-in-panel" className="text-3xs font-mono font-bold bg-warn text-[#1a1205] px-1.5 py-0.5 rounded-full">
            {unread} NEW
          </span>
        )}
        <span className="ml-auto flex items-center gap-2 shrink-0">
          <span className="font-mono text-xs text-cream/70 tabular-nums" title="Ride time">
            {fmtClock(G.GT)}
          </span>
          <button
            type="button"
            onClick={onToggle}
            aria-label="Close PA board"
            aria-keyshortcuts="B"
            className="shrink-0 w-9 h-9 rounded-full border border-white/15 bg-black/60 text-cream hover:bg-black/80 flex items-center justify-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cream"
          >
            <X className="w-4 h-4" />
          </button>
        </span>
      </header>

      <div className="flex-1 min-h-0 overflow-y-auto overscroll-contain px-3 py-3 flex flex-col gap-4">
        {/* Route strip: passed / at / next / upcoming, from the active route and the segment */}
        <div>
          <h2 className="font-mono text-3xs font-bold tracking-[0.2em] uppercase text-cream/60 mb-1.5 truncate">
            {route.id} · {stops[0]} → {stops[stops.length - 1]}
          </h2>
          <ol ref={routeRef} className="relative flex flex-col gap-0.5 max-h-32 overflow-y-auto overscroll-contain" aria-label="Route progress">
            {stops.map((name, i) => {
              const n = i + 1;
              const state = n < at ? 'passed' : n === at ? 'at' : n === next ? 'next' : 'upcoming';
              return (
                <li
                  key={n}
                  data-testid={`pa-board-stop-${n}`}
                  data-state={state}
                  className={`flex items-center gap-2 px-2 py-1 rounded text-sm ${
                    state === 'at'
                      ? 'bg-g-line/20 text-cream font-bold'
                      : state === 'next'
                      ? 'text-cream'
                      : state === 'passed'
                      ? 'text-cream/40 line-through'
                      : 'text-cream/60'
                  }`}
                >
                  <span
                    className="shrink-0 w-2 h-2 rounded-full"
                    style={{ backgroundColor: state === 'at' ? route.bulletColor : state === 'next' ? '#e3a83a' : 'rgba(255,255,255,0.25)' }}
                    aria-hidden="true"
                  />
                  <span className="min-w-0 truncate">{name}</span>
                  {state === 'at' && <span className="ml-auto shrink-0 font-mono text-3xs tracking-widest text-g-line">HERE</span>}
                  {state === 'next' && <span className="ml-auto shrink-0 font-mono text-3xs tracking-widest text-warn">NEXT</span>}
                </li>
              );
            })}
          </ol>
        </div>

        {/* Suspicion meter: G.sus, clamped 0–100 by addSus. Stage names are display only. */}
        <div>
          <div className="flex items-baseline justify-between mb-1 gap-2">
            <h2 className="font-mono text-3xs font-bold tracking-[0.2em] uppercase text-cream/60">Suspicion</h2>
            <span className="font-mono text-xs tabular-nums text-right">
              <b className={G.sus >= SUS.intervene ? 'text-bad-pale' : 'text-cream'}>{Math.round(G.sus)}</b>
              <span className="text-cream/50"> / 100 · peak {Math.round(G.peak)}</span>
              <span className="ml-2 font-bold tracking-widest text-warn">{susStage(G.sus)}</span>
            </span>
          </div>
          <div
            className="h-2 rounded-full bg-white/15 overflow-hidden"
            role="meter"
            aria-label={`Suspicion ${Math.round(G.sus)} out of 100, ${susStage(G.sus)}`}
            aria-valuenow={Math.round(G.sus)}
            aria-valuemin={0}
            aria-valuemax={100}
          >
            <div
              className={`h-full transition-all duration-300 ${G.sus >= SUS.intervene ? 'bg-bad' : G.sus >= 40 ? 'bg-warn' : 'bg-g-line'}`}
              style={{ width: `${Math.max(0, Math.min(100, G.sus))}%` }}
            />
          </div>
          <p className="mt-1 text-3xs text-cream/60 leading-snug" data-testid="pa-board-last-noticed">
            Sanity {Math.round(G.san)} · {TIER_NAMES[G.tier]}
            {lastSus ? (
              <>
                {' · '}Last noticed: {lastSus.reason} (Stop {lastSus.stop})
              </>
            ) : (
              <> · Nothing noticed yet</>
            )}
          </p>
        </div>

        {/* PA feed: every announcement this run, latest first, verbatim. */}
        <div>
          <h2 className="font-mono text-3xs font-bold tracking-[0.2em] uppercase text-cream/60 mb-1.5">Announcements</h2>
          {feed.length === 0 ? (
            <p className="text-sm text-cream/60">No announcements yet — the conductor speaks as the ride goes on.</p>
          ) : (
            <ol className="flex flex-col gap-1.5" data-testid="pa-board-feed">
              {feed.map((entry, i) => (
                <li key={`${entry.seq}-${i}`} className="px-2 py-1.5 rounded bg-white/5 border border-white/5 text-sm leading-snug break-words">
                  <span className="block font-mono text-3xs text-cream/50 mb-0.5">
                    ST {entry.stop} · {fmtClock(entry.at)}
                  </span>
                  {entry.text}
                </li>
              ))}
            </ol>
          )}
        </div>
      </div>

      {/* Flag stays put under the scroll, so a phone can still hold it. Same hold as the HUD. */}
      <div className="shrink-0 px-3 pt-2 pb-3 border-t border-white/10">
        <button
          type="button"
          data-testid="pa-board-flag"
          onPointerDown={(e) => {
            if (handsBusy) return;
            e.preventDefault();
            e.stopPropagation();
            holdingRef.current = true;
            holdingIdRef.current = e.pointerId;
            try {
              e.currentTarget.setPointerCapture(e.pointerId);
            } catch {
              /* synthetic or already-ended pointer: the window pointerup still releases */
            }
            onFlagDown();
          }}
          onPointerUp={endHold}
          onPointerCancel={endHold}
          onLostPointerCapture={endHold}
          onContextMenu={(e) => e.preventDefault()}
          aria-label="Flag: hold to catch"
          aria-disabled={handsBusy || undefined}
          className={`touch-none w-full flex items-center justify-center gap-2 min-h-11 px-3 py-2 rounded-lg border font-extrabold tracking-wider text-sm transition-colors active:translate-y-px focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cream ${
            handsBusy
              ? 'bg-black/60 border-white/10 text-cream/40 cursor-not-allowed'
              : G.flagHeld
              ? 'bg-g-line/30 border-g-line text-cream'
              : 'bg-black/65 border-white/30 text-cream hover:bg-black/80'
          }`}
        >
          <Flag className="w-4 h-4" />
          {handsBusy ? 'FLAG — HANDS BUSY' : G.flagHeld ? 'FLAGGING…' : 'HOLD TO FLAG'}
          <kbd className="text-3xs opacity-70 bg-white/10 px-1 py-0.5 rounded font-mono">F</kbd>
        </button>
        <div className="mt-1.5 h-1 rounded-full bg-white/15 overflow-hidden" aria-hidden="true">
          <div className="h-full bg-g-line transition-all duration-100" style={{ width: `${flagRatio * 100}%` }} />
        </div>
        <p className="mt-1.5 text-3xs text-cream/60 leading-snug">
          Flags placed this stretch: {G.segFlags.length} · A flag never says whether you were right — catches
          and misses are scored when the train arrives.
        </p>
        <p className="mt-1.5 text-3xs text-cream/40 font-mono">[B] PA board · [F] hold to flag</p>
      </div>
    </section>
  );
};
