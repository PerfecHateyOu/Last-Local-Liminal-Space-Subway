/**
 * Car B shell from the Astra remake (last-local-remake-astra @ afe9e89, src/scene/car.ts createCar),
 * built in Astra's Z-long coordinates and placed on this game's X-long axis by astraGeometry.
 *
 * Not ported: the fake cars beyond the ends (Cars A and C are the real ones), the post-Stop-5
 * blackout, and the per-frame tube flicker. Ceiling tubes are separate meshes so the existing
 * light pool, single-strip flicker and slow dim keep driving them.
 */
import * as THREE from 'three';
import { Parts, placeDoor, placeInMain, seatShell, standard, windowGasket } from './astraGeometry';
import { brushedMaterial, floorMaterial, glassMaterial, label, ledSign } from './astraMaterials';
export interface AstraLeaf {
  g: THREE.Group;
  x0: number;
  side: number;
}

const carLength = 23.8;
/** Four door bays per side. Astra z, which is our x. */
export const ASTRA_DOOR_X = [-8.45, -2.85, 2.85, 8.45];
const spans: [number, number][] = [[-11.81, -9.19], [-7.71, -3.59], [-2.11, 2.11], [3.59, 7.71], [9.19, 11.81]];
const signRot = (side: number) => -side * Math.PI / 2;
const lightWidth = 0.24;
/** How far a platform leaf travels when the doors are open. Astra uses 0.685. */
export const DOOR_SLIDE = 0.685;

export interface AstraCar {
  group: THREE.Group;
  /** Platform-side leaves (our far wall). `x0` is the along-car rest, `side` the open direction. */
  leaves: AstraLeaf[];
  /** 18 emissive fixtures, 9 along the car by 2. MeshBasic so the light tick can set `.color`. */
  tubes: { mesh: THREE.Mesh; mat: THREE.MeshBasicMaterial; x: number }[];
}

