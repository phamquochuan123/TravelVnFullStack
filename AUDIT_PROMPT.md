# Prompt: Audit toàn bộ lỗi — Travel Manager (đã public ra Internet)

> Cách dùng: mở một phiên Claude Code **mới** tại `D:\springjava\travel`, dán toàn bộ nội dung từ dòng `---` bên dưới xuống hết file.

---

Bạn là kỹ sư review code + security. Hãy **audit toàn bộ** dự án tại `D:\springjava\travel` và **chỉ báo cáo, KHÔNG tự sửa code** (trừ khi tôi yêu cầu sau).

## 0. Bối cảnh bắt buộc phải nhớ

- Hệ thống **vừa được public ra Internet** (Cloudflare Quick Tunnel + Caddy, xem `docker-compose.yml` service `cloudflared` và `Caddyfile`). Nghĩa là: mọi endpoint backend giờ ai cũng gọi được, không còn "chạy localhost nên không sao". Hãy ưu tiên mức độ nghiêm trọng theo góc nhìn **attacker ẩn danh trên Internet**.
- Dự án gồm **3 git repo tách rời**:
  - `D:\springjava\travel` → repo `TravelVn` (chỉ chứa docker-compose, Caddyfile, sql, gitlink 2 repo con)
  - `D:\springjava\travel\travel` → repo `be-TravelManager` — Spring Boot 3 + Java 21 + Gradle Kotlin DSL + MySQL 8 + JWT, ~34 controller, ~31 service
  - `D:\springjava\travel\react travel manager` → repo `fe-TravelManager` — React + Vite + Tailwind, có `src/pages/{admin,staff,user,auth,tours,hotels,restaurants,destinations,payment}`
- Đây là **đồ án tốt nghiệp**, chấp nhận đánh đổi kỹ thuật hợp lý — nhưng lỗi bảo mật/mất tiền/mất dữ liệu thì không.
- File `FIX_PROMPT.md` ở thư mục gốc là kết quả **một lần audit trước đó**. Coi nó là *tham chiếu*, **không phải sự thật hiện tại**: hãy tự đọc lại code để xác nhận từng mục còn hay đã hết, và tìm thêm lỗi mới.

## 1. Cách làm việc (bắt buộc)

1. **Đọc code thật trước khi kết luận.** Mỗi phát hiện phải trỏ được `đường_dẫn/file.java:dòng`. Không suy đoán từ tên file, không bịa lỗi cho đủ số lượng.
2. Với mỗi lỗi, phải nêu được **kịch bản hỏng cụ thể**: request/thao tác nào → hệ quả gì (ví dụ: "POST /payments/create với `amount=1000` cho booking giá 5.000.000đ → thanh toán 1k vẫn được xác nhận").
3. Nếu nghi ngờ nhưng chưa chắc, **ghi rõ là `CHƯA CHẮC`** kèm lý do, đừng khẳng định.
4. Không được chạy lệnh phá hoại: không `git push`, không `git filter-repo`/`reset --hard`, không sửa DB, không xoay secret, không `docker compose down -v`. Chỉ đọc + build + lint.
5. Được phép chạy để lấy dữ kiện:
   - Backend: `cd travel && ./gradlew compileJava` (hoặc `.\gradlew.bat compileJava`), `./gradlew build -x test`
   - Frontend: `cd "react travel manager" && npm run build`, `npm run lint`, `npm audit --omit=dev`
   - Git: `git log`, `git ls-files`, `git log --all --oneline -- .env` (kiểm tra secret từng bị commit) — chạy riêng cho **cả 3 repo**
6. Làm hết một lượt rồi mới báo cáo; **không dừng giữa chừng hỏi tôi từng lỗi**.

## 2. Phạm vi audit

### A. Bảo mật backend (ưu tiên cao nhất — hệ thống đang public)

