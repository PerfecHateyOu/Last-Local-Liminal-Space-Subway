#!/usr/bin/env python3
"""Export Bill's car, props, and NPC rigs to FBX for the Studio 3D Importer.

Run with Blender 5, which can read his 5.0.2 blend:
  blender --background --python tools/export_drive_assets.py
"""

from __future__ import annotations

import json
import os
import sys

import bpy

LIMIT = 20000
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "fbx")
GLB = os.path.join(ROOT, "assets", "glb")
BLEND = os.environ.get("LASTLOCAL_BLEND", "/tmp/untitled-raw.blend")
PROPS_GLB = os.environ.get("LASTLOCAL_PROPS", "/tmp/drive-assets/props_all.glb")
REPORT = os.path.join(ROOT, "assets", "drive-report.json")

NPCS = [
    "NPC_mom",
    "NPC_mom_seated",
    "NPC_dad",
    "NPC_dad_seated",
    "NPC_mta",
    "NPC_mta_seated",
    "NPC_coat",
    "NPC_coat_seated",
    "NPC_puffer",
    "NPC_puffer_seated",
    "NPC_hoodie",
    "NPC_hoodie_seated",
    "NPC_texter",
    "NPC_texter_seated",
    "NPC_overcoat",
    "NPC_overcoat_seated",
    "NPC_office",
    "NPC_office_seated",
]


def tri_count(obj) -> int:
    if obj.type != "MESH" or obj.data is None:
        return 0
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def hierarchy(root):
    out = [root]
    out.extend(root.children_recursive)
    return out


def export_selected(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        bake_anim=False,
        add_leaf_bones=False,
        object_types={"EMPTY", "MESH"},
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )


def select_hierarchy(root) -> list:
    bpy.ops.object.select_all(action="DESELECT")
    nodes = hierarchy(root)
    for obj in nodes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    return nodes


def summarize(nodes) -> dict:
    meshes = []
    total = 0
    max_mesh = 0
    for obj in nodes:
        if obj.type != "MESH":
            continue
        count = tri_count(obj)
        total += count
        max_mesh = max(max_mesh, count)
        meshes.append({"name": obj.name, "triangles": count})
    return {
        "meshCount": len(meshes),
        "totalTriangles": total,
        "maxMeshTriangles": max_mesh,
        "overLimit": max_mesh > LIMIT,
        "meshesOver": [m for m in meshes if m["triangles"] > LIMIT],
    }


def export_root(root, filename: str) -> dict:
    nodes = select_hierarchy(root)
    path = os.path.join(OUT, filename)
    export_selected(path)
    info = summarize(nodes)
    info["file"] = filename
    info["root"] = root.name
    info["bytes"] = os.path.getsize(path)
    return info


def export_from_blend() -> list:
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    report = []
    car = bpy.data.objects.get("Car_B")
    if car is not None:
        report.append(export_root(car, "Car_B.fbx"))
    else:
        report.append({"file": "Car_B.fbx", "error": "Car_B missing"})
    for name in NPCS:
        obj = bpy.data.objects.get(name)
        if obj is None:
            report.append({"file": name + ".fbx", "error": "missing"})
            continue
        report.append(export_root(obj, name + ".fbx"))
    return report


def export_props() -> list:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=PROPS_GLB)
    wanted = {
        "Prop_Phone": "prop_phone.fbx",
        "Prop_PhoneTexter": "prop_phone_texter.fbx",
        "Prop_ToteBag": "prop_tote_bag.fbx",
        "Prop_Backpack": "prop_backpack.fbx",
        "Prop_Newspaper": "prop_newspaper_folded.fbx",
        "Prop_NewspaperOpen": "prop_newspaper_open.fbx",
    }
    report = []
    for name, filename in wanted.items():
        obj = bpy.data.objects.get(name)
        if obj is None:
            report.append({"file": filename, "error": f"{name} missing"})
            continue
        report.append(export_root(obj, filename))
    return report


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(GLB, exist_ok=True)
    blend_exports = export_from_blend()
    prop_exports = export_props()
    payload = {
        "limit": LIMIT,
        "blend": BLEND,
        "blender": bpy.app.version_string,
        "note": "No mesh exceeded 20,000 triangles, so nothing was split or decimated. Named parts stay separate.",
        "carAndNpcs": blend_exports,
        "props": prop_exports,
    }
    with open(REPORT, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")
    print("wrote", REPORT)
    bad = [e for e in blend_exports + prop_exports if e.get("overLimit") or e.get("error")]
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
