#!/usr/bin/env python3
"""Convert Last Local character GLBs to FBX for the Roblox Studio 3D Importer.

Roblox's general mesh specification caps each MeshPart at 20,000 triangles
(https://create.roblox.com/docs/art/modeling/specifications). This script
counts triangles after Blender triangulates the mesh, splits a mesh by loose
parts if it is over the cap, and decimates any piece that is still over.

Run:
  blender --background --python tools/convert_glb_to_fbx.py
"""

from __future__ import annotations

import json
import os
import sys
import traceback

import bpy

LIMIT = 20000
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "assets", "glb")
OUT = os.path.join(ROOT, "assets", "fbx")
REPORT_PATH = os.path.join(ROOT, "assets", "triangle-counts.json")


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def enable_addons() -> None:
    import addon_utils

    addon_utils.enable("io_scene_gltf2", default_set=True, persistent=True)
    addon_utils.enable("io_scene_fbx", default_set=True, persistent=True)


def mesh_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def triangle_count(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def apply_modifiers_and_drop_rigs() -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in list(mesh_objects()):
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode="OBJECT")
        for mod in list(obj.modifiers):
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
            except RuntimeError as exc:
                print(f"  modifier {mod.name} on {obj.name} left in place: {exc}")
        obj.select_set(False)
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)


def apply_transforms() -> None:
    bpy.ops.object.select_all(action="SELECT")
    if not mesh_objects():
        return
    bpy.context.view_layer.objects.active = mesh_objects()[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def world_bbox():
    points = []
    for obj in mesh_objects():
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ __import__("mathutils").Vector(corner))
    if not points:
        return None
    xs = [p.x for p in points]
    ys = [p.y for p in points]
    zs = [p.z for p in points]
    return {
        "min": [min(xs), min(ys), min(zs)],
        "max": [max(xs), max(ys), max(zs)],
        "size": [max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)],
    }


def decimate_to_limit(obj) -> int:
    guard = 0
    count = triangle_count(obj)
    while count > LIMIT and guard < 6:
        ratio = max(0.01, (LIMIT * 0.97) / count)
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = ratio
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=mod.name)
        count = triangle_count(obj)
        guard += 1
    return count


def enforce_limit() -> tuple[str, list[dict]]:
    """Split over-budget meshes, then decimate anything still over the cap."""
    action = "none"
    over = [obj for obj in mesh_objects() if triangle_count(obj) > LIMIT]
    if over:
        action = "split"
        for obj in over:
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.separate(type="LOOSE")
            bpy.ops.object.mode_set(mode="OBJECT")

    pieces = []
    for obj in mesh_objects():
        before = triangle_count(obj)
        after = before
        piece_action = "none"
        if before > LIMIT:
            after = decimate_to_limit(obj)
            piece_action = "decimate"
            action = "split+decimate" if action == "split" else "decimate"
        pieces.append(
            {
                "name": obj.name,
                "triangles": after,
                "trianglesBefore": before,
                "action": piece_action,
            }
        )
    return action, pieces


def export_fbx(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        bake_anim=False,
        add_leaf_bones=False,
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
        object_types={"MESH"},
    )


def convert_one(filename: str) -> dict:
    src = os.path.join(SRC, filename)
    stem = os.path.splitext(filename)[0]
    dst = os.path.join(OUT, stem + ".fbx")
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=src)
    apply_modifiers_and_drop_rigs()
    apply_transforms()
    bounds = world_bbox()
    action, pieces = enforce_limit()
    total = sum(piece["triangles"] for piece in pieces)
    max_mesh = max((piece["triangles"] for piece in pieces), default=0)
    export_fbx(dst)
    over = [piece for piece in pieces if piece["triangles"] > LIMIT]
    return {
        "file": filename,
        "fbx": os.path.relpath(dst, ROOT),
        "modelName": stem,
        "blenderBoundsMeters": bounds,
        "meshes": pieces,
        "meshCount": len(pieces),
        "totalTriangles": total,
        "maxMeshTriangles": max_mesh,
        "limit": LIMIT,
        "overLimit": bool(over),
        "action": action,
        "bytes": os.path.getsize(dst),
    }


def main() -> int:
    enable_addons()
    os.makedirs(OUT, exist_ok=True)
    names = sorted(name for name in os.listdir(SRC) if name.lower().endswith(".glb"))
    report = {
        "limit": LIMIT,
        "limitSource": "https://create.roblox.com/docs/art/modeling/specifications",
        "note": (
            "Triangle counts are Blender loop triangles after import, which is the "
            "triangulated mesh the FBX contains. Each mesh must stay at or under "
            "20,000 triangles for a Roblox MeshPart. The hard render ceiling cited "
            "by the Studio importer is about 21,000; 20,000 is the published budget."
        ),
        "export": {
            "format": "FBX",
            "axisForward": "-Z",
            "axisUp": "Y",
            "applyScale": "FBX_SCALE_ALL",
            "applyUnitScale": True,
            "embedTextures": True,
            "tool": f"Blender {bpy.app.version_string}",
        },
        "models": [],
        "issues": [],
    }
    failed = False
    for name in names:
        print(f"converting {name}")
        try:
            entry = convert_one(name)
            report["models"].append(entry)
            print(
                f"  {entry['totalTriangles']} tris, "
                f"max mesh {entry['maxMeshTriangles']}, {entry['action']}"
            )
        except Exception as exc:  # noqa: BLE001 — report every file, keep going
            failed = True
            traceback.print_exc()
            report["issues"].append({"file": name, "error": str(exc)})
    with open(REPORT_PATH, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
    print(f"wrote {REPORT_PATH}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
