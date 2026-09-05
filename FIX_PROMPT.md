# Prompt: Fix toàn bộ lỗi đã audit — Travel Manager (Backend + Frontend)

Hãy xử lý LẦN LƯỢT từng lỗi dưới đây theo đúng thứ tự Critical → High → Medium → Low. Với MỖI lỗi:
1. Đọc lại đúng file/dòng được nêu để xác nhận hiện trạng còn khớp không (code có thể đã đổi).
2. Sửa đúng phạm vi lỗi đó, không refactor lan sang chỗ không liên quan.
3. Sau khi sửa xong 1 lỗi: build lại phần liên quan (backend: `./gradlew build` hoặc `./gradlew compileJava`; frontend: `npm run build` hoặc `npm run lint`) để chắc không gãy gì.
4. Đánh dấu lỗi đó là ĐÃ SỬA, ghi 1 dòng tóm tắt thay đổi, rồi chuyển sang lỗi tiếp theo.
5. Nếu phát hiện lỗi trong danh sách này KHÔNG còn tồn tại (đã được sửa từ trước) hoặc mô tả không còn khớp code hiện tại, ghi rõ "Không còn tồn tại / không khớp code hiện tại" kèm lý do ngắn gọn, không tự bịa ra việc sửa.

Không dừng giữa chừng để hỏi xác nhận từng lỗi nhỏ — chỉ dừng lại hỏi nếu một lỗi đòi hỏi quyết định nghiệp vụ thật sự không thể tự suy ra (ví dụ: đổi mật khẩu DB thật, xoay vòng secret production, rewrite git history — những việc này CHỈ liệt kê hướng dẫn, KHÔNG tự ý thực thi, phải hỏi người dùng trước). Khi xử lý xong toàn bộ danh sách, chạy lại một lượt rà soát cuối (build full cả 2 project + tự đọc lại từng file đã sửa) và báo cáo: còn sót lỗi nào không, có phát sinh lỗi mới nào không.

---

## 🔴 CRITICAL

1. **`.env` (root) chứa secret thật, đã commit/push lên GitHub public** — `D:\springjava\travel\.env` chứa `DB_PASSWORD`, `JWT_SECRET`, `MAIL_PASSWORD`, `VNPAY_HASH_SECRET`, không bị `.gitignore` loại trừ ở root.
   - Việc tự động hoá được: thêm `.env` vào `.gitignore` ở root, `git rm --cached .env`.
   - Việc PHẢI HỎI người dùng trước khi làm (không tự ý thực thi): rotate (đổi) từng secret thật (JWT_SECRET mới, đổi mật khẩu MySQL, tạo lại Gmail App Password, đổi VNPAY_HASH_SECRET trên cổng thanh toán), và có nên `git filter-repo`/BFG xoá `.env` khỏi toàn bộ lịch sử git hay không (ảnh hưởng lịch sử commit, cần xác nhận).

2. **VNPay thanh toán tin số tiền do client gửi** — `travel\src\main\java\com\example\travelManager\controller\PaymentController.java:50-81` (`createPayment`) và `service\PaymentIpnService.java:33-39`.
   - Sửa: `createPayment` phải tự tra lại giá thực (`finalPrice`) của booking theo `bookingId` từ DB để tạo `amount`, bỏ qua/không tin `amount` do client gửi (chỉ dùng field client gửi để hiển thị, không dùng để set giá trị lưu DB). Đồng thời kiểm tra booking đang tạo payment thuộc đúng user hiện tại (so `userId` từ JWT với `booking.getUser()`).

3. **Dockerfile backend build sai JDK version** — `travel\Dockerfile:2,19` dùng `eclipse-temurin:17-jdk-alpine` / `17-jre-alpine`, trong khi `build.gradle.kts:13` yêu cầu toolchain Java 21.
   - Sửa: đổi cả build-stage và runtime-stage sang `eclipse-temurin:21-jdk-alpine` / `eclipse-temurin:21-jre-alpine`.

4. **`GlobalExceptionHandler` ép mọi exception về HTTP 500, mất status gốc** — `travel\src\main\java\com\example\travelManager\exception\GlobalExceptionHandler.java:84-88`.
   - Sửa: thêm `@ExceptionHandler(ResponseStatusException.class)` trả đúng `ex.getStatusCode()`/`ex.getReason()`; thêm `@ExceptionHandler(AccessDeniedException.class)` trả 403. Với handler `Exception.class` fallback còn lại: log đầy đủ `ex` phía server (không nuốt im), chỉ trả message chung chung ("Đã có lỗi xảy ra, vui lòng thử lại") ra client, không trả `ex.getMessage()` thô.

