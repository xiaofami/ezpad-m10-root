@echo off
chcp 65001 >nul
title 步骤4 - 刷入已签名 boot
cd /d "%~dp0.."

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo 正在请求管理员权限，请在弹窗中点击【是】...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo ============================================================
echo   步骤 4：把已签名的 boot 刷入平板
echo ============================================================
echo.
echo 警告：本操作会替换 boot_a 分区。请确保：
echo   - 已完成步骤 1~3（有原厂备份、已签名）
echo   - 平板已解锁 bootloader
echo.
echo 请让平板进入【下载模式】：
echo   1. 平板完全关机
echo   2. 按住【音量减】不放
echo   3. 插入 USB 线，按住 15 秒后松开
echo   4. 平板后置闪光灯（摄像头旁 LED）常亮 = 成功，屏幕可能是黑的
echo.
echo 重要：进入下载模式后，不要运行其他 spd_dump 脚本，
echo       否则设备会退出下载模式导致本步骤失败。
echo.
pause

if not exist "%~dp0..\magisk_patched.img" (
  echo [失败] 找不到已签名镜像，请先运行【3_签名boot.bat】。
  pause
  exit /b 1
)

echo [检查] 确认平板在下载模式...
powershell -NoProfile -Command "$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '1782' -and $_.Present -eq $true } | Select-Object -First 1; if ($d) { exit 0 } else { exit 1 }"
if %errorlevel% neq 0 (
  echo [失败] 未检测到下载模式设备。请重新进入下载模式（后置闪光灯常亮）后再运行。
  pause
  exit /b 1
)
echo [成功] 设备在线，开始刷入（约 5 秒）...
echo.

pushd "%~dp0..\spd2"
spd_dump.exe --wait 60 exec_addr 0x3ee8 fdl fdl1-dl.bin 0x5500 fdl fdl2-dl.bin 0x9efffe00 exec w boot_a "%~dp0..\magisk_patched.img" reset > "%~dp0..\flash_result.log" 2>&1
popd

echo ============================================================
findstr /C:"Write Part Done" /C:"Force Write boot_a Done" /C:"written: 0x4000000" "%~dp0..\flash_result.log" >nul
if %errorlevel% equ 0 (
  echo [成功] 刷入完成！
  echo.
  echo 下一步：
  echo   1. 拔掉 USB 线
  echo   2. 长按电源键开机进系统
  echo   3. 打开 Magisk → Superuser → 给【[SharedUID] Shell】授权
  echo   4. 运行【5_验证root.bat】确认
) else (
  echo [失败] 刷入未成功，错误如下：
  type "%~dp0..\flash_result.log"
  echo.
  echo 常见原因：设备已退出下载模式（不要先跑探测脚本），或 USB 不稳。
  echo 请重新进入下载模式后再运行本脚本。详见 ROOT_GUIDE.md 附录A。
)
echo ============================================================
echo.
pause
