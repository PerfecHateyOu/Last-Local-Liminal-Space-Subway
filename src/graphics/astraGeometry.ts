/**
 * Astra remake geometry (last-local-remake-astra @ afe9e89, src/scene/geometry.ts),
 * remapped from that car's Z-long axis onto this game's X-long axis.
 *
 * A point (x, y, z) in Astra space lands at (z, y, -x) here: length runs along X,
 * and Astra's +X platform wall becomes our far wall (negative Z, the platform side).
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';

const cube = new THREE.BoxGeometry();
const panel = new THREE.PlaneGeometry();
const remap = new THREE.Matrix4().makeRotationY(Math.PI / 2);

type Point = [number, number, number];

/** Bake an Astra-space object into this game's axes. The mesh stays parented where it is. */
export function placeInMain(obj: THREE.Object3D) {
  obj.updateMatrix();
  remap.clone().multiply(obj.matrix).decompose(obj.position, obj.quaternion, obj.scale);
}

/**
 * A door leaf built in Astra space: spin the group onto our axis so sliding `position.x`
 * still opens it along the car, and the leaf's own offset rides along with it.
 */
export function placeDoor(group: THREE.Group) {
  const along = group.position.z;
  group.position.set(along, group.position.y, -group.position.x);
  group.rotation.set(0, Math.PI / 2, 0);
  group.scale.set(1, 1, 1);
}

export class Parts {
  group = new THREE.Group();

  mesh(geo: THREE.BufferGeometry, material: THREE.Material, x: number, y: number, z: number, target?: string) {
    const obj = new THREE.Mesh(geo, material);
    obj.position.set(x, y, z);
    if (target) obj.userData.target = target;
    this.group.add(obj);
    return obj;
  }

  box(x: number, y: number, z: number, w: number, h: number, d: number, mat: THREE.Material, target?: string) {
    const obj = this.mesh(cube, mat, x, y, z, target);
    obj.scale.set(w, h, d);
    return obj;
  }

  bevel(x: number, y: number, z: number, w: number, h: number, d: number, r: number, mat: THREE.Material, target?: string) {
    return this.mesh(new RoundedBoxGeometry(w, h, d, 2, r), mat, x, y, z, target);
  }

  face(x: number, y: number, z: number, w: number, h: number, ry: number, mat: THREE.Material, target?: string) {
    const obj = this.mesh(panel, mat, x, y, z, target);
    obj.scale.set(w, h, 1);
    obj.rotation.y = ry;
    return obj;
  }

  rod(a: Point, b: Point, r: number, mat: THREE.Material, target?: string, sides = 6) {
    const p = new THREE.Vector3(...a);
    const q = new THREE.Vector3(...b);
    const delta = q.clone().sub(p);
    const center = p.add(q).multiplyScalar(0.5);
    const geo = new THREE.CylinderGeometry(r, r, delta.length(), sides, 1, true);
    const obj = this.mesh(geo, mat, center.x, center.y, center.z, target);
    obj.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), delta.normalize());
    return obj;
  }

  pipe(points: Point[], r: number, mat: THREE.Material, target?: string, closed = false) {
    const curve = new THREE.CatmullRomCurve3(
      points.map((p) => new THREE.Vector3(...p)),
      closed,
      'centripetal'
    );
    const tubular = closed ? points.length : Math.max(6, points.length * 2);
    return this.mesh(new THREE.TubeGeometry(curve, tubular, r, 5, closed), mat, 0, 0, 0, target);
  }

  /**
   * Merge by material. `bakeAxis` writes this game's X-long axis into the geometry, for a group
   * that stays unrotated. Door leaves pass false and are turned by placeDoor instead, so sliding
   * the group doesn't get the axis swap twice.
   */
  batch(bakeAxis = true) {
    const bins = new Map<string, { material: THREE.Material; geometries: THREE.BufferGeometry[] }>();
    for (const child of this.group.children) {
      if (!(child instanceof THREE.Mesh)) continue;
      const mat = child.material as THREE.Material;
      const key = mat.uuid;
      if (!bins.has(key)) bins.set(key, { material: mat, geometries: [] });
      child.updateMatrix();
      const geo = child.geometry.index ? child.geometry.toNonIndexed() : child.geometry.clone();
      geo.applyMatrix4(child.matrix);
      if (bakeAxis) geo.applyMatrix4(remap);
      for (const attr of Object.keys(geo.attributes)) {
        if (attr !== 'position' && attr !== 'normal' && attr !== 'uv') geo.deleteAttribute(attr);
      }
      bins.get(key)!.geometries.push(geo);
    }
    this.group.clear();
    for (const data of bins.values()) {
      const geo = mergeGeometries(data.geometries, false);
      if (!geo) throw new Error('Incompatible subway geometry');
      const mesh = new THREE.Mesh(geo, data.material);
      this.group.add(mesh);
      data.geometries.forEach((g) => g.dispose());
    }
    return this.group;
  }
}

