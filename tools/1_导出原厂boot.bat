@echo off
chcp 65001 >nul
title 步骤1 - 导出原厂 boot
cd /d "%~dp0.."

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo 正在请求管理员权限，请在弹窗中点击【是】...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo ============================================================
echo   步骤 1：从平板导出原厂 boot.img（做备份，必须做）
echo ============================================================
echo.
echo 请先把平板进入【下载模式】：
echo   1. 平板完全关机（黑屏、无任何指示）
echo   2. 按住【音量减】不放
echo   3. 插入 USB 线，继续按住 15 秒后松开
echo   4. 看到平板【后置闪光灯（摄像头旁 LED）常亮】即成功，屏幕可能是黑的
echo.
echo 注意：如果平板当前在系统里，先关机再按上面步骤操作。
echo.
pause

echo.
echo [检查] 正在确认平板已进入下载模式...
powershell -NoProfile -Command "$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '1782' -and $_.Present -eq $true } | Select-Object -First 1; if ($d) { exit 0 } else { exit 1 }"
if %errorlevel% neq 0 (
  echo.
  echo [失败] 没有检测到下载模式设备。
  echo        请重新执行上面的进入下载模式步骤，确认后置闪光灯常亮后再运行本脚本。
  echo.
  pause
  exit /b 1
)
echo [成功] 平板已连接，开始导出（约 10-30 秒）...
echo.

pushd "%~dp0..\spd"
spd_dump.exe --wait 60 keep_charge 1 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 disable_transcode partition_list "%~dp0..\spd2\part.xml" read_part boot_a 0 64M "%~dp0..\stock_boot_a.img" power_off
popd

echo.
echo ============================================================
if exist "%~dp0..\stock_boot_a.img" (
  for %%A in ("%~dp0..\stock_boot_a.img") do echo [成功] 原厂 boot 已导出：%%~zA 字节（正确应为 67108864）
  echo        文件位置：%~dp0..\stock_boot_a.img
  echo.
  echo 下一步：拔掉 USB 线，长按电源键开机进系统，然后运行【2_安装Magisk并推送boot.bat】
) else (
  echo [失败] 没有生成镜像文件。请看窗口里的错误提示，或参考 ROOT_GUIDE.md 附录A 排查。
)
echo ============================================================
echo.
pause
