# So sánh hai bản concept trang chủ

Thước đo: 5 tiêu chí ở cuối `V0-BRIEF.md`.

> **Trạng thái: chưa so được.** Cột v0 còn trống vì phiên này **không gọi được v0**
> (lý do và cách gỡ ở mục cuối). Cột bản dựng tay đã đo thật, dùng lại được ngay
> khi có bản v0.
>
> Cố ý **không** tự viết một bản "kiểu v0" để lấp chỗ trống: brief giữ prompt trung
> lập để v0 tự ra đáp án riêng, mà bản do chính tôi viết thì không độc lập — so với
> nó là so với chính mình, kết luận sẽ vô nghĩa.

---

## Bảng điểm

| # | Tiêu chí | Bản dựng tay | v0 |
| --- | --- | --- | --- |
| 1 | Né phản xạ mặc định | ✅ đạt | — |
| 2 | Dấu tiếng Việt | ✅ đạt | — |
| 3 | Chịu tên dài / giá lớn | ✅ đạt *(đã vá 2026-09-05)* | — |
| 4 | Render thật 390px | ✅ đạt *(đã vá 2026-09-05)* | — |
| 5 | Chi phí port sang app | ❌ tốn — CSS thuần | — |

Cách đo: Edge headless qua CDP, 3 khổ 390 / 834 / 1440px, cuộn hết trang cho
hiệu ứng reveal chạy xong rồi mới đo `getBoundingClientRect`.

---

## 1. Né phản xạ mặc định — đạt

Không xanh dương, không thanh tìm kiếm chắn ngang hero, không kem + serif nghiêng.
Bảng màu sơn mài (nền then `oklch(0.145 0.018 48)`, giấy điệp, vàng quỳ), bo góc
`2px`, viền tóc thay đổ bóng, hero chia lệch thay vì căn giữa, tour là hàng biên tập
đảo chiều thay vì lưới card. Đủ 4 gạch đầu dòng "TRÁNH" trong brief đều tránh được.

## 2. Dấu tiếng Việt — đạt

Kiểm cả hai lớp, không chỉ nhìn bằng mắt:

- CSS Google Fonts trả về **7 khối `/* vietnamese */`** — cả `Petrona` và
  `Be Vietnam Pro` đều có subset `vietnamese` thật.
- Lúc render: `document.fonts.status = "loaded"`, `fonts.check()` đúng cho cả hai.
- Đo bề rộng `ế ộ ữ ằ ợ Nghiêng` bằng canvas: Petrona 294.6px vs serif dự phòng
  286.1px; Be Vietnam Pro 334.2px vs sans dự phòng 324.3px. Khác nhau ⇒ chữ có dấu
  đang vẽ bằng font chính, **không rơi về font dự phòng**.

## 3. Chịu tên dài / giá lớn — đã vá (vỡ ở 834px)

Đúng giá mẫu brief nêu (`5.900.000₫ / đêm`) là chỗ vỡ:

| Khổ | `5.900.000₫ / đêm` | Kết quả |
| --- | --- | --- |
| 390px | ô rộng 247px | ✅ |
| **834px** | **cần 139px, ô chỉ 127px** | ❌ tràn 12px |
| 1440px | đủ chỗ | ✅ |

