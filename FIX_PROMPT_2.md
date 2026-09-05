# Prompt: Fix các lỗi CÒN LẠI — Travel Manager (bản đã public Internet)

> Cách dùng: mở phiên Claude Code mới tại `D:\springjava\travel`, dán từ dòng `---` xuống hết file.

---

Bạn là kỹ sư backend/DevOps. Hãy sửa **các lỗi còn lại** của dự án `D:\springjava\travel` theo danh sách dưới đây, **theo đúng thứ tự**.

## Bối cảnh

- Hệ thống **đang chạy public trên Internet** qua Cloudflare Quick Tunnel (`docker-compose.yml` service `cloudflared` → `frontend:8080`) + Caddy. Mọi endpoint backend giờ ai cũng gọi được.
- Stack: Spring Boot 3 + Java 21 + Gradle KTS + MySQL 8 + JWT (`D:\springjava\travel\travel`); React + Vite + Tailwind (`D:\springjava\travel\react travel manager`).
- File `FIX_PROMPT.md` là audit đợt trước — **phần lớn đã được sửa xong rồi** (Dockerfile JDK 21, PaymentController tự tra giá từ DB + check owner, GlobalExceptionHandler, IDOR huỷ booking, rule `/hotels/*/bookings`, `@Async` email, `.dockerignore`, `SXSSFWorkbook`, container non-root, MySQL không publish port). **Đừng sửa lại những thứ đó.** Danh sách dưới đây là phần còn sót, đã được xác minh lại trên code hiện tại.

## Quy tắc làm việc

1. Với mỗi mục: đọc lại file/dòng được nêu để xác nhận hiện trạng còn khớp. Nếu đã được sửa rồi → ghi "Không còn tồn tại", **không bịa ra việc sửa**.
2. Sửa đúng phạm vi từng mục, không refactor lan sang chỗ không liên quan.
3. Sau mỗi 2–3 mục, build lại phần liên quan để chắc không gãy:
   - Backend: `cd travel && .\gradlew.bat compileJava` (cuối cùng chạy `.\gradlew.bat build -x test`)
   - Frontend: `cd "react travel manager" && npm run build`
4. **KHÔNG tự ý thực thi**, chỉ ghi hướng dẫn rồi hỏi tôi: đổi/rotate secret thật, đổi mật khẩu MySQL, sửa lịch sử git, `git push`, `docker compose down -v`, đổi cấu hình trên cổng VNPay.
5. Không dừng giữa chừng hỏi từng lỗi nhỏ — làm hết rồi báo cáo một lượt.

---

## 🚨 Nhóm 0 — RÒ RỈ DỮ LIỆU KHÁCH HÀNG RA INTERNET (làm trước mọi thứ)

**Nguyên nhân gốc chung:** trong `config\SecurityConfig.java`, rule `permitAll` wildcard ở dòng **78-83** (`GET "/hotels/**"`, `"/tours/**"`, `"/restaurants/**"`, `"/destinations/**"`) đứng **trước** các rule chặt hơn ở dòng 89, 112-118. Spring Security áp dụng **rule khớp đầu tiên**, nên các rule phía sau là **code chết**. Người trước đã sửa đúng cách cho `/hotels/*/bookings` (dòng 75-76: đẩy rule chặt lên TRƯỚC wildcard) — hãy làm y hệt cho các endpoint dưới đây.

### 0.1. `GET /restaurants/bookings/all` — **ai trên Internet cũng gọi được, không cần đăng nhập**
- Endpoint: `controller\restaurant\RestaurantController.java:204` (`allBookings()`) — trong thân method **không có bất kỳ kiểm tra quyền nào**.
- Rule định bảo vệ nó (`SecurityConfig.java:114-115`, `hasAnyRole("ADMIN","STAFF")`) bị dòng 82 (`GET "/restaurants/**"` permitAll) nuốt mất.
- Rò rỉ: `RestaurantBookingResponse` trả `contactName`, `contactPhone`, `contactEmail`, `specialRequests`, `confirmationCode` của **toàn bộ** khách đã đặt bàn.
- Kiểm chứng nhanh trước khi sửa: `curl https://<url-tunnel>/api/v1/restaurants/bookings/all` không kèm cookie → nếu trả JSON danh sách booking là đúng lỗi.

### 0.2. `GET /tours/bookings` — **ai trên Internet cũng gọi được, không cần đăng nhập**
- Endpoint: `controller\tour\TourController.java:255` (`getAllBookings()` → `tourService.getAllBookings()`) — không kiểm tra quyền trong method.
- Bị dòng 81 (`GET "/tours/**"` permitAll) nuốt. Rò rỉ toàn bộ booking tour kèm thông tin liên hệ khách.

### 0.3. `GET /bookings/room/{roomId}` — bất kỳ tài khoản nào cũng xem được khách của mọi phòng
- Endpoint: `controller\hotel\BookedRoomController.java:133` (`getByRoomId`) — không kiểm tra quyền, chỉ rơi vào rule chung `"/bookings/**"` `.authenticated()` (`SecurityConfig.java:119`).
- Chỉ cần đăng ký 1 tài khoản thường rồi duyệt `roomId = 1,2,3...` là lấy được `guestFullName`, `guestEmail`, ngày ở, `bookingConfirmationCode` của mọi khách. Có `bookingConfirmationCode` thì tra tiếp được `GET /bookings/confirmation/{code}` (endpoint này permitAll có chủ đích).

