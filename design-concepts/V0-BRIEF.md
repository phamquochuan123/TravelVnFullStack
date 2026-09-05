# Brief cho v0 — trang chủ TravelVN

> **Bàn giao cho phiên Claude Code mới.** Phiên trước đã dựng tay
> `homepage-concept.html` (xem `README.md` để biết lý do từng quyết định).
> Việc còn lại: chạy v0 với brief dưới đây, rồi so hai bản cạnh nhau.
> v0 MCP chỉ đăng ký được khi khởi động lại Claude Code — nếu tool v0 vẫn không
> gọi được, kiểm tra `claude mcp list` trước khi làm gì khác.

---

## Vì sao nên yêu cầu v0 xuất Tailwind + shadcn/ui

App thật (`react travel manager/`) đã chạy **Tailwind + shadcn/ui trên Radix**,
TypeScript, TanStack Query, zustand. Bản concept viết tay dùng CSS thuần nên port
sang React sẽ phải dịch lại toàn bộ. **Bản v0 nếu xuất đúng Tailwind + shadcn thì
port thẳng được** — đây là lợi thế thật của v0 trong trường hợp này, đáng để cân nhắc
khi chấm điểm hai bản.

---

## Prompt dán vào v0

> **Giữ prompt trung lập.** Cố ý KHÔNG mô tả hướng thị giác của bản dựng tay
> (sơn mài, "sổ tay du lịch in đẹp") trong prompt này. Nhồi hướng đó vào là ép v0
> ra cùng đáp án, so sánh mất ý nghĩa. Phần "TRÁNH" chỉ loại các phản xạ mặc định
> của ngành, không chỉ định phải đi hướng nào — v0 phải tự chọn.

```
Thiết kế trang chủ cho TravelVN — công ty lữ hành nội địa Việt Nam.

STACK (bắt buộc — để port thẳng vào app có sẵn)
React + TypeScript, Tailwind CSS, shadcn/ui trên Radix, icon lucide-react.
Không dùng thư viện ngoài stack này. Xuất component dùng được ngay.

BỐI CẢNH
Khách đặt tour + phòng khách sạn + bàn nhà hàng trong CÙNG MỘT đơn hàng.
Đây là điểm khác biệt cốt lõi, không phải trang đặt tour thông thường —
thiết kế phải làm bật được chuyện "cả chuyến đi gói trong một đơn".
Người dùng: dân văn phòng Hà Nội / TP.HCM, 25–45 tuổi, nằm lướt điện thoại
lúc 10h tối tính chuyến 3 ngày cuối tuần. Thanh toán VNPay.
TOÀN BỘ NỘI DUNG BẰNG TIẾNG VIỆT.

CÁC KHỐI CẦN CÓ
Hero có ô tìm chuyến (điểm đến / ngày đi / số khách) · điểm đến · tour nổi bật ·
khách sạn · nhà hàng · khách đánh giá · CTA cuối trang · chân trang.

TRÁNH — đây là phản xạ mặc định của ngành, rơi vào là hỏng:
· Xanh dương + trắng + thanh tìm kiếm to chắn ngang hero (Booking/Agoda)
· Kem + serif nghiêng + xanh rêu (Kinfolk / Airbnb đời mới)
· Lưới card 3 cột đều nhau, bo góc 12px, đổ bóng mềm
· Gradient trang trí, glassmorphism, hero căn giữa
Tự chọn một hướng thị giác có lập trường riêng, và nói rõ vì sao chọn hướng đó.

RÀNG BUỘC KỸ THUẬT
· Font BẮT BUỘC có subset `vietnamese` trên Google Fonts — thiếu subset là dấu
  tiếng Việt rơi về font dự phòng, chữ lỗ chỗ. Kiểm tra trước khi chọn.
  An toàn: Be Vietnam Pro, Lexend, Petrona, Bricolage Grotesque.
· Vùng chạm ≥ 44×44px trên cảm ứng.
· Tương phản chữ đạt WCAG AA.
· Tôn trọng prefers-reduced-motion.
· Responsive 390 / 834 / 1440px, không tràn ngang ở khổ nào.

DỮ LIỆU MẪU (cố ý dùng tên dài và giá lớn để thử bố cục có vỡ không)
Điểm đến: Hà Giang · Hội An · Phú Quốc · Ninh Bình · Sa Pa · Phong Nha — Kẻ Bàng
Khách sạn: Sofitel Legend Metropole Hà Nội · 6.480.000₫ / đêm
Nhà hàng: Nhà hàng Cơm Niêu Sài Gòn · 250.000₫ / người
Định dạng giá: 2.740.000₫
```

---

## Chấm hai bản theo cùng thước đo

Đừng chấm bằng "bản nào đẹp hơn". Dùng các câu hỏi này:

1. **Có né được phản xạ mặc định không?** Bản nào ra xanh-dương-thanh-tìm-kiếm
   hoặc kem-serif-nghiêng là đã thua ở bước đầu.
2. **Dấu tiếng Việt có nguyên vẹn không?** Phóng to chữ `ế ộ ữ ằ ợ` xem có bị
   lệch chân, rơi font, hay cắt dấu.
3. **Bố cục chịu được tên dài chưa?** `Nhà hàng Cơm Niêu Sài Gòn` và
   `5.900.000₫ / đêm` có xuống dòng xấu không.
4. **Render thật ở 390px** — không tràn ngang, vùng chạm ≥ 44px.
   Cách kiểm nhanh: xem `README.md`, phiên trước làm bằng Edge headless qua CDP.
5. **Port sang app tốn bao nhiêu?** Bản Tailwind + shadcn thắng rõ ở khoản này.

## Vị trí file

```
D:\springjava\travel\design-concepts\
├── homepage-concept.html   ← bản dựng tay, mở bằng trình duyệt là xem được
├── README.md               ← lý do từng quyết định thiết kế
├── NGUON-ANH.md            ← 15 ảnh Wikimedia, tác giả + giấy phép
├── V0-BRIEF.md             ← file này
└── images/
```

Ảnh trong `images/` dùng lại được cho bản v0 để so cho công bằng — cùng ảnh,
khác thiết kế, mới thấy rõ khác nhau ở đâu.
