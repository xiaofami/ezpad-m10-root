@echo off
chcp 65001 >nul
title 解锁 Bootloader
cd /d "%~dp0.."

echo.
echo ============================================================
echo   Jumper EZPad M10 - 解锁 Bootloader（Windows 版）
echo ============================================================
echo.
echo 【警告】解锁会【清空平板全部数据】（128GB 全量擦除，约 10 分钟）。
echo         请确认已备份重要数据！解锁后无法撤销（除非重新上锁）。
echo.
echo 本脚本做的事：
echo   1. 开启 OEM unlocking
echo   2. 读取设备 Identifier Token 并用泄露密钥签名
echo   3. 向设备发送解锁指令
echo   4. 等待你在平板上按音量键确认
echo.
pause

set ADB=%~dp0..\工具包\platform-tools\adb.exe
set PY=%~dp0..\工具包\解锁工具\venv\Scripts\python.exe

if not exist "%ADB%" (
  echo [失败] 找不到 adb：%ADB%
  pause
  exit /b 1
)
if not exist "%PY%" (
  echo [失败] 找不到解锁工具 Python：%PY%
  pause
  exit /b 1
)

echo.
echo [1/4] 检查平板是否已开机并连接...
"%ADB%" shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
  echo [失败] 未检测到 ADB 设备。
  echo        请让平板开机进系统、插好 USB、开启 USB 调试、并在弹窗点“允许”。
  pause
  exit /b 1
)
echo [成功] 已连接：& "%ADB%" shell getprop ro.product.model

echo.
echo [2/4] 开启 OEM unlocking...
"%ADB%" shell settings put global oem_unlock_enabled 1
echo       ro.oem_unlock_supported = & "%ADB%" shell getprop ro.oem_unlock_supported
echo       sys.oem_unlock_allowed  = & "%ADB%" shell getprop sys.oem_unlock_allowed

echo.
echo [3/4] 让平板进入 fastboot 模式并解锁...
"%ADB%" reboot bootloader
echo       等待设备进入 fastboot（约 10 秒）...
timeout /t 10 /nobreak >nul
"%~dp0..\工具包\platform-tools\fastboot.exe" devices

echo.
echo ------------------------------------------------------------
echo  接下来会执行解锁。请注意：
echo   - 工具可能显示 OEM ID（序列号的十六进制），属正常
echo   - 出现 "Unlock bootloader, pls follow instructions on device screen"
echo     时，请在【平板屏幕】上按【音量键】确认
echo   - 确认后屏幕显示 "Begin to erase user data"，开始擦除 128GB（约 10 分钟）
echo   - 擦除期间【不要断电、保持 USB 连接】
echo   - 若工具 60 秒超时报 ReadFailedError，只要你已经按了音量键，
echo     设备端解锁照样执行，不算失败（这是已知现象）
echo ------------------------------------------------------------
echo.
pause

echo.
echo [4/4] 执行解锁...
"%PY%" -m unisoc_unlock unlock
echo.
echo ============================================================
echo  解锁指令已发出。
echo.
echo  接下来请在平板上：
echo   1. 按音量键确认解锁（若还没按）
echo   2. 等待 128GB 擦除完成（约 10 分钟，别断电）
echo   3. 设备会自动重启，完成开机向导
echo   4. 重新开启：开发者选项（连点版本号 7 次）+ USB 调试 + 重新授权弹窗
echo.
echo  最后运行【1_验证解锁状态.bat】确认。
echo ============================================================
echo.
pause
