@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title USB 驱动安装向导
cd /d "%~dp0.."

echo.
echo ============================================================
echo   USB 驱动安装向导（为 Root 环节的下载模式装 WinUSB）
echo ============================================================
echo.
echo 【重要背景】
echo   我们要装驱动的设备号是 VID_1782 / PID_4D00，
echo   它【只在平板进入下载模式时才出现在电脑上】。
echo   安卓系统正常开机时看不到它，所以必须抓 timing：
echo   先把 Zadig 打开准备好，再让平板进下载模式，
echo   设备一出现就立刻在 Zadig 里选它安装。
echo.
pause

echo.
echo [第 1 步] 现在打开 Zadig（即将自动启动）...
echo         打开后请做两件事：
echo           a) 菜单 Options → List All Devices （打勾）
echo           b) 把 Zadig 窗口留在屏幕上，不要关闭
echo.
start "" "%~dp0工具包\驱动\zadig.exe"
timeout /t 5 /nobreak >nul
echo         已启动 Zadig。确认上面两件事做好后继续。
pause

echo.
echo [第 2 步] 让平板进入下载模式：
echo   1. 平板完全关机
echo   2. 按住【音量减】不放
echo   3. 插入 USB 线，继续按住 15 秒后松开
echo   4. 看到平板【后置闪光灯（摄像头旁 LED）常亮】即成功
echo.
echo 本脚本会每 2 秒检测一次设备是否在线，
echo 一旦检测到，会立刻提示你去 Zadig 操作。请保持平板在下载模式。
echo.
pause

echo.
echo [检测中] 等待下载模式设备出现（最多 180 秒）...
echo.
set FOUND=0
for /L %%i in (1,1,90) do (
  powershell -NoProfile -Command "$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match 'VID_1782' -and $_.Present -eq $true } | Select-Object -First 1; if ($d) { exit 0 } else { exit 1 }"
  if !errorlevel! equ 0 (
    set FOUND=1
    goto :FOUND_DEV
  )
  timeout /t 2 /nobreak >nul
)

:FOUND_DEV
if "!FOUND!"=="0" (
  echo.
  echo [失败] 180 秒内没检测到设备。
  echo        请重新进下载模式：关机 → 按住音量减 → 插线 15 秒 → 闪光点常亮。
  echo        并确认 Zadig 已开、List All Devices 已打勾、USB 口没换。
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo [检测成功] 设备已在线！现在【立刻】回到 Zadig 窗口操作：
echo   1. 下拉框里选含 VID_1782 / PID_4D00 的项
echo      （可能显示为 Unknown Device (1782, 4D00) 或 Gadget Serial）
echo   2. 右侧驱动选【WinUSB】
echo   3. 点【Install Driver】，UAC 点“是”
echo   4. 等安装完成
echo.
echo 装完后回到这里按任意键，脚本会验证驱动是否装好。
echo ============================================================
pause

echo.
echo [验证] 检查驱动绑定...
powershell -NoProfile -Command "$ok=$false; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match 'VID_1782' } | ForEach-Object { $vid=$_.PSChildName; Get-ChildItem $_.PSPath | ForEach-Object { $svc=(Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).Service; if($svc -eq 'WinUSB'){ $ok=$true } } }; if($ok){ Write-Host '[成功] 已检测到 VID_1782 设备绑定了 WinUSB 驱动' } else { Write-Host '[注意] 尚未检测到 WinUSB 绑定，请确认已在 Zadig 点 Install Driver 并安装完成' }"
echo.
echo ============================================================
echo  驱动装好后，就可以做 Root 了：
echo  运行 tools\1_导出原厂boot.bat（需重新进下载模式）
echo ============================================================
echo.
pause
