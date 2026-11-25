/**
 * Suspicion System (0–100)
 * Shared scoring values and NEON band definitions. The original game has
 * its own PA labels and parent intervention rules.
 */

export type SuspicionBand = 'CALM' | 'UNEASY' | 'WATCHED' | 'HUNTED';

export interface SuspicionBandInfo {
  band: SuspicionBand;
  min: number;
  max: number;
  color: string;
  label: string;
}

export const SUSPICION_BANDS: readonly SuspicionBandInfo[] = [
  { band: 'CALM', min: 0, max: 24, color: '#4ade80', label: 'CALM' },
  { band: 'UNEASY', min: 25, max: 49, color: '#f59e0b', label: 'UNEASY' },
  { band: 'WATCHED', min: 50, max: 74, color: '#f97316', label: 'WATCHED' },
  { band: 'HUNTED', min: 75, max: 100, color: '#dc2626', label: 'HUNTED' },
] as const;

export const SUSPICION_DELTAS = {
  FALSE_POSITIVE: 20,
  FAILED_MASK_PROMPT: 15,
  PROMPT_TIMEOUT: 8,
  VISIBLE_REACTION: 10,
  REFUSE_SAFE_HAVEN: 10,
  CLEAN_STOP: -5,
  /** Forgiving false stop (Stop 4: Classon Av) uses a soft penalty if player reacts */
  FORGIVING_FALSE_STOP_REACT: 4,
  /** Stepping off at Metropolitan Av false stop or breaking restraint */
  FALSE_STOP_EXIT_PENALTY: 18,
  RESTRAINT_LET_GO: 15,
} as const;

export type SuspicionReason =
  | 'false_positive'
  | 'failed_mask_prompt'
  | 'prompt_timeout'
  | 'visible_reaction'
  | 'refuse_safe_haven'
  | 'clean_stop'
  | 'forgiving_false_stop'
  | 'false_stop_exit'
  | 'restraint_let_go';

export interface SuspicionEvent {
  reason: SuspicionReason;
  delta: number;
  resultingValue: number;
  stopNumber: number;
}

export interface SuspicionState {
  value: number;
  peak: number;
  history: SuspicionEvent[];
}

export function createInitialSuspicion(): SuspicionState {
  return {
    value: 0,
    peak: 0,
    history: [],
  };
}

export function clampSuspicion(value: number): number {
  return Math.max(0, Math.min(100, value));
}

export function getSuspicionBand(value: number): SuspicionBand {
  const clamped = clampSuspicion(Math.round(value));
  if (clamped <= 24) return 'CALM';
  if (clamped <= 49) return 'UNEASY';
  if (clamped <= 74) return 'WATCHED';
  return 'HUNTED';
}

export function getSuspicionBandInfo(value: number): SuspicionBandInfo {
  const band = getSuspicionBand(value);
  return SUSPICION_BANDS.find((b) => b.band === band) ?? SUSPICION_BANDS[0];
}

export function getDeltaForReason(reason: SuspicionReason): number {
  switch (reason) {
    case 'false_positive':
      return SUSPICION_DELTAS.FALSE_POSITIVE;
    case 'failed_mask_prompt':
      return SUSPICION_DELTAS.FAILED_MASK_PROMPT;
    case 'prompt_timeout':
      return SUSPICION_DELTAS.PROMPT_TIMEOUT;
    case 'visible_reaction':
      return SUSPICION_DELTAS.VISIBLE_REACTION;
    case 'refuse_safe_haven':
      return SUSPICION_DELTAS.REFUSE_SAFE_HAVEN;
    case 'clean_stop':
      return SUSPICION_DELTAS.CLEAN_STOP;
    case 'forgiving_false_stop':
      return SUSPICION_DELTAS.FORGIVING_FALSE_STOP_REACT;
    case 'false_stop_exit':
      return SUSPICION_DELTAS.FALSE_STOP_EXIT_PENALTY;
    case 'restraint_let_go':
      return SUSPICION_DELTAS.RESTRAINT_LET_GO;
    default:
      return 0;
  }
}

export function applySuspicionChange(
  state: SuspicionState,
  reason: SuspicionReason,
  stopNumber: number,
  practiceMode = false,
): SuspicionState {
  const rawDelta = getDeltaForReason(reason);
  // Practice mode softens penalties so players can learn safely
  const delta = practiceMode && rawDelta > 0 ? Math.ceil(rawDelta * 0.5) : rawDelta;
  const nextValue = clampSuspicion(Math.round(state.value + delta));
  return {
    value: nextValue,
    peak: Math.max(state.peak, nextValue),
    history: [
      ...state.history,
      {
        reason,
        delta,
        resultingValue: nextValue,
        stopNumber,
      },
    ],
  };
}

/**
 * How closely Mom & Dad monitor the player based on current suspicion band.
 * Higher bands increase parent stare frequency and hold duration, tighten stare tolerance,
 * and lower `headSnapRadPerSec` (the player head-turn angular speed threshold in rad/s above
 * which a sudden turn is flagged — 6.2 at CALM down to 3.8 at HUNTED, so lower means more sensitive).
 */
export function getParentWatchProfile(value: number, nightmare: boolean): {
  glanceIntervalSec: number;
  holdLookSec: number;
  stareToleranceSec: number;
  /** Player head-turn speed threshold (rad/s) flagged as a snap; falls 6.2 -> 3.8 from CALM to HUNTED. */
  headSnapRadPerSec: number;
} {
  const band = getSuspicionBand(value);
  const mult = nightmare ? 0.72 : 1.0;
  const holdMult = nightmare ? 1.45 : 1.0;

  switch (band) {
    case 'CALM':
      return {
        glanceIntervalSec: 11 * mult,
        holdLookSec: 2.8 * holdMult,
        stareToleranceSec: 3.4 * mult,
        headSnapRadPerSec: 6.2,
      };
    case 'UNEASY':
      return {
        glanceIntervalSec: 8 * mult,
        holdLookSec: 3.8 * holdMult,
        stareToleranceSec: 2.7 * mult,
        headSnapRadPerSec: 5.2,
      };
    case 'WATCHED':
      return {
        glanceIntervalSec: 5.5 * mult,
        holdLookSec: 5.0 * holdMult,
        stareToleranceSec: 2.1 * mult,
        headSnapRadPerSec: 4.4,
      };
    case 'HUNTED':
      return {
        glanceIntervalSec: 3.8 * mult,
        holdLookSec: 6.5 * holdMult,
        stareToleranceSec: 1.5 * mult,
        headSnapRadPerSec: 3.8,
      };
  }
}