**Cách sửa cho 0.1 + 0.2 + 0.3 — làm cả 2 lớp, đừng chỉ làm 1:**

**Lớp 1 — SecurityConfig:** chèn các rule sau vào **ngay dưới dòng 76** (tức là TRƯỚC block permitAll wildcard dòng 78-83), theo đúng mẫu comment đã có sẵn ở dòng 75:
```java
.requestMatchers(HttpMethod.GET, "/restaurants/bookings/all").hasAnyRole("ADMIN", "STAFF")
.requestMatchers(HttpMethod.GET, "/tours/bookings").hasAnyRole("ADMIN", "STAFF")
.requestMatchers(HttpMethod.GET, "/bookings/room/*").hasAnyRole("ADMIN", "STAFF")
.requestMatchers(HttpMethod.GET, "/restaurants/bookings/my", "/tours/my-bookings").authenticated()
.requestMatchers(HttpMethod.GET, "/hotels/my-favorites", "/tours/my-favorites", "/restaurants/my-favorites").authenticated()
```
Sau đó **xoá** các rule đã thành code chết ở dòng 89 và 112-113 (và phần `"/restaurants/bookings/all"` trong dòng 114-115) để file không còn gây hiểu nhầm là "đã bảo vệ rồi".

**Lớp 2 — kiểm tra quyền ngay trong controller** (phòng khi sau này ai đó sửa lại SecurityConfig làm hở lần nữa): thêm `@PreAuthorize("hasAnyRole('ADMIN','STAFF')")` lên 3 method `RestaurantController.allBookings()`, `TourController.getAllBookings()`, `BookedRoomController.getByRoomId()`. (`@EnableMethodSecurity` đã bật sẵn ở `SecurityConfig.java:29` nên annotation này có hiệu lực ngay.)

**Sau khi sửa, tự kiểm chứng lại bằng `curl`** (không cookie → phải ra 401/403; cookie user thường → 403; cookie admin → 200) và ghi kết quả vào báo cáo.

### 0.4. Rà quét lại **toàn bộ** endpoint bị wildcard nuốt
Nguyên nhân gốc ở trên gần như chắc chắn còn nạn nhân khác mà tôi chưa liệt kê hết.

**Sửa:** liệt kê **mọi** `@GetMapping` của các controller có `@RequestMapping` là `/hotels`, `/tours`, `/restaurants`, `/destinations`, `/rooms`, `/bookings`, rồi đối chiếu từng path với thứ tự rule trong `SecurityConfig`. Với mỗi endpoint, ghi rõ: **rule nào thực sự khớp đầu tiên** và **có đúng ý đồ không**. Endpoint nào trả dữ liệu cá nhân/nội bộ mà đang rơi vào `permitAll` → xử lý theo đúng công thức 2 lớp ở trên. Báo cáo lại thành bảng: `Method | Path | Rule khớp đầu tiên (dòng) | Ý đồ | Kết luận`.

### 0.6. Đặt tour RẺ nhưng chiếm chỗ chuyến ĐẮT — không kiểm tra `departure` có thuộc `tour` không
`controller\tour\TourBookingController.java:59-72`: `tourId` lấy từ path, `departureId` lấy từ body, nhưng **không có chỗ nào kiểm tra `departure.getTour().getId()` có bằng `tourId` hay không**. Giá thì tính từ `tour` (dòng 73-76), còn chỗ ngồi thì trừ vào `departure` (dòng 202-204: `decrementSlot(departure.getId(), needed)`) và `booking.setDeparture(departure)` (dòng 185).

**Kịch bản khai thác:** gọi `POST /tour-bookings/tours/{id-tour-rẻ}` với body `departureId` = chuyến khởi hành của **tour đắt**. Hệ thống tính tiền theo giá tour rẻ, nhưng ghi booking + trừ slot của tour đắt. Khách trả 2 triệu để đi chuyến 20 triệu, đồng thời làm hỏng số chỗ trống của tour đắt.

**Sửa:** ngay sau khi load `departure` (dòng 70-71), thêm:
```java
if (departure.getTour() == null || !departure.getTour().getId().equals(tourId)) {
    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
            "Chuyến khởi hành không thuộc tour này");
}
```
Rà thêm: `request.getRoomId()` (dòng 105) và `request.getRestaurantId()` (dòng 139) cũng nhận id tuỳ ý từ client — kiểm tra xem có ràng buộc nghiệp vụ nào bị bỏ qua tương tự không (ví dụ phòng/nhà hàng phải cùng thành phố với điểm đến của tour, như luồng `BookedRoomController.java:60-68` đã làm) và bổ sung nếu thiếu.

### 0.7. Booking khách sạn không có chủ sở hữu thật — quyền dựa trên email do client tự khai
`domain\hotel\BookedRoom.java` **không có** quan hệ `@ManyToOne UserEntity user` (chỉ có `guestEmail` là `String`). `BookingRequest.guestEmail` chỉ được validate `@NotBlank` và được ghi thẳng vào booking (`service\hotel\BookedRoomServiceImpl.java:57`), **không bao giờ đối chiếu với user đang đăng nhập**.

