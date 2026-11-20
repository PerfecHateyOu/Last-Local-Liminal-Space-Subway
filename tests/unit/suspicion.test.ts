import { test } from 'bun:test';
import assert from 'node:assert/strict';
import {
  applySuspicionChange,
  clampSuspicion,
  createInitialSuspicion,
  getSuspicionBand,
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
