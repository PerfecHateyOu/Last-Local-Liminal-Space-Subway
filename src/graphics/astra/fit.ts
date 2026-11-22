/**
 * Fit Astra's R160 shell into the original car envelope.
 *
 * Astra builds one car with length along local Z (23.8 m), width along local X
 * (3.32 m) and the ceiling at local Y 2.68. The original ride is length along
 * world X (18 m), width along world Z (3.06 m), ceiling at Y 2.43, travel toward
 * -X, and the platform on -Z.
 *
 * Mount: scale in local space, then rotation.y = -π/2.
 *   world x = -localZ * LENGTH_SCALE
 *   world y =  localY * HEIGHT_SCALE
 *   world z =  localX * WIDTH_SCALE
 * So local -X (Astra's side < 0) lands on world -Z, the platform side.
 */
import * as THREE from 'three';

export const ASTRA_LENGTH = 23.8;
export const ASTRA_WIDTH = 3.32;
export const ASTRA_CEILING_Y = 2.68;

export const CAR_LENGTH = 18;
export const CAR_WIDTH = 3.06;
export const CAR_CEILING_Y = 2.43;

export const LENGTH_SCALE = CAR_LENGTH / ASTRA_LENGTH;
export const WIDTH_SCALE = CAR_WIDTH / ASTRA_WIDTH;
export const HEIGHT_SCALE = CAR_CEILING_Y / ASTRA_CEILING_Y;

/** Leaf travel in Astra's local metres. World travel is this times LENGTH_SCALE. */
export const DOOR_SLIDE_LOCAL = 0.685;

/** rotation.y that sends Astra local +Z onto world -X (the direction of travel). */
export const MOUNT_YAW = -Math.PI / 2;

const _along = new THREE.Vector3();

export function mountAstraShell(group: THREE.Object3D, centerX: number) {
  group.rotation.set(0, MOUNT_YAW, 0);
  group.scale.set(WIDTH_SCALE, HEIGHT_SCALE, LENGTH_SCALE);
  group.position.set(centerX, 0, 0);
  group.updateMatrix();
}

/** World X along the consist. The car does not scroll; the tunnel does. */
export function alongCarX(obj: THREE.Object3D): number {
  obj.getWorldPosition(_along);
  return _along.x;
}
