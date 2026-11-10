import { test, expect } from './game';
import type { Page } from '@playwright/test';

// The PA board (src/components/PaBoard.tsx): B toggles it, it lists the conductor PA verbatim,
// the badge counts announcements made while it was closed, and the suspicion meter reads G.sus.
// Tab stays the Evidence log, so the board takes B.

// Live anomaly copy. If any of it appears in the panel, the board is spoiling what's wrong.
const ANOMALY_DESCS = [
  'typo',
  'sticker',
  'stain',
  'cold sterile blue',
  'stared directly',
  'Hollow St',
  'shifted its background color',
  'far doors',
  'unrecognized silent passenger',
  'warped into disturbing words',
  'twisted her neck',
  'uncanny expression',
  'answered an unspoken thought',
  'completely empty',
  'Poster Drift',
  'Headcount',
  'Phantom Stop',
  'Extra Door',
  'adswap',
  'dadanswer',
  'Active Anomalies',
];

const LIE = 'This is Court Square. Last stop. Everybody off the train.';

async function feedTexts(page: Page): Promise<string[]> {
  return page.getByTestId('pa-board-feed').locator('li').evaluateAll((rows) =>
    rows.map((row) => {
      const stamp = row.querySelector('span')?.textContent ?? '';
      return (row.textContent || '').replace(stamp, '').trim();
    }),
  );
}

