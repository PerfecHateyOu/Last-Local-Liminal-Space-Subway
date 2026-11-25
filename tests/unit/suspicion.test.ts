import { test } from 'bun:test';
import assert from 'node:assert/strict';
import {
  applySuspicionChange,
  clampSuspicion,
  createInitialSuspicion,
  getDeltaForReason,
  getParentWatchProfile,
  getSuspicionBand,
  type SuspicionReason,
} from '../../src/game/suspicion';

test('Suspicion bands and scoring deltas match specification exactly', () => {
  assert.equal(getSuspicionBand(0), 'CALM');
  assert.equal(getSuspicionBand(24), 'CALM');
  assert.equal(getSuspicionBand(25), 'UNEASY');
  assert.equal(getSuspicionBand(49), 'UNEASY');
  assert.equal(getSuspicionBand(50), 'WATCHED');
  assert.equal(getSuspicionBand(74), 'WATCHED');
  assert.equal(getSuspicionBand(75), 'HUNTED');
  assert.equal(getSuspicionBand(100), 'HUNTED');

  let s = createInitialSuspicion();
  s = applySuspicionChange(s, 'false_positive', 2);
  assert.equal(s.value, 20);
  s = applySuspicionChange(s, 'failed_mask_prompt', 2);
  assert.equal(s.value, 35);
  s = applySuspicionChange(s, 'prompt_timeout', 3);
  assert.equal(s.value, 43);
  s = applySuspicionChange(s, 'visible_reaction', 3);
  assert.equal(s.value, 53);
  s = applySuspicionChange(s, 'refuse_safe_haven', 6);
  assert.equal(s.value, 63);
  s = applySuspicionChange(s, 'clean_stop', 7);
  assert.equal(s.value, 58);

  // Clamps cleanly to 100 and never throws
  s = applySuspicionChange(s, 'false_positive', 8);
  s = applySuspicionChange(s, 'false_positive', 8);
  s = applySuspicionChange(s, 'false_positive', 8);
  assert.equal(s.value, 100);
});

test('Clamps the original engine score without rounding', () => {
  assert.equal(clampSuspicion(-0.5), 0);
  assert.equal(clampSuspicion(24.5), 24.5);
  assert.equal(clampSuspicion(100.5), 100);
});

test('Unknown suspicion reason scores 0 and never produces NaN', () => {
  const unknown = 'unexpected_reason' as SuspicionReason;
  assert.equal(getDeltaForReason(unknown), 0);

  const next = applySuspicionChange(createInitialSuspicion(), unknown, 1);
  assert.equal(Number.isNaN(next.value), false);
  assert.equal(next.value, 0);
  assert.equal(getSuspicionBand(next.value), 'CALM');
  assert.equal(next.history.length, 1);
  assert.equal(next.history[0].delta, 0);
});

test('Head-snap threshold falls 6.2 -> 3.8 from CALM to HUNTED and is unchanged by Nightmare', () => {
  const calm = getParentWatchProfile(0, false);
  const uneasy = getParentWatchProfile(25, false);
  const watched = getParentWatchProfile(50, false);
  const hunted = getParentWatchProfile(75, false);

  assert.equal(calm.headSnapRadPerSec, 6.2);
  assert.equal(uneasy.headSnapRadPerSec, 5.2);
  assert.equal(watched.headSnapRadPerSec, 4.4);
  assert.equal(hunted.headSnapRadPerSec, 3.8);

  assert.ok(calm.headSnapRadPerSec > uneasy.headSnapRadPerSec);
  assert.ok(uneasy.headSnapRadPerSec > watched.headSnapRadPerSec);
  assert.ok(watched.headSnapRadPerSec > hunted.headSnapRadPerSec);

  for (const score of [0, 25, 50, 75]) {
    const normal = getParentWatchProfile(score, false);
    const nightmare = getParentWatchProfile(score, true);
    assert.equal(nightmare.headSnapRadPerSec, normal.headSnapRadPerSec);
    assert.ok(nightmare.glanceIntervalSec < normal.glanceIntervalSec);
    assert.ok(nightmare.stareToleranceSec < normal.stareToleranceSec);
    assert.ok(nightmare.holdLookSec > normal.holdLookSec);
  }
});
