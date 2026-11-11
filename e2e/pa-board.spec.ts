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

  test('the announcement toast stacks above the open panel and does not take clicks', async ({ page, game }) => {
    await game(`G.isTouch = true; G.Q = []; G.paFeed = []; G.paSeq = 0; ride(0); G.chapterRollsign = null; G.notifyUI();`);
    await page.getByTestId('pa-board-toggle').tap();
    await expect(page.getByTestId('pa-board')).toBeVisible();
    await game(`G.setPA('Stand clear of the closing doors, please.', 30); G.chapterRollsign = null; G.notifyUI();`);
    const toast = page.getByTestId('pa-toast');
    await expect(toast).toBeVisible();
    await expect(toast).toContainText('Stand clear of the closing doors, please.');

    const stacked = await page.evaluate(() => {
      const t = document.querySelector('[data-testid="pa-toast"]') as HTMLElement;
      const panel = document.querySelector('[data-testid="pa-board"]') as HTMLElement;
      const inner = t.firstElementChild as HTMLElement;
      const tcs = getComputedStyle(t);
      const pcs = getComputedStyle(panel);
      const r = t.getBoundingClientRect();
      const pause = document.querySelector('button[aria-label="Pause"]') as HTMLElement;
      const close = document.querySelector('button[aria-label="Close PA board"]') as HTMLElement;
      const flag = document.querySelector('button[aria-label="Flag: hold to catch"]') as HTMLElement;
      const hit = (el: HTMLElement) => {
        const b = el.getBoundingClientRect();
        const top = document.elementFromPoint(b.x + b.width / 2, b.y + b.height / 2) as HTMLElement | null;
        return top && (top === el || el.contains(top));
      };
      // Clicks pass through the toast (pointer-events none). Enabling them is only for the paint check.
      const clicksPass =
        getComputedStyle(t).pointerEvents === 'none' && hit(pause) && hit(close) && hit(flag);
      t.style.pointerEvents = 'auto';
      const mid = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) as HTMLElement | null;
      const onTop = !!mid && (mid === t || t.contains(mid));
      return {
        position: tcs.position,
        toastZ: tcs.zIndex,
        panelZ: pcs.zIndex,
        onTop,
        clicksPass,
        anim: getComputedStyle(inner).animationName,
      };
    });
    expect(stacked.position).toBe('absolute');
    expect(Number(stacked.toastZ)).toBeGreaterThan(Number(stacked.panelZ));
    expect(stacked.onTop).toBe(true);
    expect(stacked.clicksPass).toBe(true);
    expect(stacked.anim).toContain('transitSignFlicker');
  });
});

/** The name span is fully inside the panel and its own text is not clipped. */
async function expectNameInside(page: import('@playwright/test').Page, testId: string, text: string) {
  const el = page.getByTestId(testId);
  await expect(el).toHaveText(text);
  const fit = await el.evaluate((node) => {
    const n = node as HTMLElement;
    const panel = document.querySelector('[data-testid="pa-board"]') as HTMLElement;
    const t = n.getBoundingClientRect();
    const p = panel.getBoundingClientRect();
    const cs = getComputedStyle(n);
    return {
      inside:
        t.x >= p.x - 0.5 &&
        t.x + t.width <= p.x + p.width + 0.5 &&
        t.y >= p.y - 0.5 &&
        t.y + t.height <= p.y + p.height + 0.5,
      clipped: n.scrollWidth > n.clientWidth + 1 || n.scrollHeight > n.clientHeight + 1,
      overflow: cs.overflow,
      textOverflow: cs.textOverflow,
    };
  });
  expect(fit.inside, `${testId} box inside the panel`).toBe(true);
  expect(fit.clipped, `${testId} text clipped`).toBe(false);
  expect(fit.textOverflow).not.toBe('ellipsis');
}

const PHONE_WIDTHS = [320, 360, 390] as const;

