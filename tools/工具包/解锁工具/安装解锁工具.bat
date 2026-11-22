@echo off
chcp 65001 >nul
title 安装解锁工具
cd /d "%~dp0"

echo.
echo ============================================================
echo   安装解锁工具（unisoc-unlock）到本地虚拟环境
echo ============================================================
echo.
echo 本项目出于体积和可移植性考虑，不随仓库附带 Python 虚拟环境。
echo 本脚本会在本目录创建 venv，并根据 requirements.txt 安装
echo unisoc-unlock 及其依赖（libusb1、pycryptodome）。
echo 需要电脑已安装 Python 3 并加入 PATH，且能联网（仅安装时）。
echo.
pause

where python >nul 2>&1
if errorlevel 1 (
  echo [失败] 没有找到 Python 3。请先安装并勾选“Add Python to PATH”。
  pause
  exit /b 1
)

if exist venv\Scripts\python.exe (
  echo [提示] 已存在 venv，跳过创建。
) else (
  echo [1/2] 正在创建虚拟环境 venv ...
  python -m venv venv
  if errorlevel 1 (
    echo [失败] 创建 venv 失败。
    pause
    exit /b 1
  )
)

echo [2/2] 正在安装 unisoc-unlock ...
venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 (
  echo [失败] 安装失败，请检查网络连接后重试。
  pause
  exit /b 1
)

echo.
echo ============================================================
echo [成功] 解锁工具已安装到：%~dp0venv
echo        现在可以运行 tools\解锁\0_解锁Bootloader.bat
echo ============================================================
echo.
pause