---

## 🟠 HIGH

5. **IDOR — hủy booking khách sạn của người khác** — `travel\...\controller\hotel\BookedRoomController.java:130-134` (`cancelBooking`, `DELETE /bookings/{bookingId}`).
   - Sửa: thêm kiểm tra `booking.getUser().getId().equals(currentUserId)` (hoặc theo role ADMIN/STAFF) trước khi cho hủy, theo đúng mẫu đã làm ở `TourBookingController.cancel()`.

6. **IDOR — hủy booking nhà hàng của người khác** — `travel\...\controller\restaurant\RestaurantController.java:207-213` (`cancel`).
   - Sửa: tương tự mục 5, kiểm tra ownership trước khi hủy.

7. **`permitAll` rộng làm lộ danh sách booking khách sạn** — `travel\...\config\SecurityConfig.java:74-79` (rule `GET "/hotels/**"` permitAll) khớp nhầm vào `GET /hotels/{hotelId}/bookings` (`BookedRoomController.java:83-89`).
   - Sửa: thêm rule cụ thể `.requestMatchers(HttpMethod.GET, "/hotels/*/bookings").hasAnyRole("ADMIN","STAFF")` đặt TRƯỚC rule wildcard permitAll (Spring Security match theo thứ tự khai báo, rule đầu tiên khớp sẽ thắng).

8. **Xoá phòng cascade xoá luôn lịch sử booking đã thanh toán** — `travel\...\service\hotel\RoomService.java:61-68,143-150` (`deleteRoom`, `deleteRoomFromHotel`), do `Room.bookings` khai báo `cascade = CascadeType.ALL` (`domain\hotel\Room.java:54`).
   - Sửa: trước khi xoá, kiểm tra `bookedRoomRepository.existsByRoomIdAndStatusIn(roomId, ACTIVE_STATUSES)` (theo đúng mẫu `TourService.deleteTour` đã làm), nếu còn booking thì chặn xoá (trả lỗi rõ ràng) hoặc chuyển sang soft-delete thay vì xoá cứng.

9. **Logic đặt tour bị viết trùng và lệch nhau ở 2 endpoint** — `travel\...\service\tour\TourService.java:340-345` (`bookTour`, dùng read-modify-write không an toàn với concurrency) vs `travel\...\controller\tour\TourBookingController.java:181-184` (`book`, đã dùng UPDATE nguyên tử `decrementSlot` đúng cách).
   - Sửa: gộp về một luồng duy nhất — xoá phần tự viết lại logic đặt tour trong `TourBookingController`, chuyển toàn bộ sang gọi `TourService` đã được sửa để luôn dùng `decrementSlot`/`incrementSlot` nguyên tử (bỏ cách đọc-sửa-ghi `departureRepository.save()` trực tiếp trong `bookTour`). Đồng bộ lại công thức tính chiết khấu package về một chỗ duy nhất.

10. **Controller Review/Coupon/SeasonalPrice không có service layer** — `HotelReviewController`, `RestaurantReviewController`, `TourReviewController`, `TourCouponController`, `TourSeasonalPriceController` (trong `travel\...\controller\hotel`, `\restaurant`, `\tour`).
    - Sửa: tạo `ReviewService` (generic hoặc theo từng entity) chứa toàn bộ business rule hiện đang nằm trong controller (kiểm tra quyền review, trạng thái booking, chống review trùng...), controller chỉ gọi service. Có thể làm chung một lần cho cả 3 module review vì logic gần như giống hệt nhau; Coupon/SeasonalPrice xử lý tương tự (tạo service riêng, chuyển logic ra khỏi controller).

11. **Frontend: logout không đồng bộ giữa `AppContext` và Zustand `authStore`** — `react travel manager\src\components\layout\Navbar.tsx:78-81`, `src\pages\user\ProfilePage.tsx:799-803` (chỉ clear Zustand, không clear `AppContext`) vs `src\components\layout\AdminLayout.tsx:187-191`, `StaffLayout.tsx:59-63` (chỉ clear `AppContext`, không clear Zustand); `src\components\ProtectedRoute.jsx` đọc từ `AppContext`.
    - Sửa: viết MỘT hàm `logout()` dùng chung (đặt trong `authStore` hoặc một hook `useLogout`) luôn clear cả `AppContext` lẫn Zustand `authStore`, rồi `window.location.href = '/login'` (hard reload để tránh vênh state). Thay toàn bộ 4+ nơi gọi logout hiện tại (Navbar, ProfilePage, AdminLayout, StaffLayout, Menubar) bằng hàm dùng chung này.