for (const width of PHONE_WIDTHS) {
  test.describe(`PA board route header at ${width}px`, () => {
    test.use({ viewport: { width, height: 700 }, hasTouch: true, isMobile: true });

    test('G, L and 7 origin and terminus stay fully readable', async ({ page, game }) => {
      await game(`G.isTouch = true; G.Q = []; ride(0); G.chapterRollsign = null; G.notifyUI();`);
      await page.getByTestId('pa-board-toggle').tap();
      const lines = [
        { id: 'G', origin: 'Hoyt–Schermerhorn', terminus: 'Court Sq' },
        { id: 'L', origin: '8th Av', terminus: 'Myrtle–Wyckoff Avs' },
        { id: '7', origin: 'Times Sq–42nd St', terminus: 'Terminal Echo' },
      ] as const;
      for (const line of lines) {
        await game(`window.__RT.setRoute('${line.id}'); G.chapterRollsign = null; G.notifyUI();`);
        await expectNameInside(page, 'pa-board-origin', line.origin);
        await expectNameInside(page, 'pa-board-terminus', line.terminus);
      }
    });
  });
}

test.describe('PA board route header with a wider font', () => {
  test.use({ viewport: { width: 320, height: 700 }, hasTouch: true, isMobile: true });

  test('a larger type size still shows the full L terminus', async ({ page, game }) => {
    await game(`G.isTouch = true; G.Q = []; ride(0); G.chapterRollsign = null; G.notifyUI();`);
    await page.getByTestId('pa-board-toggle').tap();
    await page.evaluate(() => {
      document.documentElement.style.setProperty('--text-3xs', '18px');
      const header = document.querySelector('[data-testid="pa-board-route-header"]') as HTMLElement;
      header.style.letterSpacing = '0.14em';
    });
    await game(`window.__RT.setRoute('L'); G.notifyUI();`);
    await expectNameInside(page, 'pa-board-origin', '8th Av');
    await expectNameInside(page, 'pa-board-terminus', 'Myrtle–Wyckoff Avs');
    await game(`window.__RT.setRoute('G'); G.notifyUI();`);
    await expectNameInside(page, 'pa-board-origin', 'Hoyt–Schermerhorn');
    await expectNameInside(page, 'pa-board-terminus', 'Court Sq');
  });
});

test.describe('PA toast geometry and flicker', () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

  test('with the flicker finished, the toast stays centered and opaque', async ({ page, game }) => {
    await game(`G.Q = []; ride(0); G.setPA('Stand clear of the closing doors, please.', 30); G.chapterRollsign = null; G.notifyUI();`);
    await expect(page.getByTestId('pa-toast')).toBeVisible();
    const done = await page.evaluate(async () => {
      const t = document.querySelector('[data-testid="pa-toast"]') as HTMLElement;
      const inner = t.firstElementChild as HTMLElement;
      await Promise.all(inner.getAnimations().map((a) => a.finished.catch(() => undefined)));
      for (const a of inner.getAnimations()) a.finish();
      const cs = getComputedStyle(t);
      const ics = getComputedStyle(inner);
      const r = t.getBoundingClientRect();
      return {
        // Tailwind v4 centers with the `translate` property, not `transform`, so the
        // flicker's transform: scale() on the inner box cannot un-center the toast.
        outerTranslate: cs.translate,
        outerTransform: cs.transform,
        innerTransform: ics.transform,
        innerOpacity: Number(ics.opacity),
        centerDelta: Math.abs(r.x + r.width / 2 - window.innerWidth / 2),
        anim: ics.animationName,
      };
    });
    expect(done.anim).toContain('transitSignFlicker');
    expect(done.innerOpacity).toBeGreaterThan(0.95);
    expect(done.centerDelta).toBeLessThan(8);
    expect(done.outerTranslate).toMatch(/-50%/);
    expect(done.outerTransform).toBe('none');
  });

  test('with screen effects reduced, the toast is still centered above the panel', async ({ page, game }) => {
    await page.evaluate(() => document.documentElement.setAttribute('data-effects', 'reduced'));
    await game(`G.Q = []; ride(0); G.notifyUI();`);
    await page.keyboard.press('KeyB');
    await game(`G.setPA('The next stop is Fulton St.', 30); G.notifyUI();`);
    await expect(page.getByTestId('pa-toast')).toBeVisible();
    const geom = await page.evaluate(async () => {
      const t = document.querySelector('[data-testid="pa-toast"]') as HTMLElement;
      const inner = t.firstElementChild as HTMLElement;
      const panel = document.querySelector('[data-testid="pa-board"]') as HTMLElement;
      for (const a of inner.getAnimations()) a.finish();
      const r = t.getBoundingClientRect();
      const tcs = getComputedStyle(t);
      const ics = getComputedStyle(inner);
      t.style.pointerEvents = 'auto';
      const mid = document.elementFromPoint(r.x + r.width / 2, r.y + Math.min(r.height, 12) / 2) as HTMLElement | null;
      return {
        position: tcs.position,
        above: Number(tcs.zIndex) > Number(getComputedStyle(panel).zIndex),
        centerDelta: Math.abs(r.x + r.width / 2 - window.innerWidth / 2),
        opacity: Number(ics.opacity),
        onTop: !!mid && (mid === t || t.contains(mid)),
        anim: ics.animationName,
      };
    });
    expect(geom.position).toBe('absolute');
    expect(geom.above).toBe(true);
    expect(geom.centerDelta).toBeLessThan(8);
    expect(geom.opacity).toBeGreaterThan(0.95);
    expect(geom.onTop).toBe(true);
    expect(geom.anim).toContain('simpleFadeIn');
  });
});

