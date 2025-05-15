<p align="center">
    <pre>
                  /========================================================================\
                  ||   ██╗  ██╗██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗   ||
                  ||   ██║  ██║╚██╗██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝   ||
                  ||   ███████║ ╚███╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║      ||
                  ||   ██╔══██║ ██╔██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║      ||
                  ||   ██║  ██║██╔╝ ██╗    ███████║╚██████╗██║  ██║██║██║        ██║      ||
                  ||   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝      ||
                  \========================================================================/
    </pre>
</p>

---

### ✍️ **Mục đích Script**

Script được tạo ra với mục tiêu chính là **nâng cao trải nghiệm chơi game** của bạn, không nhằm mục đích gian lận hay phá hoại cân bằng game. Chúng tôi khuyến khích bạn tùy chỉnh và phát triển thêm nếu muốn!

---

## 📜 **Các Phiên Bản Script Hx**

### 0️⃣•1️⃣ **Hx_V.0.1: Khởi đầu - Chống AFK**

Phiên bản đầu tiên, tập trung giải quyết vấn đề duy nhất: **ngăn chặn việc bị kick khỏi game do không hoạt động (AFK)**.

✨ **Tính năng chính:**

* **🛡️ Chống AFK:** Tự động nhận diện trạng thái không hoạt động và mô phỏng nhấn phím (mặc định: `Space`) để giữ bạn luôn online.
* **💬 Thông báo:** Hiển thị các thông báo trạng thái đơn giản trên màn hình (đã kích hoạt, cảnh báo AFK,...).
* **⚙️ Cấu hình cơ bản:** Cho phép điều chỉnh các thông số qua biến ở đầu script:
    * `afkThreshold`: Ngưỡng thời gian (giây) để xác định AFK.
    * `interventionInterval`: Khoảng thời gian (giây) giữa các lần nhấn phím mô phỏng.
    * `enableIntervention`: Bật/tắt (`true`/`false`) tính năng mô phỏng nhấn phím.
    * `simulatedKeyCode`: Mã phím được mô phỏng (vd: `Enum.KeyCode.Space`).

---

### 0️⃣•2️⃣ **Hx_V.0.2: Tối Ưu Hóa Hiệu Năng (Giảm Lag & Tăng FPS)**

Phiên bản mới tập trung vào việc **cải thiện hiệu năng game** bằng cách tùy chỉnh đồ họa và vật lý trực tiếp trên máy của người chơi, giúp giảm lag và tăng chỉ số FPS.

✨ **Tính năng chính:**

* **🎨 Tối ưu hóa Đồ họa & Hiệu ứng:** Tự động giảm tải hoặc loại bỏ các yếu tố gây nặng máy:
    * Tắt đổ bóng (*Shadows*).
    * Đơn giản hóa hệ thống ánh sáng (*Lighting*).
    * Loại bỏ/giảm hiệu ứng hạt, khói, lửa,... (*Particles*, *Effects*).
    * Xóa hình ảnh dán (*Decals*), vân bề mặt (*Textures*).
    * Làm phẳng mặt nước địa hình (*Terrain Water*).
    * Ẩn các yếu tố thị giác phụ như mây, khí quyển, thiên thể (*Visual Extras*).
* **🧱 Tối ưu hóa Vật lý & Đối tượng:** Giảm gánh nặng tính toán cho CPU:
    * Tắt va chạm (*Collisions*) cho các vật thể không quan trọng.
    * Neo cứng các bộ phận (*Anchor*).
    * Đơn giản hóa vật liệu (*Materials*).
    * *Tùy chọn theo Preset:* Xóa mô hình (*Models*), âm thanh (*Sounds*), giao diện (*UI*) không thiết yếu.
* **📊 Chế độ Cài đặt Sẵn (Presets):** Cung cấp các mức độ tối ưu hóa khác nhau:
    * `OFF`: Tắt hoàn toàn tối ưu hóa.
    * `Minimal`: Tối ưu hóa nhẹ, ít ảnh hưởng hình ảnh.
    * `Balanced`: Cân bằng giữa hiệu năng và chất lượng hình ảnh.
    * `PerformanceBoost`: Tăng cường hiệu năng rõ rệt, hy sinh một phần đồ họa.
    * `UltraLow`: Tối ưu hóa tối đa, giảm mạnh đồ họa để đạt FPS cao nhất.
* **🖱️ Giao diện Điều khiển:** Một nút bấm nhỏ gọn trên màn hình:
    * Nhấp để chuyển đổi giữa các Preset.
    * Hiển thị Preset đang hoạt động (vd: "Hx: Balanced").
    * Có thể kéo thả để di chuyển nút.
* **🔄 Tối ưu hóa Liên tục (Real-time):**
    * *Tùy chọn theo Preset:* Kích hoạt `OPTIMIZE_ON_ADD` để tự động tối ưu các đối tượng mới xuất hiện.