12. **Frontend Dockerfile thiếu `.dockerignore`** — `react travel manager\Dockerfile:6` (`COPY . .`) copy đè cả `node_modules` build trên Windows lẫn `.git`, `dist`, log file vào image.
    - Sửa: tạo `react travel manager\.dockerignore` với nội dung tối thiểu: `node_modules`, `dist`, `.git`, `*.log`, `.env`.

---

## 🟡 MEDIUM

13. `BookedRoomServiceImpl.cancelBooking` (`travel\...\service\hotel\BookedRoomServiceImpl.java:96-110`) thiếu `@Transactional` → thêm `@Transactional` bao trọn method.
14. `HotelController`, `RestaurantController`, `TourController` tự inject `*FavoriteRepository` xử lý favorite trong controller → tạo `FavoriteService` dùng chung, chuyển logic ra khỏi 3 controller (`HotelController.java:39-40,181-224`, `RestaurantController.java:44-46,217-259`, `TourController.java:60-66,248-290`).
15. N+1 query — `HotelController.java:76,244` (`toResponse` gọi `countRoomsByHotelId` trong loop khi list): thêm 1 query gộp đếm phòng theo danh sách hotelId rồi map vào response.
16. N+1 query — `RoomController.java:54-62,90-104` (`getAllRooms` gọi `getAllBookingsByRoomId` trong loop): batch-load bằng `findByRoom_IdIn` rồi group trong bộ nhớ.
17. N+1 query — `TourController.java:294-336` (`toResponse`/`toListResponse` gọi rating + ảnh + `departures.size()` trong loop): viết 1 query JPQL group-by lấy rating trung bình + ảnh đại diện hàng loạt theo danh sách tourId.
18. `ExportController.java:41-91,93-140` (Excel) và `:144-196,198-243` (PDF) không phân trang, load hết vào RAM: đổi Excel sang `SXSSFWorkbook` (streaming), giới hạn theo khoảng ngày cho cả Excel và PDF.
19. `ExportController.java:148-196,202-243` — PDF: `Document`/`PdfWriter` không dùng try-with-resources → bọc lại bằng try-with-resources hoặc try/finally để đảm bảo đóng khi có exception giữa chừng.
20. Gửi email đồng bộ + nuốt exception im lặng ở `BookedRoomController.java:64-74`, `RestaurantController.java:164-173`, `TourBookingController.java:187-197`, `IncidentReportController.java:89-94`: đánh dấu các method gửi mail trong `EmailService` là `@Async`, thay `catch (Exception ignored) {}` bằng `catch (Exception e) { log.warn(...) }`.
21. Thiếu validate giá âm — `domain\request\hotel\RoomCreateRequest.java:16-17` (`roomPrice`), `domain\request\restaurant\RestaurantRequest.java:38` (`pricePerPerson`), `TourSeasonalPriceController.java:114-117` (`priceAdult`/`priceChild`): thêm `@DecimalMin(value = "0", inclusive = false)` theo mẫu đã đúng ở `TourRequest.java:29-34`.
22. `domain\request\hotel\BookingRequest.java:13-17` không validate `checkOutDate` phải sau `checkInDate`: thêm `@AssertTrue` custom validator trên DTO hoặc kiểm tra tường minh trong `BookedRoomServiceImpl.bookRoom`.
23. `TourService.java:174-179` (`deleteDeparture`) xoá cứng không kiểm tra booking còn tham chiếu: thêm check `bookingRepository.existsByDepartureIdAndStatusIn(...)` giống mẫu `deleteTour`.
24. Frontend XSS — `react travel manager\src\pages\hotels\HotelDetailPage.tsx:747-750` dùng `dangerouslySetInnerHTML` render mô tả khách sạn không sanitize: đổi sang `{hotel.description}` (text thường) vì field nguồn chỉ là `<textarea>` thuần (`HotelForm.jsx:181-190`), không có lý do dùng HTML render.
25. Frontend — `react travel manager\src\pages\restaurants\BookRestaurant.jsx:67-76` không dùng React Hook Form + Zod, validate SĐT chỉ kiểm tra rỗng: chuyển sang RHF + Zod, dùng chung schema/regex số điện thoại `/^0[35789]\d{8}$/` với `BookingPage.tsx`/`RegisterPage.tsx`.
26. `docker-compose.yml:9-16` publish cổng MySQL `"3307:3306"` ra host: đổi `ports` thành `expose: ["3306"]` như đã làm đúng cho service backend, đổi `DB_PASSWORD` sang giá trị mạnh hơn (cần hỏi người dùng giá trị mới trước khi set, không tự bịa mật khẩu production).
27. Error response shape không nhất quán — `travel\...\filter\JwtRequestFilter.java:83` (`{"error","reason"}`), `config\CustomAuthenticationEntryPoint.java:21` (`{"authenticated","message"}`), so với `GlobalExceptionHandler`/`response\ErrorResponse.java:10-11` (`{"statusCode","message"}`): hợp nhất cả 3 nơi về cùng 1 shape `{statusCode, message}`.
28. `Caddyfile:3` — domain vẫn là placeholder `YOUR_SERVER_IP.nip.io`: cần hỏi người dùng domain/IP thật trước khi sửa (không tự bịa), sau đó cập nhật.
29. Cả 2 Dockerfile (`travel\Dockerfile`, `react travel manager\Dockerfile`) chạy container bằng root: thêm user non-root ở stage runtime (`RUN addgroup -S app && adduser -S app -G app` rồi `USER app`).