- **Secret**: `.env` (root), `application.properties`, `docker-compose.yml`, file config frontend. Có secret thật hardcode không? Có từng bị commit vào lịch sử git của **bất kỳ repo nào** không (`git log --all -p -- .env` / `-S "JWT_SECRET"`)? Có secret nào lọt vào bundle frontend (`VITE_*`, thư mục `dist/`) không?
- **`SecurityConfig.java`**: liệt kê **toàn bộ** rule theo đúng thứ tự khai báo, chỉ ra rule `permitAll`/wildcard nào **nuốt nhầm** endpoint nhạy cảm (Spring Security lấy rule khớp đầu tiên). Kiểm tra `csrf`, `cors`, `sessionManagement`, `anonymous`, `formLogin`, endpoint `/actuator/**`, swagger, `/error`.
- **JWT** (`filter/JwtRequestFilter.java`, `util/`): thuật toán, độ dài secret, có verify signature không, expiration, refresh token, chỗ lấy token (header vs cookie), cờ cookie `HttpOnly`/`Secure`/`SameSite` (lưu ý giờ chạy HTTPS qua Caddy/Cloudflare → `APP_COOKIE_SECURE` phải đúng), có revoke/logout thật không.
- **Phân quyền & IDOR**: quét **toàn bộ 34 controller**. Với mỗi endpoint nhận `{id}` hoặc `bookingId`/`userId`/`orderId`, xác nhận có kiểm tra **ownership** (so với user trong JWT) hoặc `@PreAuthorize` role. Liệt kê endpoint nào thiếu — đặc biệt các hành vi `GET` chi tiết, `PUT`, `DELETE`, huỷ booking, xem hoá đơn, xem thông tin user khác.
- **Endpoint admin/staff**: có bị bảo vệ chỉ ở phía React (ẩn menu) mà backend vẫn cho gọi không? Kiểm tra `AdminPlacesController`, `AdminHotelController`, `AdminRestaurantController`, `ExportController`, `IncidentReportController`…
- **Thanh toán VNPay** (`PaymentController.java`, `service/PaymentIpnService.java`): có tin `amount` do client gửi không; có verify `vnp_SecureHash` đúng cách (so sánh constant-time, đúng thứ tự param, đúng encode) không; IPN có idempotent không (gọi lại 2 lần có cộng tiền/đặt vé 2 lần?); có kiểm tra booking thuộc đúng user không; có chống việc client tự gọi endpoint "đánh dấu đã thanh toán" không.
- **Input & injection**: query JPQL/native có nối chuỗi không (`@Query`, `EntityManager.createQuery` + biến); có validate `@Valid`/`@NotNull`/`@Min` trên request DTO không; upload file (nếu có): giới hạn kiểu/kích thước, path traversal trong tên file, thư mục lưu có bị serve thẳng không.
- **Rò rỉ thông tin**: `GlobalExceptionHandler` có trả stacktrace/`ex.getMessage()` thô ra client không; log có in token/password/PII không; response DTO có lộ `password`, `passwordHash`, email/sđt người khác không (kiểm tra entity trả thẳng thay vì DTO).
- **Lạm dụng**: endpoint nào cho phép spam mà không rate-limit / captcha (đăng ký, quên mật khẩu, gửi email, review, tạo booking)? Endpoint list có phân trang giới hạn không hay `findAll()` trả toàn bộ bảng?
- **Tài khoản mặc định**: `seed_data.sql`, `CommandLineRunner`, data init — có admin mật khẩu yếu/mặc định đang tồn tại trên bản public không?

### B. Đúng đắn & chất lượng backend

- Race condition khi đặt phòng/tour cùng lúc (kiểm tra trùng lịch rồi mới insert nhưng không khoá/không unique constraint) → double booking.
- `@Transactional`: thiếu ở chỗ ghi nhiều bảng; đặt sai (method `private`/gọi nội bộ cùng class → proxy không áp dụng); `readOnly` sai chỗ.
- `LazyInitializationException` / N+1 query: dùng entity ngoài transaction, thiếu `fetch join`, vòng lặp gọi repository.
- Vòng lặp JSON vô hạn giữa entity 2 chiều; entity dùng trực tiếp làm `@RequestBody` (mass assignment: client set `role`, `id`, `status`).
- `spring.jpa.hibernate.ddl-auto` đang là gì (nếu `update`/`create` trên bản public → rủi ro dữ liệu).
- Xử lý tiền tệ bằng `double`/`float` thay vì `BigDecimal`; timezone/`LocalDateTime` khi so ngày check-in/check-out; off-by-one khi tính số đêm.
- Gửi mail đồng bộ chặn request; `AsyncConfig` có đúng không; exception nuốt trong `catch {}` rỗng.
- Chỉ có **1 file test** trong `src/test` → chỉ ra những luồng rủi ro nhất đang không có test nào che (không cần viết test, chỉ liệt kê).
- Cảnh báo compile / deprecated API sau khi chạy `./gradlew build -x test`.

