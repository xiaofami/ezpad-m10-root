@echo off
chcp 65001 >nul
title 设备状态检查
echo.
echo ============================================================
echo   设备状态检查
echo ============================================================
echo.
echo 【系统模式 / ADB】
"%~dp0..\platform-tools\adb.exe" devices
echo.
echo 【Fastboot 模式】
"%~dp0..\platform-tools\fastboot.exe" devices
echo.
echo 【下载模式 / BROM】
powershell -NoProfile -Command "$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '1782' -and $_.Present -eq $true } | Select-Object -First 1; if ($d) { Write-Host ('  在线: ' + $d.FriendlyName) } else { Write-Host '  离线（平板当前不在下载模式）' }"
echo.
echo ============================================================
echo  说明：导出和刷入 boot 必须在“下载模式”下进行。
echo        看上面【下载模式】是否显示“在线”。
echo ============================================================
echo.
pause