Toàn bộ cơ chế phân quyền của module khách sạn đang dựa trên chuỗi email này:
- `BookedRoomController.java:154-155` (huỷ booking) so `booking.getGuestEmail()` với email đăng nhập.
- `PaymentController.java:241-242` (thanh toán) cũng so `guestEmail`.

**Hai hệ quả đều là lỗi thật:**
1. **Đặt phòng nhân danh người khác:** user A đăng nhập rồi gửi `guestEmail = victim@gmail.com`. Phòng bị chiếm, và `BookedRoomController.java:73-79` gửi **email xác nhận đặt phòng tới nạn nhân** bằng chính Gmail thật của đồ án → biến hệ thống thành công cụ spam/phishing.
2. **Người đặt tự khoá mình:** nếu gõ nhầm email (hoặc cố tình đặt hộ người thân), chính họ **không huỷ và không thanh toán được** booking vừa tạo, vì cả 2 chỗ trên đều so với email đăng nhập.

**Sửa:**
- Thêm `@ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private UserEntity user;` vào `BookedRoom` (giống `TourBooking` và `RestaurantBooking` đã có).
- `bookRoom(...)` nhận thêm user hiện tại và `booking.setUser(currentUser)`. Nếu `guestEmail` khác email đăng nhập thì vẫn cho lưu (đặt hộ người thân là nhu cầu thật) nhưng **quyền huỷ/thanh toán phải xét theo `booking.getUser()`**, không xét `guestEmail`.
- Sửa `BookedRoomController.cancelBooking` (`:154`) và `PaymentController.resolveTrustedAmount` nhánh `"HOTEL"` (`:241`) sang so `booking.getUser().getId()` với user hiện tại (giữ nguyên nhánh ADMIN/STAFF).
- **Lưu ý migration:** `ddl-auto=update` sẽ tự thêm cột `user_id` NULL cho các booking cũ. Xử lý `user == null` (dữ liệu cũ) bằng cách fallback về so `guestEmail` như hiện tại, kèm comment `// dữ liệu cũ trước khi có cột user_id`.

### 0.8. STAFF được cấp quyền ghi đè dữ liệu hàng loạt ngoài ý định
`SecurityConfig.java:71-72` mở `"/admin/places/**"` cho `hasAnyRole("ADMIN","STAFF")`, với comment ghi rõ ý định là *"Google Places search/photo dùng chung bởi ADMIN và STAFF khi tạo/sửa hotel/restaurant"*. Nhưng wildcard `**` cũng nuốt luôn `AdminPlacesBackfillController` (`@RequestMapping("/admin/places/backfill")`), và rule này đứng **trước** dòng 73 (`/admin/**` = chỉ ADMIN).

`POST /admin/places/backfill/hotels` (và `/restaurants`, `/tours`) **duyệt toàn bộ bảng** (`hotelRepository.findAll()`), gọi API bên ngoài (OpenTripMap) rồi **ghi đè `description` và `photo`** của mọi bản ghi thiếu dữ liệu, `save` trực tiếp. Đây là thao tác quản trị dữ liệu diện rộng, không phải "search/photo".

**Sửa:**
- Thêm `.requestMatchers("/admin/places/backfill/**").hasRole("ADMIN")` **ngay TRƯỚC** dòng 72 (rule cụ thể phải đứng trước wildcard — đúng nguyên tắc đã áp dụng ở dòng 75-76).
- Nhân tiện gia cố chính endpoint backfill: nó tải ảnh từ URL do dịch vụ ngoài trả về (`applyPhoto(details.previewUrl(), ...)`) rồi lưu thẳng vào DB dạng BLOB, **không giới hạn kích thước, không timeout**. Thêm giới hạn dung lượng ảnh tải về (ví dụ 5MB, dùng chung hằng số với `ImageUploadValidator` ở mục 4) và timeout kết nối cho `OpenTripMapService`.

### 0.5. CSRF đang tắt, `SameSite` là lớp phòng thủ DUY NHẤT — đọc kỹ trước khi làm mục 5
`SecurityConfig.java:51` có `.csrf(AbstractHttpConfigurer::disable)` trong khi JWT được lưu ở **cookie** (`AuthController.java:86,130,194`). Nghĩa là không có CSRF token nào cả, và thứ duy nhất chặn website khác thay mặt user gửi request có kèm cookie chính là thuộc tính `SameSite`.

**Ràng buộc bắt buộc khi làm mục 5 bên dưới:** được phép đổi `Strict` → `Lax` (Lax vẫn chặn POST/PUT/PATCH/DELETE cross-site, chỉ nới cho điều hướng GET top-level — đúng nhu cầu luồng quay về từ VNPay). **Tuyệt đối KHÔNG được đặt `SameSite=None`** — làm vậy là mở toang CSRF cho toàn bộ API. Nếu vì lý do nào đó thấy cần `None`, dừng lại và hỏi tôi.

---

## 🔴 Nhóm 1 — Do vừa public ra Internet (làm trước)

