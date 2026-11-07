# 7:50 — Về nhà · Room v0.5

Godot 4.7.2 / Windows x64. Phòng được dựng lại theo mặt bằng, tọa độ v4 và ảnh hiện trạng; 5 ảnh phòng mẫu cũ chỉ tham khảo vật liệu.

## Chạy

**Nếu vừa clone từ GitHub:** cài Python 3.10+ rồi chạy `python tools/setup_godot.py` để tải Godot và Windows export templates, sau đó mở `Mo_Project_Godot.cmd` và nhấn F5. Cũng có thể mở `project.godot` bằng Godot 4.7.2 đã cài. Repository không chứa engine, bản `.exe`, backup hoặc ảnh tham chiếu riêng; các texture/audio cần chạy game đã được đưa vào Git. Bộ GLB/JSON v4 và generator có sẵn; ZIP/HTML chứa ảnh và các bản sao lưu chỉ giữ ở máy gốc.

- Nhấp đúp **Choi_VeNha.cmd**. Bản độc lập ở **build/VeNha.exe**, cần giữ **VeNha.pck** bên cạnh.
- **Mo_Project_Godot.cmd** mở project; F5 chạy game. Godot portable đã có trong `tools/godot/`.
- WASD di chuyển, chuột nhìn, Shift chạy, Ctrl ngồi, E tương tác, Esc đóng PC/tạm dừng, F6 đổi ngày/đêm. Menu Esc có độ nhạy chuột và FOV 75–85°; mặc định 80°.

Đi dọc hành lang rồi rẽ phải vào khu PC. Cầu thang gần cửa ban công đi lên từ trái sang phải; lên tới chiếu nghỉ thì rẽ về phía chân giường. Dùng Ctrl khi bước lên đệm dưới trần gác thấp. Đứng ngoài vùng quét của cánh cửa để mở/đóng. Nhìn màn hình PC, bể cá, công tắc, bát Bống hoặc đệm để dùng E.

## Đã thay đổi

- Giữ đường bao chữ L, cửa/cửa sổ, nhánh PC, vị trí nội thất v4; WC nằm ngoài hành lang. Khoảng từ tường lõm đến mép mặt bếp khoảng 1,354 m.
- Nội thất có cánh/tay nắm, cạnh bo, chậu rửa rỗng, máy giặt cửa tròn, ghế lưới, case RGB, bể cá, quần áo và chăn có nếp. 9 bộ PBR dùng UV theo mét, normal/roughness và AO nhẹ nơi phù hợp.
- Ánh sáng ngày/đêm và ba công tắc riêng; giữ controller, UI PC, quan sát bể cá, Bống và gấp chăn. Dốc va chạm ẩn phục vụ cầu thang dốc của v4; bước qua bát/ổ thấp có kiểm tra va chạm, không cần nhảy.

## Dữ liệu và giới hạn

- ZIP gốc giữ nguyên. GLB, JSON, script tạo mô hình và tài liệu v4 ở `assets/layout/room_v4/`. Bản trước khi sửa nằm trong **.history/before_room_v05.zip**.
- `scenes/room/room.tscn` chứa các instance nội thất. `scenes/room/layout_v4.tres` giữ **thông số tạm**: trần 4,15 m, mặt gác 2,2805 m, WC sâu 2,21 m theo hướng tạm hiểu và rộng 1,18 m. Đây chưa phải số đo xác nhận. V4 dùng cạnh trái 4,185 m để cân bằng các số đo xấp xỉ.
- Chỗ nối thang được thêm hai bậc trên và khoảng mở sàn để xử lý phần blockout giao nhau; không dời chân thang, bàn PC hoặc nới hành lang. Mép bể cá và viền màn hình được thu gọn vài cm để hết giao nhau, giữ nguyên tâm.
- Tài sản được tạo bằng mã, chưa phải bản scan phòng. Ảnh nhỏ trên bảng, cá và vài đồ trang trí còn mô phỏng. Gương chưa phản chiếu trực tiếp; cửa chuyển trạng thái tức thời. Ngoài cửa chính chưa có màn chơi; ban công chỉ có ngưỡng nhỏ theo v4. Khay vệ sinh mèo là vị trí tạm vì v4 chưa có tọa độ riêng.
- Chưa triển khai NPC, Bống chạy/jumpscare hoặc nhiệm vụ ngày. Chưa xác nhận 60 FPS/1080p hay chất lượng thị giác: người dùng tự đánh giá trong game; không chụp/quay/render bằng chứng.

Kiểm tra kỹ thuật: **19/19 PASS** với `tests/technical_smoke.gd`, gồm đường đi liên tục cửa → PC → gác → xuống sàn, va chạm và khôi phục điều khiển sau tương tác. Bản Windows độc lập cũng khởi chạy headless, exit 0, không báo lỗi. Đây không phải đánh giá đồ họa hoặc benchmark FPS. Nguồn và giấy phép tài sản: `assets/ASSET_SOURCES.md`.
