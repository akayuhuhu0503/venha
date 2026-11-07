# Tài sản và nguồn — Room v0.5

- **Bộ v4, GLB/JSON/HTML/ảnh và generator gốc**: người dùng cung cấp trong `7150_PHONG_3D_SUA_LOI_DI_WC_v4.zip`; bản nguyên trạng ở `layout/room_v4/`, SHA256 trong `SOURCE_ARCHIVE.json`. Không gán CC0 cho dữ liệu người dùng.
- **9 ảnh `reference/room_v4_embedded/`**: trích nguyên bytes JPEG từ HTML của bộ v4, giữ độ phân giải nhúng. Ảnh hiện trạng dùng để đối chiếu. 5 ảnh phòng mẫu trong bộ v2 không được dùng để suy ra kiến trúc. Ảnh không được dùng làm texture hay đưa vào bản game xuất.
- **Mesh nội thất/kiến trúc mới**: tạo trong `scripts/furniture/`, `scripts/environment/`, `scripts/geometry.gd`. Không tải asset bên ngoài. Phần tài sản mới do project tạo cung cấp theo CC0-1.0: https://creativecommons.org/publicdomain/zero/1.0/ .
- **PBR**: 9 bộ, 32 PNG gồm albedo, normal OpenGL, roughness, một số AO và hình desktop; tạo bằng `tools/generate_pbr.py`. Xem `textures/LICENSE.md` và `textures/pbr/manifest.json` cho kích thước, chu kỳ theo mét và nguồn. Không lấy pixel từ ảnh phòng. Không có lightmap hoặc room AO bake.
- **10 WAV**: âm thanh tổng hợp CC0, không phải bản thu thực địa Hà Nội; xem `audio/LICENSE.md` và `tools/generate_audio.py`.
- **Godot 4.7.2 stable**: MIT; binary/template từ bản phát hành chính thức, nguồn/hash tại `tools/godot_sources.json`, giấy phép `tools/godot/LICENSE.txt`.

Ảnh bảng ghim và một số vật nhỏ vẫn là đồ họa minh họa, không phải ảnh cá nhân được tái tạo.
