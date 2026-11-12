# TypeScript Roblox exporter

This folder is the in-browser exporter from the deleted repository `PerfecHateyOu/ROBLOX-LL-EXPORT`, commit `62381425a7ac912f4c2fa547c189287ecdc1dd51`, file `src/roblox/robloxExporter.ts`. It is a separate track from the Rojo project in [`../rojo/`](../rojo/).

`robloxExporter.ts` has no imports. It does not read the web game's source.

- `generateRobloxPlaceRbxlx()` returns a Part-based Roblox place file, `LAST_LOCAL_Roblox.rbxlx`.
- `ROBLOX_SCRIPTS` holds three standalone Luau sources: `LastLocalConfig.luau`, `LastLocalServer.server.luau`, and `LastLocalClient.client.luau`.

## Write the files

From this folder, with Node 22:

```bash
node --experimental-strip-types write-exports.mts
```

That writes `out/LAST_LOCAL_Roblox.rbxlx` and the three `.luau` files. In Roblox Studio, choose **File → Open from File** and open the `.rbxlx`.

`downloadTextFile` and `downloadBinaryFile` are the browser download helpers from the old web UI. They need `document`. The Node script does not call them.

## What was not copied

In the deleted repo, `src/components/RobloxExportModal.tsx` called this exporter from the web game and also loaded `src/dev/glbExport.ts` for procedural `.glb` downloads. That modal and the GLB exporter belong to the web game. They are not part of this folder, and this folder is not wired into the web game's `src/` tree, `package.json`, build, or CI.

Procedural `.glb` export in this repository is still `bun run export:glb` from the repo root.
