/**
 * Astra's procedural R160 interior, visual only.
 * The whole-car blackout and the per-tube jitter from that remake are not here.
 * Ceiling lenses are unlit strips the original lighting code can hide and recolor.
 */
import * as THREE from 'three';
import { Parts, seatShell, standard, windowGasket } from './geometry';
import { adPoster, brushedMaterial, floorMaterial, glassMaterial, label, ledSign, releaseMaterial, routeMap } from './materials';
import { DOOR_SLIDE_LOCAL, HEIGHT_SCALE, WIDTH_SCALE } from './fit';

/** Same warm white as SubwayCarBuilder.LIGHT_ON. One material per lens so a cold-light anomaly can recolor just that tube. */
const LENS_COLOR = 0xfff4de;

const carLength = 23.8;
const doorCenters = [-8.45, -2.85, 2.85, 8.45];
const spans: Array<[number, number]> = [[-11.81, -9.19], [-7.71, -3.59], [-2.11, 2.11], [3.59, 7.71], [9.19, 11.81]];
const signRot = (side: number) => -side * Math.PI / 2;
const lightWidth = 0.24;

export interface AstraCar {
  group: THREE.Group;
  lenses: Array<{ mesh: THREE.Mesh; mat: THREE.MeshBasicMaterial }>;
  setDoors: (doorFraction: number) => void;
  dispose: () => void;
}

export interface AstraCarOptions {
  /** Skip this end bulkhead (1 = local +Z, -1 = local -Z). Used at the cab. */
  skipFar?: 1 | -1 | null;
  /**
   * Leave the end doorway open. The original swinging gangway door is the door
   * the player walks through; a second solid leaf would sit in that opening.
   */
  openGangway?: boolean;
}

