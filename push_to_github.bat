@echo off
chcp 65001 >nul
title 推送到 GitHub
cd /d "%~dp0"

echo.
echo ============================================================
echo   推送本地仓库到 GitHub
echo ============================================================
echo.
echo 本脚本需要先在 GitHub 网页上创建一个【空仓库】
echo （不要勾选 README / LICENSE / .gitignore，保持完全空）。
echo 创建后会得到一个地址，类似：
echo   https://github.com/你的用户名/仓库名.git
echo.

set /p REPO="请粘贴你的 GitHub 仓库地址（.git 结尾）: "

if "%REPO%"=="" (
  echo [失败] 地址不能为空。
  pause
  exit /b 1
)

echo.
echo [1/2] 添加远程仓库 origin ...
git remote remove origin 2>nul
git remote add origin "%REPO%"

echo [2/2] 推送（首次会弹出 GitHub 登录窗口，请用浏览器/账号登录授权）...
git branch -M main
git push -u origin main

if errorlevel 1 (
  echo.
  echo [失败] 推送失败。常见原因：
  echo   - 未登录 GitHub：Windows 通常会弹出登录窗口，请完成登录
  echo   - 地址错误：确认仓库地址以 .git 结尾且仓库为空
  echo   - 网络问题：重试
  echo.
  echo 也可改用 Personal Access Token（PAT）作为密码：
  echo   GitHub → Settings → Developer settings → Personal access tokens
  echo   生成时勾选 repo 权限，推送时用户名填 GitHub 用户名，密码填 token。
) else (
  echo.
  echo [成功] 已推送到 GitHub！仓库地址：
  echo   %REPO:.git=%
)
echo.
pause
