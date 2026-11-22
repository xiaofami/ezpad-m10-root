@echo off
chcp 65001 >nul
title 步骤3 - 重新签名 boot
cd /d "%~dp0.."

echo.
echo ============================================================
echo   步骤 3：拉回补丁镜像并重新签名（Android 11 必须做）
echo ============================================================
echo.
echo 本脚本会自动完成：
echo   1. 从平板取回刚修补好的镜像
echo   2. 用展锐密钥重新签名（不改动 vbmeta）
echo   3. 校验签名结果
echo.
pause

set ADB=%~dp0..\platform-tools\adb.exe
"%ADB%" shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
  echo [失败] 没有检测到 ADB 设备，请确认平板开机并插好 USB。
  pause
  exit /b 1
)

echo [1/3] 正在从平板取回修补后的镜像...
"%ADB%" shell "cp /sdcard/Download/magisk_patched-*.img /sdcard/Download/patched.img" 2>nul
"%ADB%" pull /sdcard/Download/patched.img "%~dp0..\magisk_patched.img"
if not exist "%~dp0..\magisk_patched.img" (
  echo [失败] 没有取回镜像。请确认已在 Magisk 里完成“修补文件”并生成了 magisk_patched 开头的镜像。
  pause
  exit /b 1
)

set PY=python
where python >nul 2>&1
if errorlevel 1 (
  echo [失败] 没有找到 Python。请先安装 Python 3 并勾选“Add Python to PATH”。
  pause
  exit /b 1
)

echo.
echo [2/3] 正在重新签名（约几秒）...
"%PY%" "%~dp0..\avbtool" add_hash_footer --image "%~dp0..\magisk_patched.img" --partition_name boot --partition_size 67108864 --key "%~dp0..\rsa4096_boot.pem" --algorithm SHA256_RSA4096 --prop com.android.build.boot.fingerprint:Jumper/EZpad_M10_EEA/EZpad_M10:11/RP1A.201005.001/29540:user/release-keys --prop com.android.build.boot.os_version:11 --rollback_index 0 --salt 6e7a76beb8434f65c0c3ff73127aa4467a9e468f43489d9a57cd7e5f233ee860
if errorlevel 1 (
  echo [失败] 签名出错，请检查 Python 是否可用、avbtool 和密钥文件是否齐全。
  pause
  exit /b 1
)

echo.
echo [3/3] 校验签名结果...
"%PY%" "%~dp0..\avbtool" info_image --image "%~dp0..\magisk_patched.img" | findstr /C:"Salt" /C:"Rollback Index" /C:"Algorithm" /C:"Size:" /C:"Digest"

echo.
echo ============================================================
echo [成功] 已签名镜像：%~dp0..\magisk_patched.img
echo        请核对上面显示的 Salt 与原厂一致：
echo        6e7a76beb8434f65c0c3ff73127aa4467a9e468f43489d9a57cd7e5f233ee860
echo.
echo 下一步：让平板进入下载模式，运行【4_刷入boot.bat】。
echo ============================================================
echo.
pause
