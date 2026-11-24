import { describe, test, expect } from 'bun:test';
import { ledSignText } from '../../src/ui/ledSignModel';

describe('ledSignText', () => {
  test('formats riding next-stop text with uppercase route letter and station', () => {
    expect(ledSignText('G', 'Fulton St', 'next')).toBe('G  NEXT: FULTON ST');
    expect(ledSignText('G', 'Court Sq', 'next')).toBe('G  NEXT: COURT SQ');
  });

  test('formats stopped and boarding station text without NEXT prefix', () => {
    expect(ledSignText('G', 'Fulton St', 'at')).toBe('G  FULTON ST');
    expect(ledSignText('G', 'Hoyt–Schermerhorn', 'at')).toBe('G  HOYT–SCHERMERHORN');
    expect(ledSignText('G', 'Court Sq', 'at')).toBe('G  COURT SQ');
  });

  test('follows active route lines and never hardcodes G', () => {
    expect(ledSignText('L', 'Lorimer St', 'next')).toBe('L  NEXT: LORIMER ST');
    expect(ledSignText('L', 'Myrtle–Wyckoff Avs', 'at')).toBe('L  MYRTLE–WYCKOFF AVS');
    expect(ledSignText('7', 'Terminal Echo', 'next')).toBe('7  NEXT: TERMINAL ECHO');
  });

  test('uppercases long names whole and trims surrounding whitespace', () => {
    expect(ledSignText(' g ', ' Clinton–Washington Avs ', 'at')).toBe('G  CLINTON–WASHINGTON AVS');
    expect(ledSignText('g', 'Bedford–Nostrand Avs', 'next')).toBe('G  NEXT: BEDFORD–NOSTRAND AVS');
  });
});