/** Real announcements, including the longest signed next-stop and the longest filled line. */
const TOAST_LINES = [
  'This is Court Square. Last stop. Everybody off the train.',
  'This is the Last Local. Myrtle–Wyckoff–bound L train.',
  'Myrtle–Wyckoff. This is the last stop on this train.',
  'The next stop is Abandoned Steinway Platform.',
  'The next stop is Sub-River Tube Level -4.',
  'Stand clear of the closing doors, please.',
] as const;

async function finishToast(page: import('@playwright/test').Page) {
  await page.evaluate(() => {
    const inner = document.querySelector('[data-testid="pa-toast"]')?.firstElementChild as HTMLElement | null;
    for (const a of inner?.getAnimations() ?? []) a.finish();
  });
}

/** Layout boxes after the flicker is finished, so geometry is not the first animation frame. */
async function toastVsHeader(page: import('@playwright/test').Page) {
  await finishToast(page);
  return page.evaluate(() => {
    const rect = (el: Element | null) => {
      if (!el) return null;
      const b = el.getBoundingClientRect();
      return { x: b.x, y: b.y, width: b.width, height: b.height, bottom: b.bottom, right: b.right };
    };
    const panel = document.querySelector('[data-testid="pa-board"]') as HTMLElement;
    const header = panel.querySelector('header') as HTMLElement;
    const toast = document.querySelector('[data-testid="pa-toast"]') as HTMLElement;
    const body = document.querySelector('[data-testid="pa-board-body"]') as HTMLElement;
    const overlap = (a: { x: number; y: number; right: number; bottom: number }, b: typeof a) =>
      a.x < b.right - 0.5 && b.x < a.right - 0.5 && a.y < b.bottom - 0.5 && b.y < a.bottom - 0.5;
    const t = rect(toast)!;
    const h = rect(header)!;
    const pause = document.querySelector('button[aria-label="Pause"]') as HTMLElement;
    const close = document.querySelector('button[aria-label="Close PA board"]') as HTMLElement;
    const flag = document.querySelector('[data-testid="pa-board-flag"]') as HTMLElement;
    const hit = (el: HTMLElement) => {
      const b = el.getBoundingClientRect();
      if (b.width < 8 || b.height < 8) return false;
      const top = document.elementFromPoint(b.x + b.width / 2, b.y + Math.min(b.height / 2, b.height - 2)) as HTMLElement | null;
      return !!top && (top === el || el.contains(top));
    };
    return {
      toast: t,
      header: h,
      panel: rect(panel),
      bodyH: body.clientHeight,
      scrollW: body.scrollWidth,
      clientW: body.clientWidth,
      scrollH: body.scrollHeight,
        overHeader: t && h ? overlap(t, h) : true,
        panelTop: panel.style.top,
        toastOffset: toast ? toast.offsetTop + toast.offsetHeight : -1,
      toastZ: Number(getComputedStyle(toast).zIndex),
      panelZ: Number(getComputedStyle(panel).zIndex),
      hits: { pause: hit(pause), close: hit(close), flag: hit(flag) },
    };
  });
}

