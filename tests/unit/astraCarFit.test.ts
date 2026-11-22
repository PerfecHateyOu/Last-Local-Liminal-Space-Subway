import { test } from 'bun:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import { CAR_LENGTH, HEIGHT_SCALE, LENGTH_SCALE, WIDTH_SCALE, mountAstraShell, alongCarX } from '../../src/graphics/astra/fit';
import { seatShell } from '../../src/graphics/astra/geometry';

function installCanvasMock() {
  if (typeof document !== 'undefined' && document.createElement) return;
  const ctx = new Proxy(Object.create(null), {
    get(_t, prop) {
      if (prop === 'measureText') return () => ({ width: 80 });
      if (prop === 'createLinearGradient' || prop === 'createRadialGradient') return () => ctx;
      return () => undefined;
    },
    set() {
      return true;
    },
  });
  const canvas = () => ({
    width: 16,
    height: 16,
    getContext: () => ctx,
  });
  (globalThis as unknown as { document: { createElement: (tag: string) => ReturnType<typeof canvas> } }).document = {
    createElement: (tag: string) => (tag === 'canvas' ? canvas() : canvas()),
  };
}

test('Astra shell mount puts car length on world X and the platform side on -Z', () => {
  const root = new THREE.Group();
  const platformEnd = new THREE.Object3D();
  // Local -X is Astra's side < 0. Local +Z is one end of the car.
  platformEnd.position.set(-1.555, 2.605, 11.9);
  const nearSide = new THREE.Object3D();
  nearSide.position.set(1.555, 1.4, 0);
  root.add(platformEnd, nearSide);
  mountAstraShell(root, 0);
  root.updateWorldMatrix(true, true);

  const end = new THREE.Vector3();
  const near = new THREE.Vector3();
  platformEnd.getWorldPosition(end);
  nearSide.getWorldPosition(near);

  // Independent of mountAstraShell: Ry(-π/2) then the three scales.
  assert.ok(Math.abs(end.x - (-11.9 * LENGTH_SCALE)) < 1e-6, `end x ${end.x}`);
  assert.ok(Math.abs(end.y - (2.605 * HEIGHT_SCALE)) < 1e-6, `end y ${end.y}`);
  assert.ok(Math.abs(end.z - (-1.555 * WIDTH_SCALE)) < 1e-6, `end z ${end.z}`);
  assert.ok(Math.abs(end.x + CAR_LENGTH / 2) < 0.02, 'end sits at the original 18 m car');
  assert.ok(end.z < -1.3 && end.z > -1.6, 'platform side is the original -Z wall');
  assert.ok(near.z > 1.3, 'the other side stays on +Z');
  assert.ok(end.y < 2.45 && end.y > 2.2, 'ceiling stays under the original 2.43 m shell');
});

test('a local +Z door slide travels toward world -X, which is forward', () => {
  const root = new THREE.Group();
  const leaf = new THREE.Object3D();
  leaf.position.set(-1.5, 1.3, 2.85);
  root.add(leaf);
  mountAstraShell(root, -19.5);
  root.updateWorldMatrix(true, true);
  const closed = new THREE.Vector3();
  leaf.getWorldPosition(closed);
  leaf.position.z += 0.685;
  root.updateWorldMatrix(true, true);
  const open = new THREE.Vector3();
  leaf.getWorldPosition(open);
  assert.ok(open.x < closed.x - 0.4, `slide should move toward -X, closed ${closed.x} open ${open.x}`);
  assert.ok(Math.abs(open.z - closed.z) < 1e-6, 'slide stays on the same side of the car');
  assert.ok(closed.z < 0, 'this leaf is on the platform side');
  assert.ok(Math.abs(alongCarX(leaf) - open.x) < 1e-6);
});