### 1. Security header **không hề được áp dụng** trên URL public
`Caddyfile:3` vẫn là placeholder `YOUR_SERVER_IP.nip.io` (chưa thay), đồng thời `docker-compose.yml` cho `cloudflared` chạy `tunnel --url http://frontend:8080` → traffic public **đi thẳng vào nginx của frontend, bypass hoàn toàn Caddy**. Kết quả: block `header { HSTS / X-Frame-Options / X-Content-Type-Options / Referrer-Policy }` trong `Caddyfile` chưa bao giờ có tác dụng, và container `caddy` đang chiếm port 80/443 cho một hostname không tồn tại.

**Sửa:** chuyển các security header sang `react travel manager\nginx.conf` (nơi traffic thật đi qua) bằng `add_header ... always`:
- `X-Frame-Options "DENY"`
- `X-Content-Type-Options "nosniff"`
- `Referrer-Policy "strict-origin-when-cross-origin"`
- `Permissions-Policy "geolocation=(), microphone=(), camera=()"`
- **Không** thêm HSTS ở đây (Cloudflare đã lo TLS ở edge, thêm HSTS ở tầng này dễ tự khoá mình khi test HTTP local).

Đồng thời trong `docker-compose.yml`: comment/tắt service `caddy` khi còn dùng Quick Tunnel (ghi rõ comment là "chỉ bật khi có domain thật"), để nó không giữ port 80/443 vô ích. Giữ nguyên `Caddyfile`, chỉ thêm comment ở đầu file rằng nó chỉ dùng khi có domain/VPS thật.

### 2. Không có rate limit trên bất kỳ endpoint nào
Xác minh: `grep -rn "RateLimit\|Bucket4j"` trong `travel\src\main\java` không ra kết quả nào. Các endpoint public trong `controller\AuthController.java`: `/login:76`, `/auth/google:93`, `/send-reset-otp:148`, `/reset-password:153`, `/send-otp:158`, `/verify-otp:170`. `/send-otp` và `/send-reset-otp` gửi mail qua Gmail App Password → bị spam từ Internet là **khoá luôn tài khoản Gmail thật**, và `/login` + `/verify-otp` bị brute-force OTP không giới hạn.

**Sửa:** thêm rate limit đơn giản, không cần thư viện ngoài — viết một `RateLimitFilter` (hoặc `HandlerInterceptor`) dùng `ConcurrentHashMap<String, Deque<Long>>` khoá theo IP (đọc `X-Forwarded-For` trước, fallback `getRemoteAddr()` — vì đứng sau proxy nên `getRemoteAddr()` luôn là IP nội bộ docker):
- `/send-otp`, `/send-reset-otp`: tối đa **3 request / 10 phút / IP** (và thêm giới hạn theo email trong body nếu dễ lấy)
- `/login`, `/verify-otp`, `/reset-password`: tối đa **10 request / 5 phút / IP**
- Vượt ngưỡng → trả HTTP **429** với shape lỗi thống nhất `{statusCode, message}` giống `response\ErrorResponse.java`.
- Dọn entry cũ định kỳ (hoặc dọn lazy khi ghi) để map không phình vô hạn.
Đăng ký filter này trong `config\SecurityConfig.java` đặt **trước** `JwtRequestFilter`.

### 3. Log rò rỉ dữ liệu + ồn trên bản public
`travel\src\main\resources\application.properties`:
- `:7 spring.jpa.show-sql=true` → in toàn bộ SQL (kèm dữ liệu người dùng) ra log container.
- `:36-37 logging.level.org.springframework.web.multipart=DEBUG` và `logging.level.org.apache.tomcat.util.http.fileupload=DEBUG`.

**Sửa:** đưa cả 3 dòng về mặc định tắt cho production, nhưng vẫn bật được khi dev bằng biến môi trường:
- `spring.jpa.show-sql=${JPA_SHOW_SQL:false}`
- 2 dòng logging DEBUG → `${MULTIPART_LOG_LEVEL:WARN}` (hoặc xoá hẳn).
Không thêm biến mới vào `.env` production (mặc định đã là tắt).

### 4. Upload file không whitelist kiểu file
Xác minh: `grep -rn "getContentType"` trong `service\hotel\RoomService.java` và `service\tour\TourService.java` không có kết quả. `application.properties:33-34` cho phép `max-file-size=20MB` / `max-request-size=50MB`. Có ~11 controller nhận `MultipartFile` (`AdminHotelController`, `AdminRestaurantController`, `AdminStaffController`, `AdminTourController`, `DestinationController`, `HotelController`, `RoomController`, `IncidentReportController`, `ProfileController`, `RestaurantController`, `TourController`).

