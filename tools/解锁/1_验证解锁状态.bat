@echo off
chcp 65001 >nul
title 验证解锁状态
cd /d "%~dp0.."

echo.
echo ============================================================
echo   验证 Bootloader 是否已解锁
echo ============================================================
echo.
echo 前提：解锁后平板已重启进系统，开发者选项和 USB 调试已重新开启，
echo       电脑上已重新点“允许 USB 调试”。
echo.
pause

set ADB=%~dp0..\工具包\platform-tools\adb.exe
"%ADB%" shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
  echo [失败] 未检测到 ADB 设备。请确认平板开机、USB 插好、已重新授权 USB 调试。
  pause
  exit /b 1
)

echo.
echo 【解锁状态三项检查】（三项全部符合即解锁成功）
echo.
echo 1) verifiedbootstate（期望 orange，未解锁是 green）：
"%ADB%" shell getprop ro.boot.verifiedbootstate
echo.
echo 2) flash.locked（期望 0，未解锁是 1）：
"%ADB%" shell getprop ro.boot.flash.locked
echo.
echo 3) vbmeta.device_state（期望 unlocked，未解锁是 locked）：
"%ADB%" shell getprop ro.boot.vbmeta.device_state
echo.
echo ============================================================
echo 若显示 orange / 0 / unlocked，说明解锁成功！
echo 可以继续做 root：运行 tools\1_导出原厂boot.bat
echo ============================================================
echo.
pause
