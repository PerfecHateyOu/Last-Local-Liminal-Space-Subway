import { describe, expect, test } from 'bun:test';
import * as THREE from 'three';
import { ASTRA_DOOR_X, createAstraCar } from '../../src/graphics/astraCar';
import { LENGTH_SCALE } from '../../src/graphics/astra/fit';
import { SubwayCarBuilder } from '../../src/graphics/subwayCarBuilder';

function installCanvasMock() {
  if (typeof document !== 'undefined' && typeof document.createElement === 'function') return () => {};
  const hadDocument = typeof document !== 'undefined';
  const previous = hadDocument ? document : undefined;
  const makeCanvas = () => {
    const c = {
      width: 16,
      height: 16,
      dataset: {} as Record<string, string>,
      getContext: () => ctx,
    };
    const ctx: Record<string, unknown> = new Proxy(Object.create(null), {
      get(_t, prop) {
        if (prop === 'canvas') return c;
        if (prop === 'measureText') return () => ({ width: 80 });
        if (prop === 'createLinearGradient' || prop === 'createRadialGradient') return () => ctx;
        if (prop === 'createImageData') {
          return (w: number, h: number) => ({ data: new Uint8ClampedArray(w * h * 4), width: w, height: h });
        }
        return () => undefined;
      },
      set() {
        return true;
      },
    });
    return c;
  };
  (globalThis as unknown as { document: { createElement: (tag: string) => ReturnType<typeof makeCanvas> } }).document = {
    createElement: () => makeCanvas(),
  };
  return () => {
    if (hadDocument) {
      (globalThis as unknown as { document: Document }).document = previous as Document;
    } else {
      delete (globalThis as unknown as { document?: Document }).document;
    }
  };
}

describe('Car B 23.8m layout and consist alignment', () => {
  test('pins Car B length (23.8m), ends (±11.9m), doors (±2.85, ±8.45), and adjacent car centers (±22.4m)', () => {
    const restore = installCanvasMock();
    try {
      expect(SubwayCarBuilder.CAR_B_END).toBe(11.9);
      expect(SubwayCarBuilder.CAR_B_END * 2).toBeCloseTo(23.8, 6);
      expect(ASTRA_DOOR_X).toEqual([-8.45, -2.85, 2.85, 8.45]);

      const astra = createAstraCar();
      astra.group.updateWorldMatrix(true, true);
      const carBBox = new THREE.Box3().setFromObject(astra.group);
      expect(carBBox.min.x).toBeCloseTo(-11.9, 1);
      expect(carBBox.max.x).toBeCloseTo(11.9, 1);
      expect(carBBox.max.x - carBBox.min.x).toBeCloseTo(23.8, 1);
      expect(astra.leaves.map((l) => l.x0)).toEqual([-8.45, -8.45, -2.85, -2.85, 2.85, 2.85, 8.45, 8.45]);

      const scene = new THREE.Scene();
      const builder = new SubwayCarBuilder(scene);
      builder.buildScene();
      scene.updateMatrixWorld(true);

      // Platform leaves match Car B door centers (±2.85, ±8.45).
      expect(builder.farLeaves.map((l) => l.x0)).toEqual([-8.45, -8.45, -2.85, -2.85, 2.85, 2.85, 8.45, 8.45]);

      // Adjacent cars A and C sit at world centers -22.4 and +22.4.
      expect(builder.carAGroup.position.x).toBe(-2.9);
      expect(builder.carCGroup.position.x).toBe(2.9);
      const carAShell = builder.carAGroup.children.find((c) => c.position.x === -19.5)!;
      const carCShell = builder.carCGroup.children.find((c) => c.position.x === 19.5)!;
      expect(carAShell).toBeDefined();
      expect(carCShell).toBeDefined();
      expect(carAShell.getWorldPosition(new THREE.Vector3()).x).toBeCloseTo(-22.4, 6);
      expect(carCShell.getWorldPosition(new THREE.Vector3()).x).toBeCloseTo(22.4, 6);

      // Car B window pane 2 aligns to the left center glazing (-1.01), not the x = 0 center post.
      expect(builder.panes.map((p) => p.x)).toEqual([-6.64, -4.67, -1.01, 1.01, 4.67]);

      // Car A passenger pa2 sits on an Astra bench, clear of Car A's door bays.
      const pa2 = builder.carAPassengers.find((p) => p.tid === 'pa2')!;
      expect(pa2).toBeDefined();
      const pa2WorldX = pa2.g.getWorldPosition(new THREE.Vector3()).x;
      const carADoorBays = ASTRA_DOOR_X.map((dz) => [-22.4 - (dz + 0.74) * LENGTH_SCALE, -22.4 - (dz - 0.74) * LENGTH_SCALE]);
      for (const [lo, hi] of carADoorBays) {
        expect(pa2WorldX < lo || pa2WorldX > hi).toBe(true);
      }

      // Opening the Car B gangway doors leaves both ±11.9m doorways clear along the aisle.
      builder.gangwayDoors.frontGroup!.rotation.y = Math.PI / 2;
      builder.gangwayDoors.rearGroup!.rotation.y = -Math.PI / 2;
      scene.updateMatrixWorld(true);
      const ray = new THREE.Raycaster();
      for (const dir of [-1, 1]) {
        ray.set(new THREE.Vector3(dir * 10.5, 1.18, 0), new THREE.Vector3(dir, 0, 0));
        const hits = ray.intersectObject(builder.carGroup, true).filter((h) => h.distance < 2.2);
        expect(hits).toHaveLength(0);
      }
    } finally {
      restore();
    }
  });
});
