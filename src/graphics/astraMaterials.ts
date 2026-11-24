/**
 * Canvas materials from the Astra remake (last-local-remake-astra @ afe9e89, src/scene/materials.ts).
 * Generated in the page, so the itch build stays self-contained.
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

let cachedFloorTex: THREE.CanvasTexture | null = null;
let cachedBrushedTex: THREE.CanvasTexture | null = null;
let cachedGlassTex: THREE.CanvasTexture | null = null;

export function floorMaterial() {
  if (!cachedFloorTex) {
    cachedFloorTex = canvas(256, 256, (c) => {
      const size = 256;
      const rnd = noise(64819);
      const img = typeof c.createImageData === 'function' ? c.createImageData(size, size) : null;
      if (img) {
        const d = img.data;
        for (let i = 0; i < d.length; i += 4) {
          d[i] = 99;
          d[i + 1] = 99;
          d[i + 2] = 99;
          d[i + 3] = 255;
        }
        // Speckled transit terrazzo pattern via direct pixel writes (~2ms vs 56k fillRects).
        for (let i = 0; i < 14000; i++) {
          const w = rnd() > 0.55 ? 2 : 1;
          const h = rnd() > 0.6 ? 2 : 1;
          const shade = Math.round(43 + rnd() * 109);
          const x0 = Math.floor(rnd() * (size - w));
          const y0 = Math.floor(rnd() * (size - h));
          for (let dy = 0; dy < h; dy++) {
            for (let dx = 0; dx < w; dx++) {
              const p = ((y0 + dy) * size + (x0 + dx)) * 4;
              d[p] = shade;
              d[p + 1] = shade;
              d[p + 2] = Math.max(0, shade - 2);
            }
          }
        }
        c.putImageData(img, 0, 0);
      } else {
        c.fillStyle = '#636363';
        c.fillRect(0, 0, size, size);
      }
      c.strokeStyle = 'rgba(38,37,35,.44)';
      c.lineWidth = 1;
      c.strokeRect(0.5, 0.5, size - 1, size - 1);
    });
    cachedFloorTex.wrapS = cachedFloorTex.wrapT = THREE.RepeatWrapping;
    cachedFloorTex.repeat.set(4, 29);
  }
  return new THREE.MeshLambertMaterial({ map: cachedFloorTex });
}

export function brushedMaterial(color: THREE.ColorRepresentation, strength = 0.72) {
  if (!cachedBrushedTex) {
    cachedBrushedTex = canvas(256, 256, (c) => {
      c.fillStyle = '#e1e1df';
      c.fillRect(0, 0, 256, 256);
      const rnd = noise(719);
      for (let i = 0; i < 750; i++) {
        c.fillStyle = rnd() > 0.4 ? 'rgba(255,255,255,.22)' : 'rgba(23,25,23,.11)';
        c.fillRect(rnd() * 256, rnd() * 256, 4 + rnd() * 110, 0.5 + rnd() * 0.8);
      }
    });
  }
  return new THREE.MeshPhongMaterial({
    color,
    map: cachedBrushedTex,
    shininess: Math.round(35 + strength * 40),
    specular: 0x62645e,
  });
}

export function signTexture(width: number, height: number, fn: (c: CanvasRenderingContext2D) => void) {
  return new THREE.MeshBasicMaterial({ map: canvas(width, height, fn), toneMapped: true });
}

interface LedSignEntry {
  tex: THREE.CanvasTexture;
  ctx: CanvasRenderingContext2D;
  text: string;
}

const ledRegistry: LedSignEntry[] = [];

export function paintLedSign(c: CanvasRenderingContext2D, text: string) {
  c.fillStyle = '#14170f';
  c.fillRect(0, 0, 672, 74);
  c.textBaseline = 'middle';
  c.font = '900 58px Arial, sans-serif';
  c.fillStyle = '#ffc060';
  c.shadowColor = '#ffab40';
  c.shadowBlur = 2;
  const msg = text.toUpperCase();
  const w = c.measureText(msg).width;
  const scale = w > 0 ? Math.min(1, 644 / w) : 1;
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
}

export function ledSign(text: string) {
  const mat = signTexture(672, 74, (c) => paintLedSign(c, text));
  const tex = mat.map as THREE.CanvasTexture;
  const ctx = (tex.image as HTMLCanvasElement).getContext('2d')!;
  ledRegistry.push({ tex, ctx, text });
  return mat;
}

export function setLedSignText(text: string) {
  for (const entry of ledRegistry) {
    if (entry.text === text) continue;
    paintLedSign(entry.ctx, text);
    entry.text = text;
    entry.tex.needsUpdate = true;
  }
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
  if (!cachedGlassTex) {
    cachedGlassTex = canvas(256, 128, (c) => {
      const surface = c.createLinearGradient(0, 0, 0, 128);
      surface.addColorStop(0, 'rgba(177,192,176,.15)');
      surface.addColorStop(0.5, 'rgba(58,76,68,.12)');
      surface.addColorStop(1, 'rgba(168,133,91,.18)');
      c.fillStyle = surface;
      c.fillRect(0, 0, 256, 128);
      for (const [y, w, opacity] of [[5, 4, 0.16], [9, 1.5, 0.12], [41, 2, 0.1], [60, 1.5, 0.08]] as const) {
        c.lineWidth = w;
        c.strokeStyle = 'rgba(215,222,207,' + opacity + ')';
        c.beginPath();
        c.moveTo(0, y);
        c.lineTo(256, y + 4.5);
        c.stroke();
      }
      const rnd = noise(6715);
      for (let i = 0; i < 200; i++) {
        c.fillStyle = 'rgba(201,203,183,' + rnd() * 0.1 + ')';
        c.fillRect(rnd() * 256, rnd() * 128, 0.5 + rnd() * 1.0, 0.5 + rnd() * 1.0);
      }
    });
  }
  return new THREE.MeshBasicMaterial({
    map: cachedGlassTex,
    color: '#bdc7bb',
    transparent: true,
    opacity: 0.72,
    depthWrite: false,
    side: THREE.DoubleSide,
  });
}