**Sửa:** viết **một** util dùng chung, ví dụ `util\ImageUploadValidator.java` với method `validateImage(MultipartFile file)`:
- Chặn file rỗng.
- Whitelist content-type: `image/jpeg`, `image/png`, `image/webp`, `image/gif`.
- Whitelist đuôi file (lowercase): `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`.
- Chặn tên file chứa `..`, `/`, `\` (path traversal).
- Giới hạn kích thước ảnh riêng: **5MB** (nhỏ hơn giới hạn multipart chung).
- Sai → ném `IllegalArgumentException` với message tiếng Việt rõ ràng (đã có handler trả 400 sẵn ở `GlobalExceptionHandler:70`).
Gọi util này ở **mọi** chỗ nhận `MultipartFile` ảnh trong các service/controller nêu trên. Hạ `spring.servlet.multipart.max-file-size` xuống `10MB` và `max-request-size` xuống `30MB`.

### 5. ~~Cookie `SameSite=Strict` gãy luồng quay về từ VNPay~~ — ĐÃ KIỂM CHỨNG: KHÔNG PHẢI LỖI, ĐỪNG SỬA
Nghi vấn ban đầu: `controller\AuthController.java:86,130,194` set cookie JWT `.sameSite("Strict")`, nên khi VNPay redirect ngược về thì cookie không đi kèm điều hướng cross-site.

**Đã kiểm tra và kết luận là KHÔNG ảnh hưởng**, vì hai lý do:
1. `src\pages\payment\PaymentResultPage.tsx:21` gọi `api.get('/payment/result' + location.search)` — endpoint này đã `permitAll` sẵn (`SecurityConfig.java:57`), **không cần cookie**.
2. Trang HTML do nginx phục vụ tĩnh (không cần auth), và mọi request XHR sau đó là **same-site** (từ origin trycloudflare gọi về chính nó) → `SameSite=Strict` không chặn.

**Việc cần làm ở mục này: KHÔNG làm gì cả.** Giữ nguyên `Strict`. Đọc kỹ mục 0.5 — vì CSRF đang tắt, `Strict` hiện là lớp phòng thủ CSRF mạnh nhất đang có; hạ xuống `Lax` là **làm yếu đi mà không đổi lại được gì**. Chỉ ghi vào báo cáo: "đã xác minh, không phải lỗi".

### 6. URL public hardcode trong `.env` → đổi tunnel là sập thanh toán
`.env` đang ghi cứng URL Quick Tunnel hiện tại ở `VNPAY_RETURN_URL` và `APP_CORS_ALLOWED_ORIGINS`. Quick Tunnel **sinh URL ngẫu nhiên mới mỗi lần restart** `cloudflared` → sau restart, CORS chặn frontend và VNPay redirect về URL chết.

**Sửa (không đụng vào giá trị secret nào):** tạo script `update-tunnel-url.ps1` ở thư mục gốc, làm các việc sau:
- Đọc URL tunnel hiện tại từ `docker compose logs cloudflared` (bắt regex `https://[a-z0-9-]+\.trycloudflare\.com`).
- Ghi đè **chỉ 2 dòng** `VNPAY_RETURN_URL=` và `APP_CORS_ALLOWED_ORIGINS=` trong `.env` (giữ nguyên mọi dòng khác, giữ nguyên phần `,http://localhost:5173,http://localhost:5174`).
- In ra URL mới + nhắc chạy `docker compose up -d --force-recreate backend frontend`.
Thêm mục hướng dẫn ngắn vào `README` gốc (tạo `README.md` ở `D:\springjava\travel` nếu chưa có) mô tả quy trình mỗi lần bật lại demo.

---

## 🟠 Nhóm 2 — Chất lượng / còn sót từ audit cũ

### 7. `ddl-auto=update` trên bản đang chạy public
`application.properties:6`. Với dữ liệu demo thật đang chạy, Hibernate tự đổi schema khi entity đổi là rủi ro mất/hỏng dữ liệu.

**Sửa:** đổi thành `spring.jpa.hibernate.ddl-auto=${JPA_DDL_AUTO:update}` để ít nhất override được bằng env, và thêm comment cảnh báo nên set `validate` khi demo/bảo vệ đồ án. **Không** tự đổi mặc định sang `validate` (sẽ làm app không khởi động được nếu schema hiện tại lệch) — chỉ báo lại cho tôi biết cần chạy `validate` lúc nào.

### 8. `axiosInstance` fallback về `localhost:8081`
`react travel manager\src\api\axiosInstance.js:10`: `baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:8081/api/v1"`. Nếu lúc `docker build` quên truyền `VITE_API_BASE_URL`, bundle public sẽ gọi `localhost:8081` của **máy người dùng** → toàn bộ app chết mà không có thông báo rõ ràng.

**Sửa:** đổi fallback thành `"/api/v1"` (đường dẫn tương đối — luôn đúng khi chạy sau nginx proxy, và vẫn chạy được ở dev nhờ proxy của Vite). Kiểm tra `vite.config.js` có khai báo `server.proxy` cho `/api` trỏ về `http://localhost:8081` chưa; nếu chưa thì thêm, để dev không gãy sau thay đổi này.

### 9. `Menubar.jsx` trùng chức năng với `Navbar.tsx`
`react travel manager\src\components\Menubar.jsx` vs `src\components\layout\Navbar.tsx`. (Phần logout đã được gộp đúng về `AppContext.jsx:58-60` rồi — **không sửa lại logout**.)

**Sửa:** kiểm tra `Menubar.jsx` còn được import ở đâu không (`grep -rn "Menubar" src`). Nếu **không** còn nơi nào import → xoá file. Nếu **còn** được dùng → thay chỗ dùng đó bằng `Navbar` rồi xoá `Menubar.jsx`, đảm bảo `npm run build` vẫn xanh.

