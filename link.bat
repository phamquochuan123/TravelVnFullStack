@echo off
REM Lay link public hien tai cua Cloudflare Quick Tunnel.
REM
REM Chay bang cach nhay dup vao file nay, hoac go "link" trong cmd o thu muc nay.
REM
REM Vi sao can file nay: Quick Tunnel sinh ten ngau nhien MOI LAN cloudflared khoi
REM dong lai, va log giu lai tat ca URL cu da chet. Phai lay dong CUOI CUNG, lay
REM nham dong dau la mo phai link tu hom truoc.
cd /d "%~dp0"
powershell -NoProfile -Command "$u = (docker compose logs cloudflared | Select-String 'https://[a-z0-9-]+\.trycloudflare\.com' -AllMatches).Matches.Value | Select-Object -Last 1; if ($u) { Write-Host ''; Write-Host '  Link public hien tai:' -ForegroundColor Cyan; Write-Host ('  ' + $u) -ForegroundColor Green; Write-Host '' } else { Write-Host ''; Write-Host '  Khong tim thay link. Cloudflared co dang chay khong?' -ForegroundColor Red; Write-Host '  Thu: docker compose up -d cloudflared' -ForegroundColor Yellow; Write-Host '' }"
pause
