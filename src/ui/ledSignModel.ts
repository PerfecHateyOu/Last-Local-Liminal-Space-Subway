/**
 * Pure formatting model for the in-car LED strip signs (above the doors in Cars A, B, and C).
 * No Three.js dependencies so formatting can be unit-tested directly.
 */
export type LedSignMode = 'next' | 'at';

/**
 * Format the in-car LED display text from the active route letter and stop name.
 *   - 'next': "G  NEXT: FULTON ST"
 *   - 'at':   "G  FULTON ST"
 */
export function ledSignText(line: string, stopName: string, mode: LedSignMode): string {
  const l = line.trim().toUpperCase();
  const s = stopName.trim().toUpperCase();
  return mode === 'next' ? `${l}  NEXT: ${s}` : `${l}  ${s}`;
}