* **📢 Hệ thống Thông báo:** Hiển thị thông báo nhỏ ở góc màn hình (khởi động, đổi Preset).
⚠️ **Lưu ý** Phiên bản này tối ưu quá mức nhưng chưa tích hợp FastFlags!

---

### 0️⃣•3️⃣ **Hx_V.0.3 : Ổn Định & Tối Ưu An Toàn**

Phiên bản này được xây dựng lại dựa trên những phản hồi về các lỗi không mong muốn (như xóa khối) từ các phiên bản trước. Mục tiêu chính là cung cấp một trải nghiệm ổn định và an toàn tuyệt đối, tập trung vào các phương pháp giảm lag ít can thiệp vào cấu trúc game nhất có thể, đồng thời tích hợp các cải tiến hiệu năng hiện đại.

✨ **Những Cải Tiến Chính & Tính Năng:**

* **🚫 Không Xóa Khối/Model:** Script KHÔNG còn thay đổi thuộc tính (như làm vô hình, đổi vật liệu) hoặc xóa bất kỳ `BasePart` hay `Model` nào không nằm trong danh sách cực kỳ an toàn được định nghĩa trước. Điều này đảm bảo không gây lỗi game do xóa nhầm đối tượng.
* **⚡ Tích Hợp FastFlags Thông Minh:**
   * Tự động áp dụng các FastFlags tối ưu hiệu năng ở chế độ cao nhất (`Performance`).
   * Tự động phát hiện nền tảng: Nếu script chạy trên một môi trường (thường là di động) không hỗ trợ `setfflag` do giới hạn quyền, tính năng FastFlags sẽ được bỏ qua một cách lặng lẽ, không gây lỗi và không hiển thị thông báo không cần thiết.
* **🎨 Tối Ưu Hóa Đồ Họa An Toàn:**
   * Tắt đổ bóng toàn cục (Global Shadows).
   * Tùy chọn chuyển sang chế độ render `Compatibility` (nhẹ hơn `Voxel`).
   * Đơn giản hóa ánh sáng môi trường (Environment Light).
   * Tắt các hiệu ứng hậu kỳ (Post-Processing Effects).
   * Không can thiệp vào `Atmosphere` và `Clouds` bằng cách xóa hoặc clone để tránh các lỗi khôi phục Lighting đã gặp phải.
* **💧 Tối Ưu Nước Địa Hình:** Làm phẳng mặt nước để giảm gánh nặng render.
* **💥 Tắt Hiệu Ứng Hạt:** Vô hiệu hóa `ParticleEmitters`, `Beams`, `Trails`, `khói`, `lửa`,...
* **📉 Ép Chất Lượng Đồ Họa:** Tùy chọn để đặt mức chất lượng đồ họa của Roblox xuống thấp nhất.
* **🗑️ Xóa Chọn Lọc (An Toàn Hơn):**
   * Tùy chọn: Xóa `Decal`, `Texture` không thuộc về nhân vật.
   * Tùy chọn: Xóa `Sound` không thiết yếu (không phải nhạc nền, không đang phát).
   * Tùy chọn: Xóa `ScreenGui` không thiết yếu (có danh sách trắng các UI quan trọng như Chat, CoreGui, và UI của chính script).
* **🔧 Cấu Hình Preset Tinh Gọn:
   * `OFF`: Tắt tối ưu, cố gắng phục hồi các cài đặt đã thay đổi (trừ FastFlags).
   * `Minimal`: Tối ưu nhẹ nhàng.
   * `Balanced`: Cân bằng hiệu năng và đồ họa.
   * `Performance`: Kết hợp tất cả các tối ưu an toàn ở trên cùng với FastFlags.
* **🖱️ Giao Diện Điều Khiển:** Nút bấm nhỏ gọn có thể kéo thả, hiển thị preset hiện tại.
* **🔄 Tối Ưu Khi Có Đối Tượng Mới:** Tùy chọn để tự động áp dụng các tối ưu an toàn (chủ yếu là tắt hiệu ứng) cho các đối tượng mới được thêm vào game.
* **📢 Thông Báo Tiếng Việt:** Toàn bộ thông báo cho người dùng được hiển thị bằng tiếng Việt.
* **🚀 Tùy Chỉnh Khởi Động:** Cho phép đặt preset mặc định khi chạy script từ xa thông qua biến toàn cục `DEFAULT_SETTING`.
* **🧹 Dọn Dẹp Độc Lập:** Script chỉ dọn dẹp các UI do chính nó tạo ra (dựa trên tên UI có chứa phiên bản, ví dụ `HxLagReducerScreenGui_v036`).
* **🐛 Sửa Lỗi & Tăng Độ Ổn Định:** Nhiều cải tiến nhỏ trong việc xử lý lỗi, kiểm tra đối tượng và khởi tạo script để đảm bảo hoạt động mượt mà hơn trên PC.
* **⚠️ Lưu ý:** Một khi `FastFlags` đã được áp dụng, thường sẽ có hiệu lực trong suốt phiên chơi và không thể dễ dàng "tắt" bởi script.