export function createCar(options: AstraCarOptions = {}): AstraCar {
  const skipFar = options.skipFar ?? null;
  const openGangway = options.openGangway ?? true;
  const root = new THREE.Group();
  const parts = new Parts();
  const wall = standard('#c7c6b9');
  const trim = brushedMaterial('#a9aaa1');
  const brushed = brushedMaterial('#c3c4b9');
  const chrome = new THREE.MeshPhongMaterial({ color: '#332f28', specular: '#8a8c86', shininess: 90 });
  const rubber = standard('#252a27');
  const joint = standard('#5d5e56');
  const ceiling = standard('#c9cdc3');
  const dark = standard('#353933');
  const endMat = brushedMaterial('#a4a69b');
  const throughGlass = new THREE.MeshBasicMaterial({ color: '#555f54', transparent: true, opacity: 0.25, depthWrite: false });
  const doorGlass = new THREE.MeshBasicMaterial({ color: '#3f514c', transparent: true, opacity: 0.24, depthWrite: false, side: THREE.DoubleSide });
  const under = standard('#68655a');
  const seal = standard('#373c36');
  const shoe = standard('#7f7f72');
  const darkGlass = standard('#202822');
  const seatMats = ['#cc6428', '#d58934', '#e5ab48', '#c66b2d'].map((color) => new THREE.MeshPhongMaterial({ color, specular: '#3c3a35', shininess: 75 }));
  const sideGlass = glassMaterial();
  const floor = parts.face(0, -0.002, 0, 3.32, carLength, 0, floorMaterial());
  floor.rotation.x = -Math.PI / 2;
  const shell = seatShell(8);
  parts.box(0, 2.68, 0, 3.28, 0.15, carLength, ceiling);
  for (const s of [-1, 1]) {
    parts.box(s * 1.59, 0.12, 0, 0.07, 0.24, carLength, dark);
    parts.box(s * 1.6, 2.1, 0, 0.10, 0.64, carLength, wall);
    const slope = parts.box(s * 1.32, 2.42, 0, 0.68, 0.08, carLength, ceiling);
    slope.rotation.z = -s * 0.43;
    parts.box(s * 0.94, 2.583, 0, 0.032, 0.035, carLength, chrome);
    parts.box(s * 0.79, 2.612, 0, 0.012, 0.011, carLength, joint);
    parts.box(s * 0.35, 2.610, 0, 0.009, 0.008, carLength, joint);
    for (let j = 0; j < 12; j++) {
      const z = -10.88 + j * 1.98;
      parts.box(0, 2.606, z, 1.70, 0.012, 0.015, joint);
      for (const x of [-0.72, 0, 0.72]) parts.box(x, 2.600, z + 0.035, 0.012, 0.012, 0.017, dark);
      const grate = parts.box(s * 0.64, 2.599, z + 0.19, 0.25, 0.014, 0.31, trim);
      for (let b = 0; b < 3; b++) parts.box(grate.position.x, 2.587, z + 0.095 + b * 0.095, 0.20, 0.005, 0.014, dark);
    }
    parts.rod([s * 0.98, 2.16, -11.79], [s * 0.98, 2.16, 11.79], 0.020, chrome);
    parts.rod([s * 1.49, 1.90, -11.79], [s * 1.49, 1.90, 11.79], 0.012, chrome);
  }

  const lenses: AstraCar['lenses'] = [];
  const lensGeo = new THREE.BoxGeometry(lightWidth, 0.047, 2.503);
  const lampGroup = new THREE.Group();
  for (let j = 0; j < 9; j++) {
    const z = -10.48 + j * 2.62;
    for (const s of [-1, 1]) {
      const support = parts.box(s * 1.21, 2.431, z, lightWidth + 0.07, 0.07, 2.57, trim);
      support.rotation.z = -s * 0.38;
      const mat = new THREE.MeshBasicMaterial({ color: LENS_COLOR });
      const lens = new THREE.Mesh(lensGeo, mat);
      lens.position.set(s * 1.21, 2.405, z);
      lens.rotation.z = -s * 0.38;
      lampGroup.add(lens);
      lenses.push({ mesh: lens, mat });
      parts.box(s * 1.21, 2.387, z + 1.24, 0.26, 0.037, 0.027, chrome).rotation.z = -s * 0.38;
      for (const u of [-0.11, 0.11]) parts.box(s * 1.21 + u, 2.41 - s * u * 0.42, z, 0.008, 0.007, 2.49, chrome);
      parts.box(s * 1.21, 2.378, z, 0.004, 0.003, 2.493, ceiling);
    }
  }
  root.add(lampGroup);

  const stickers = label('Do not lean on door', '#cdc7b6', '#343831', 512, 75);
  const fleet = label('5632', '#242924', '#e2e2d3', 280, 108);
  const warning = label('Do not pass between cars', '#c6c2b3', '#31332d', 768, 92);
  const greenBullet = label('G', '#63813a', '#f5f5e8', 80, 80);
  const map = routeMap();
  const ads = [0, 1, 2, 3].map((n) => adPoster(n));
  const led = ledSign('G   COURT SQ');
  const doors: { group: THREE.Group; dir: number; z: number; platformSide: boolean }[] = [];
  const addWallPane = (p: Parts, s: number, xc: number, y: number, z: number, w: number, h: number, mat: THREE.Material, target?: string) => p.face(s * xc, y, z, w, h, signRot(s), mat, target);

  for (const side of [-1, 1]) {
    for (let k = 0; k < spans.length; k++) {
      const [start, end] = spans[k];
      const z = (start + end) * 0.5;
      const len = end - start;
      parts.box(side * 1.605, 0.49, z, 0.10, 0.98, len, wall);
      parts.box(side * 1.606, 1.965, z, 0.10, 0.25, len, wall);
      for (const edge of [start + 0.055, end - 0.055]) parts.box(side * 1.605, 1.395, edge, 0.10, 0.84, 0.11, brushed);
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
        parts.box(side * 1.520, 1.63, wz + winLen * 0.22, 0.026, 0.046, 0.093, trim);
      }
      const seatCount = Math.floor((len - 0.2) / 0.472);
      const seatSpace = (len - 0.23) / seatCount;
      parts.box(side * 1.38, 0.269, z, 0.39, 0.31, len - 0.075, under);
      parts.box(side * 1.26, 0.414, z, 0.51, 0.105, len - 0.09, shoe, 'seat');
      parts.box(side * 1.172, 0.232, z, 0.009, 0.104, len - 0.12, dark);
      parts.box(side * 1.166, 0.234, z, 0.008, 0.080, len - 0.20, under);
      for (let i = 0; i < seatCount; i++) {
        const pos = z + (i - (seatCount - 1) * 0.5) * seatSpace;
        const m = seatMats[[0, 1, 2, 2, 1, 0, 3, 1][(i + k) % 8]];
        const obj = parts.mesh(shell, m, side * 1.59, 0, pos, 'seat');
        obj.rotation.y = side > 0 ? Math.PI : 0;
        obj.scale.z = seatSpace / 0.472;
      }
      for (const edge of [start + 0.07, end - 0.07]) {
        parts.pipe([[side * 1.54, 0.90, edge], [side * 1.47, 0.925, edge], [side * 1.13, 0.79, edge], [side * 1.015, 0.697, edge], [side * 1.01, 0.42, edge], [side * 1.09, 0.32, edge]], 0.017, chrome);
        parts.rod([side * 0.994, 0, edge], [side * 0.994, 2.164, edge], 0.019, chrome);
        for (const yy of [0.016, 0.065, 2.128]) parts.rod([side * 0.994, yy, edge], [side * 0.994, yy + 0.018, edge], yy === 0.016 ? 0.061 : 0.030, chrome);
        parts.pipe([[side * 0.995, 2.00, edge], [side * 0.99, 2.15, edge], [side * 1.017, 2.30, edge], [side * 1.14, 2.42, edge]], 0.016, chrome);
      }
      const routeHere = (k === 2 || ((k + (side > 0 ? 1 : 0)) % 3 === 0));
      const posterId = (k + (side > 0 ? 1 : 2)) % 4;
      const posterWidth = routeHere ? Math.min(2.75, len - 0.22) : Math.min(1.48, len - 0.38);
      const h = routeHere ? 0.28 : 0.37;
      const y = routeHere ? 2.051 : 2.07;
      parts.box(side * 1.536, y, z, 0.048, h + 0.058, posterWidth + 0.062, trim, routeHere ? 'map' : 'poster');
      parts.box(side * 1.505, y, z, 0.018, h + 0.024, posterWidth + 0.024, joint, routeHere ? 'map' : 'poster');
      const target = routeHere ? 'map' : 'poster';
      const regular = routeHere ? map : ads[posterId];
      addWallPane(parts, side, 1.493, y, z, posterWidth, h, regular, target);
    }

    for (const z of doorCenters) {
      const width = 1.48;
      parts.box(side * 1.602, 2.05, z, 0.09, 0.35, width, brushed);
      parts.box(side * 1.526, 1.965, z, 0.10, 0.05, width + 0.055, trim, 'doors');
      parts.box(side * 1.524, 2.21, z, 0.080, 0.182, 1.17, dark, 'doors');
      addWallPane(parts, side, 1.477, 2.21, z, 1.10, 0.121, led, 'doors');
      for (const d of [-1, 1]) {
        parts.box(side * 1.60, 0.973, z + d * 0.755, 0.134, 1.95, 0.046, brushed, 'doors');
        parts.box(side * 1.61, 0.018, z, 0.3, 0.028, width, trim, 'doors');
        // side < 0 is the platform after the mount (local -X -> world -Z). Static near leaves batch into the shell.
        const isPlatform = side < 0;
        const door = isPlatform ? new Parts() : parts;
        const center = d * 0.367;
        const cz = isPlatform ? center : z + center;
        const ww = 0.734;
        door.box(side * 1.587, 0.438, cz, 0.075, 0.876, ww, brushed, 'doors');
        door.box(side * 1.587, 1.845, cz, 0.075, 0.20, ww, brushed, 'doors');
        for (const e of [-1, 1]) door.box(side * 1.587, 1.31, cz + e * 0.298, 0.075, 0.88, 0.135, brushed, 'doors');
        for (const v of [-1, 1]) {
          door.box(side * 1.541, 1.305 + v * 0.44, cz, 0.032, 0.039, 0.508, rubber, 'doors');
          door.box(side * 1.541, 1.305, cz + v * 0.253, 0.032, 0.898, 0.039, rubber, 'doors');
        }
        addWallPane(door, side, 1.586, 1.31, cz, 0.478, 0.849, doorGlass, 'doors');
        door.box(side * 1.540, 0.969, cz - d * 0.358, 0.034, 1.91, 0.019, seal, 'doors');
        door.box(side * 1.542, 0.139, cz, 0.022, 0.264, 0.701, trim, 'doors');
        addWallPane(door, side, 1.542, 0.738, cz, 0.318, 0.047, stickers, 'doors');
        for (const e of [-1, 1]) door.box(side * 1.535, 0.713, cz + e * 0.168, 0.009, 0.009, 0.009, dark, 'doors');
        if (isPlatform) {
          const obj = door.batch();
          obj.position.z = z;
          root.add(obj);
          doors.push({ group: obj, dir: d, z, platformSide: true });
        }
      }
    }
    for (let k = 0; k < 15; k++) {
      const z = -10.67 + k * 1.52;
      if (Math.abs(z) > 11.6) continue;
      parts.rod([side * 0.982, 2.153, z], [side * 0.982, 2.045, z], 0.011, chrome);
      parts.pipe([[side * 0.984, 2.045, z], [side * 0.984, 2.008, z - 0.035], [side * 0.983, 1.950, z - 0.071], [side * 0.98, 1.915, z - 0.068], [side * 0.98, 1.892, z], [side * 0.98, 1.915, z + 0.068], [side * 0.983, 1.95, z + 0.071], [side * 0.984, 2.008, z + 0.035]], 0.012, shoe, undefined, true);
    }
  }

  // Gangway walk is ±0.38 m world Z and the swing door is 2 m tall. Both are world
  // metres, so the hole is sized after the shell's scale.
  const openingInner = 0.52 / WIDTH_SCALE;
  const openingTop = 2.08 / HEIGHT_SCALE;
  for (const far of [-1, 1] as const) {
    if (far === skipFar) continue;
    const z = far * 11.88;
    const ry = far === -1 ? 0 : Math.PI;
    // Side walls and a header only. A full-width slab here would sit in the gangway
    // the player already walks through (collision is ±0.38 m, not the mesh).
    for (const side of [-1, 1]) {
      const outer = 1.60;
      const panelW = outer - openingInner;
      const panelC = side * (openingInner + panelW / 2);
      parts.box(panelC, openingTop / 2, z, panelW, openingTop, 0.112, endMat);
    }
    const capH = 2.68 - openingTop;
    parts.box(0, openingTop + capH / 2, z, 3.22, capH, 0.112, endMat);
    for (const s of [-1, 1]) {
      parts.box(s * 1.01, 1.39, z - far * 0.073, 0.75, 0.91, 0.053, rubber);
      parts.box(s * 1.01, 1.39, z - far * 0.105, 0.68, 0.839, 0.035, darkGlass);
      parts.box(s * 0.93, 1.45, z - far * 0.139, 0.019, 0.83, 0.019, trim);
      parts.box(s * 1.01, 0.812, z - far * 0.064, 0.88, 0.054, 0.067, chrome);
      parts.face(s * 1.12, 2.03, z - far * 0.075, 0.35, 0.129, ry, fleet);
      for (let j = 0; j < 4; j++) parts.box(s * 1.02, 0.28 + j * 0.11, z - far * 0.061, 0.51, 0.014, 0.008, dark);
    }
    const post = (openingInner + 0.04);
    for (const side of [-1, 1]) {
      parts.box(side * post, 1.04, z - far * 0.072, 0.034, 2.08, 0.078, seal, 'doors');
    }
    if (!openGangway) {
      for (const side of [-1, 1]) {
        parts.box(side * 0.323, 1.043, z - far * 0.123, 0.132, 2.006, 0.033, brushed, 'doors');
        parts.box(side * 0.274, 1.474, z - far * 0.147, 0.034, 0.75, 0.028, rubber, 'doors');
      }
      parts.box(0, 0.58, z - far * 0.123, 0.761, 1.09, 0.033, brushed, 'doors');
      parts.box(0, 1.937, z - far * 0.123, 0.761, 0.215, 0.033, brushed, 'doors');
      for (const off of [-1, 1]) parts.box(0, 1.474 + off * 0.352, z - far * 0.147, 0.58, 0.044, 0.028, rubber, 'doors');
      parts.face(0, 1.474, z - far * 0.161, 0.515, 0.667, ry, throughGlass, 'doors');
      parts.box(0, 0.36, z - far * 0.154, 0.7, 0.58, 0.006, trim, 'doors');
      parts.face(0, 0.965, z - far * 0.15, 0.58, 0.072, ry, warning, 'doors');
      parts.rod([0.265, 0.76, z - far * 0.214], [0.265, 0.994, z - far * 0.214], 0.016, chrome, 'doors');
    }
    parts.face(-0.545, 1.81, z - far * 0.07, 0.132, 0.132, ry, greenBullet);
    parts.box(0, 2.50, z - far * 0.080, 1.59, 0.22, 0.13, dark);
    parts.face(0, 2.50, z - far * 0.153, 1.49, 0.16, ry, led, 'doors');
    parts.box(0, 2.500, z - far * 0.055, 2.09, 0.058, 0.052, trim);
  }

  root.add(parts.batch());
  shell.dispose();
  return {
    group: root,
    lenses,
    setDoors(doorFraction: number) {
      for (const door of doors) {
        door.group.position.z = door.z + (door.platformSide ? door.dir * DOOR_SLIDE_LOCAL * doorFraction : 0);
      }
    },
    dispose() {
      for (const m of [map, ...ads, stickers, fleet, warning, greenBullet, led]) releaseMaterial(m);
      lensGeo.dispose();
    },
  };
}
