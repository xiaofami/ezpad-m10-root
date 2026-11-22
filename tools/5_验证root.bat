@echo off
chcp 65001 >nul
title 步骤5 - 验证 root
cd /d "%~dp0.."

echo.
echo ============================================================
echo   步骤 5：验证 root 是否成功
echo ============================================================
echo.
echo 请先让平板开机进系统，插好 USB。
echo 并且已在 Magisk App 的【Superuser】里给【[SharedUID] Shell】授权。
echo.
pause

set ADB=%~dp0..\platform-tools\adb.exe
"%ADB%" shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
  echo [失败] 未检测到 ADB 设备，请确认平板开机、USB 插好、已允许 USB 调试。
  pause
  exit /b 1
)

echo [1] 检查 root 权限（期望：uid=0(root) ... context=u:r:magisk:s0）
"%ADB%" shell su -c id
echo.
echo [2] Magisk 版本
"%ADB%" shell su -c magisk -v
echo.
echo [3] 解锁状态（期望 verifiedbootstate=orange, flash.locked=0）
"%ADB%" shell getprop ro.boot.verifiedbootstate
"%ADB%" shell getprop ro.boot.flash.locked
echo.
echo ============================================================
echo 判断：如果第 [1] 项显示 uid=0(root)，恭喜，root 成功！
echo       如果显示 Permission denied，请到 Magisk App → Superuser
echo       找到 [SharedUID] Shell 并授权，然后重新运行本脚本。
echo ============================================================
echo.
pause