export function createAstraCar(): AstraCar {
  const root = new THREE.Group();
  const parts = new Parts();
  const wall = standard('#c7c6b9', 0.19, 0.54);
  const trim = brushedMaterial('#a9aaa1');
  const brushed = brushedMaterial('#c3c4b9', 0.67);
  const chrome = standard('#e2e4df', 0.96, 0.145);
  const rubber = standard('#252a27', 0.09, 0.81);
  const joint = standard('#5d5e56', 0.27, 0.56);
  const ceiling = standard('#c9cdc3', 0.18, 0.68);
  const dark = standard('#353933', 0.45, 0.54);
  const under = standard('#68655a', 0.46, 0.53);
  const seal = standard('#373c36', 0.13, 0.7);
  const shoe = standard('#7f7f72', 0.7, 0.31);
  const seatMats = ['#cc6428', '#d58934', '#e5ab48', '#c66b2d'].map((col) => standard(col, 0.1, 0.245));
  const sideGlass = glassMaterial();
  const floor = parts.face(0, -0.002, 0, 3.32, carLength, 0, floorMaterial());
  floor.rotation.x = -Math.PI / 2;
  const shell = seatShell();
  parts.box(0, 2.68, 0, 3.28, 0.15, carLength, ceiling);
  for (const s of [-1, 1]) {
    parts.box(s * 1.59, 0.12, 0, 0.07, 0.24, carLength, dark);
    parts.box(s * 1.6, 2.1, 0, 0.1, 0.64, carLength, wall);
    const slope = parts.box(s * 1.32, 2.42, 0, 0.68, 0.08, carLength, ceiling);
    slope.rotation.z = -s * 0.43;
    parts.box(s * 0.94, 2.583, 0, 0.032, 0.035, carLength, chrome);
    parts.box(s * 0.79, 2.612, 0, 0.012, 0.011, carLength, joint);
    parts.box(s * 0.35, 2.61, 0, 0.009, 0.008, carLength, joint);
    for (let j = 0; j < 12; j++) {
      const z = -10.88 + j * 1.98;
      parts.box(0, 2.606, z, 1.7, 0.012, 0.015, joint);
      for (const x of [-0.72, 0, 0.72]) parts.box(x, 2.6, z + 0.035, 0.012, 0.012, 0.017, dark);
      const grate = parts.box(s * 0.64, 2.599, z + 0.19, 0.25, 0.014, 0.31, trim);
      for (let b = 0; b < 9; b++) parts.box(grate.position.x, 2.587, z + 0.072 + b * 0.031, 0.2, 0.005, 0.009, dark);
    }
    parts.rod([s * 0.98, 2.16, -11.79], [s * 0.98, 2.16, 11.79], 0.02, chrome);
    parts.rod([s * 1.49, 1.9, -11.79], [s * 1.49, 1.9, 11.79], 0.012, chrome);
  }

  const tubeSpots: { s: number; z: number }[] = [];
  for (let j = 0; j < 9; j++) {
    const z = -10.48 + j * 2.62;
    for (const s of [-1, 1]) {
      tubeSpots.push({ s, z });
      const support = parts.box(s * 1.21, 2.431, z, lightWidth + 0.07, 0.07, 2.57, trim);
      support.rotation.z = -s * 0.38;
      parts.box(s * 1.21, 2.387, z + 1.24, 0.26, 0.037, 0.027, chrome).rotation.z = -s * 0.38;
      for (const u of [-0.11, 0.11]) parts.box(s * 1.21 + u, 2.41 - s * u * 0.42, z, 0.008, 0.007, 2.49, chrome);
      parts.box(s * 1.21, 2.378, z, 0.004, 0.003, 2.493, ceiling);
    }
  }

  const stickers = label('Do not lean on door', '#cdc7b6', '#343831', 512, 75);
  const led = ledSign('G   COURT SQ');
  const leaves: AstraLeaf[] = [];
  const addWallPane = (p: Parts, s: number, xc: number, y: number, z: number, w: number, h: number, mat: THREE.Material, target?: string) =>
    p.face(s * xc, y, z, w, h, signRot(s), mat, target);

  for (const side of [-1, 1]) {
    for (let k = 0; k < spans.length; k++) {
      const [start, end] = spans[k];
      const z = (start + end) * 0.5;
      const len = end - start;
      parts.box(side * 1.605, 0.49, z, 0.1, 0.98, len, wall);
      parts.box(side * 1.606, 1.965, z, 0.1, 0.25, len, wall);
      for (const edge of [start + 0.055, end - 0.055]) parts.box(side * 1.605, 1.395, edge, 0.1, 0.84, 0.11, brushed);
      const windowCount = len > 3 ? 2 : 1;
      const winLen = (len - 0.18) / windowCount;
      for (let wi = 0; wi < windowCount; wi++) {
        const wz = start + 0.09 + winLen * (wi + 0.5);
        const h = 0.83;
        for (const offset of [-1, 1]) {
          parts.box(side * 1.552, 1.397 + offset * h * 0.5, wz, 0.062, 0.036, winLen, brushed);
          parts.box(side * 1.547, 1.397 + offset * (h * 0.5 - 0.037), wz, 0.035, 0.051, winLen - 0.046, rubber);
          parts.box(side * 1.552, 1.397, wz + offset * winLen * 0.5, 0.054, h, 0.035, brushed);
          parts.box(side * 1.547, 1.397, wz + offset * (winLen * 0.5 - 0.034), 0.033, h - 0.033, 0.045, rubber);
        }
        const rim = parts.mesh(windowGasket(winLen - 0.018, h - 0.01, 0.047, 0.09), brushed, side * 1.525, 1.397, wz);
        rim.rotation.y = signRot(side);
        const inner = parts.mesh(windowGasket(winLen - 0.067, h - 0.057, 0.039, 0.077), rubber, side * 1.523, 1.397, wz);
        inner.rotation.y = signRot(side);
        addWallPane(parts, side, 1.596, 1.397, wz, winLen - 0.087, h - 0.11, sideGlass);
        parts.box(side * 1.568, 1.007, wz, 0.054, 0.036, winLen, brushed);
        parts.box(side * 1.542, 1.43, wz + winLen * 0.22, 0.047, 0.74, 0.012, seal);
        parts.box(side * 1.52, 1.63, wz + winLen * 0.22, 0.026, 0.046, 0.093, trim);
      }
      const seatCount = Math.floor((len - 0.2) / 0.472);
      const seatSpace = (len - 0.23) / seatCount;
      parts.box(side * 1.38, 0.269, z, 0.39, 0.31, len - 0.075, under);
      parts.box(side * 1.26, 0.414, z, 0.51, 0.105, len - 0.09, shoe, 'seat');
      parts.box(side * 1.172, 0.232, z, 0.009, 0.104, len - 0.12, dark);
      parts.box(side * 1.166, 0.234, z, 0.008, 0.08, len - 0.2, under);
      for (let i = 0; i < seatCount; i++) {
        const pos = z + (i - (seatCount - 1) * 0.5) * seatSpace;
        const m = seatMats[[0, 1, 2, 2, 1, 0, 3, 1][(i + k) % 8]];
        const obj = parts.mesh(shell, m, side * 1.59, 0, pos, 'seat');
        obj.rotation.y = side > 0 ? Math.PI : 0;
        obj.scale.z = seatSpace / 0.472;
      }
      for (const edge of [start + 0.07, end - 0.07]) {
        parts.pipe([[side * 1.54, 0.9, edge], [side * 1.47, 0.925, edge], [side * 1.13, 0.79, edge], [side * 1.015, 0.697, edge], [side * 1.01, 0.42, edge], [side * 1.09, 0.32, edge]], 0.017, chrome);
        parts.rod([side * 0.994, 0, edge], [side * 0.994, 2.164, edge], 0.019, chrome);
        for (const yy of [0.016, 0.065, 2.128]) parts.rod([side * 0.994, yy, edge], [side * 0.994, yy + 0.018, edge], yy === 0.016 ? 0.061 : 0.03, chrome);
        parts.pipe([[side * 0.995, 2.0, edge], [side * 0.99, 2.15, edge], [side * 1.017, 2.3, edge], [side * 1.14, 2.42, edge]], 0.016, chrome);
      }
    }

    for (const z of ASTRA_DOOR_X) {
      const width = 1.48;
      parts.box(side * 1.602, 2.05, z, 0.09, 0.35, width, brushed);
      parts.box(side * 1.526, 1.965, z, 0.1, 0.05, width + 0.055, trim, 'doors');
      parts.box(side * 1.524, 2.21, z, 0.08, 0.182, 1.17, dark, 'doors');
      const display = addWallPane(parts, side, 1.477, 2.21, z, 1.1, 0.121, led, 'doors');
      // Pull the sign out of the batch so it stays a readable quad, then place it on our axis.
      parts.group.remove(display);
      placeInMain(display);
      root.add(display);
      for (const d of [-1, 1]) {
        parts.box(side * 1.6, 0.973, z + d * 0.755, 0.134, 1.95, 0.046, brushed, 'doors');
        parts.box(side * 1.61, 0.018, z, 0.3, 0.028, width, trim, 'doors');
        const door = new Parts();
        const center = d * 0.367;
        const ww = 0.734;
        door.box(side * 1.587, 0.438, center, 0.075, 0.876, ww, brushed, 'doors');
        door.box(side * 1.587, 1.845, center, 0.075, 0.2, ww, brushed, 'doors');
        for (const e of [-1, 1]) door.box(side * 1.587, 1.31, center + e * 0.298, 0.075, 0.88, 0.135, brushed, 'doors');
        for (const v of [-1, 1]) {
          door.box(side * 1.541, 1.305 + v * 0.44, center, 0.032, 0.039, 0.508, rubber, 'doors');
          door.box(side * 1.541, 1.305, center + v * 0.253, 0.032, 0.898, 0.039, rubber, 'doors');
        }
        const glass = new THREE.MeshStandardMaterial({
          color: '#3f514c', transparent: true, opacity: 0.23, metalness: 0.69, roughness: 0.16, depthWrite: false, side: THREE.DoubleSide,
        });
        addWallPane(door, side, 1.586, 1.31, center, 0.478, 0.849, glass, 'doors');
        door.box(side * 1.54, 0.969, center - d * 0.358, 0.034, 1.91, 0.019, seal, 'doors');
        door.box(side * 1.542, 0.139, center, 0.022, 0.264, 0.701, trim, 'doors');
        addWallPane(door, side, 1.542, 0.738, center, 0.318, 0.047, stickers, 'doors');
        for (const e of [-1, 1]) door.box(side * 1.535, 0.713, center + e * 0.168, 0.009, 0.009, 0.009, dark, 'doors');
        const obj = door.batch(false);
        obj.position.z = z;
        placeDoor(obj);
        root.add(obj);
        // Only the platform side (Astra +X, our far wall) slides. Near leaves stay shut.
        if (side > 0) leaves.push({ g: obj, x0: z, side: d });
      }
    }
    for (let k = 0; k < 15; k++) {
      const z = -10.67 + k * 1.52;
      if (Math.abs(z) > 11.6) continue;
      parts.rod([side * 0.982, 2.153, z], [side * 0.982, 2.045, z], 0.011, chrome);
      parts.pipe(
        [[side * 0.984, 2.045, z], [side * 0.984, 2.008, z - 0.035], [side * 0.983, 1.95, z - 0.071], [side * 0.98, 1.915, z - 0.068],
          [side * 0.98, 1.892, z], [side * 0.98, 1.915, z + 0.068], [side * 0.983, 1.95, z + 0.071], [side * 0.984, 2.008, z + 0.035]],
        0.012, shoe, undefined, true
      );
    }
  }

  // End LED headers over the gangway openings. The ends stay open so Cars A and C stay walkable.
  const darkHeader = standard('#353933', 0.45, 0.54);
  for (const far of [-1, 1] as const) {
    const z = far * 11.88;
    const ry = far === -1 ? 0 : Math.PI;
    parts.box(0, 2.236, z - far * 0.08, 1.59, 0.257, 0.13, darkHeader);
    parts.face(0, 2.24, z - far * 0.153, 1.49, 0.188, ry, led);
  }

  root.add(parts.batch());

  const tubes = tubeSpots.map(({ s, z }) => {
    const mat = new THREE.MeshBasicMaterial({ color: 0xfff4de });
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(lightWidth, 0.047, 2.503), mat);
    mesh.position.set(s * 1.21, 2.405, z);
    mesh.rotation.z = -s * 0.38;
    placeInMain(mesh);
    root.add(mesh);
    return { mesh, mat, x: z };
  });

  return { group: root, leaves, tubes };
}
