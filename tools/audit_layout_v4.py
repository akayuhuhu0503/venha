"""Read-only audit of supplied v4 JSON and GLB. Never executes its generator."""
from pathlib import Path
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "layout" / "room_v4"


def world(point):
    return (point[0], point[2], -point[1])


def main():
    data = json.loads((SOURCE / "7150_ROOM_LAYOUT_SOURCE.json").read_text(encoding="utf-8"))
    parts = data["parts"]
    dims = data["metadata"]["dimensions_m"]
    by_name = {part["name"]: part for part in parts}
    glb_bytes = (SOURCE / "7150_PHONG_TRO_LAYOUT_v4.glb").read_bytes()
    magic, version, length = struct.unpack_from("<4sII", glb_bytes)
    assert magic == b"glTF" and version == 2 and length == len(glb_bytes)
    chunk_length, chunk_type = struct.unpack_from("<II", glb_bytes, 12)
    assert chunk_type == 0x4E4F534A
    glb = json.loads(glb_bytes[20:20 + chunk_length])
    nodes = {node["name"]: node for node in glb["nodes"]}
    assert len(glb["meshes"]) == len(parts) == 189
    max_error = 0.0
    for index, part in enumerate(parts):
        node = nodes[f"{index:03d}_{part['group']}"]
        matrix = node["matrix"]
        point = part.get("center")
        if point is None:
            point = [(a + b) * 0.5 for a, b in zip(part["a"], part["b"])]
        expected = world(point)
        max_error = max(max_error, max(abs(a - b) for a, b in zip(matrix[12:15], expected)))
        # A second conversion or mirror on import must never be added.
        determinant = (
            matrix[0] * (matrix[5] * matrix[10] - matrix[9] * matrix[6])
            - matrix[4] * (matrix[1] * matrix[10] - matrix[9] * matrix[2])
            + matrix[8] * (matrix[1] * matrix[6] - matrix[5] * matrix[2])
        )
        assert abs(determinant - 1.0) < 1e-6
    assert max_error < 1e-6

    def box_bounds(name):
        part = by_name[name]
        return tuple((c - size / 2, c + size / 2) for c, size in zip(part["center"], part["size"]))

    entrance = box_bounds("01 Sàn cửa vào thụt trái")
    corridor = box_bounds("02 Sàn lối đi chính")
    pc = box_bounds("03 Sàn hốc PC bên phải")
    bath = box_bounds("Sàn WC nằm SAU vách hành lang")
    assert abs(pc[0][1] - corridor[0][0] - 3.75) < 1e-8
    assert abs(corridor[0][1] - corridor[0][0] - 1.54) < 1e-8
    assert abs(corridor[0][0] - entrance[0][0] - 0.47) < 1e-8
    assert abs(bath[0][0] - 1.54) < 1e-8
    assert all(part.get("center", part.get("a"))[0] >= 1.54 for part in parts if part["group"] == "bath")
    kitchen_clear = box_bounds("Mặt đá bếp")[0][0] - entrance[0][0]
    assert abs(kitchen_clear - 1.35) < 0.01
    assert dims["wc_intrusion_into_corridor_m"] == 0

    user_chair = world(by_name["Ghế PC tôi"]["center"])
    user_screen = world(by_name["Mặt hình AOC tôi"]["center"])
    duc_chair = world(by_name["Ghế PC Đức"]["center"])
    duc_screen = world(by_name["Mặt hiển thị Đức"]["center"])
    user_direction = tuple(b - a for a, b in zip(user_chair, user_screen))
    duc_direction = tuple(b - a for a, b in zip(duc_chair, duc_screen))
    assert user_direction[0] > 0.4 and abs(user_direction[2]) < 0.1
    assert duc_direction[2] > 0.4 and abs(duc_direction[0]) < 0.1

    loft_top = box_bounds("Mặt gỗ sàn gác")[2][1]
    last_tread_top = box_bounds("Bậc cầu thang 9")[2][1]
    left = by_name["Sống thang kim loại trái"]
    right = by_name["Sống thang kim loại phải"]
    bottom = [(a + b) / 2 for a, b in zip(left["a"], right["a"])]
    top = [(a + b) / 2 for a, b in zip(left["b"], right["b"])]
    stair_run = math.hypot(top[0] - bottom[0], top[1] - bottom[1])
    angle = math.degrees(math.atan2(top[2] - bottom[2], stair_run))
    print("PASS: 189 JSON parts and GLB node positions match world=(x,z,-y); max error", max_error)
    print("PASS: main width 3.75m; hall 1.54m; entrance inset .47m; WC starts x=1.54m")
    print(f"PASS: entrance-to-counter clearance {kitchen_clear:.5f}m; source measured value 1.35m")
    print("PASS: seated view directions user +X, Duc +Z in Godot")
    print(f"SOURCE LIMIT: loft finished top {loft_top:.4f}m; last tread {last_tread_top:.4f}m; gap {loft_top-last_tread_top:.4f}m")
    print(f"SOURCE LIMIT: stair run {stair_run:.4f}m; stringer slope {angle:.2f}deg; tread width .5158m")
    print(f"SOURCE LIMIT: shell wall top 2.62m is not a usable ceiling; proposed 4.15m leaves {4.15-loft_top:.4f}m above loft")
    print("Read-only audit; supplied build_room_v4.py was inspected, never executed.")


if __name__ == "__main__":
    main()
