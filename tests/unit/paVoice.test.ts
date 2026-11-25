import { describe, test, expect } from 'bun:test';
import {
  announcementDurationSeconds,
  announcementPhonemes,
  makeAnnouncement,
  unpronouncedWords,
} from '../../src/audio/paVoice';
import { ROUTES } from '../../src/game/routeManager';
import { fillRoute, routeText } from '../../src/game/routeText';
import { SEGS } from '../../src/constants';

describe('paVoice', () => {
  test('every word in every spoken PA line across G, L, and 7 routes has a pronunciation entry', () => {
    const lines: string[] = [
      'Stand clear of the closing doors, please.',
      ...SEGS.filter((s) => s.paLie).map((s) => s.paLie!),
    ];

    for (const routeId of ['G', 'L', '7'] as const) {
      const route = ROUTES[routeId];
      for (const stop of route.stops.slice(1)) {
        lines.push(`The next stop is ${stop}.`);
        lines.push(`This is ${stop}.`);
      }
      lines.push(fillRoute('{terminus}. This is the last stop on this train.', routeText(route)));
    }

    const missing: Array<{ line: string; words: string[] }> = [];
    for (const line of lines) {
      const unknown = unpronouncedWords(line);
      if (unknown.length > 0) missing.push({ line, words: unknown });
    }

    expect(missing).toEqual([]);
  });

  test('converts lines into phoneme sequences with word boundaries and punctuation pauses', () => {
    const phones = announcementPhonemes('The next stop is Fulton St.');
    expect(phones.length).toBeGreaterThan(10);
    expect(phones).toContain('_');
    expect(phones[phones.length - 1]).toBe('|');
    expect(unpronouncedWords('The next stop is Fulton St.')).toEqual([]);
  });

  test('estimates positive durations that scale with phrase length', () => {
    const shortDur = announcementDurationSeconds('This is 21 St.');
    const longDur = announcementDurationSeconds('The next stop is Abandoned Steinway Platform.');
    expect(shortDur).toBeGreaterThan(0.5);
    expect(longDur).toBeGreaterThan(shortDur);
    expect(longDur).toBeLessThan(6.0);
  });

  test('makeAnnouncement renders finite, non-silent audio samples in [-1, 1]', () => {
    const mockCtx = {
      createBuffer(_channels: number, length: number, sampleRate: number) {
        const data = new Float32Array(length);
        return {
          length,
          sampleRate,
          duration: length / sampleRate,
          numberOfChannels: 1,
          getChannelData: () => data,
        };
      },
    } as unknown as BaseAudioContext;

    const buf = makeAnnouncement(mockCtx, 'The next stop is Fulton St.');
    const samples = buf.getChannelData(0);
    expect(samples.length).toBeGreaterThan(10000);

    let peak = 0;
    for (let i = 0; i < samples.length; i++) {
      const s = samples[i];
      expect(Number.isFinite(s)).toBe(true);
      expect(Math.abs(s)).toBeLessThanOrEqual(1);
      if (Math.abs(s) > peak) peak = Math.abs(s);
    }
    expect(peak).toBeGreaterThan(0.1);
  });
});
