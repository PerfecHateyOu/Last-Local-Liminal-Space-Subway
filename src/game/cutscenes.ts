/**
 * Pure cutscene definitions and clock-isolated player for LAST LOCAL.
 * No React or Three.js dependencies so definitions and playback can be unit-tested directly.
 */
import { fillRoute } from './routeText';

export type CutsceneId = 'intro' | 'haven' | 'trial' | 'arrival';

export interface CutsceneShot {
  yaw: number;
  pitch: number;
  eye?: [number, number, number];
}

export type CutsceneAction =
  | { type: 'chime' }
  | { type: 'closeDoors' }
  | { type: 'openDoors' }
  | { type: 'giveRecorder'; where: 'haven' };

export interface CutsceneBeat {
  /** Duration of this beat in seconds (must be > 0). */
  dur: number;
  shot: CutsceneShot;
  sub?: string;
  subDur?: number;
  pa?: string;
  paDur?: number;
  hint?: string;
  hintDur?: number;
  action?: CutsceneAction;
}

export interface CutsceneDef {
  id: CutsceneId;
  title: string;
  beats: CutsceneBeat[];
}

export interface CutsceneOptions {
  looped?: boolean;
  chapterStart?: boolean;
  isTouch?: boolean;
}

/**
 * Build one of the four in-engine cutscenes with current route place names.
 */
export function buildCutscene(id: CutsceneId, opts: CutsceneOptions = {}): CutsceneDef {
  switch (id) {
    case 'intro': {
      const looped = !!opts.looped;
      const chapterStart = !!opts.chapterStart;
      const isTouch = !!opts.isTouch;

      const dadLine = chapterStart
        ? 'Grab a seat right here.'
        : fillRoute('Grab a seat right here. Thirteen stops to {terminus}.');

      const lookHint = isTouch
        ? 'Drag to look around. Hold FLAG while looking at anything that changes.'
        : 'Move the mouse to look. Hold F while looking at anything that changes.';

      const beats: CutsceneBeat[] = [
        {
          // Silent opening: doors open, clean screen and empty PA feed on a fresh start.
          dur: 1.2,
          shot: { yaw: 0, pitch: -0.05, eye: [0, 1.18, 0.4] },
        },
        {
          dur: 1.6,
          shot: { yaw: 0.08, pitch: -0.03 },
          pa: fillRoute('This is the Last Local. {terminus}–bound {line} train.'),
          paDur: 4.0,
          sub: fillRoute('<em>You board at {origin}, between Mom and Dad.</em>'),
          subDur: 2.0,
        },
        {
          dur: 2.4,
          shot: { yaw: 0.15, pitch: -0.02 },
          sub: `<b>Dad:</b> ${dadLine}`,
          subDur: 2.8,
          ...(looped ? {} : { hint: lookHint, hintDur: 7.0 }),
        },
        {
          dur: 1.8,
          shot: { yaw: 0.42, pitch: -0.02 },
          sub: '<b>Mom:</b> Stay where we can see you, okay?',
          subDur: 2.4,
        },
      ];

      if (looped) {
        beats.push({
          dur: 2.4,
          shot: { yaw: 0.15, pitch: -0.04 },
          sub: '<em>He said that last time, too.</em>',
          subDur: 2.4,
        });
      }

      beats.push(
        {
          dur: 1.0,
          shot: { yaw: 0, pitch: -0.05 },
          pa: 'Stand clear of the closing doors, please.',
          paDur: 3.0,
          action: { type: 'chime' },
        },
        {
          dur: 1.2,
          shot: { yaw: 0, pitch: -0.05 },
          action: { type: 'closeDoors' },
        },
      );

      return {
        id: 'intro',
        title: fillRoute('{origin}'),
        beats,
      };
    }

    case 'haven':
      return {
        id: 'haven',
        title: 'Safe Haven',
        beats: [
          {
            dur: 0.8,
            shot: { yaw: 0.08, pitch: -0.04 },
          },
          {
            dur: 2.7,
            shot: { yaw: 0.42, pitch: -0.02 },
            sub: '<b>Mom:</b> Feels good to stand up, right?',
            subDur: 2.6,
          },
          {
            dur: 2.9,
            shot: { yaw: 0.15, pitch: -0.02 },
            sub: `<b>Dad:</b> ${fillRoute('Couple more stops after this. Then {terminus}.')}`,
            subDur: 2.8,
          },
          {
            dur: 4.0,
            shot: { yaw: 0.15, pitch: 0.02 },
            action: { type: 'giveRecorder', where: 'haven' },
          },
        ],
      };

    case 'trial':
      return {
        id: 'trial',
        title: 'False Stop',
        beats: [
          {
            dur: 1.6,
            shot: { yaw: 0, pitch: 0.04, eye: [0, 1.6, 2.2] },
            sub: '<em>The doors shut behind you. The platform is empty.</em>',
            subDur: 2.2,
          },
          {
            dur: 1.7,
            shot: { yaw: 0.35, pitch: 0.02 },
            sub: '<em>Three ways out. None of the signs agree.</em>',
            subDur: 2.0,
          },
          {
            dur: 1.7,
            shot: { yaw: 0, pitch: 0 },
            sub: '<em>Somewhere overhead, a light flickers once.</em>',
            subDur: 1.7,
          },
        ],
      };

    case 'arrival':
      return {
        id: 'arrival',
        title: fillRoute('{terminus}'),
        beats: [
          {
            dur: 1.9,
            shot: { yaw: 0, pitch: -0.05 },
            action: { type: 'chime' },
          },
          {
            dur: 1.1,
            shot: { yaw: -0.35, pitch: -0.03 },
            action: { type: 'openDoors' },
          },
          {
            dur: 1.8,
            shot: { yaw: 0.42, pitch: -0.02 },
            sub: `<b>Mom:</b> ${fillRoute('Here we are. {terminus}.')}`,
            subDur: 3.0,
          },
          {
            dur: 1.8,
            shot: { yaw: 0.12, pitch: -0.02 },
            sub: '<em>Your parents stand up and gather their bags.</em>',
            subDur: 2.0,
          },
        ],
      };
  }
}