### 10. `src\types\index.ts` có interface lỗi thời / dead code
**Sửa:** với mỗi interface trong file, `grep` xem có được import ở đâu không. Interface không được dùng ở bất kỳ đâu → xoá. Interface **đang dùng** nhưng field lệch với DTO backend tương ứng (`travel\...\domain\response\...`) → cập nhật cho khớp. Ghi lại danh sách đã xoá/đã sửa.

### 11. Dọn rác trong thư mục làm việc
Các file rác đang nằm local (đã kiểm tra: **không** file nào bị git track, nên xoá là an toàn):
`react travel manager\hs_err_pid20768.log`, `hs_err_pid8636.log`, `vite-dev2.log`, `vite-dev3.log`, `tsconfig.tsbuildinfo`; `travel\backend-run.log`, `travel\cookies.txt`; gốc: `compose-up.log`, `frontend-rebuild.log`, `rebuild-public.log`.

**Sửa:** xoá các file trên, rồi bổ sung vào `.gitignore` của repo tương ứng (nếu chưa có): `*.log`, `hs_err_pid*.log`, `cookies.txt`, `tsconfig.tsbuildinfo`, `.env`.
**Lưu ý:** `travel\cookies.txt` có thể chứa session cookie thật → xoá hẳn, đừng chỉ gitignore.

### 12. Test suite gần như rỗng
`travel\src\test` chỉ có 1 file (`TravelManagerApplicationTests.contextLoads()`).

**Sửa:** viết unit test (JUnit 5 + Mockito, mock repository — **không** cần DB thật, không cần `@SpringBootTest` nặng) cho đúng 4 luồng rủi ro nhất, mỗi luồng 2–3 case:
1. `PaymentController.resolveTrustedAmount` — booking của người khác → từ chối; amount lấy từ DB chứ không từ request.
2. `BookedRoomServiceImpl.cancelBooking` — user thường huỷ booking của người khác → bị chặn; ADMIN/STAFF thì được.
3. Tính giá / số đêm khi đặt phòng — check-out phải sau check-in, số đêm đúng, không off-by-one.
4. Đặt tour — `decrementSlot` khi hết chỗ phải fail, không cho âm slot.
Chạy `.\gradlew.bat test` cho xanh mới coi là xong.

### 13. Thanh toán thành công nhưng booking kẹt ở PENDING, VNPay không retry
`service\PaymentIpnService.java:61-68`: sau khi `compareAndSwap` đã set payment = `SUCCESS`, hàm gọi `confirmBooking(...)` trong `try/catch` chỉ `log.error` rồi **vẫn `return "00"`** (báo VNPay "Confirm Success"). Nếu `confirmBooking` ném exception (booking bị xoá, sai `bookingType`, lỗi DB), khách **đã mất tiền** nhưng booking vĩnh viễn ở `PENDING`, và vì trả "00" nên VNPay **không bao giờ gọi lại IPN** → không có cơ hội tự phục hồi.

**Sửa:**
- Khi `confirmBooking` ném exception: **không** trả "00". Trả mã lỗi để VNPay retry (theo tài liệu VNPay dùng `"99"` → `RspCode 99 / Unknown error`), và để transaction rollback đúng cách — lưu ý `@Transactional` ở dòng 33 là `jakarta.transaction.Transactional`, exception đã bị `catch` nuốt nên rollback **không** xảy ra; phải ném lại hoặc gọi `TransactionAspectSupport.currentTransactionStatus().setRollbackOnly()`.
- Cân nhắc thêm cột/enum trạng thái trung gian (ví dụ `SUCCESS_UNCONFIRMED`) hoặc ít nhất `log.error` kèm đủ thông tin để đối soát tay.
- Thêm mã "99" vào `switch` xử lý mã trả về ở `PaymentController.ipn()` (`:129-135`) — hiện `default` đang gộp mọi mã lạ thành "00".

### 14. Nhiều endpoint load nguyên bảng vào RAM rồi mới lọc/phân trang
- `PaymentController:167-175` (`/payment/my`): `findByUserEmail(email)` lấy **tất cả** rồi sort + phân trang bằng Java.
- `PaymentController:190-215` (`/payment/admin/payments`): `findAllByOrderByCreatedAtDesc()` lấy **toàn bộ** bảng payment rồi filter `status`/`orderType`/`search` bằng `Stream` trong bộ nhớ.
- `RestaurantController:204` (`allBookings`), `BookedRoomController:126` (`getAllBookings`), `TourController:255` (`getAllBookings`): **không phân trang gì cả**, trả toàn bộ booking trong 1 response.

**Sửa:** chuyển sang phân trang ở tầng DB — repository nhận `Pageable` và trả `Page<T>`, filter đẩy vào query (dùng `@Query` với điều kiện `:status is null or p.status = :status` hoặc `Specification`). Với 3 endpoint `all*` đang trả `List`, thêm tham số `page`/`size` (mặc định `size=20`) và trả `Page<T>`; **nhớ sửa cả frontend** ở chỗ gọi các API này cho khớp shape mới (`res.data.content`), rồi `npm run build` cho xanh.