test.describe('PA board', () => {
  test('B toggles it and it lists the conductor PA with the route strip', async ({ page, game }) => {
    await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0); G.setPA('The next stop is Fulton St.', 30); G.notifyUI();`);
    const board = page.getByTestId('pa-board');
    await expect(board).toHaveCount(0);

    await page.keyboard.press('KeyB');
    await expect(board).toBeVisible();
    await expect(board).toContainText('The next stop is Fulton St.');
    await expect(board).toContainText('Hoyt');
    await expect(board).toContainText('Court Sq');
    await expect(page.getByTestId('pa-board-stop-1')).toHaveAttribute('data-state', 'at');
    await expect(page.getByTestId('pa-board-stop-2')).toHaveAttribute('data-state', 'next');
    await expect(page.getByTestId('pa-board-toggle')).toHaveAttribute('aria-pressed', 'true');

    await page.keyboard.press('KeyB');
    await expect(board).toHaveCount(0);
    await expect(page.getByTestId('pa-board-toggle')).toHaveAttribute('aria-pressed', 'false');
  });

  test('HERE and NEXT follow travel, a stop, the haven, the false 6b stretch, a trial and the last stop', async ({ page, game }) => {
    await game(`G.Q = []; ride(0);`);
    await page.keyboard.press('KeyB');
    const at = (n: number) => page.getByTestId(`pa-board-stop-${n}`);

    // Riding toward Fulton: just left Hoyt.
    await expect(at(1)).toHaveAttribute('data-state', 'at');
    await expect(at(2)).toHaveAttribute('data-state', 'next');

    // Stopped at Fulton.
    await game(`G.phase = 'stop'; G.notifyUI();`);
    await expect(at(2)).toHaveAttribute('data-state', 'at');
    await expect(at(3)).toHaveAttribute('data-state', 'next');
    await expect(at(2)).toContainText('HERE');
    await expect(at(3)).toContainText('NEXT');

    // Haven is stop 6 itself.
    await game(`G.Q = []; G.startSegment(4); G.phase = 'haven'; G.notifyUI();`);
    await expect(at(6)).toHaveAttribute('data-state', 'at');
    await expect(at(7)).toHaveAttribute('data-state', 'next');
    await expect(at(5)).toHaveAttribute('data-state', 'passed');

    // The false 6b stretch re-uses stop 6 while travelling, not the stop before it.
    await game(`G.Q = []; G.startSegment(5); G.notifyUI();`);
    expect(await game(`return G.seg.b && G.phase === 'ride' && G.seg.stop === 6;`)).toBe(true);
    await expect(at(6)).toHaveAttribute('data-state', 'at');
    await expect(at(5)).toHaveAttribute('data-state', 'passed');
    await expect(at(7)).toHaveAttribute('data-state', 'next');

    await game(`G.phase = 'trial'; G.notifyUI();`);
    await expect(at(6)).toHaveAttribute('data-state', 'at');

    // A later false stop's trial is that stop, not the one before it.
    await game(`G.Q = []; G.startSegment(8); G.phase = 'trial'; G.notifyUI();`);
    await expect(at(9)).toHaveAttribute('data-state', 'at');
    await expect(at(10)).toHaveAttribute('data-state', 'next');

    // Arrived at the last stop: HERE, and no NEXT.
    await game(`G.Q = []; G.startSegment(12); G.phase = 'stop'; G.notifyUI();`);
    await expect(at(13)).toHaveAttribute('data-state', 'at');
    await expect(at(12)).toHaveAttribute('data-state', 'passed');
    await expect(at(13)).toContainText('HERE');
    await expect(at(13)).not.toContainText('NEXT');
  });

  test('the strip reads the active route on G, L and 7', async ({ page, game }) => {
    await game(`G.Q = []; ride(0);`);
    await page.keyboard.press('KeyB');
    const board = page.getByTestId('pa-board');
    await expect(board).toContainText('Hoyt–Schermerhorn');
    await expect(board).toContainText('Court Sq');

    await game(`window.__RT.setRoute('L'); G.notifyUI();`);
    await expect(board).toContainText('8th Av');
    await expect(board).toContainText('Myrtle–Wyckoff Avs');
    await expect(board).not.toContainText('Hoyt–Schermerhorn');

    await game(`window.__RT.setRoute('7'); G.notifyUI();`);
    await expect(board).toContainText('Times Sq–42nd St');
    await expect(board).toContainText('Terminal Echo');
    await expect(page.getByTestId('pa-board-stop-1')).toHaveAttribute('data-state', 'at');
  });

  test('the badge counts announcements made while it is closed, then clears on open', async ({ page, game }) => {
    await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0); G.setPA('Test one', 30); G.setPA('Test two', 30); G.notifyUI();`);
    const badge = page.getByTestId('pa-board-unread');
    await expect(badge).toHaveText('2');

    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toBeVisible();
    await expect(badge).toHaveCount(0);

    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await expect(badge).toHaveCount(0);
  });

  test('lines that arrive while the board is open are not unread after it closes', async ({ page, game }) => {
    await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0);`);
    await page.keyboard.press('KeyB');
    await game(`G.setPA('While open', 30); G.notifyUI();`);
    await expect(page.getByTestId('pa-board')).toContainText('While open');
    await expect(page.getByTestId('pa-board-unread')).toHaveCount(0);

    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board-unread')).toHaveCount(0);

    await game(`G.setPA('After close', 30); G.notifyUI();`);
    await expect(page.getByTestId('pa-board-unread')).toHaveText('1');
  });

  test('the feed keeps 12 announcements and the badge counts only the ones still there', async ({ page, game }) => {
    const capped = await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0);
      for (let i = 1; i <= 15; i++) G.setPA('Line ' + i, 1);
      return { len: G.paFeed.length, first: G.paFeed[0].text, last: G.paFeed[G.paFeed.length - 1].text, seq: G.paSeq };`);
    expect(capped).toEqual({ len: 12, first: 'Line 4', last: 'Line 15', seq: 15 });
    await expect(page.getByTestId('pa-board-unread')).toHaveText('12');

    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board-feed').locator('li')).toHaveCount(12);
    const shown = await feedTexts(page);
    expect(shown[0]).toBe('Line 15');
    expect(shown).not.toContain('Line 1');
    expect(shown).not.toContain('Line 3');
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board-unread')).toHaveCount(0);

    await game(`G.setPA('Line 16', 1); G.notifyUI();`);
    await expect(page.getByTestId('pa-board-unread')).toHaveText('1');
    await page.keyboard.press('KeyB');
    const again = await feedTexts(page);
    expect(again[0]).toBe('Line 16');
    expect(again).not.toContain('Line 4');
    expect(again).toHaveLength(12);
  });

  test('a new run clears the feed and does not hide the next announcement behind the old seen count', async ({ page, game }) => {
    await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0); G.setPA('Old one', 30); G.setPA('Old two', 30); G.notifyUI();`);
    await page.keyboard.press('KeyB');
    await page.keyboard.press('KeyB');
    await game(`G.startIntro(); G.Q = []; G.setPA('After reset', 30); G.notifyUI();`);
    await expect(page.getByTestId('pa-board-unread')).toHaveText('1');
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toContainText('After reset');
    await expect(page.getByTestId('pa-board')).not.toContainText('Old one');
    expect(await game(`return G.paFeed.length;`)).toBe(1);
  });

  test('a false stop lie is stored verbatim, with no lie marker', async ({ page, game }) => {
    const lie = await game(`G.Q = []; G.paFeed = []; G.paSeq = 0; G.startSegment(8); return G.seg.paLie;`);
    expect(lie).toBe(LIE);
    await game(`G.setPA(G.seg.paLie, 5); G.notifyUI();`);
    await page.keyboard.press('KeyB');
    const texts = await feedTexts(page);
    expect(texts[0]).toBe(LIE);
    const body = await page.getByTestId('pa-board').innerText();
    expect(body).not.toMatch(/\blie\b/i);
    expect(body).not.toMatch(/\bfalse\b/i);
  });

  test('the suspicion meter shows the real sus value and stage', async ({ page, game }) => {
    await game(`G.Q = []; ride(0); G.addSus(25, 'test'); G.notifyUI();`);
    await page.keyboard.press('KeyB');
    const board = page.getByTestId('pa-board');
    await expect(board).toContainText('UNEASY');
    await expect(board.getByRole('meter', { name: /Suspicion 25 out of 100/ })).toBeVisible();
    await expect(page.getByTestId('pa-board-last-noticed')).toContainText('Last noticed: test');
    expect(await game(`return G.sus;`)).toBe(25);
  });

  test('the board never names a live anomaly or whether a flag caught', async ({ page, game }) => {
    const scored = await game(`G.Q = []; ride(0); G.seg._masks = [];
      const a = G.anomalyMgr.createAnomaly('lighttemp', 6);
      if (!a) throw new Error('no anomaly');
      G.active = [a]; a.at = G.GT;
      const tid = a.tids[0];
      G.flagHeld = true; G.flagTid = null; G.flagProg = 0; G.flagLock = false;
      for (let i = 0; i < 20; i++) { G.gazeTid = tid; G.updateFlag(0.05); }
      G.flagHeld = false; G.updateFlag(0.05);
      const before = G.acc.correct;
      G.arrive();
      return { flags: G.segFlags.length, correct: G.acc.correct - before, desc: a.desc };`);
    expect(scored.flags).toBeGreaterThanOrEqual(1);
    expect(scored.correct).toBeGreaterThanOrEqual(1);

    await page.keyboard.press('KeyB');
    const board = page.getByTestId('pa-board');
    await expect(board).toContainText(`Flags placed this stretch: ${scored.flags}`);
    await expect(board).toContainText('A flag never says whether you were right');
    for (const desc of ANOMALY_DESCS) await expect(board).not.toContainText(desc);
    await expect(board).not.toContainText(scored.desc);
    const body = await board.innerText();
    expect(body).not.toMatch(/\bcaught\b/i);
    expect(body).not.toMatch(/\bmiss\b/i);
    expect(body).not.toMatch(/\bcorrect\b/i);
  });

  test('hold to flag matches the HUD: release, cancel, closing, and hands busy', async ({ page, game }) => {
    await game(`G.Q = []; ride(0); G.gazeTid = 'seat';`);
    await page.keyboard.press('KeyB');
    const flag = page.getByTestId('pa-board-flag');

    await flag.dispatchEvent('pointerdown', { pointerId: 1, bubbles: true, pointerType: 'mouse', button: 0 });
    expect(await game(`return G.flagHeld;`)).toBe(true);
    await flag.dispatchEvent('pointerup', { pointerId: 1, bubbles: true, pointerType: 'mouse' });
    expect(await game(`return { held: G.flagHeld, n: G.segFlags.length };`)).toEqual({ held: false, n: 0 });

    await flag.dispatchEvent('pointerdown', { pointerId: 1, bubbles: true, pointerType: 'touch', button: 0 });
    expect(await game(`return G.flagHeld;`)).toBe(true);
    await page.locator('body').dispatchEvent('pointercancel', { pointerId: 1, bubbles: true });
    expect(await game(`return G.flagHeld;`)).toBe(false);

    await flag.dispatchEvent('pointerdown', { pointerId: 1, bubbles: true, pointerType: 'touch', button: 0 });
    await page.keyboard.press('KeyB');
    expect(await game(`return G.flagHeld;`)).toBe(false);
    await expect(page.getByTestId('pa-board')).toHaveCount(0);

    await page.keyboard.press('KeyB');
    await game(`window.__EVP.hasRecorder = true; window.__EVP.raise(); G.notifyUI();`);
    const busy = page.getByTestId('pa-board-flag');
    await expect(busy).toHaveAttribute('aria-disabled', 'true');
    await expect(busy).toContainText('FLAG — HANDS BUSY');
    await busy.dispatchEvent('pointerdown', { pointerId: 1, bubbles: true, pointerType: 'touch', button: 0 });
    expect(await game(`return G.flagHeld;`)).toBe(false);
    expect(await game(`return G.segFlags.length;`)).toBe(0);
  });

  test('Esc closes the board without pausing; pause, the report and the menu close it too', async ({ page, game }) => {
    await game(`G.Q = []; ride(0);`);
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toBeVisible();

    await page.keyboard.press('Escape');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    expect(await game(`return G.paused;`)).toBe(false);

    await page.keyboard.press('KeyB');
    await page.keyboard.press('KeyP');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await expect(page.getByRole('dialog', { name: 'Train Paused' })).toBeVisible();
    expect(await game(`return G.paused;`)).toBe(true);
    // B does not reopen it behind the pause menu.
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await page.keyboard.press('KeyP');
    expect(await game(`return G.paused;`)).toBe(false);

    await page.keyboard.press('KeyB');
    await game(`G.phase = 'end'; G.notifyUI();`);
    await expect(page.getByTestId('pa-board')).toHaveCount(0);

    await game(`G.phase = 'menu'; G.notifyUI();`);
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
  });

  test('Tab stays Evidence, and B does not fire behind the album, the route lines, the camera, or a text field', async ({ page, game }) => {
    await game(`G.Q = []; ride(0);`);
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toBeVisible();

    await page.keyboard.press('Tab');
    const evidence = page.getByRole('dialog', { name: 'Evidence Log' });
    await expect(evidence).toBeVisible();
    await expect(page.getByTestId('pa-board')).toBeVisible();
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toBeVisible();
    await expect(evidence).toBeVisible();
    await page.keyboard.press('Tab');
    await expect(evidence).toHaveCount(0);

    await page.keyboard.press('KeyL');
    const lines = page.getByRole('dialog', { name: 'MTA Transit Line Switching' });
    await expect(lines).toBeVisible();
    await page.keyboard.press('KeyB');
    await expect(lines).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(lines).toHaveCount(0);
    await expect(page.getByTestId('pa-board')).toBeVisible();
    expect(await game(`return G.paused;`)).toBe(false);

    await game(`G.toggleCamera(); G.notifyUI();`);
    await page.keyboard.press('KeyB'); // closes; it was already open
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await page.keyboard.press('KeyB'); // camera still up: don't open over it
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await game(`G.toggleCamera(); G.notifyUI();`);

    await page.evaluate(() => {
      const input = document.createElement('input');
      input.id = 'pa-board-type-test';
      document.body.appendChild(input);
      input.focus();
    });
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toHaveCount(0);
    await page.evaluate(() => document.getElementById('pa-board-type-test')?.remove());
    await page.keyboard.press('KeyB');
    await expect(page.getByTestId('pa-board')).toBeVisible();
  });
});

test.describe('PA board on a phone', () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

  test('the panel clears the walk stick, the FLAG button and the tool row', async ({ page, game }) => {
    await game(`G.isTouch = true; window.__EVP.hasRecorder = true; G.Q = []; G.startSegment(4); G.notifyUI();`);
    await page.getByTestId('pa-board-toggle').tap();
    const board = page.getByTestId('pa-board');
    await expect(board).toBeVisible();
    await expect(page.getByTestId('pa-board-flag')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Close PA board' })).toBeVisible();

    const overlap = (a: { x: number; y: number; width: number; height: number }, b: typeof a) =>
      a.x < b.x + b.width - 1 && b.x < a.x + a.width - 1 && a.y < b.y + b.height - 1 && b.y < a.y + a.height - 1;

    const boardBox = (await board.boundingBox())!;
    const stick = (await page.getByTestId('move-stick').boundingBox())!;
    // The HUD FLAG button is the round one. The panel has another control with the same name.
    const hudFlag = await page.locator('button[aria-label="Flag: hold to catch"]').evaluateAll((els) => {
      const el = els.find((e) => !e.closest('[data-testid="pa-board"]')) as HTMLElement | undefined;
      if (!el) return null;
      const r = el.getBoundingClientRect();
      return { x: r.x, y: r.y, width: r.width, height: r.height };
    });
    expect(overlap(boardBox, stick), 'walk stick stays clear of the panel').toBe(false);
    expect(hudFlag, 'HUD flag button').not.toBeNull();
    expect(overlap(boardBox, hudFlag!), 'HUD flag stays clear of the panel').toBe(false);

    const pause = (await page.getByRole('button', { name: 'Pause' }).boundingBox())!;
    expect(overlap(boardBox, pause), 'pause stays clear of the panel').toBe(false);

    const vp = page.viewportSize()!;
    const flagBox = (await page.getByTestId('pa-board-flag').boundingBox())!;
    expect(flagBox.y).toBeGreaterThanOrEqual(0);
    expect(flagBox.y + flagBox.height).toBeLessThanOrEqual(vp.height + 0.5);
    expect(flagBox.x).toBeGreaterThanOrEqual(0);
    expect(flagBox.x + flagBox.width).toBeLessThanOrEqual(vp.width + 0.5);
    const close = (await page.getByRole('button', { name: 'Close PA board' }).boundingBox())!;
    expect(Math.min(close.width, close.height)).toBeGreaterThanOrEqual(44);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  });
});