const PHONE_TOAST = [
  [320, 568],
  [360, 640],
  [390, 844],
] as const;

for (const [width, height] of PHONE_TOAST) {
  test.describe(`toast clears the header at ${width}×${height}`, () => {
    test.use({ viewport: { width, height }, hasTouch: true, isMobile: true });

    test('every real announcement sits above the header, and the panel stays usable', async ({ page, game }) => {
      await game(`G.isTouch = true; G.Q = []; ride(0); G.chapterRollsign = null; G.notifyUI();`);
      await page.getByTestId('pa-board-toggle').tap();
      await expect(page.getByTestId('pa-board')).toBeVisible();
      for (const line of TOAST_LINES) {
        await game(`G.setPA(${JSON.stringify(line)}, 30); G.chapterRollsign = null; G.notifyUI();`);
        await expect(page.getByTestId('pa-toast')).toContainText(line.slice(0, 18));
        const g = await toastVsHeader(page);
        expect(g.overHeader, `${line} ${JSON.stringify({ toast: g.toast, header: g.header, bodyH: g.bodyH, panelTop: g.panelTop, toastOffset: g.toastOffset })}`).toBe(false);
        expect(g.toast.bottom).toBeLessThanOrEqual(g.header.y + 1);
        expect(g.toastZ).toBeGreaterThan(g.panelZ);
        expect(g.bodyH, line).toBeGreaterThanOrEqual(36);
        expect(g.scrollW, line).toBeLessThanOrEqual(g.clientW + 1);
        expect(g.hits.pause, line).toBe(true);
        expect(g.hits.close, line).toBe(true);
        expect(g.hits.flag, line).toBe(true);
        const vp = page.viewportSize()!;
        expect(g.panel!.y).toBeGreaterThanOrEqual(0);
        expect(g.panel!.bottom).toBeLessThanOrEqual(vp.height + 0.5);
        expect(g.panel!.height).toBeGreaterThan(120);
      }
    });
  });
}