### C. Frontend React

- Token lưu ở đâu (`localStorage`/cookie), có bị XSS lấy được không; `dangerouslySetInnerHTML`; render nội dung user nhập (review, tên khách sạn).
- Route guard admin/staff chỉ ở client → nêu rõ endpoint backend tương ứng có tự bảo vệ không.
- Biến `VITE_*` nào chứa secret thật sẽ bị nhúng vào bundle public.
- Gọi API: có xử lý lỗi/401 tập trung không, có hardcode `http://localhost:8081` sót lại trong `src/api/` không (sẽ vỡ khi chạy qua domain public), base URL có khớp `VITE_API_BASE_URL=/api/v1` + `nginx.conf` proxy không.
- Lỗi React thường gặp: thiếu `key`, `useEffect` thiếu/dư dependency gây gọi API vô hạn, set state sau khi unmount, race condition khi search/filter (response cũ về sau ghi đè response mới), form không disable lúc submit → double-submit tạo 2 booking.
- Kết quả `npm run build` + `npm run lint` + `npm audit`: lỗi/warning nào có thật.
- Rác lọt vào repo: `dist/`, `node_modules/`, `hs_err_pid*.log`, `vite-dev*.log`, `*.log`, `cookies.txt`, `tsconfig.tsbuildinfo` — cái nào đang **được git track** (dùng `git ls-files`), cái nào chỉ nằm local.

### D. Hạ tầng / deploy (giờ là bề mặt tấn công thật)

- `docker-compose.yml`: port nào bị publish ra host/Internet ngoài ý muốn; DB có lộ 3306 không; biến môi trường có default nguy hiểm (`APP_COOKIE_SECURE:-false`, `APP_CORS_ALLOWED_ORIGINS` mặc định localhost trong khi đang chạy public → CORS/cookie sẽ sai); `restart`, healthcheck, volume dữ liệu MySQL có bền không.
- `Caddyfile`: còn placeholder `YOUR_SERVER_IP` chưa thay; header bảo mật đủ chưa (thiếu CSP?); có đang thực sự đứng trước không hay traffic đi thẳng qua cloudflared.
- **Cloudflare Quick Tunnel**: URL `*.trycloudflare.com` là public hoàn toàn, không auth. Đánh giá rủi ro và nêu cách giới hạn (Cloudflare Access, tắt tunnel khi không demo).
- `travel/Dockerfile` + `react travel manager/Dockerfile` + `nginx.conf`: JDK/JRE version có khớp `build.gradle.kts` (Java 21) không; chạy root hay non-root; nginx có `try_files` cho SPA và proxy `/api` đúng không; có cache-control hợp lý không.
- `application.properties`: `spring.jpa.show-sql`, log level DEBUG, `server.error.include-stacktrace` — có bật trên bản public không.

## 3. Định dạng báo cáo (bắt buộc)

Trình bày đúng thứ tự sau:

1. **Bảng tổng hợp** — cột: `#` | Mức độ (🔴 Critical / 🟠 High / 🟡 Medium / 🔵 Low) | Khu vực (BE/FE/Infra) | Tóm tắt 1 dòng | File:dòng
2. **Chi tiết từng lỗi** theo thứ tự Critical → Low, mỗi lỗi gồm:
   - **Vị trí**: `file:dòng`
   - **Hiện trạng**: trích 3–10 dòng code liên quan
   - **Kịch bản hỏng**: attacker/người dùng làm gì → hậu quả gì
   - **Cách sửa đề xuất**: cụ thể, đủ để làm theo (không cần viết code dài)
   - **Tự sửa được / phải hỏi tôi trước** (rotate secret, đổi mật khẩu DB, sửa lịch sử git → luôn xếp vào "phải hỏi")
3. **Đối chiếu với `FIX_PROMPT.md`**: mục nào đã sửa xong, mục nào còn nguyên, mục nào không còn khớp code hiện tại.
4. **Top 5 việc phải làm NGAY vì hệ thống đang public** — xếp theo thứ tự thực thi.
5. Ghi kết quả đầy đủ ra file `D:\springjava\travel\AUDIT_REPORT.md`.

Cuối cùng, tóm tắt cho tôi trong tối đa 10 dòng: có bao nhiêu lỗi mỗi mức, và điều gì đáng lo nhất ngay lúc này.
