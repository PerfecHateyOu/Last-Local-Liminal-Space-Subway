declare module 'bun:test' {
  type TestFn = () => void | Promise<void>;

  export function describe(name: string, fn: () => void): void;
  export function test(name: string, fn: TestFn): void;
  export function it(name: string, fn: TestFn): void;
  export function beforeEach(fn: TestFn): void;
  export function afterEach(fn: TestFn): void;
  export function beforeAll(fn: TestFn): void;
  export function afterAll(fn: TestFn): void;

  interface Matchers<T> {
    not: Matchers<T>;
    toBe(expected: unknown): void;
    toEqual(expected: unknown): void;
    toStrictEqual(expected: unknown): void;
    toMatchObject(expected: Record<string, unknown>): void;
    toBeCloseTo(expected: number, numDigits?: number): void;
    toBeLessThan(expected: number): void;
    toBeLessThanOrEqual(expected: number): void;
    toBeGreaterThan(expected: number): void;
    toBeGreaterThanOrEqual(expected: number): void;
    toBeNull(): void;
    toBeDefined(): void;
    toBeUndefined(): void;
    toBeTruthy(): void;
    toBeFalsy(): void;
    toMatch(expected: RegExp | string): void;
    toContain(expected: unknown): void;
    toHaveLength(expected: number): void;
    toThrow(expected?: RegExp | string): void;
  }

  export function expect<T>(actual: T): Matchers<T>;
}
