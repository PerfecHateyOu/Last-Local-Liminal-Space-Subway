import { test, expect } from './game';
import { SKIP_TUTORIAL } from './game';

// Collect every distinct 672x74 LED CanvasTexture across Cars A, B, and C.
const COLLECT_LED_TEXTURES = `(() => {
  const seen = new Set();
  for (const grp of [G.carBuilder.carGroup, G.carBuilder.carAGroup, G.carBuilder.carCGroup]) {
    grp.traverse((o) => {
      if (!o.isMesh) return;
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      for (const m of mats) {
        const map = m && m.map;
        if (map && map.image && map.image.width === 672 && map.image.height === 74) {
          seen.add(map);
        }
      }
    });
  }
  return [...seen];
})()`;

test.describe('In-car LED e-signs', () => {
  test('shows boarding station on intro, NEXT while riding, and station name at arrival', async ({ game }) => {
    const boarding = await game(`return G.carBuilder.ledSignText;`);
    expect(boarding).toBe('G  HOYT–SCHERMERHORN');

    const riding = await game(`ride(0); return G.carBuilder.ledSignText;`);
    expect(riding).toBe('G  NEXT: FULTON ST');

    const stopped = await game(`G.Q = []; G.arrive(); return G.carBuilder.ledSignText;`);
    expect(stopped).toBe('G  FULTON ST');
  });

  test('repaints all three cars textures together with identical pixels that change with text', async ({ game }) => {
    const res = await game(`
      const texes = ${COLLECT_LED_TEXTURES};
      const beforeUrls = texes.map((t) => t.image.toDataURL());
      ride(0);
      const rideUrls = texes.map((t) => t.image.toDataURL());
      G.Q = []; G.arrive();
      const stopUrls = texes.map((t) => t.image.toDataURL());
      return {
        count: texes.length,
        beforeUnique: new Set(beforeUrls).size,
        rideUnique: new Set(rideUrls).size,
        stopUnique: new Set(stopUrls).size,
        changedBoardToRide: beforeUrls[0] !== rideUrls[0],
        changedRideToStop: rideUrls[0] !== stopUrls[0],
      };
    `);
    expect(res).toEqual({
      count: 3,
      beforeUnique: 1,
      rideUnique: 1,
      stopUnique: 1,
      changedBoardToRide: true,
      changedRideToStop: true,
    });
  });

  test('line switch renames the sign together with the HUD', async ({ page, game }) => {
    await game(`ride(6);`);
    expect(await game(`return G.carBuilder.ledSignText;`)).toBe('G  NEXT: FLUSHING AV');

    await game(`window.__RT.setRoute('L');`);
    expect(await game(`return G.carBuilder.ledSignText;`)).toBe('L  NEXT: LORIMER ST');
    await expect(page.getByTestId('hud-route-panel')).toContainText('Lorimer St');

    await game(`window.__RT.setRoute('7');`);
    expect(await game(`return G.carBuilder.ledSignText;`)).toBe('7  NEXT: VERNON–JACKSON VOID');
    await expect(page.getByTestId('hud-route-panel')).toContainText('Vernon–Jackson Void');
  });

  test('False Stop Trial keeps the presented stop and never leaks false stop status', async ({ game }) => {
    const res = await game(`
      ride(8); // Stop 9: Metropolitan Av (False Stop)
      const riding = G.carBuilder.ledSignText;
      G.Q = []; G.arrive();
      const atStop = G.carBuilder.ledSignText;
      G.Q = []; G.startTrial();
      const inTrial = G.carBuilder.ledSignText;
      return { riding, atStop, inTrial };
    `);
    expect(res).toEqual({
      riding: 'G  NEXT: METROPOLITAN AV',
      atStop: 'G  METROPOLITAN AV',
      inTrial: 'G  METROPOLITAN AV',
    });
  });

  test('final stretch shows NEXT: COURT SQ and ends on G  COURT SQ at arrival', async ({ game }) => {
    const res = await game(`
      ride(12); // Stop 13: Court Sq (final)
      const riding = G.carBuilder.ledSignText;
      G.Q = []; G.arrive();
      const atArrival = G.carBuilder.ledSignText;
      return { riding, atArrival };
    `);
    expect(res).toEqual({
      riding: 'G  NEXT: COURT SQ',
      atArrival: 'G  COURT SQ',
    });
  });

  test.describe('mobile 390x844', () => {
    test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

    test('long station names update cleanly on mobile viewport', async ({ page }) => {
      await page.addInitScript(SKIP_TUTORIAL);
      await page.goto('/');
      await page.evaluate(() => {
        localStorage.clear();
        localStorage.setItem('gtrain-settings', JSON.stringify({ fullscreenOnBoard: false }));
      });
      await page.reload();
      await page.getByRole('button', { name: 'Board the Train' }).click();
      await page.waitForFunction(() => (window as any).__G?.phase !== 'menu');

      const res = await page.evaluate(() => {
        const G = (window as any).__G;
        const boarding = G.carBuilder.ledSignText;
        G.Q = [];
        G.startSegment(1); // Stop 3: Clinton–Washington Avs
        const riding = G.carBuilder.ledSignText;
        G.Q = [];
        G.arrive();
        const atStop = G.carBuilder.ledSignText;
        return { boarding, riding, atStop };
      });
      expect(res).toEqual({
        boarding: 'G  HOYT–SCHERMERHORN',
        riding: 'G  NEXT: CLINTON–WASHINGTON AVS',
        atStop: 'G  CLINTON–WASHINGTON AVS',
      });
    });
  });
});