---

### 0️⃣•4️⃣ **Hx_V.0.4: Hub Đa Năng (Anti-AFK, Auto Clicker, Reduces Lag, ESP Player)**

Phiên bản nâng cấp toàn diện, tích hợp nhiều chức năng mạnh mẽ vào một **Hub điều khiển với giao diện đồ họa (GUI)** trực quan.

✨ **Tính năng chính:**

* **🖥️ Giao diện đồ họa (GUI):**
    * Cửa sổ có thể kéo thả, ẩn/hiện bằng nút bấm riêng.
    * Hỗ trợ chế độ trong suốt (*Transparent Mode*).
    * Các tính năng được phân loại rõ ràng.
* **🛡️ Anti-AFK Tích hợp:**
    * Kế thừa và cải tiến từ phiên bản gốc.
    * Bật/tắt chế độ can thiệp ngay trên GUI.
    * Hiển thị trạng thái AFK trên GUI.
* **🖱️ Auto Clicker Mạnh mẽ:**
    * Chế độ **Toggle** (bật/tắt) và **Hold** (giữ để click).
    * Tương thích **PC** (Hotkey tùy chỉnh) & **Mobile** (nút ảo).
    * Điều chỉnh **CPS** (Số lần click mỗi giây).
    * Cho phép **chọn vị trí click cố định**.
    * Nút ảo Mobile có thể di chuyển và khóa vị trí.
* **🛠️ Tiện ích Khác (ETC):**
    * **⚡ Reduces Lag:** Tùy chọn giảm cài đặt đồ họa để tăng FPS.
    * **👀 ESP Players:** Hiển thị người chơi khác qua vật cản (*Highlight*).
* **🚀 Tính năng Nền:**
    * Nỗ lực mở khóa giới hạn FPS (*FPS Unlocker*).
    * Quản lý tài nguyên script hiệu quả.
    * Hệ thống thông báo chi tiết.
* **⚙️ Cấu hình Nâng cao:**
    * Bảng `Config = {...}` lớn ở đầu script cho phép tùy chỉnh sâu mọi yếu tố (màu sắc, kích thước, icon, hành vi,...).
    * Nhiều tùy chọn quan trọng có thể chỉnh trực tiếp trên GUI.

---

## 🚀 **Hướng dẫn Cài đặt & Sử dụng**

1.  **✅ Yêu cầu BẮT BUỘC:** Bạn **phải** có một trình thực thi script (*executor*) đang hoạt động trong Roblox.
2.  **📋 Sao chép Mã:** Copy toàn bộ nội dung của phiên bản script bạn muốn dùng.
3.  **⚙️ Thực thi:** Mở giao diện executor trong game, dán mã đã sao chép và nhấn nút thực thi (thường là `Execute`, `Run`, `Inject`...).
4.  **🎮 Sử dụng (Đối với Hx Hub v2 / v0.3):**
    * Một nút nhỏ (icon Hx) sẽ xuất hiện. Nhấn vào đó để mở/đóng GUI chính.
    * Tương tác với các nút và tùy chọn trên GUI để kích hoạt/điều chỉnh tính năng.

---

## ⚠️ **Lưu ý Quan trọng (Áp dụng cho tất cả script)**

* **⚖️ RỦI RO VI PHẠM ĐIỀU KHOẢN DỊCH VỤ (ToS) CỦA ROBLOX:**
    * Việc sử dụng *executor* để chạy script can thiệp vào game là **hành vi vi phạm nghiêm trọng** quy định của Roblox.
    * Các tính năng như Auto Clicker, ESP, Anti-AFK tự động **bị coi là gian lận (cheating)**.
    * Hành vi này **CÓ THỂ** dẫn đến hình phạt nặng, bao gồm **KHÓA TÀI KHOẢN VĨNH VIỄN (BAN)**.
* **🛡️ SỬ DỤNG VỚI RỦI RO CỦA RIÊNG BẠN:** Bạn hoàn toàn chịu trách nhiệm về việc sử dụng các script này và mọi hậu quả có thể xảy ra. Nhà phát triển không chịu trách nhiệm nếu tài khoản của bạn bị phạt.
* **🧩 KHẢ NĂNG TƯƠNG THÍCH:**
    * Script chỉ hoạt động khi có executor tương thích.
    * Các tính năng có thể **không hoạt động ổn định** hoặc như mong đợi trong mọi game trên Roblox.
* **🚫 KHÔNG ĐẢM BẢO:** Script được cung cấp **"nguyên trạng" (as-is)**, không có bất kỳ đảm bảo nào về hiệu suất, tính ổn định, hay khả năng không bị Roblox phát hiện trong tương lai.

**🙏 Hãy chơi game một cách có trách nhiệm, tôn trọng cộng đồng và tuân thủ các quy tắc của nền tảng.**
