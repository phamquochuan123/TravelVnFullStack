# Travel Manager — hướng dẫn chạy và công khai link

## ⚠️ Trước tiên: m đang dùng cmd hay PowerShell?

Nhìn dấu nhắc lệnh:

- `D:\springjava\travel>` → **cmd.exe**
- `PS D:\springjava\travel>` → **PowerShell**

Hai cái dùng lệnh khác nhau. Bên dưới ghi cả hai; chọn đúng cột của mình.
Muốn dùng bản PowerShell trong khi đang ở cmd thì gõ `powershell` rồi Enter.

| Việc | cmd.exe | PowerShell |
|---|---|---|
| Lọc dòng trong output | `findstr abc` | `Select-String abc` |
| Chạy file `.ps1` | `powershell -ExecutionPolicy Bypass -File x.ps1` | `.\x.ps1` |
| Ký tự `%` trong `curl -w` | viết `%%` | viết `%` |

---

## Mở link public (làm mỗi khi bật lại máy / restart Docker)

Mở terminal tại thư mục `D:\springjava\travel` — **không phải** `D:\springjava\travel\travel` —
rồi chạy 2 lệnh sau, đúng thứ tự.

### Bước 1 — lấy URL mới và ghi vào `.env`

PowerShell:
```powershell
.\update-tunnel-url.ps1
```

cmd.exe:
```cmd
powershell -ExecutionPolicy Bypass -File update-tunnel-url.ps1
```

Script sẽ in ra:

```
Dang doc URL tunnel tu log cloudflared...
URL tunnel hien tai: https://xxxx-yyyy-zzzz.trycloudflare.com

Da cap nhat .env:
  VNPAY_RETURN_URL=https://xxxx-yyyy-zzzz.trycloudflare.com/payment/result
  APP_CORS_ALLOWED_ORIGINS=https://xxxx-yyyy-zzzz.trycloudflare.com,http://localhost:5173,http://localhost:5174
```

**Dòng `URL tunnel hien tai` chính là link để gửi cho người khác.**

Script chỉ ghi đè đúng 2 dòng trong `.env`, mọi dòng khác (mật khẩu DB, JWT secret, mail...)
giữ nguyên không đụng tới.

### Bước 2 — nạp lại backend để nó nhận URL mới

```powershell
docker compose up -d --force-recreate backend
```

Đợi khoảng 20–60 giây (máy đang bận thì lâu hơn). Kiểm tra đã lên chưa:

cmd.exe:
```cmd
docker compose logs backend | findstr "Started TravelManagerApplication"
```

PowerShell:
```powershell
docker compose logs backend | Select-String "Started TravelManagerApplication"
```

Thấy dòng `Started TravelManagerApplication in ... seconds` là xong.
Đừng dùng `--tail=5` để kiểm — backend in rất nhiều dòng lúc khởi động,
5 dòng cuối thường rơi vào giữa chừng và trông như bị treo.

---

## Vì sao phải làm cả 2 bước

Cloudflare Quick Tunnel **sinh một URL ngẫu nhiên MỚI mỗi lần container `cloudflared` khởi động lại**.
URL cũ chết ngay lập tức. Trong khi đó `.env` lưu URL ở 2 chỗ mà backend cần:

| Biến | Dùng để làm gì | Sai thì hỏng cái gì |
|---|---|---|
| `APP_CORS_ALLOWED_ORIGINS` | Danh sách origin được phép gọi API | Trình duyệt chặn **toàn bộ** lời gọi API — web mở ra trắng trơn, không load được dữ liệu |
| `VNPAY_RETURN_URL` | Nơi VNPay chuyển khách về sau khi trả tiền | Trả tiền xong bị đá về URL chết, không thấy kết quả |

Bước 1 sửa file `.env`. Nhưng **backend chỉ đọc `.env` lúc khởi động**, nên phải có bước 2
để nó nạp lại giá trị mới. Bỏ bước 2 là web vẫn dùng URL cũ → CORS chặn hết.

**Không cần build lại frontend.** Frontend gọi API bằng đường dẫn tương đối `/api/v1`
(qua nginx proxy) chứ không nhúng URL tuyệt đối vào bundle, nên URL đổi không ảnh hưởng nó.

---

## Khi nào phải chạy lại 2 bước

- Khởi động lại máy tính
- Bật/tắt lại Docker Desktop
- Chạy `docker compose up`, `docker compose restart`, `docker compose down` có đụng `cloudflared`

