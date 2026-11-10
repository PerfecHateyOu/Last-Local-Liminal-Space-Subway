import { describe, expect, test } from 'bun:test';
import { atStop, nextStopIndex, susStage, syncPaSeen } from '../../src/ui/paBoardModel';

describe('PA board suspicion stage (display only)', () => {
  test('labels the real sus scale without moving the intervene threshold', () => {
    expect(susStage(0)).toBe('CALM');
    expect(susStage(19)).toBe('CALM');
    expect(susStage(20)).toBe('UNEASY');
    expect(susStage(39)).toBe('UNEASY');
    expect(susStage(40)).toBe('WATCHED');
    expect(susStage(59)).toBe('WATCHED');
    expect(susStage(60)).toBe('IT KNOWS');
    expect(susStage(100)).toBe('IT KNOWS');
  });
});

describe('PA board HERE / NEXT', () => {
  test('riding, stopped, haven, trial, the false 6b stretch, and before boarding', () => {
    expect(atStop({ seg: null, phase: 'intro' })).toBe(1);
    expect(atStop({ seg: { stop: 2 }, phase: 'ride' })).toBe(1);
    expect(atStop({ seg: { stop: 2 }, phase: 'stop' })).toBe(2);
    expect(atStop({ seg: { stop: 6 }, phase: 'haven' })).toBe(6);
    expect(atStop({ seg: { stop: 9 }, phase: 'trial' })).toBe(9);
    // 6b re-uses stop 6 while travelling and while stopped. It is not stop 5.
    expect(atStop({ seg: { stop: 6, b: true }, phase: 'ride' })).toBe(6);
    expect(atStop({ seg: { stop: 6, b: true }, phase: 'stop' })).toBe(6);
    expect(atStop({ seg: { stop: 6, b: true }, phase: 'trial' })).toBe(6);
    expect(atStop({ seg: { stop: 13 }, phase: 'ride' })).toBe(12);
    expect(atStop({ seg: { stop: 13 }, phase: 'stop' })).toBe(13);
  });

  test('NEXT is the following stop, and the last stop has none', () => {
    expect(nextStopIndex(1, 13)).toBe(2);
    expect(nextStopIndex(12, 13)).toBe(13);
    expect(nextStopIndex(13, 13)).toBeNull();
  });
});

describe('PA board unread count', () => {
  const feed = (seqs: number[]) => seqs.map((seq) => ({ seq }));

  test('counts announcements made while closed', () => {
    expect(syncPaSeen(feed([1, 2]), 0, false, 2)).toEqual({ unread: 2, seen: 0 });
  });

  test('opening marks the whole feed seen, including lines that arrived while it was open', () => {
    expect(syncPaSeen(feed([1, 2, 3]), 0, true, 3)).toEqual({ unread: 0, seen: 3 });
    // Closed again: those three are seen. One newer line is the only unread.
    expect(syncPaSeen(feed([1, 2, 3, 4]), 3, false, 4)).toEqual({ unread: 1, seen: 3 });
  });

  test('a capped feed never reports more unread than it still holds', () => {
    // 15 announcements happened; the feed kept seq 4..15. None were seen.
    const capped = feed([4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
    expect(syncPaSeen(capped, 0, false, 15)).toEqual({ unread: 12, seen: 0 });
    // Seen through 15, then one more arrives and the oldest drops. Unread is 1, not 0.
    const shifted = feed([5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    expect(syncPaSeen(shifted, 15, false, 16)).toEqual({ unread: 1, seen: 15 });
  });

  test('a new run zeroes the counter, so a remembered seen-seq cannot hide new lines', () => {
    expect(syncPaSeen([], 15, false, 0)).toEqual({ unread: 0, seen: 0 });
    expect(syncPaSeen(feed([1]), 15, false, 1)).toEqual({ unread: 1, seen: 0 });
  });
});
