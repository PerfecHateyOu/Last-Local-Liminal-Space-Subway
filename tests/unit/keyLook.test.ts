import { describe, expect, test } from 'bun:test';
import { KEY_LOOK_RATE, KeyLook } from '../../src/input/keyLook';
import type { GameEngine } from '../../src/game/gameState';

function view(): GameEngine {
  return { phase: 'ride', ty: 0, tp: 0 } as GameEngine;
}

describe('KeyLook pause', () => {
  test('a repeat of a key forgotten by pause does not turn; a fresh press does', () => {
    const look = new KeyLook();
    const G = view();
    look.press('ArrowLeft');
    look.apply(G, 0.1, 1);
    const atPause = G.ty;
    expect(atPause).toBeCloseTo(KEY_LOOK_RATE.yaw * 0.1);
    look.clear();
    look.press('ArrowLeft', true);
    look.apply(G, 0.4, 1);
    expect(G.ty).toBe(atPause);
    look.press('ArrowLeft');
    look.apply(G, 0.1, 1);
    expect(G.ty).toBeCloseTo(atPause + KEY_LOOK_RATE.yaw * 0.1);
  });

  test('releasing the forgotten key lets the next hold turn, including its repeats', () => {
    const look = new KeyLook();
    const G = view();
    look.press('ArrowUp');
    look.clear();
    look.release('ArrowUp');
    look.press('ArrowUp', true);
    look.apply(G, 0.1, 1);
    expect(G.tp).toBeCloseTo(KEY_LOOK_RATE.pitch * 0.1);
  });
});
