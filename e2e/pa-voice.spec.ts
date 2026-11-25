import { test, expect } from './game';

const AUDIO_PROBE = `if (!window.__paPeakRms) {
  const an = A.ac.createAnalyser();
  an.fftSize = 2048;
  A.outGain.connect(an);
  window.__paPeakRms = async (ms) => {
    let m = 0;
    const t0 = performance.now();
    while (performance.now() - t0 < ms) {
      const d = new Float32Array(an.fftSize);
      an.getFloatTimeDomainData(d);
      let s = 0;
      for (const v of d) s += v * v;
      m = Math.max(m, Math.sqrt(s / d.length));
      await sleep(30);
    }
    return m;
  };
}`;

test.describe('PA voice announcements', () => {
  test('a spoken PA line is measurably audible over the speakers', async ({ game }) => {
    const r = await game(`${AUDIO_PROBE}
      ride(0);
      A.setBedLevel(0.0001, 0.05);
      A.getRideMusic()?.setPaused(true);
      await sleep(200);
      G.setPA('The next stop is Fulton St.', 4.5);
      const rms = await window.__paPeakRms(1800);
      const last = A.getPaVoice()?.last;
      return { rms, last };`);
    expect(r.rms).toBeGreaterThan(0.005);
    expect(r.last?.text).toBe('The next stop is Fulton St.');
    expect(r.last?.chime).toBe(true);
  });

  test('the next-stop PA speaks "The next stop is Fulton St." on segment 0', async ({ game }) => {
    const r = await game(`
      ride(0);
      A.stopPaVoice();
      if (A.getPaVoice()) A.getPaVoice().last = null;
      G.conductorAt = null;
      advance(7.2);
      const last = A.getPaVoice()?.last;
      return { paText: G.paText, spokenText: last?.text ?? null, chime: last?.chime ?? null };`);
    expect(r.paText).toBe('The next stop is Fulton St.');
    expect(r.spokenText).toBe('The next stop is Fulton St.');
    expect(r.chime).toBe(true);
  });

  test('garbled conductor broadcasts stay unspoken by PaVoice', async ({ game }) => {
    const r = await game(`
      ride(1);
      G.Q = [];
      G.paText = '';
      G.paUntil = 0;
      G.subHtml = '';
      G.intercomUntil = 0;
      A.stopPaVoice();
      if (A.getPaVoice()) A.getPaVoice().last = null;
      G.conductorFree = [[0, 999]];
      G.conductorAt = G.ts + 0.1;
      advance(0.2);
      return { paText: G.paText, spoken: A.getPaVoice()?.last ?? null };`);
    expect(r.paText).toMatch(/stand clear|next stop|dispatcher/);
    expect(r.spoken).toBeNull();
  });

  test('pausing stops the PA voice mid-line and does not resume it', async ({ game }) => {
    const r = await game(`
      ride(0);
      G.setPA('The next stop is Clinton–Washington Avs.', 4.5);
      await sleep(150);
      const beforePause = A.getPaVoice()?.speaking ?? false;
      key('KeyP');
      await sleep(150);
      const whilePaused = A.getPaVoice()?.speaking ?? false;
      key('KeyP');
      await sleep(150);
      const afterResume = A.getPaVoice()?.speaking ?? false;
      return { beforePause, whilePaused, afterResume };`);
    expect(r.beforePause).toBe(true);
    expect(r.whilePaused).toBe(false);
    expect(r.afterResume).toBe(false);
  });
});