export function standard(color: THREE.ColorRepresentation, metalness = 0, roughness = 0.64) {
  if (metalness < 0.5 && roughness >= 0.45) {
    return new THREE.MeshLambertMaterial({ color });
  }
  return new THREE.MeshPhongMaterial({
    color,
    shininess: Math.round((1 - roughness) * 85 + 15),
    specular: metalness >= 0.6 ? 0x8a8c86 : 0x3c3a35,
  });
}

/** Scooped fiberglass seat shell from Astra's seatShell(), simplified for software WebGL. */
export function seatShell() {
  const contours = [
    [0.08, 1.01], [0.105, 1.025], [0.133, 0.99], [0.137, 0.856], [0.157, 0.692],
    [0.202, 0.569], [0.302, 0.487], [0.432, 0.47], [0.498, 0.476], [0.548, 0.482],
    [0.572, 0.463], [0.574, 0.431], [0.556, 0.409], [0.399, 0.4], [0.11, 0.525], [0.054, 0.975], [0.08, 1.01],
  ];
  const n = 8;
  const p: number[] = [];
  const idx: number[] = [];
  const uv: number[] = [];
  for (let j = 0; j < contours.length; j++) {
    const [d, h] = contours[j];
    for (let i = 0; i <= n; i++) {
      const v = (i / n) * 2 - 1;
      const lip = Math.pow(Math.abs(v), 2.4);
      const sideHeight = lip * (j < 9 ? 0.041 : 0.023);
      p.push(d + lip * (j < 5 ? 0.075 : 0.014), h + sideHeight, 0.231 * v);
      uv.push(i / n, j / (contours.length - 1));
    }
    if (j > 0) {
      for (let i = 0; i < n; i++) {
        const a = (j - 1) * (n + 1) + i;
        const b = a + n + 1;
        idx.push(a, a + 1, b, a + 1, b + 1, b);
      }
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(p, 3));
  g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

/** Sheet-metal trim and a radiused rubber gasket around a window. */
export function windowGasket(w: number, h: number, thickness: number, radius: number) {
  const round = (path: THREE.Path, width: number, height: number, r: number) => {
    const a = width / 2;
    const b = height / 2;
    path.moveTo(-a + r, -b);
    path.lineTo(a - r, -b);
    path.quadraticCurveTo(a, -b, a, -b + r);
    path.lineTo(a, b - r);
    path.quadraticCurveTo(a, b, a - r, b);
    path.lineTo(-a + r, b);
    path.quadraticCurveTo(-a, b, -a, b - r);
    path.lineTo(-a, -b + r);
    path.quadraticCurveTo(-a, -b, -a + r, -b);
  };
  const shape = new THREE.Shape();
  const hole = new THREE.Path();
  round(shape, w, h, radius);
  round(hole, w - 2 * thickness, h - 2 * thickness, Math.max(0.015, radius - thickness));
  shape.holes.push(hole);
  return new THREE.ShapeGeometry(shape, 2);
}
