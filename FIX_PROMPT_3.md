# Kế hoạch sửa 5 lỗi LOGIC NGHIỆP VỤ — Travel Manager

> Khác 2 file trước (bảo mật + hạ tầng), đợt này là **sai nghiệp vụ**: tính năng có UI
> nhưng không chạy, số liệu báo cáo sai, dữ liệu bị xoá mất.
> Trạng thái: ✅ đã làm | ⬜ chưa làm

---

## 1. ⬜ Giá theo mùa không bao giờ được áp dụng

**Hiện trạng.** `TourBookingController.book:80-83` và `TourService.bookTour` lấy thẳng
`tour.getPriceAdult()`. Không chỗ nào đọc bảng `tour_seasonal_prices`.
`TourSeasonalPriceService` chỉ có CRUD, không có hàm tra giá theo ngày.

Đáng chú ý: `TourSeasonalPriceRepository.findActiveByTourIdAndDate(tourId, date)` **đã tồn tại
từ trước, chưa từng được gọi** — tính năng bị bỏ dở giữa chừng, không phải chưa thiết kế.

**Hệ quả.** Admin đặt giá Tết gấp đôi → khách đặt tour Tết vẫn trả giá thường.

**Cách sửa.**
- Thêm `TourSeasonalPriceService.resolvePrice(tourId, ngayKhoiHanh)` trả về cặp giá
  (người lớn / trẻ em): có mùa khớp thì lấy giá mùa, không thì lấy giá mặc định của tour.
  Nhiều mùa chồng nhau thì lấy mùa có `startDate` muộn nhất (mùa khai báo sau đè mùa trước).
- Gọi trong **cả hai** luồng đặt tour (`TourBookingController.book` và `TourService.bookTour`),
  tính theo `departure.getDepartureDate()` — không phải ngày hôm nay.
- **Quan trọng:** giá hiển thị phải khớp giá tính tiền, nếu không khách thấy một đằng trả một nẻo.
  Thêm `priceAdult`/`priceChild` vào `TourDepartureResponse`, và sửa
  `BookingPage.tsx` dùng giá của chuyến đang chọn thay vì `tour.priceAdult`.

## 2. ⬜ Doanh thu trên dashboard tính sai

**Hiện trạng.** `StatisticsController:120-133` cộng `finalPrice` của mọi tour booking
`status != CANCELLED`.

**Hai cái sai.**
- Cộng cả booking `PENDING` — khách bấm đặt rồi bỏ, chưa trả đồng nào, vẫn tính là doanh thu.
- Chỉ tính tour. Khách đặt phòng lẻ hoặc đặt bàn đóng góp **0đ** (hai list đó chỉ dùng để đếm
  số lượng theo trạng thái).

**Cách sửa.** Lấy doanh thu từ bảng `payments` với `status = SUCCESS` — đây mới là tiền thật
đã vào, và nó bao trùm cả 3 loại booking vì `payments` có cột `booking_type`.
Thêm repository method lọc theo khoảng `createdAt`. Giữ nguyên các số đếm booking theo trạng thái.

## 3. ⬜ Huỷ đặt phòng thì xoá cứng dữ liệu

**Hiện trạng.** `BookedRoomServiceImpl.cancelBooking:129` gọi `deleteById(bookingId)`.

**Hệ quả.** Mất sạch lịch sử đặt phòng. Nếu booking đã thanh toán thì bản ghi `payments`
trỏ tới `booking_id` không còn đích → đối soát không ra.

Bất nhất với `TourBookingController.cancel` — bên đó làm đúng: đặt `CANCELLED`, hoàn chỗ,
hoàn lượt coupon, huỷ dây chuyền, có `@Transactional`.

**Cách sửa.** Đổi sang đặt `status = CANCELLED` (soft cancel). Việc kiểm tra trùng lịch đã
loại `CANCELLED` sẵn (`findByRoom_IdAndStatusNotAndCheckOutDateAfterAndCheckInDateBefore`)
nên phòng vẫn được giải phóng đúng. Chỗ "giải phóng phòng" đổi từ `existsByRoom_Id`
sang `existsByRoom_IdAndStatusNot(roomId, CANCELLED)`.

## 4. ⬜ Cờ `Room.isBooked` luôn sai

**Hiện trạng.** Grep toàn bộ source: có `setBooked(false)` khi huỷ, **không có `setBooked(true)`
ở bất kỳ đâu**. Cờ này được trả ra `RoomResponse` và FE dùng thật ở
`BookingPage.tsx:302` (`filter(r => !r.isBooked && ...)`) — vì luôn `false` nên bộ lọc vô nghĩa.

**Vấn đề gốc.** Một phòng không thể "đã đặt" hay "chưa đặt" một cách tuyệt đối — nó phụ thuộc
**khoảng ngày** đang xét. Một cờ boolean trên bảng `rooms` không diễn tả được điều đó.

**Cách sửa.** Không cố vá cờ. Thay bằng thứ đúng bản chất: cho
`GET /hotels/{id}/rooms` nhận thêm `checkIn`/`checkOut` (tuỳ chọn) và loại các phòng
đã kín trong khoảng đó. `BookingPage` truyền ngày của chuyến đi vào.
Bỏ `isBooked` khỏi response và khỏi bộ lọc FE để không còn giá trị giả.

## 5. ⬜ Không kiểm tra số khách vượt sức chứa phòng

**Hiện trạng.** `Room.maxGuests` có trong entity, có form nhập ở admin, có trả ra response —
nhưng `BookedRoomServiceImpl.bookRoom` không so `numOfAdults + numOfChildren` với nó.

Đối chiếu: nhà hàng có kiểm tra sức chứa, tour có `decrementSlot`. Chỉ khách sạn thiếu.

**Cách sửa.** Thêm kiểm tra trong `bookRoom`, ném `IllegalArgumentException` (đã có handler
trả 400) với thông báo rõ số khách tối đa.

---

## Sau khi làm xong
1. `./gradlew build` + `npm run build` + `npx eslint src` phải xanh.
2. Rebuild image, deploy, kiểm chứng bằng curl trên hệ thống đang chạy.
3. Không tự ý đổi dữ liệu thật trong DB ngoài phạm vi sửa lỗi.
