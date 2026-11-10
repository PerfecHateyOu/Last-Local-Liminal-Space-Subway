/**
 * Pure PA-board state. The panel (src/components/PaBoard.tsx) and the HUD badge
 * (src/App.tsx) both read this so the strip, the stage labels and the unread
 * count can't drift apart.
 *
 * Stage names are display labels only. Suspicion itself still clamps at 0–100
 * and a parent intervenes at SUS.intervene; nothing here ends a run.
 */
import { SUS } from '../constants';

/** Display-only suspicion stage. Thresholds match the wiring notes: <20 / <40 / <60 / ≥60. */
export function susStage(sus: number): string {
  if (sus >= SUS.intervene) return 'IT KNOWS';
  if (sus >= 40) return 'WATCHED';
  if (sus >= 20) return 'UNEASY';
  return 'CALM';
}

/**
 * The stop the train is at, or has just left.
 * While stopped (stop / haven / trial) it's the segment's stop.
 * While riding it's the stop before it.
 * The false 6b stretch re-uses stop 6 for the whole stretch (ride and stop).
 * Before the first segment, stop 1 (the boarded station).
 */
export function atStop(G: { seg: { stop: number; b?: boolean } | null; phase: string }): number {
  const seg = G.seg;
  if (!seg) return 1;
  if (seg.b) return seg.stop;
  if (G.phase === 'stop' || G.phase === 'haven' || G.phase === 'trial') return seg.stop;
  return Math.max(1, seg.stop - 1);
}

/** The following stop on a 1-based strip, or null once the train is at the last one. */
export function nextStopIndex(at: number, stopCount: number): number | null {
  return at < stopCount ? at + 1 : null;
}

/**
 * Announcements still in the feed that the player has not had on screen.
 * The feed itself is capped (oldest dropped), so the count cannot exceed the
 * feed. A new run zeroes `paSeq`; a remembered seen-seq from the previous run
 * is discarded. While the panel is open every current entry counts as seen.
 */
export function syncPaSeen(
  feed: readonly { seq: number }[],
  seenSeq: number,
  open: boolean,
  paSeq: number,
): { unread: number; seen: number } {
  const seen = open || paSeq < seenSeq ? (open ? paSeq : 0) : seenSeq;
  if (open) return { unread: 0, seen };
  let unread = 0;
  for (const entry of feed) if (entry.seq > seen) unread++;
  return { unread, seen };
}