### 15. Đặt phòng trong gói tour không khoá row → double booking
`controller\tour\TourBookingController.java:105` dùng `roomRepository.findById(...)` rồi mới kiểm tra trùng lịch (`:112-119`) và `save`. Trong khi đó luồng đặt phòng lẻ `service\hotel\BookedRoomServiceImpl.java:28` đã làm đúng bằng `roomRepository.findByIdForUpdate(...)` (khoá bi quan). Hai luồng **ghi cùng một bảng**, nên luồng không khoá làm vô hiệu hoá luồng có khoá: 2 request đồng thời (1 gói tour + 1 đặt lẻ, hoặc 2 gói tour) đều qua được check trùng lịch → 1 phòng bị bán 2 lần.

**Sửa:** đổi dòng 105 sang `roomRepository.findByIdForUpdate(request.getRoomId())`. Method `book()` đã có `@Transactional` (dòng 58) nên khoá sẽ giữ tới hết transaction.

### 16. OTP sinh bằng PRNG không dùng cho mật mã
`service\ProfileServiceImpl.java:123` và `:179` dùng `ThreadLocalRandom.current().nextInt(100000, 1000000)`. `ThreadLocalRandom` là PRNG tuyến tính, **không** an toàn mật mã — output đoán được nếu quan sát được một số giá trị. Đây là OTP dùng cho **reset mật khẩu** → dẫn tới chiếm tài khoản.

**Sửa:** khai báo một `private static final SecureRandom SECURE_RANDOM = new SecureRandom();` trong class và đổi cả 2 chỗ sang `String.format("%06d", SECURE_RANDOM.nextInt(1_000_000))` (lưu ý dùng `%06d` để OTP bắt đầu bằng số 0 vẫn đủ 6 chữ số — cách cũ `nextInt(100000, 1000000)` đã loại bỏ mọi OTP bắt đầu bằng 0, làm giảm không gian khoá).

### 17. `/send-otp` và `/send-reset-otp` gửi mail tới địa chỉ tuỳ ý, không cần đăng nhập
`controller\AuthController.java:148-151` (`sendResetOtp(@RequestParam email)`) và `:158-167` (`sendVerifyOtp`, khi chưa đăng nhập thì lấy email từ body). Cả hai đều `permitAll` (`SecurityConfig.java:53-55`). Kẻ tấn công gửi email bất kỳ vào đó → hệ thống dùng **Gmail thật của đồ án** bắn mail tới nạn nhân. Không giới hạn số lần.

**Sửa:** đây là lý do mục 2 (rate limit) là bắt buộc, nhưng cần thêm 2 việc:
- Giới hạn theo **email** trong body/param nữa, không chỉ theo IP (cùng 1 IP đổi email liên tục vẫn spam được nhiều nạn nhân; cùng 1 email từ nhiều IP vẫn dội bom được 1 nạn nhân).
- `sendResetOtp` khi email không tồn tại: hiện `ProfileServiceImpl.java:118-121` ném lỗi "không tìm thấy" → lộ email nào đã đăng ký (user enumeration). Đổi sang **luôn trả 200** bất kể email có tồn tại hay không, chỉ gửi mail khi thực sự có tài khoản.

### 18. Vài lỗi nhỏ, gom lại sửa một lượt
- **500 thay vì 401:** `RuntimeException("Not authenticated")` xuất hiện ở `TourController.java:250`, `TourBookingController.java:64`, `RestaurantController.java:196`, `StaffController.java:34,47`. Đổi hết sang `new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Chưa đăng nhập")`.
- **Giá phòng không đóng băng lúc đặt:** `PaymentController.java:243-244` tính lại `roomPrice × nights` tại thời điểm thanh toán. Admin sửa giá phòng giữa lúc khách đặt và lúc khách trả tiền → khách trả giá mới. Sửa: thêm cột `totalPrice` vào `BookedRoom`, chốt giá ngay lúc `bookRoom`, `resolveTrustedAmount` đọc cột đó (fallback tính lại nếu null cho dữ liệu cũ).
- **Đặt bàn được xác nhận trước khi trả tiền:** `TourBookingController.java:167` set `RestaurantBookingStatus.CONFIRMED` ngay lúc tạo, trong khi tour vẫn `PENDING` chờ thanh toán. Nếu khách bỏ không thanh toán, chỗ ở nhà hàng vẫn bị giữ. Sửa: để `PENDING`, và cho `PaymentIpnService.confirmBooking` nhánh `"TOUR"` xác nhận luôn `restaurantBooking` đi kèm.

### 19. Đổi/reset mật khẩu bỏ qua hoàn toàn chính sách độ dài
Lúc đăng ký có ràng buộc `@Size(min = 6)` (`domain\request\ProfileRequest.java:24`), nhưng 2 đường vòng để đặt mật khẩu mới thì **không có ràng buộc nào**:
- `domain\request\ResetPasswordRequest.java:14-15`: `newPassword` chỉ có `@NotBlank`.
- `controller\ProfileController.java:76-82`: `changePassword` nhận `@RequestBody ChangePasswordRequest` **không có `@Valid`**, và class `ChangePasswordRequest` (khai báo inner ở cuối file) **không có annotation validate nào**.