---

## 🟢 LOW

30. Test suite gần như rỗng (`travel\src\test\java\...\TravelManagerApplicationTests.java` chỉ có `contextLoads()`): bổ sung unit test tối thiểu cho các luồng đã sửa ở mục 2, 5, 6, 8, 9, 13 (đặt phòng, hủy booking, tính giá, cascade delete) để tránh regressions sau này.
31. `service\EmailService.java` hardcode địa chỉ gửi `"phamquochuan9876@gmail.com"` lặp 7 lần: inject qua `@Value("${spring.mail.username}")` một lần, dùng chung.
32. `domain\UserEntity.java:68-70` (`role`) thiếu `fetch = FetchType.LAZY`, không nhất quán với các quan hệ `@ManyToOne` khác trong codebase: thêm `fetch = FetchType.LAZY`.
33. `controller\AuthController.java` trả JWT cả trong cookie httpOnly lẫn body JSON: cân nhắc bỏ token khỏi response body nếu cookie httpOnly là cơ chế chính (xác nhận với người dùng trước vì có thể ảnh hưởng cách FE đang dùng).
34. `POST /admin/setup` permitAll vĩnh viễn (`SecurityConfig.java:53-55`, `ProfileServiceImpl.java:50-70`): cân nhắc đổi sang yêu cầu token/secret một lần qua biến môi trường để bootstrap thay vì để endpoint permitAll mãi mãi.
35. Upload ảnh (`RoomService`, `TourService.java:184-192`, `AdminStaffController.java:71-119`) không whitelist MIME type/đuôi file: thêm kiểm tra content-type nằm trong danh sách ảnh cho phép (jpg/png/webp...).
36. JWT không có cơ chế revoke/blacklist khi logout (`util\JwtUtil.java`): ghi nhận là hạn chế thiết kế, có thể để nguyên nếu chấp nhận rủi ro thấp, hoặc thêm blacklist token (Redis/DB) nếu cần chặt hơn — hỏi người dùng có muốn đầu tư việc này không trước khi làm vì tốn công sức không nhỏ.
37. `docker-compose.yml` healthcheck dùng `mysqladmin ping ... -p${DB_PASSWORD}` lộ password qua process args: đổi sang dùng biến môi trường `MYSQL_PWD` hoặc script riêng.
38. `Caddyfile` thiếu security header (HSTS, X-Frame-Options, X-Content-Type-Options): thêm block `header { Strict-Transport-Security ...; X-Frame-Options DENY; X-Content-Type-Options nosniff }`.
39. `react travel manager\src\components\Menubar.jsx` trùng lặp chức năng với `Navbar.tsx` (nguyên nhân gốc của lỗi 11): sau khi sửa mục 11, cân nhắc gộp về một component Navbar duy nhất, xoá component trùng.
40. `react travel manager\src\types\index.ts` một số interface lỗi thời so với backend thật nhưng xác nhận là dead code (không import ở đâu ngoài `User`): xoá các interface không dùng hoặc cập nhật khớp lại field backend nếu định dùng trong tương lai.

---

Sau khi xử lý xong TOÀN BỘ 40 mục trên (trừ các mục yêu cầu hỏi người dùng trước — với các mục đó, hỏi trước rồi mới làm), hãy:
- Build lại full cả backend (`./gradlew build`) và frontend (`npm run build` + `npm run lint`).
- Liệt kê lại danh sách 40 mục kèm trạng thái: Đã sửa / Không còn tồn tại / Đang chờ xác nhận người dùng (cho các mục nhạy cảm).
- Nếu có gì phát sinh ngoài danh sách trong lúc sửa (bug mới lộ ra), báo cáo riêng, không tự ý mở rộng phạm vi nếu không liên quan trực tiếp.
