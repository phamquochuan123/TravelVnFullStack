# Cập nhật URL Cloudflare Quick Tunnel vào .env
#
# Vì sao cần: Quick Tunnel sinh URL *.trycloudflare.com NGẪU NHIÊN MỚI mỗi lần
# container cloudflared khởi động lại. URL cũ nằm cứng trong .env ở 2 chỗ:
#   - VNPAY_RETURN_URL       -> VNPay redirect về URL chết, khách không thấy kết quả
#   - APP_CORS_ALLOWED_ORIGINS -> backend chặn CORS, frontend gọi API nào cũng lỗi
#
# Cách dùng:  .\update-tunnel-url.ps1
# Chạy sau mỗi lần `docker compose up -d` hoặc restart cloudflared.

$ErrorActionPreference = "Stop"

$envPath = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envPath)) {
    Write-Error "Khong tim thay file .env tai: $envPath"
}

Write-Host "Dang doc URL tunnel tu log cloudflared..." -ForegroundColor Cyan

$logs = docker compose logs cloudflared 2>&1 | Out-String
$matchResult = [regex]::Matches($logs, 'https://[a-z0-9-]+\.trycloudflare\.com')

if ($matchResult.Count -eq 0) {
    Write-Error "Khong tim thay URL trycloudflare trong log. Kiem tra container da chay chua: docker compose ps"
}

# Lay URL xuat hien sau cung — tunnel moi nhat
$tunnelUrl = $matchResult[$matchResult.Count - 1].Value
Write-Host "URL tunnel hien tai: $tunnelUrl" -ForegroundColor Green

# Doc .env, chi ghi de dung 2 dong can thiet, giu nguyen moi dong khac (ke ca secret)
$lines = Get-Content $envPath -Encoding UTF8
$localOrigins = "http://localhost:5173,http://localhost:5174"

$updated = $lines | ForEach-Object {
    if ($_ -match '^VNPAY_RETURN_URL=') {
        "VNPAY_RETURN_URL=$tunnelUrl/payment/result"
    }
    elseif ($_ -match '^APP_CORS_ALLOWED_ORIGINS=') {
        "APP_CORS_ALLOWED_ORIGINS=$tunnelUrl,$localOrigins"
    }
    else {
        $_
    }
}

Set-Content -Path $envPath -Value $updated -Encoding UTF8

Write-Host ""
Write-Host "Da cap nhat .env:" -ForegroundColor Green
Write-Host "  VNPAY_RETURN_URL=$tunnelUrl/payment/result"
Write-Host "  APP_CORS_ALLOWED_ORIGINS=$tunnelUrl,$localOrigins"
Write-Host ""
Write-Host "Buoc tiep theo — nap lai bien moi truong cho backend:" -ForegroundColor Yellow
Write-Host "  docker compose up -d --force-recreate backend"
Write-Host ""
Write-Host "Luu y: VITE_* duoc bake vao bundle luc build, khong doi theo bien moi truong." -ForegroundColor DarkGray
Write-Host "Frontend goi API qua duong dan tuong doi /api/v1 nen KHONG can build lai." -ForegroundColor DarkGray