test('seat shells are visible from above and the lip faces the aisle', () => {
  const geo = seatShell();
  geo.computeVertexNormals();
  const pos = geo.getAttribute('position');
  const nrm = geo.getAttribute('normal');
  let sitting = 0;
  let sittingUp = 0;
  let lip = 0;
  let lipOut = 0;
  for (let i = 0; i < pos.count; i++) {
    if (Math.abs(pos.getZ(i)) > 0.05) continue;
    if (pos.getX(i) > 0.48 && pos.getX(i) < 0.56 && pos.getY(i) > 0.47) {
      sitting++;
      if (nrm.getY(i) > 0.5) sittingUp++;
    }
    if (pos.getX(i) > 0.56) {
      lip++;
      if (nrm.getX(i) > 0.5) lipOut++;
    }
  }
  assert.ok(sitting > 4, `sitting surface vertices ${sitting}`);
  assert.equal(sittingUp, sitting, 'the seat pan faces up');
  assert.ok(lip > 4, `front lip vertices ${lip}`);
  assert.equal(lipOut, lip, 'the front lip faces the aisle (+local X)');
});

test('the mounted car opens platform doors on -Z and leaves the gangway walk clear', async () => {
  const hadDocument = typeof document !== 'undefined';
  const previous = hadDocument ? document : undefined;
  installCanvasMock();
  try {
  const { createCar } = await import('../../src/graphics/astra/car');
  const car = createCar({ openGangway: true });
  mountAstraShell(car.group, 0);
  const doorGroups = () => car.group.children.filter((c) => (c as THREE.Group).isGroup && Math.abs(c.position.z) > 0.1);
  const centerOf = (obj: THREE.Object3D) => new THREE.Box3().setFromObject(obj).getCenter(new THREE.Vector3());
  car.setDoors(0);
  car.group.updateWorldMatrix(true, true);
  const closed = doorGroups().map(centerOf);
  car.setDoors(1);
  car.group.updateWorldMatrix(true, true);
  const opened = doorGroups().map(centerOf);
  let moved = 0;
  for (let i = 0; i < closed.length; i++) {
    const dx = opened[i].x - closed[i].x;
    if (Math.abs(dx) < 0.05) {
      assert.ok(closed[i].z > 0.5, `a door that stays shut should be the near side, z=${closed[i].z}`);
      continue;
    }
    moved++;
    assert.ok(opened[i].z < -0.5, `a door that slides should be on the platform, z=${opened[i].z}`);
    assert.ok(Math.abs(opened[i].z - closed[i].z) < 0.02, 'the slide does not jump across the car');
  }
  assert.equal(moved, 8, 'four platform door pairs, two leaves each');

  assert.equal(car.lenses.length, 18);
  let nearTubes = 0;
  for (const lens of car.lenses) {
    const w = lens.mesh.getWorldPosition(new THREE.Vector3());
    assert.ok(Math.abs(w.x) < 9.2, `tube x ${w.x}`);
    assert.ok(w.y > 2.0 && w.y < 2.45, `tube y ${w.y}`);
    assert.equal(lens.mat.color.getHex(), 0xfff4de);
    if (Math.abs(w.x) <= 5) nearTubes++;
  }
  assert.ok(nearTubes >= 4, `cold-light tubes within 5 m: ${nearTubes}`);

  car.group.updateWorldMatrix(true, true);
  const ray = new THREE.Raycaster();
  for (const y of [0.4, 1.18, 1.95]) {
    for (const dir of [1, -1]) {
      ray.set(new THREE.Vector3(dir * 7.6, y, 0), new THREE.Vector3(dir, 0, 0));
      const hit = ray.intersectObject(car.group, true)[0];
      assert.ok(!hit || hit.distance > 2.5, `gangway at y=${y} dir=${dir} blocked at ${hit?.distance}`);
    }
  }
  car.dispose();
  } finally {
    if (hadDocument) {
      (globalThis as unknown as { document: Document }).document = previous as Document;
    } else {
      delete (globalThis as unknown as { document?: Document }).document;
    }
  }
});