Nguyên nhân — [homepage-concept.html:337](homepage-concept.html#L337) và
[:344](homepage-concept.html#L344):

```css
.row{ grid-template-columns:minmax(0,2.2fr) minmax(0,1.4fr) minmax(0,1fr) auto; }
.row__price{ white-space:nowrap; }   /* không xuống dòng được */
```

Cột giá là `minmax(0,1fr)` → ở 834px co còn 127px, mà `nowrap` bắt chữ nằm một dòng
139px, `overflow:visible` nên nó **đè sang cột `.row__go` bên cạnh**. `2.740.000₫ / đêm`
cũng vậy (136px). Chỉ hỏng trong dải ~761–900px: dưới 760px có breakpoint xếp lại
lưới ([:453](homepage-concept.html#L453)), trên 900px thì đủ rộng.

**Đã vá** — cột giá đổi sang `minmax(max-content,1fr)` để không bao giờ co nhỏ hơn
nội dung; hai cột `2.2fr`/`1.4fr` vẫn `minmax(0,…)` nên nhường được 12px đó.
Đo lại: **0 mục bị cắt** ở cả 3 khổ.

## 4. Render thật 390px — đã vá (vùng chạm thiếu)

`docW = 390`, **0 phần tử tràn ngang** ở cả 3 khổ. Phần này đạt.

Vùng chạm thì không: **10 link chân trang cao 19px** ở mọi khổ, kể cả 390px cảm ứng —
`Tour trọn gói`, `Đặt phòng khách sạn`, `Chính sách huỷ & hoàn tiền`,
`hotro@travelvn.vn`, `024 7100 0000`… Brief bắt buộc ≥ 44×44px.

Nguyên nhân — [homepage-concept.html:408](homepage-concept.html#L408): `<a>` trong
chân trang là inline, `.foot ul{ gap:.6rem }` ⇒ bước nhảy dọc chỉ ~29px.

**Đã vá** — khoanh vùng vào `.foot ul a` để không đụng logo `.mark` (cũng là `<a>`
trong chân trang, nhưng là `inline-flex` có kiểu riêng):

```css
.foot ul{ gap:.15rem; }                  /* .6rem → .15rem, bù phần đệm mới */
.foot ul a{ display:block; padding-block:.8rem; }   /* 19 + 25.6 ≈ 44.6px */
```

Đo lại ở 390px: **0 vùng chạm dưới 44px** (trước là 10). Chân trang cao thêm ~73px
mỗi cột — cái giá phải trả, và là cách sửa đúng.

*(Ghi chú — hai thứ còn dưới 44px không tính là lỗi: 5 link nav 37px chỉ có ở
834/1440px, là chuột chứ không phải cảm ứng, và vẫn trên ngưỡng 24px của WCAG 2.5.8.
3 ô `<input>` tìm chuyến 24px cũng chỉ ở 1440px — phiên trước đã xử lý chủ ý bằng
`@media (max-width:1080px){ .search__f input{ min-height:44px } }`, mà input lại nằm
trong `.search__f` có `<label>` nên cả khối bấm được.)*

## 5. Chi phí port sang app — bản dựng tay tốn

App thật đã có sẵn, đã xác nhận trong `react travel manager/package.json`:

| | |
| --- | --- |
| Tailwind | **v4.1.18** — CSS-first, `@import "tailwindcss"` trong `src/index.css` |
| shadcn/ui | có `components.json` + `src/components/ui/` (button, card, dialog, form…) |
| Radix | 16 gói `@radix-ui/*` |
| Khác | React 19.2, lucide-react, TanStack Query 5, zustand 5, TS |

Bản dựng tay viết **CSS thuần ~920 dòng** với biến `:root` riêng ⇒ port là dịch lại
toàn bộ sang utility class + token Tailwind. Bản v0 nếu xuất đúng stack thì thắng rõ
ở tiêu chí này — đúng như brief dự đoán.

**Nhưng có một cái bẫy brief chưa tính:** app dùng **Tailwind v4**, mà v0 thường xuất
**v3** (`tailwind.config.js` + `@tailwind base/components/utilities`). Nên "port thẳng"
nhiều khả năng vẫn phải chuyển v3 → v4 (`@theme`, bỏ config JS). Khi chấm tiêu chí 5,
nhớ xem bản v0 xuất v3 hay v4 chứ đừng cho điểm tuyệt đối luôn.

---

## Vì sao chưa chạy được v0

Hai chuyện tách biệt, phải gỡ cả hai:

1. **Sai project scope.** Server `v0` đăng ký trong `~/.claude.json` dưới khoá
   `D:/springjava/travel/react travel manager` (chữ **D hoa**). Phiên này mở ở
   `d:\...` chữ **d thường** — Claude Code coi đó là project khác, `mcpServers` rỗng,
   nên không nạp v0. Chạy `claude mcp list` ở thư mục chữ d thường chỉ thấy Google
   Drive + figma; ở chữ D hoa mới thấy v0.
2. **Chưa đăng nhập.** Ở đúng thư mục, `claude mcp list` báo
   `v0: https://v0.app/api/mcp (HTTP) - ! Needs authentication`.

Cách gỡ:

```powershell
cd "D:\springjava\travel\react travel manager"   # D hoa
claude
# trong phiên: /mcp  →  chọn v0  →  Authenticate  →  đăng nhập trên trình duyệt
# xong thì thoát và mở lại phiên (tool MCP chỉ nạp lúc khởi động)
```

Rồi dán nguyên khối prompt trong `V0-BRIEF.md` (dòng 29–67) vào v0, lưu kết quả
vào thư mục này, và điền cột v0 của bảng trên.
