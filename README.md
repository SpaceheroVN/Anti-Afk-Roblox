# Hx Scripts for Roblox (Anti-AFK & Multi-Tool Hub)

Đây là kho lưu trữ chứa các script Lua cho Roblox, được phát triển dưới tên 'Hx'. Bao gồm một script Anti-AFK đơn giản và một Hub đa năng (v2) tích hợp Anti-AFK, Auto Clicker, ESP, và nhiều hơn nữa.

---

## 1. Hx Anti-AFK (Script gốc)

Phiên bản đầu tiên, tập trung duy nhất vào việc chống bị kick khỏi game do AFK.

### Tính năng chính
* **Chống AFK:** Tự động phát hiện khi người chơi không hoạt động và mô phỏng nhấn phím (mặc định: `Space`) để duy trì trạng thái online.
* **Thông báo:** Hiển thị thông báo trạng thái đơn giản trên màn hình (đã kích hoạt, cảnh báo AFK, v.v.).
* **Cấu hình cơ bản:** Cho phép chỉnh sửa ngưỡng thời gian AFK, khoảng thời gian can thiệp, và phím mô phỏng qua các biến ở đầu script.
    * `afkThreshold`: Thời gian (giây) không hoạt động để coi là AFK.
    * `interventionInterval`: Khoảng thời gian (giây) giữa các lần nhấn phím khi AFK.
    * `enableIntervention`: `true`/`false` để bật/tắt mô phỏng nhấn phím.
    * `simulatedKeyCode`: Phím được mô phỏng (ví dụ: `Enum.KeyCode.Space`).

---

## 2. Hx Hub v2 (Anti-AFK, Auto Clicker, ETC)

```
-- ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗      ██╗  ██╗██╗  ██╗
-- ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝      ██║  ██║╚██╗██╔╝
-- ███████╗██║     ██████╔╝██║██████╔╝   ██║         ███████║ ╚███╔╝
-- ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║         ██╔══██║ ██╔██╗
-- ███████║╚██████╗██║  ██║██║██║        ██║         ██║  ██║██╔╝ ██╗
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝         ╚═╝  ╚═╝╚═╝  ╚═╝
```
Phiên bản nâng cấp toàn diện, là một Hub đa chức năng với giao diện đồ họa (GUI) trực quan.
### Tính năng chính

* **Giao diện đồ họa (GUI):**
    * Cửa sổ kéo thả, có thể ẩn/hiện bằng nút bấm riêng.
    * Hỗ trợ chế độ trong suốt (Transparent Mode).
    * Các chức năng được sắp xếp gọn gàng theo từng mục.
* **Anti-AFK Tích hợp:**
    * Kế thừa và cải tiến tính năng chống AFK từ script gốc.
    * Có thể bật/tắt chế độ can thiệp (mô phỏng input) ngay trên GUI.
    * Hiển thị trạng thái AFK hiện tại trên GUI.
* **Auto Clicker Mạnh mẽ:**
    * Hỗ trợ chế độ **Toggle** (bật/tắt) và **Hold** (giữ để click).
    * Tương thích **PC** (dùng Hotkey tùy chỉnh) và **Mobile** (dùng nút ảo trên màn hình).
    * Tùy chỉnh **CPS** (Clicks Per Second) qua ô nhập liệu.
    * Cho phép **chọn vị trí click cố định** trên màn hình.
    * Nút ảo Mobile có thể di chuyển và khóa vị trí.
* **Tiện ích khác (ETC):**
    * **Reduces Lag:** Tùy chọn giảm các cài đặt đồ họa để tăng FPS.
    * **ESP Players:** Hiển thị người chơi khác qua tường (Highlight).
* **Tính năng nền:**
    * Cố gắng mở khóa FPS (FPS Unlocker).
    * Quản lý và dọn dẹp tài nguyên script hiệu quả.
    * Hệ thống thông báo chi tiết hơn.
* **Cấu hình Nâng cao:**
    * Cung cấp một bảng `Config = {...}` cực lớn ở đầu script cho phép tùy chỉnh sâu rộng mọi khía cạnh (màu sắc, kích thước, icon, hành vi...).
    * Nhiều tùy chọn quan trọng có thể điều chỉnh trực tiếp qua GUI mà không cần sửa code.

---

## 🚀 Cài đặt & Sử dụng (Chung cho cả hai script)

1.  **Yêu cầu BẮT BUỘC:** Bạn **phải** có một trình thực thi script (executor) đang hoạt động trong Roblox.
2.  **Sao chép Mã:** Copy toàn bộ nội dung của script bạn muốn sử dụng (`Hx Anti-AFK` hoặc `Hx Hub v2`).
3.  **Thực thi:** Mở giao diện executor trong game, dán mã vừa sao chép vào ô nhập liệu và nhấn nút thực thi (thường là `Execute`, `Run`, `Inject`...).
4.  **Sử dụng (Đối với Hx Hub v2):**
    * Một nút nhỏ (icon Hx) sẽ xuất hiện, nhấn vào đó để ẩn/hiện GUI chính.
    * Tương tác với các nút và tùy chọn trên GUI để sử dụng các tính năng.

---

## ⚠️ Lưu ý Quan trọng & Tuyên bố Miễn trừ Trách nhiệm (Áp dụng cho cả hai script)

* **RỦI RO VI PHẠM ĐIỀU KHOẢN DỊCH VỤ (ToS) CỦA ROBLOX:**
    * Việc sử dụng bất kỳ phần mềm thứ ba nào (executor) để chạy script can thiệp vào gameplay là **vi phạm nghiêm trọng** quy định của Roblox.
    * Các tính năng như Auto Clicker, ESP, Anti-AFK tự động được coi là **gian lận (cheating)**.
    * Hành vi này **CÓ THỂ** dẫn đến các hình phạt nghiêm khắc, bao gồm **CẤM TÀI KHOẢN VĨNH VIỄN (BAN)**.
* **SỬ DỤNG VỚI RỦI RO CỦA RIÊNG BẠN:** Bạn hoàn toàn chịu trách nhiệm về việc sử dụng các script này và mọi hậu quả phát sinh. Nhà phát triển không chịu trách nhiệm nếu tài khoản của bạn bị phạt.
* **KHẢ NĂNG TƯƠNG THÍCH & BỊ PHÁT HIỆN:**
    * Script chỉ hoạt động khi có executor tương thích.
    * Các tính năng (đặc biệt trong `Hx Hub v2`) có thể **không hoạt động ổn định** trong mọi game trên Roblox.
    * Các hệ thống chống gian lận (anti-cheat) của Roblox hoặc của từng game **có thể phát hiện** việc sử dụng script này bất cứ lúc nào.
* **KHÔNG ĐẢM BẢO:** Script được cung cấp **"nguyên trạng" (as-is)** mà không có bất kỳ sự đảm bảo nào về hiệu suất, tính ổn định, hay khả năng không bị phát hiện trong tương lai.

**Hãy chơi game một cách có trách nhiệm và tôn trọng cộng đồng cũng như các quy tắc của nền tảng.**
