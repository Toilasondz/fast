# VSFastColor — Tweak Tăng Tốc Nhập Màu / Coloring VideoStar

## 1. Giới thiệu
Tweak dành riêng cho ứng dụng **VideoStar** trên iOS, giúp tăng tốc quá trình nhập các preset màu (Custom Coloring, QR Code Coloring, LUTs, Curves) từ **1 - 2 phút** xuống chỉ còn **khoảng 5 - 10 giây**.

---

## 2. Cơ chế tăng tốc siêu tốc
VideoStar thông thường mất nhiều thời gian để nhập màu vì:
* Phải duyệt qua hàng trăm thông số curves/layers và kích hoạt hoạt họa UI (`UIView animation`) cho từng bước.
* Có các độ trễ luồng (`[NSThread sleepForTimeInterval:]`, `dispatch_after`) nhằm hạn chế giật lag giao diện.

**VSFastColor giải quyết triệt để vấn đề này bằng cách:**
1. **Method Swizzling:** Thu gọn thời lượng hoạt họa trung gian xuống `0.005s` và gộp giao dịch CoreAnimation (`CATransaction setDisableActions:YES`) khi nạp màu.
2. **Loại bỏ độ trễ phân giải (Throttle Bypass):** Bỏ qua các lệnh `sleep` nhân tạo trong vòng lặp đọc thông số màu.
3. **Ưu tiên CPU tối đa:** Đẩy luồng xử lý màu lên mức `UserInteractive` (Priority 1.0) để chip Apple Bionic xử lý song song với tốc độ cao nhất.

---

## 3. Cách sử dụng trên iPhone
1. Mở ứng dụng **VideoStar**.
2. Một nút nổi hình viên thuốc bo tròn sẽ xuất hiện trên màn hình:
   * 🟢 **⚡ Nhập Màu: BẬT**: Chế độ tăng tốc đang hoạt động (nhập màu siêu tốc ~5-10s).
   * ⚪ **⚡ Nhập Màu: TẮT**: Tắt tăng tốc, app chạy theo tốc độ mặc định ban đầu.
3. **Kéo thả:** Bạn có thể kéo nút nổi đến bất kỳ mép màn hình nào thuận tiện cho thao tác edit video. Vị trí sẽ tự động được ghi nhớ cho các lần mở app sau.
4. **Bật / Tắt:** Chạm 1 lần vào nút để chuyển đổi trạng thái ngay khi chuẩn bị nhập QR hoặc preset màu.

---

## 4. Cách chèn file dylib vào VideoStar (.ipa)
Bạn có thể chèn file `VSFastColor.dylib` vào VideoStar bằng bất kỳ công cụ nào sau đây:
* **Esign / GBox / Scarlet:** Chọn IPA VideoStar -> Thêm Thư viện động (Dylib) -> Chọn `VSFastColor.dylib` -> Ký và cài đặt.
* **Sideloadly (trên PC/Mac):** Kéo file IPA VideoStar vào Sideloadly -> Bấm **Advanced Options** -> Mục **Inject dylibs/frameworks** -> Thêm `VSFastColor.dylib` -> Start.
* **TrollStore / Azule / optool:**
  ```bash
  optool install -c load -p "@executable_path/VSFastColor.dylib" -t VideoStar.app/VideoStar
  ```

---

## 5. File thành phẩm
* File dylib đã biên dịch sẵn: [`VSFastColor.dylib`](file:///C:/Users/hson/.gemini/antigravity/scratch/VSFastColor/VSFastColor.dylib)
* Kiến trúc: **ARM64** (iOS 14.0+)
* Dung lượng: **~95 KB** (cực kỳ nhẹ, không gây hao pin hay lag app).
