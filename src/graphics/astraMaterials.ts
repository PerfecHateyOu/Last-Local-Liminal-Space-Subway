/**
 * Canvas materials from the Astra remake (last-local-remake-astra @ afe9e89, src/scene/materials.ts).
 * Generated in the page, so the itch build stays self-contained. The env map is attached per
 * material; it is not assigned to the scene, so cars A and C and the characters are unchanged.
 */
import * as THREE from 'three';

function canvas(width: number, height: number, paint: (c: CanvasRenderingContext2D) => void) {
  const surface = document.createElement('canvas');
  surface.width = width;
  surface.height = height;
  const c = surface.getContext('2d')!;
  paint(c);
  const texture = new THREE.CanvasTexture(surface);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

function noise(seed: number) {
  return () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}

export function environmentMap() {
  const tex = canvas(768, 384, (c) => {
    const grad = c.createLinearGradient(0, 0, 0, 384);
    for (const [p, col] of [
      [0, '#b9bcb7'], [0.2, '#e6e7d8'], [0.32, '#958f7e'], [0.42, '#686556'], [0.48, '#252b2c'],
      [0.51, '#88877b'], [0.56, '#373d3c'], [0.68, '#c48c45'], [0.72, '#55524a'], [1, '#30352f'],
    ] as const) grad.addColorStop(p, col);
    c.fillStyle = grad;
    c.fillRect(0, 0, 768, 384);
    for (let i = 0; i < 8; i++) {
      c.fillStyle = '#fafbec';
      c.fillRect(i * 96 + 6, 83, 78, 10);
      c.fillStyle = '#e5e8df';
      c.fillRect(i * 96 + 8, 97, 73, 3);
      c.fillStyle = '#1d2626';
      c.fillRect(i * 96 + 8, 154, 70, 44);
      c.fillStyle = '#b7b6a8';
      c.fillRect(i * 96 + 80, 122, 5, 114);
    }
  });
  tex.mapping = THREE.EquirectangularReflectionMapping;
  return tex;
}

let env: THREE.Texture | null = null;
function envMap() {
  return (env ??= environmentMap());
}

export function floorMaterial() {
  const tex = canvas(512, 512, (c) => {
    c.fillStyle = '#636363';
    c.fillRect(0, 0, 512, 512);
    const rnd = noise(64819);
    for (let i = 0; i < 56000; i++) {
      const size = 0.5 + rnd() * 2.4;
      const shade = Math.round(43 + rnd() * 109);
      c.fillStyle = 'rgb(' + shade + ',' + shade + ',' + (shade - 2) + ')';
      c.fillRect(rnd() * 512, rnd() * 512, size, size * (0.4 + rnd()));
    }
    c.strokeStyle = 'rgba(38,37,35,.44)';
    c.lineWidth = 1;
    c.strokeRect(0.3, 0.3, 511.5, 511.5);
  });
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(4, 29);
  return new THREE.MeshStandardMaterial({ map: tex, metalness: 0.16, roughness: 0.43, envMap: envMap(), envMapIntensity: 0.42 });
}

export function brushedMaterial(color: THREE.ColorRepresentation, strength = 0.72) {
  const tex = canvas(256, 256, (c) => {
    c.fillStyle = '#e1e1df';
    c.fillRect(0, 0, 256, 256);
    const rnd = noise(719);
    for (let i = 0; i < 4100; i++) {
      c.fillStyle = rnd() > 0.4 ? 'rgba(255,255,255,.17)' : 'rgba(23,25,23,.08)';
      c.fillRect(rnd() * 256, rnd() * 256, 2 + rnd() * 110, 0.2 + rnd() * 0.4);
    }
  });
  return new THREE.MeshStandardMaterial({
    color, map: tex, metalness: strength, roughness: 0.31, envMap: envMap(), envMapIntensity: 0.8,
  });
}

export function signTexture(width: number, height: number, fn: (c: CanvasRenderingContext2D) => void) {
  return new THREE.MeshBasicMaterial({ map: canvas(width, height, fn), toneMapped: true });
}

export function ledSign(text: string) {
  return signTexture(672, 74, (c) => {
    c.fillStyle = '#14170f';
    c.fillRect(0, 0, 672, 74);
    c.textBaseline = 'middle';
    c.font = '900 58px Arial, sans-serif';
    c.fillStyle = '#ffc060';
    c.shadowColor = '#ffab40';
    c.shadowBlur = 2;
    const msg = text.toUpperCase();
    const scale = Math.min(1, 644 / c.measureText(msg).width);
    c.save();
    c.translate(336, 38);
    c.scale(scale, 1);
    c.textAlign = 'center';
    c.fillText(msg, 0, 0);
    c.restore();
    c.shadowBlur = 0;
    c.fillStyle = 'rgba(19,19,10,.34)';
    for (let x = 0; x < 672; x += 4) c.fillRect(x, 0, 1, 74);
    for (let y = 0; y < 74; y += 4) c.fillRect(0, y, 672, 1);
  });
}

export function label(text: string, bg: string, fg: string, width = 512, height = 96) {
  return signTexture(width, height, (c) => {
    c.fillStyle = bg;
    c.fillRect(0, 0, width, height);
    c.font = 'bold ' + Math.floor(height * 0.65) + 'px Arial';
    c.textBaseline = 'middle';
    c.textAlign = 'center';
    c.fillStyle = fg;
    c.fillText(text, width / 2, height * 0.52, width * 0.94);
  });
}

export function glassMaterial() {
  const texture = canvas(512, 256, (c) => {
    const surface = c.createLinearGradient(0, 0, 0, 256);
    surface.addColorStop(0, 'rgba(177,192,176,.13)');
    surface.addColorStop(0.5, 'rgba(58,76,68,.10)');
    surface.addColorStop(1, 'rgba(168,133,91,.17)');
    c.fillStyle = surface;
    c.fillRect(0, 0, 512, 256);
    c.save();
    c.filter = 'blur(2px)';
    for (const [y, w, opacity] of [[10, 5, 0.24], [18, 1, 0.15], [82, 2, 0.12], [119, 1, 0.1]] as const) {
      c.lineWidth = w;
      c.strokeStyle = 'rgba(215,222,207,' + opacity + ')';
      c.beginPath();
      c.moveTo(0, y);
      c.lineTo(512, y + 9);
      c.stroke();
    }
    c.restore();
    const rnd = noise(6715);
    for (let i = 0; i < 1100; i++) {
      c.fillStyle = 'rgba(201,203,183,' + rnd() * 0.1 + ')';
      c.fillRect(rnd() * 512, rnd() * 256, 0.4 + rnd() * 0.85, 0.3 + rnd() * 1.2);
    }
  });
  return new THREE.MeshStandardMaterial({
    map: texture, color: '#bdc7bb', transparent: true, metalness: 0.69, roughness: 0.17,
    envMap: envMap(), envMapIntensity: 1.08, depthWrite: false, side: THREE.DoubleSide,
  });
}
