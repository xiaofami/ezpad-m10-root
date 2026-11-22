@echo off
chcp 65001 >nul
title 步骤2 - 安装Magisk并推送boot
cd /d "%~dp0.."

echo.
echo ============================================================
echo   步骤 2：安装 Magisk，并把原厂 boot 推送到平板
echo ============================================================
echo.
echo 请先让平板【开机进入 Android 系统】，并插好 USB 线。
echo （如果刚做完导出，平板已关机：拔掉 USB，长按电源键开机，再插回 USB）
echo.
echo 如果屏幕上弹出“允许 USB 调试”，请点【允许】并勾选“一律允许”。
echo.
pause

set ADB=%~dp0..\platform-tools\adb.exe
"%ADB%" shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
  echo.
  echo [失败] 没有检测到 ADB 设备。
  echo        确认：平板已开机、USB 线插好、开发者选项里“USB 调试”已开、屏幕上已点“允许”。
  echo.
  pause
  exit /b 1
)
echo [成功] 设备已连接：& "%ADB%" shell getprop ro.product.model

if not exist "%~dp0..\stock_boot_a.img" (
  echo.
  echo [失败] 找不到原厂 boot 备份，请先运行【1_导出原厂boot.bat】。
  pause
  exit /b 1
)

echo.
echo [1/2] 正在安装 Magisk...
"%ADB%" install -r "%~dp0..\Magisk-v31.1.apk"
echo.
echo [2/2] 正在推送原厂 boot 到平板（约 2 秒）...
"%ADB%" push "%~dp0..\stock_boot_a.img" /sdcard/Download/boot.img

echo.
echo ============================================================
echo   接下来请在【平板屏幕上】手动操作：
echo     1. 打开 Magisk App
echo     2. 点底部的【安装】
echo     3. 点【选择并修补一个文件 / Patch a file】
echo     4. 找到并选择 Download 目录里的 boot.img
echo     5. 等待修补完成，会生成 magisk_patched-xxxxx.img
echo.
echo   完成后，回到电脑运行【3_签名boot.bat】。
echo ============================================================
echo.
pause
