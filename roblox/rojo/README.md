# Last Local (Roblox slice)

This folder is the Rojo project in this repository (`roblox/rojo/`).

A first Roblox port of [Last Local](https://github.com/PerfecHateyOu/Last-Local-Liminal-Space-Subway-), the liminal subway horror game. This slice is one G-train car: you walk the aisle, the conductor calls the real stops, and you hold Flag on the passenger who does not belong.

The car is built from Parts. People are your Blender models if you import them, and simple block figures if you do not. The game runs either way.

## Play it in Studio (no extra tools)

1. Install [Roblox Studio](https://create.roblox.com/) and sign in.
2. In Studio, choose **File → Open from File**.
3. Open `LastLocal.rbxlx` from this folder.
4. Press **Play** (or F5).
5. You start in the aisle.
   - **WASD** walks. The **mouse** looks. You cannot jump.
   - The amber line at the top is the conductor. The words are the ones from the web game.
   - Under the station card, the suspicion meter reads like **0 CALM** (then **25 UNEASY**, **50 WATCHED**, **75 HUNTED** as the number rises). The bar under it is the same 0–100 value. The server owns the number; the HUD only shows it.
   - After the doors close, put the dot in the middle of the screen on a person and **hold F** (or hold the **FLAG** button). The bar fills in about a second.
   - **Caught** means that person was the wrong one. **False flag:** plus their name means they were ordinary.
   - You cannot walk through a standing passenger. Seated people are on the benches, out of the aisle.
   - The car stays still. The tunnel slides past the windows: dark walls, rails, and lamps. It speeds up after the doors close and slows as the next platform arrives.
   - The platform stops at the doors. The signs use the station's real name. The view leans a little while you are moving, and it is still at a station.
6. Press **Stop** (Shift+F5) when you want to quit. Press Play again for a new ride.

The block people are the fallback. Import the FBX files below when you want your sculpts in the seats.

## Put your characters in the car

Studio's 3D Importer does not read `.glb`. The same models are in `assets/fbx/` as `.fbx`. Each file is one Model. The script looks for that Model by name in **ReplicatedStorage → Models**. If the name is wrong or the model is missing, that rider stays a block figure. The Output window lists which is which when you press Play.

1. Open `LastLocal.rbxlx` if it is not already open.
2. In the **Explorer** (the list of everything in the place, usually on the right), open **ReplicatedStorage**. There is already a folder named **Models**. It starts empty.
3. In the toolbar, open the **Avatar** tab and click **Import 3D**.
4. Choose one file from `assets/fbx`, for example `mom.fbx`.
5. In the preview, the figure should look roughly person-sized. If it is enormous, set the scale to **0.01** and look again. If it is tiny, set the scale to **100**. The game measures the mesh again at Play and fits a standing person to about 5 studs and a seated person a little shorter, so the preview only has to be in the right neighborhood.
6. Click **Import**.
7. Find the new model in the Explorer. It may land in **Workspace**. Click it once.
8. At the top of the **Properties** panel, set **Name** to the file name without `.fbx`. It must match exactly, including the underscores, and it is case-sensitive. `mom` is right. `Mom` is not found.
9. Drag that model onto **ReplicatedStorage → Models**.
10. Repeat for each file you want in the car. Press **Play** again.

If Import 3D drops a pile of loose parts instead of one model, select all of those parts, right-click, choose **Group**, and name the group.

If a person faces the wall instead of the aisle, select their model inside **Models** and add an attribute: click **Add Attribute**, name it `YawOffset`, type **number**, value **180**. Press Play again.

### Names this slice actually uses

Put the modeled car in as **`Car_B`**. If that model is missing, the Part-built car is used and the ride still runs. Door leaves, gangway doors, and `LightStrip_00` through `LightStrip_11` keep those names so the doors can slide and each tube can be driven on its own. A single tube may blink. The whole car still goes dark only on the door tick.

| Name in ReplicatedStorage.Models | What it is |
| --- | --- |
| `Car_B` | Bill's Car B interior. Also accepted as `car_B_interior`. |
| `prop_phone` | Mom and Dad's phone. Also `Prop_Phone`. |
| `prop_phone_texter` | The texter's phone. Also `Prop_PhoneTexter`. |
| `prop_tote_bag` | The coat woman's tote. Also `Prop_ToteBag`. |
| `prop_backpack` | Hoodie and texter backpack. Also `Prop_Backpack`. |
| `prop_newspaper_folded` | The standing office rider's paper. Also `Prop_Newspaper`. |
| `NPC_mom_seated`, `NPC_dad_seated`, `NPC_mta_seated`, `NPC_coat_seated`, `NPC_puffer`, `NPC_hoodie`, `NPC_texter_seated`, `NPC_overcoat_seated`, `NPC_office` | Characters from the blend. A seated rider tries the seated file first. The older names (`mom`, `dad`, `passenger_mta`, and the rest of the table below) still work. |



| Name in ReplicatedStorage.Models | Who |
| --- | --- |
| `mom` | Mom, seated |
| `dad` | Dad, seated next to her |
| `passenger_mta` | the man across the aisle |
| `passenger_coat` | the woman on your bench |
| `passenger_puffer` | the standing passenger |
| `anomaly_extra` | the extra person at the far end of the bench. This is the one Flag should catch. |
| `passenger_hoodie_standing` | standing, only on the rides into Flushing Av and Broadway |
| `passenger_texter_seated` | seated, those same two rides |
| `passenger_overcoat` | seated, those same two rides |
| `passenger_office_standing` | standing, those same two rides |

These files are converted and ready, and this slice does not place them: `passenger_hoodie_seated`, `passenger_texter_standing`, `passenger_office_seated`, `anomaly_faceless`, `anomaly_stretched`, `character_mom`, `character_dad`, `character_coat`, `character_mta`. Leave them out of **Models** for now.

`anomaly_faceless` and `anomaly_stretched` are real exports, but the source files are tiny (about 12 cm and 15 cm). They are not full bodies. The far-seat rider uses `anomaly_extra`, which is a full seated mesh, matching `manifest.json`.

## What you should see on a ride

The car does not roll, and you do not either. The tunnel and the platforms move past the windows. That is steadier than moving the car with you inside it.

You board at Hoyt–Schermerhorn, with that name on the platform signs. The first line is "This is the Last Local. Court Square–bound G train." Dad says to grab a seat. Then "Stand clear of the closing doors, please." and the doors close.

Between stations the line is "The next stop is …" with the signed station name. The ride uses the same three parts as that timer: a short speed-up, a steady run, then braking. On the way to Broadway the tunnel stops for a few seconds, one ceiling tube blinks, and the minute board reads 4 MIN until the train moves. On the way to Greenpoint Av it stops and the lamps dim, then come back. The whole car does not go dark. Tunnel walls, rail ties, and lamps stream toward the back of the car when the train is moving. Those lamps are only glowing parts outside. They do not dim or flicker the lights inside the car.

The next platform slides in from the front and stops lined up with the doors, signs showing that station's name. At a normal station the line is "This is …", the doors open, then "Stand clear of the closing doors, please." and you leave. When the doors open, a banner reads MINIMUM DWELL TIME and counts down. You watch it. You cannot close the doors or send the train off. While you are stopped, the view does not bob.

During a stretch, a board at the top right shows the next stop and a minute count. On the way to Flushing Av the announcement says "The next stop is Court Sq." On the way to Nassau Av the board shows 4 MIN. An amber plate appears on the wall for that tell. Hold F while looking at the plate. Caught means you flagged it while it was wrong.

Two arrivals are different, on purpose:

- **Classon Av** and **Metropolitan Av** are false stops. The doors open early. The lights do not blink. At Metropolitan Av the conductor says "This is Court Square. Last stop. Everybody off the train." That line is the lie from the web game.
- After Myrtle–Willoughby Avs, and again pulling into **21 St**, the whole car goes black for a fraction of a second and then the lights are back. That is the only blackout. Nothing else flickers.
- On the way to Court Sq the lamps dim in a straight line. Slow dimming is allowed. It is not a flicker.
- At Court Sq the line is "Court Square. This is the last stop on this train." Mom says "Here we are. Court Square." The doors stay open. The screen keeps **Caught** or **Missed**, and a line like "1 missed, 0 false flags."

Flag only counts while the doors are closed and you are between stations. Holding F at the platform does nothing. That matches the web game. At each stop the screen briefly shows Caught, Missed, False flag, or Clean. Suspicion starts at 0. A correct flag lowers it; a false alarm (flagging while nothing is wrong) raises it; a clean stop and a quiet miss each decay it a little. Reaching 100 does not end the ride. As the band rises, a passenger may glance when you walk, then heads turn toward you and one word of the conductor's line repeats. One ceiling tube may blink. Higher still, the lamps dim slowly. The whole car does not flicker. Design notes for what is still TBD (staring check, Psych Log, parent lines, ending variants) live in `SUSPICION.md`.

You stay on the train at every stop. Choosing to step off is not in this slice.

## Publish

1. **File → Publish to Roblox**.
2. Sign in if Studio asks.
3. Choose **Create new experience**.
4. Name it **Last Local**.
5. Click **Create**.

The place is then on your Roblox account. Open it from the Creator dashboard when you want to play it outside Studio.

## Use Rojo instead of the place file

Rojo copies the scripts in `src/` into Studio while you edit them. You still import the FBX files by hand. Meshes cannot live in the place file until Studio uploads them.

1. Install Rojo 7: [rojo.space/docs](https://rojo.space/docs/v7/getting-started/installation/).
2. In Studio's **Toolbox** or Creator Store, install the **Rojo** plugin, version 7.
3. Open a terminal in this folder and run `rojo serve`.
4. In Studio, **File → Open from File** and open `LastLocal.rbxlx`, or start from a baseplate.
5. **Plugins → Rojo → Connect** while Studio is in Edit mode, before you press Play. Rojo cannot connect during a playtest. If you try, Studio shows `Http requests can only be executed by game server`. Stop the playtest (Shift+F5), then Connect.
6. Import the FBX files into **ReplicatedStorage.Models** as above. Rojo is set to leave unknown things in that folder alone, so a sync should not delete them.
7. Press Play. You should be looking out of your own eyes, not at your avatar. The other people in the car are block figures until you import the FBX files. The Output window lists each one. The car is dim on purpose: warm pools under the ceiling lamps, the ends of the car darker.

If you change a script, Rojo updates Studio. Build a place file again with:

```bash
rojo build -o LastLocal.rbxlx
```

Check the scripts with selene, and with luau-lsp once you have Roblox's type file (the analyze command prints the path it expects):

```bash
selene src
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform roblox --sourcemap sourcemap.json --definitions tools/globalTypes.d.luau src
```

`tools/globalTypes.d.luau` is the definition file from [luau-lsp 1.70.1](https://github.com/JohnnyMorganz/luau-lsp/blob/1.70.1/scripts/globalTypes.d.luau). It is not in git. Download it to that path if you want to typecheck.

To rebuild the FBX files from `assets/glb/` (needs Blender on the PATH):

```bash
blender --background --python tools/convert_glb_to_fbx.py
```

## Triangle counts

Roblox's published MeshPart budget is **20,000 triangles per mesh** ([modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)). The Studio importer's hard ceiling is about 21,000. Counts below are Blender's triangulated meshes after import, which is what the FBX contains. Every mesh is under the cap. None were split or decimated.

| FBX | Meshes | Triangles | Largest mesh |
| --- | ---: | ---: | ---: |
| anomaly_extra.fbx | 10 | 1,380 | 424 |
| anomaly_faceless.fbx | 3 | 52 | 20 |
| anomaly_stretched.fbx | 3 | 96 | 32 |
| character_coat.fbx | 8 | 96 | 12 |
| character_dad.fbx | 10 | 120 | 12 |
| character_mom.fbx | 10 | 110 | 12 |
| character_mta.fbx | 9 | 108 | 12 |
| dad.fbx | 15 | 1,480 | 424 |
| mom.fbx | 14 | 1,432 | 424 |
| passenger_coat.fbx | 17 | 1,692 | 424 |
| passenger_hoodie_seated.fbx | 19 | 1,764 | 424 |
| passenger_hoodie_standing.fbx | 19 | 1,836 | 424 |
| passenger_mta.fbx | 16 | 1,620 | 424 |
| passenger_office_seated.fbx | 22 | 1,592 | 424 |
| passenger_office_standing.fbx | 24 | 1,640 | 424 |
| passenger_overcoat.fbx | 14 | 1,666 | 424 |
| passenger_puffer.fbx | 14 | 1,612 | 424 |
| passenger_texter_seated.fbx | 18 | 1,532 | 436 |
| passenger_texter_standing.fbx | 18 | 1,604 | 436 |

The full per-mesh list is `assets/triangle-counts.json`. Export was Blender 4.0.2, FBX, Y up, -Z forward, unit scale applied, textures embedded. Reimporting `mom.fbx` into Blender kept a 1.37 m up-axis, the same height as the GLB.

## Not in this version

Sound, cars A and C, stepping off, the parents' other lines, the Safe Haven, the trial, the camera, and the tape recorder. Suspicion scoring, bands, and the on-screen meter are in; staring detection, the Psych Log, parent-line changes by band, and band-based Court Square endings are not. The extra passenger is seated from the start, instead of appearing mid-ride. The open-air stretch over Newtown Creek is not in this version: every stop is still in the tunnel. Those are later slices.
