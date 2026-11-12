/**
 * Writes the place file and the three Luau scripts next to this folder.
 * Does not use the browser download helpers in robloxExporter.ts.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { generateRobloxPlaceRbxlx, ROBLOX_SCRIPTS } from './robloxExporter.ts';

const outDir = join(dirname(fileURLToPath(import.meta.url)), 'out');
mkdirSync(outDir, { recursive: true });

const place = join(outDir, 'LAST_LOCAL_Roblox.rbxlx');
writeFileSync(place, generateRobloxPlaceRbxlx());
console.log(place);

for (const script of ROBLOX_SCRIPTS) {
  const path = join(outDir, script.filename);
  writeFileSync(path, script.code);
  console.log(path);
}