test.describe('320×568 with a wider font and the longest toast', () => {
  test.use({ viewport: { width: 320, height: 568 }, hasTouch: true, isMobile: true });

  test('the header stays clear and the flags note can be scrolled to', async ({ page, game }) => {
    await game(`G.isTouch = true; G.Q = []; ride(0); window.__RT.setRoute('L'); G.chapterRollsign = null; G.notifyUI();`);
    await page.getByTestId('pa-board-toggle').tap();
    await page.evaluate(() => {
      document.documentElement.style.setProperty('--text-3xs', '18px');
      const header = document.querySelector('[data-testid="pa-board-route-header"]') as HTMLElement;
      header.style.letterSpacing = '0.14em';
    });
    await game(`G.setPA('The next stop is Abandoned Steinway Platform.', 30); G.notifyUI();`);
    await expect(page.getByTestId('pa-toast')).toBeVisible();
    const g = await toastVsHeader(page);
    expect(g.overHeader, JSON.stringify({ toast: g.toast, header: g.header, bodyH: g.bodyH, panelTop: g.panelTop, toastOffset: g.toastOffset })).toBe(false);
    expect(g.toast.bottom).toBeLessThanOrEqual(g.header.y + 1);
    expect(g.bodyH).toBeGreaterThanOrEqual(16);
    expect(g.hits.close).toBe(true);
    expect(g.hits.pause).toBe(true);
    expect(g.hits.flag).toBe(true);
    expect(g.scrollW).toBeLessThanOrEqual(g.clientW + 1);
    await expectNameInside(page, 'pa-board-origin', '8th Av');
    await expectNameInside(page, 'pa-board-terminus', 'Myrtle–Wyckoff Avs');
    await page.evaluate(() => {
      const m = document.querySelector('[data-testid="pa-board-body"]') as HTMLElement;
      m.scrollTop = m.scrollHeight;
    });
    const seen = await page.evaluate(() => {
      const m = document.querySelector('[data-testid="pa-board-body"]') as HTMLElement;
      const note = document.querySelector('[data-testid="pa-board-flags-note"]') as HTMLElement;
      const mb = m.getBoundingClientRect();
      const nb = note.getBoundingClientRect();
      return {
        atEnd: m.scrollTop + m.clientHeight >= m.scrollHeight - 1,
        noteEnd: nb.bottom,
        bodyEnd: mb.bottom,
        noteStart: nb.top,
      };
    });
    expect(seen.atEnd).toBe(true);
    expect(seen.noteEnd).toBeLessThanOrEqual(seen.bodyEnd + 1);
    expect(seen.noteStart).toBeLessThan(seen.bodyEnd);
    await expect(page.getByTestId('pa-board-flags-note')).toContainText('A flag never says whether you were right');
  });
});

test.describe('toast dismissal restores the panel and does not drop a held flag', () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

  test('clearing the toast lifts the panel and leaves the hold down', async ({ page, game }) => {
    await game(`G.isTouch = true; G.Q = []; ride(0); G.chapterRollsign = null; G.notifyUI();`);
    await page.getByTestId('pa-board-toggle').tap();
    const before = await page.getByTestId('pa-board').evaluate((el) => el.getBoundingClientRect().y);
    await page.getByTestId('pa-board-flag').dispatchEvent('pointerdown', { pointerId: 1, bubbles: true, pointerType: 'touch', button: 0 });
    expect(await game(`return G.flagHeld;`)).toBe(true);
    await game(`G.setPA('This is Court Square. Last stop. Everybody off the train.', 30); G.notifyUI();`);
    await finishToast(page);
    const dipped = await page.getByTestId('pa-board').evaluate((el) => el.getBoundingClientRect().y);
    expect(dipped).toBeGreaterThan(before + 8);
    expect(await game(`return G.flagHeld;`)).toBe(true);
    await game(`G.paText = ''; G.paUntil = 0; G.notifyUI();`);
    await expect(page.getByTestId('pa-toast')).toHaveCount(0);
    const after = await page.getByTestId('pa-board').evaluate((el) => el.getBoundingClientRect().y);
    expect(Math.abs(after - before)).toBeLessThan(2);
    expect(await game(`return G.flagHeld;`)).toBe(true);
    await page.getByTestId('pa-board-flag').dispatchEvent('pointerup', { pointerId: 1, bubbles: true, pointerType: 'touch' });
  });
});

test.describe('desktop panel does not dip for a toast', () => {
  test.use({ viewport: { width: 1280, height: 720 } });

  test('the panel top stays under the HUD bar', async ({ page, game }) => {
    await game(`G.Q = []; ride(0); G.chapterRollsign = null; G.notifyUI();`);
    await page.keyboard.press('KeyB');
    const open = await page.getByTestId('pa-board').evaluate((el) => el.getBoundingClientRect().y);
    await game(`G.setPA('This is Court Square. Last stop. Everybody off the train.', 30); G.notifyUI();`);
    await finishToast(page);
    const withToast = await page.getByTestId('pa-board').evaluate((el) => {
      const y = el.getBoundingClientRect().y;
      const hud = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--hud-h')) || 0;
      return { y, hud };
    });
    expect(Math.abs(withToast.y - open)).toBeLessThan(2);
    expect(Math.abs(withToast.y - (withToast.hud + 8))).toBeLessThan(3);
  });
});
