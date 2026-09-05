# TravelVN — Concept trang chủ

Bản concept độc lập. **Không đụng vào code trong `react travel manager/`.**

Mở xem: nhấp đúp `homepage-concept.html` (một file HTML tĩnh, không cần build).

```
design-concepts/
├── homepage-concept.html   ← toàn bộ concept, CSS + JS nội tuyến
├── images/                 ← 15 ảnh, giấy phép tự do
├── NGUON-ANH.md            ← tác giả + giấy phép từng ảnh
└── README.md
```

---

## Hướng thiết kế

Điểm xuất phát là một câu hỏi cụ thể chứ không phải "trang du lịch đẹp":
*người Hà Nội 10h tối, cầm điện thoại dưới đèn bàn, đang tính chuyến 3 ngày đi Hà Giang.*
Trang này phải giống mở một cuốn sổ tay du lịch in đẹp, không giống mở một cổng đặt vé.

### Bảng màu — sơn mài, không phải xanh du lịch

Phản xạ đầu tiên của ngành du lịch là trắng + xanh dương + thanh tìm kiếm to.
Phản xạ thứ hai (khi tránh xanh dương) là kem + serif nghiêng + xanh rêu kiểu Kinfolk.
Concept này tránh cả hai, lấy màu từ **sơn mài Việt**:

| Vai trò | Màu | Dùng ở đâu |
| --- | --- | --- |
| Nền then | `oklch(0.145 0.018 48)` — đen ngả nâu | hero, ẩm thực, CTA, chân trang |
| Giấy điệp | `oklch(0.958 0.011 84)` — trắng ngà ấm | điểm đến, tour, khách kể lại |
| Vàng quỳ | `oklch(0.722 0.132 64)` | nhấn, số chương, chữ nghiêng |

Trang được **đóng khung hai đầu**: hero tối → ruột sáng → CTA tối. Đây là cách một
tạp chí in hoạt động (bìa tối, ruột giấy, bìa sau tối), và nền tối làm ảnh nổi lên.

Màu cũ của dự án (`#1a5276` xanh + `#e67e22` cam) không bị vứt đi — cam đã chuyển
thành vàng quỳ trầm hơn, xanh navy nhường chỗ cho nền then ấm.

### Chữ

| | Font | Vì sao |
| --- | --- | --- |
| Hiển thị | **Petrona** | serif tương phản thấp, hơi hẹp, đọc như sách hướng dẫn in đẹp — không phải Playfair/Cormorant |
| Nội dung | **Be Vietnam Pro** | font do người Việt vẽ *cho tiếng Việt* |

Cả hai đều có bộ ký tự `vietnamese` trên Google Fonts — đã kiểm tra, dấu tiếng Việt
không bị rơi về font dự phòng. Đây là điểm dễ hỏng nhất khi chọn font cho trang tiếng Việt.

### Bố cục

- Hero **chia lệch**: chữ trái, ảnh dọc phải, ảnh phụ chèn phá lưới. Không phải hero căn giữa.
- Điểm đến là **khảm lệch** 4 ảnh khác cỡ, so le chiều dọc — không phải lưới 3 cột đều nhau.
- Tour là **hàng biên tập** đảo chiều luân phiên — không phải card.
- Bo góc `2px`, viền tóc thay cho đổ bóng, không gradient trang trí, không glassmorphism.

### Chuyển động

Hiện dần khi cuộn (`IntersectionObserver`, chỉ `opacity`/`transform`), ảnh phóng chậm
khi rê chuột, gạch chân chạy ở menu, hairline vàng khi focus ô tìm kiếm.
Có `prefers-reduced-motion` — tắt sạch khi người dùng yêu cầu.

---

## Đã kiểm tra

Render thật bằng Edge headless qua CDP ở 3 khổ màn hình. **Đo lại 2026-09-05** —
lần đo đầu bỏ sót chân trang và giá ở khổ tablet, bảng dưới là số sau khi vá:

| Khổ | Tràn ngang | Vùng chạm < 44px | Giá / tên dài bị cắt |
| --- | --- | --- | --- |
| 1440px | không | — | không |
| 834px | không | — | không |
| 390px | không | không | không |

Hai lỗi đã vá (chi tiết trong `SO-SANH.md`):

- **10 link chân trang cao 19px** ở mọi khổ, kể cả 390px cảm ứng. Bảng cũ ghi "không"
  là sai. Vá bằng `.foot ul a{ display:block; padding-block:.8rem }`.
- **`5.900.000₫ / đêm` tràn ô ở 834px** — cột giá `minmax(0,1fr)` co còn 127px trong
  khi chữ `nowrap` cần 139px nên đè sang cột kế. Vá bằng `minmax(max-content,1fr)`.

Đáp ứng ràng buộc trong `PRODUCT.md`: vùng chạm ≥ 44px trên cảm ứng, tương phản
chữ đạt WCAG AA (vàng dùng cho chữ nhỏ trên giấy là `--gold-ink`, tối hơn vàng nhấn).

## Còn phải làm nếu chốt hướng này

1. **Thay ảnh.** 15 ảnh hiện tại là ảnh Wikimedia Commons dùng tạm — xem `NGUON-ANH.md`.
   Cần ảnh thật của tour/khách sạn/nhà hàng, và ảnh khách hàng thật cho phần đánh giá.
2. **Dữ liệu là giả.** Giá, mã tour, số chỗ, tên khách đều bịa để xem bố cục chịu được
   tên dài và giá lớn hay không.
3. Tách token màu/chữ ra `:root` dùng chung trước khi port sang React.
4. `srcset`/AVIF cho ảnh, và bỏ `loading="lazy"` ở ảnh hero.