Chỉ recreate riêng `backend` hoặc `frontend` thì **không** cần, vì `cloudflared` không bị động tới.

---

## Chỉ muốn xem URL, không sửa gì

cmd.exe:
```cmd
docker compose logs cloudflared | findstr trycloudflare
```

PowerShell:
```powershell
docker compose logs cloudflared | Select-String trycloudflare
```

---

## Kiểm tra hệ thống chạy đúng

Thay `<URL>` bằng link vừa lấy được.

cmd.exe (chú ý `%%`):
```cmd
curl -s -o NUL -w "%%{http_code}\n" <URL>/
curl -s -o NUL -w "%%{http_code}\n" <URL>/api/v1/tours
curl -s -o NUL -w "%%{http_code}\n" <URL>/api/v1/restaurants/bookings/all
```

PowerShell:
```powershell
curl.exe -s -o NUL -w "%{http_code}`n" <URL>/
curl.exe -s -o NUL -w "%{http_code}`n" <URL>/api/v1/tours
curl.exe -s -o NUL -w "%{http_code}`n" <URL>/api/v1/restaurants/bookings/all
```

Mong đợi lần lượt: `200` (trang chủ), `200` (API công khai),
`401` (endpoint admin — trả 401 nghĩa là đang được bảo vệ đúng).

Xem trạng thái toàn bộ container:

```powershell
docker compose ps
```

Phải thấy đủ 4 dòng `backend`, `frontend`, `db`, `cloudflared` ở trạng thái `Up`
(riêng `db` có thêm `healthy`).

---

## Lưu ý khi demo

- **Ai có link đều vào được**, không có lớp bảo vệ nào phía trước. Xong buổi demo nên tắt:
  `docker compose stop cloudflared`
- **Máy phải bật.** Tunnel chạy từ chính máy này, tắt máy là link chết.
- Link đổi mỗi lần restart nên **đừng in link vào slide** — lấy link ngay trước lúc trình bày.

---

## Xử lý sự cố

**Web mở được nhưng không có dữ liệu, F12 báo lỗi CORS**
→ Quên bước 2. Chạy `docker compose up -d --force-recreate backend`.

**`.\update-tunnel-url.ps1` báo không tìm thấy file**
→ Đang đứng sai thư mục. Script nằm ở `D:\springjava\travel`, không phải `D:\springjava\travel\travel`.
Chạy `cd D:\springjava\travel` trước.
(Lệnh `docker compose` thì chạy được ở cả hai chỗ vì nó tự tìm ngược lên thư mục cha,
nhưng đường dẫn `.\` thì không.)

**URL không phản hồi gì cả, kể cả trang chủ, dù container vẫn `Up`**
→ Tunnel đứt kết nối. Kiểm tra: `docker compose logs cloudflared --tail=20`,
nếu thấy lặp đi lặp lại

```
ERR Serve tunnel error error="control stream encountered a failure while serving"
INF Retrying connection in up to 1m4s
```

thì tunnel hỏng thật (Quick Tunnel không cam kết uptime, thỉnh thoảng đứt).
Khắc phục: `docker compose up -d --force-recreate cloudflared`, đợi ~25 giây,
xác nhận log có dòng `Registered tunnel connection`, rồi **chạy lại cả 2 bước**
vì URL đã đổi.

Phân biệt nhanh: tunnel hỏng thì **trang chủ cũng không mở được**;
quên bước 2 thì trang chủ mở bình thường, chỉ dữ liệu không load.

**`docker compose logs backend --tail=5` chỉ thấy thông tin connection pool**
→ Không phải lỗi, backend mới khởi động chưa in xong. Đợi ~20 giây rồi xem lại,
hoặc lọc thẳng: `docker compose logs backend | Select-String "Started TravelManagerApplication"`.

**Script báo `Khong tim thay URL trycloudflare trong log`**
→ Container `cloudflared` chưa chạy. Kiểm tra `docker compose ps`, nếu thiếu thì
`docker compose up -d cloudflared` rồi đợi ~10 giây và chạy lại script.

**PowerShell báo `cannot be loaded because running scripts is disabled`**
→ Chạy một lần: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` rồi chạy lại script.

**Backend không khởi động được, log có `Schema-validation`**
→ Schema DB lệch với entity. Chạy một lần với chế độ tự tạo cột:
`docker compose run --rm -e JPA_DDL_AUTO=update backend`
rồi bỏ biến đó đi và khởi động lại như bình thường.