Kết quả: user đặt được mật khẩu `"1"` qua `/reset-password` hoặc `/profile/change-password`, rồi mật khẩu đó dùng đăng nhập bình thường.

**Sửa:** thêm `@Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")` vào `ResetPasswordRequest.newPassword` và vào `ChangePasswordRequest.newPassword`, đồng thời thêm `@Valid` vào tham số `@RequestBody` của `ProfileController.changePassword` (không có `@Valid` thì annotation trên DTO không chạy). Rà thêm `UpdateProfileRequest` ở `ProfileController.java:60-66` — cũng đang thiếu `@Valid`.

### 20. Đổi quyền / xoá tài khoản không có hiệu lực cho tới 10 tiếng sau
`filter\JwtRequestFilter.java:88-90` dựng authority từ **claim `roles` trong token** (`jwtUtil.extractRoles(jwt)`), không đọc lại role từ DB. Token sống 10 tiếng (`util\JwtUtil.java:42`).

Hệ quả:
- ADMIN hạ quyền một STAFF qua `PUT /admin/users/{id}/role` → người đó **vẫn giữ quyền STAFF thêm tối đa 10 tiếng**.
- Filter đã đọc DB để kiểm tra khoá tài khoản (`:80-87`) — nhưng nếu `userOpt` **rỗng** (tài khoản đã bị xoá) thì code rơi thẳng xuống nhánh authenticate, tức **user đã xoá vẫn dùng token bình thường**.
- Không có cơ chế thu hồi token khi logout (đã ghi nhận ở `FIX_PROMPT.md` mục 36).

**Sửa (tối thiểu, không cần dựng blacklist):** trong khối đã đọc `userOpt` sẵn ở dòng 80:
- Nếu `userOpt.isEmpty()` → **không** set authentication (để request đi tiếp như ẩn danh), thay vì bỏ qua như hiện tại.
- Dựng authority từ `userOpt.get().getRole()` trong DB thay vì từ claim trong token. Vì đằng nào cũng đã query user rồi nên **không tốn thêm query nào**. Giữ claim `roles` trong token để FE dùng hiển thị, nhưng phía server không tin nó nữa.

### 21. Overbooking nhà hàng do đọc-rồi-ghi không khoá
`controller\restaurant\RestaurantController.java:151-158` và `controller\tour\TourBookingController.java:147-153` đều: gọi `sumGuestCountByRestaurantAndDateTime(...)` để cộng số khách đã đặt → so với `restaurant.getCapacity()` → rồi mới `save`. Không có khoá nào giữa bước đọc và bước ghi.

Hai request đồng thời cùng khung giờ đều thấy "còn chỗ" → nhà hàng nhận quá sức chứa. Đây đúng là loại lỗi mà luồng đặt phòng đã xử lý bằng `findByIdForUpdate` và luồng đặt tour đã xử lý bằng `decrementSlot` nguyên tử.

**Sửa:** thống nhất theo mẫu đã đúng trong codebase — thêm `findByIdForUpdate` cho `Restaurant` (theo mẫu `RoomRepository.findByIdForUpdate`) và dùng nó ở cả 2 chỗ trên; đảm bảo cả 2 method đều `@Transactional` (`RestaurantController.book` hiện chưa có, `TourBookingController.book` đã có ở dòng 58).

### 22. Dọn phụ thuộc
`build.gradle.kts`:
- `io.jsonwebtoken:jjwt-*:0.11.5` là bản cũ; `JwtUtil` đang dùng API đã deprecated (`setClaims`, `setSubject`, `parserBuilder`). Nâng lên `0.12.x` và đổi sang API mới (`claims()`, `subject()`, `Jwts.parser()`), rồi chạy lại test đăng nhập cho chắc.
- `spring-boot-starter-thymeleaf` + `thymeleaf-extras-springsecurity6`: kiểm tra `src\main\resources\templates` có template nào thực sự được dùng không (email đang gửi bằng chuỗi HTML trong `EmailService` hay bằng template?). Nếu không dùng → xoá cả 2 dependency cho nhẹ image.

---

## Sau khi làm xong tất cả

1. Build full: `cd travel && .\gradlew.bat build` và `cd "react travel manager" && npm run build && npm run lint`.
2. Rebuild + chạy lại stack để chắc không gãy runtime: `docker compose build backend frontend` rồi `docker compose up -d`, sau đó `docker compose ps` + `docker compose logs --tail=50 backend` xem có lỗi khởi động không.
3. Báo cáo lại danh sách đầy đủ (0.1–0.8 và 1–22, trong đó mục 5 chỉ để xác nhận "không phải lỗi") kèm trạng thái: **Đã sửa / Không còn tồn tại / Chờ tôi xác nhận**, mỗi mục 1 dòng tóm tắt thay đổi. Riêng nhóm 0 phải kèm kết quả `curl` chứng minh endpoint đã bị chặn.
4. Nếu trong lúc sửa lộ ra bug mới ngoài danh sách → báo riêng ở cuối, **không tự ý mở rộng phạm vi**.
