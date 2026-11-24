import { test, expect } from './game';
import { SKIP_TUTORIAL } from './game';

test.describe('Cutscenes', () => {
  test('intro plays on boarding and freezes GT, sanity, and suspicion while real time passes', async ({ page, game }) => {
    const before = await game(`return { phase: G.phase, active: G.cutsceneActive, gt: G.GT, san: G.san, sus: G.sus };`);
    expect(before).toMatchObject({ phase: 'intro', active: true, gt: 0, san: 100, sus: 0 });
    await expect(page.getByTestId('cutscene-overlay')).toBeVisible();

    await page.waitForTimeout(450);
    const after = await game(`return { active: G.cutsceneActive, gt: G.GT, san: G.san, sus: G.sus };`);
    expect(after).toEqual({ active: true, gt: 0, san: 100, sus: 0 });
  });

  test('skipping intro by button closes the doors and departs to stretch 0', async ({ page, game }) => {
    await page.getByTestId('cutscene-skip').click();
    const state = await game(`return { active: G.cutsceneActive, phase: G.phase, segIdx: G.segIdx, doorTarget: G.doorTarget };`);
    expect(state).toEqual({ active: false, phase: 'ride', segIdx: 0, doorTarget: 0 });
    await expect(page.getByTestId('cutscene-overlay')).toHaveCount(0);
  });

  test('skipping intro by Space closes the doors and departs to stretch 0', async ({ page, game }) => {
    await page.keyboard.press('Space');
    const state = await game(`return { active: G.cutsceneActive, phase: G.phase, segIdx: G.segIdx, doorTarget: G.doorTarget };`);
    expect(state).toEqual({ active: false, phase: 'ride', segIdx: 0, doorTarget: 0 });
    await expect(page.getByTestId('cutscene-overlay')).toHaveCount(0);
  });

  test('watching the intro through reaches stretch 0 with the PA on the board', async ({ game }) => {
    const res = await game(`advance(9.3); return { active: G.cutsceneActive, phase: G.phase, segIdx: G.segIdx, feed: G.paFeed.map((e) => e.text) };`);
    expect(res.active).toBe(false);
    expect(res.phase).toBe('ride');
    expect(res.segIdx).toBe(0);
    expect(res.feed.some((t: string) => t.includes('Last Local'))).toBe(true);
    expect(res.feed.some((t: string) => t.includes('Stand clear of the closing doors'))).toBe(true);
  });

  test('haven hands over the recorder watched or skipped with values unmoved during the scene', async ({ game }) => {
    const watched = await game(`const E = window.__EVP; ride(4); G.executeSafeHaven();
      const gt0 = G.GT, san0 = G.san, sus0 = G.sus;
      advance(2);
      const mid = { active: G.cutsceneActive, gt: G.GT, san: G.san, sus: G.sus, has: E.hasRecorder };
      advance(9);
      return { gt0, san0, sus0, mid, endHas: E.hasRecorder, endActive: G.cutsceneActive };`);
    expect(watched.mid).toEqual({ active: true, gt: watched.gt0, san: watched.san0, sus: watched.sus0, has: false });
    expect(watched.endHas).toBe(true);
    expect(watched.endActive).toBe(false);

    const skipped = await game(`const E = window.__EVP; G.newGame(); ride(4); G.executeSafeHaven();
      G.skipCutscene();
      return { has: E.hasRecorder, active: G.cutsceneActive };`);
    expect(skipped).toEqual({ has: true, active: false });
  });

  test('trial scene opens the False Stop and the first round starts only on its end', async ({ game }) => {
    const res = await game(`ride(3); G.Q = []; G.startTrial();
      const during = { phase: G.phase, active: G.cutsceneActive, choice: !!G.choice };
      advance(5.1);
      const after = { phase: G.phase, active: G.cutsceneActive, choice: !!G.choice };
      return { during, after };`);
    expect(res.during).toEqual({ phase: 'trial', active: true, choice: false });
    expect(res.after).toEqual({ phase: 'trial', active: false, choice: true });
  });

  test('arrival scene ends with the three-way Court Square exit choice, or opens at once on skip', async ({ game }) => {
    const watched = await game(`ride(12); G.Q = []; G.arrive();
      const during = { active: G.cutsceneActive, choice: !!G.choice, resolved: G.resolvedEnding };
      advance(7.0);
      const after = { active: G.cutsceneActive, items: G.choice?.items.map((i) => i.val), resolved: G.resolvedEnding };
      return { during, after };`);
    expect(watched.during).toEqual({ active: true, choice: false, resolved: null });
    expect(watched.after).toEqual({ active: false, items: ['escalators', 'lower_level', 'surface_hatch'], resolved: null });

    const skipped = await game(`ride(12); G.Q = []; G.arrive(); G.skipCutscene();
      return { active: G.cutsceneActive, items: G.choice?.items.map((i) => i.val), resolved: G.resolvedEnding };`);
    expect(skipped).toEqual({ active: false, items: ['escalators', 'lower_level', 'surface_hatch'], resolved: null });
  });

  test.describe('mobile 390x844 with touch', () => {
    test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

    test('overlay and Skip button fit and tap skips to the ride', async ({ page }) => {
      await page.addInitScript(SKIP_TUTORIAL);
      await page.goto('/');
      await page.evaluate(() => {
        localStorage.clear();
        localStorage.setItem('gtrain-settings', JSON.stringify({ fullscreenOnBoard: false }));
      });
      await page.reload();
      await page.getByRole('button', { name: 'Board the Train' }).click();
      await page.waitForFunction(() => (window as any).__G?.phase !== 'menu');

      const skipBtn = page.getByTestId('cutscene-skip');
      await expect(skipBtn).toBeVisible();
      const box = await skipBtn.boundingBox();
      expect(box).not.toBeNull();
      expect(box!.width).toBeGreaterThanOrEqual(44);
      expect(box!.height).toBeGreaterThanOrEqual(44);
      expect(box!.x + box!.width).toBeLessThanOrEqual(390);
      expect(box!.y + box!.height).toBeLessThanOrEqual(844);

      await skipBtn.tap();
      const phase = await page.evaluate(() => (window as any).__G.phase);
      expect(phase).toBe('ride');
      await expect(page.getByTestId('cutscene-overlay')).toHaveCount(0);
    });
  });
});