/**
 * Isolated cutscene player advancing strictly on its own clock.
 * Never skips a beat or its action on a large dt spike.
 */
export class CutscenePlayer {
  public readonly id: CutsceneId;
  public readonly title: string;
  public readonly beats: readonly CutsceneBeat[];
  public readonly totalDuration: number;

  public index = 0;
  public beatElapsed = 0;
  public elapsed = 0;
  public finished = false;

  constructor(def: CutsceneDef) {
    if (!def.beats || def.beats.length === 0) {
      throw new Error(`Cutscene "${def.id}" must have at least one beat`);
    }
    let total = 0;
    for (let i = 0; i < def.beats.length; i++) {
      const dur = def.beats[i].dur;
      if (typeof dur !== 'number' || !Number.isFinite(dur) || dur <= 0) {
        throw new Error(`Cutscene "${def.id}" beat ${i} has non-positive duration: ${dur}`);
      }
      total += dur;
    }
    this.id = def.id;
    this.title = def.title;
    this.beats = def.beats;
    this.totalDuration = total;
  }

  public get currentBeat(): CutsceneBeat {
    return this.beats[this.index];
  }

  public get progress(): number {
    if (this.finished) return 1;
    if (this.totalDuration <= 0) return 1;
    return Math.max(0, Math.min(1, this.elapsed / this.totalDuration));
  }

  /**
   * Advance the cutscene clock by `dt` seconds.
   * Returns `'beat'` when the next beat starts, `'finished'` when the last beat ends, or `null`.
   * A huge `dt` advances at most one beat per call so no beat or action is ever jumped over.
   */
  public update(dt: number): 'beat' | 'finished' | null {
    if (this.finished || dt <= 0 || !Number.isFinite(dt)) return null;

    const cur = this.beats[this.index];
    const rem = cur.dur - this.beatElapsed;
    if (dt < rem - 1e-9) {
      this.beatElapsed += dt;
      this.elapsed += dt;
      return null;
    }

    // Never carry a large dt spike into the next beat; only carry sub-frame remainder.
    const carry = dt <= 0.1 ? Math.max(0, dt - rem) : 0;
    this.elapsed += rem;

    if (this.index + 1 >= this.beats.length) {
      this.beatElapsed = cur.dur;
      this.elapsed = this.totalDuration;
      this.finished = true;
      return 'finished';
    }

    this.index += 1;
    const next = this.beats[this.index];
    this.beatElapsed = Math.min(carry, next.dur * 0.99);
    this.elapsed += this.beatElapsed;
    return 'beat';
  }

  /**
   * End the cutscene immediately and return the actions of every beat not yet played, in order.
   * Calling skip() after the cutscene has finished is a no-op returning [].
   */
  public skip(): CutsceneAction[] {
    if (this.finished) return [];
    const actions: CutsceneAction[] = [];
    for (let i = this.index + 1; i < this.beats.length; i++) {
      const action = this.beats[i].action;
      if (action) actions.push(action);
    }
    this.index = this.beats.length - 1;
    this.beatElapsed = this.beats[this.index].dur;
    this.elapsed = this.totalDuration;
    this.finished = true;
    return actions;
  }
}
