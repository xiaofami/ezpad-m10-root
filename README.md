# EZpad M10 Bootloader Unlock & Root

[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4)](#english)
[![Device](https://img.shields.io/badge/Device-EZpad%20M10-fa8c00)](#english)
[![SoC](https://img.shields.io/badge/SoC-Unisoc%20T618%20%28UMS512%29-2ea44f)](#english)
[![Android](https://img.shields.io/badge/Android-11-555)](#english)
[![Status](https://img.shields.io/badge/Root-verified-brightgreen)](#english)

在 Jumper EZpad M10 上完成 Bootloader 解锁与 Root 的可复现流程。
A reproducible bootloader unlock and root workflow for the Jumper EZpad M10.

**[中文](#中文) · [English](#english)**

---

<a id="中文"></a>

# 中文版

## 项目简介

本项目完整记录了 **Jumper EZPad M10** 平板从解锁 Bootloader 到获取 Root 权限的全过程，并封装为可直接在 Windows 上运行的脚本。

| 项目 | 参数 |
| --- | --- |
| 设备 | Jumper EZPad M10（`EZpad_M10_EEA`） |
| 芯片 | Unisoc T618 / UMS512 |
| 系统 | Android 11，固件 V1.1.2（build 29540） |
| 当前状态 | 已解锁，Root 已验证 |

这套流程在本机型上实测成功。所有工具均已本地化保存在仓库中，运行时无需联网下载。

> **风险提示**：解锁会清空设备全部数据；刷机存在变砖风险。操作前请备份，并自行承担后果。详见 [免责声明](DISCLAIMER.md)。

## 核心特性

- **完整流程**：解锁与 Root 分为两个独立阶段；已解锁的设备可直接进入 Root 阶段。
- **工具本地化**：platform-tools、Zadig、两版 spd_dump、FDL、Magisk、avbtool 及签名密钥均随仓库提供。
- **脚本自动化**：自动申请管理员权限、自检设备状态、逐条提示操作，并明确反馈成功或失败。
- **排错详尽**：附录收录本次实操遇到的全部问题及解决方案。
- **文档分层**：正文为清晰主线，失败记录归入附录，避免干扰阅读。

## 验证结果

Root 完成后，在本机上取得如下输出：

```text
$ adb shell su -c id
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0

$ adb shell su -c magisk -v
31.1:MAGISK:R

$ adb shell getprop ro.boot.verifiedbootstate
orange

$ adb shell getprop ro.boot.flash.locked
0
```

## 快速开始

### 准备

1. 一台 Windows 电脑，安装 Python 3 并勾选“Add Python to PATH”。
2. 如需解锁：运行 `tools\工具包\解锁工具\安装解锁工具.bat`（仅首次需联网）。
3. 如需 Root：运行 `tools\0_安装驱动向导.bat`，按提示为下载模式安装 WinUSB 驱动。

> 可随时运行 `tools\0_查看设备状态.bat`，确认设备当前处于系统、fastboot 还是下载模式。

### 第一阶段：解锁 Bootloader

已解锁（`verifiedbootstate=orange`）可跳过本阶段。

```bat
tools\解锁\0_解锁Bootloader.bat
tools\解锁\1_验证解锁状态.bat
```

解锁原理：读取设备 Identifier Token，使用展锐泄露密钥 `rsa4096_vbmeta.pem` 签名，再通过定制 fastboot 命令完成解锁。标准命令 `fastboot flashing unlock` 在本机型无效。

### 第二阶段：Root

依次执行：

| 步骤 | 操作 |
| --- | --- |
| 1 | `tools\1_导出原厂boot.bat` — 导出并备份原厂 boot（必需） |
| 2 | `tools\2_安装Magisk并推送boot.bat` — 安装 Magisk，推送 boot |
| 3 | 在平板打开 Magisk → 安装 → 选择并修补文件 → 选 `Download/boot.img` |
| 4 | `tools\3_签名boot.bat` — 用展锐密钥重新签名（Android 11 必需，不要改动 vbmeta） |
| 5 | `tools\4_刷入boot.bat` — 通过 BROM 写回 `boot_a` |
| 6 | `tools\5_验证root.bat` — 确认 `uid=0(root)` |

> 进入下载模式的标志是**平板后置闪光灯（摄像头旁 LED）常亮**，此时屏幕可能是黑的。

完整步骤与原理参见 [详细手册](docs/ROOT_GUIDE.md)。

## 目录结构

```text
.
├── README.md                  本文件
├── ACKNOWLEDGEMENTS.md        第三方出处与许可证
├── DISCLAIMER.md              免责声明
├── LICENSE                    MIT 许可证（含第三方例外条款）
├── docs/
│   └── ROOT_GUIDE.md          详细操作手册
└── tools/
    ├── 解锁/                  解锁脚本
    ├── 0_安装驱动向导.bat
    ├── 0_查看设备状态.bat
    ├── 1_导出原厂boot.bat
    ├── 2_安装Magisk并推送boot.bat
    ├── 3_签名boot.bat
    ├── 4_刷入boot.bat
    ├── 5_验证root.bat
    └── 工具包/                本地化工具
        ├── platform-tools/
        ├── 驱动/
        ├── spd_导出用/
        ├── spd_刷入用/
        ├── 解锁工具/
        ├── 签名工具/
        └── Magisk-v31.1.apk
```

运行时生成的 boot 镜像、日志等产物不会提交到仓库，详见 `.gitignore`。

## 许可证

本项目原创内容（文档、脚本）采用 [MIT 许可证](LICENSE)。仓库附带的第三方工具保留各自原始许可证，不属于本项目 MIT 授权范围，详见 [LICENSE](LICENSE) 与 [致谢](ACKNOWLEDGEMENTS.md)。

## 免责声明

本项目仅供学习与技术参考，不保证适用于其他设备或固件版本。刷机有风险，请备份数据并自行承担后果。详见 [DISCLAIMER.md](DISCLAIMER.md)。

---

<a id="english"></a>

# English Version

## Overview

This repository documents the complete process of unlocking the bootloader and obtaining root on a **Jumper EZPad M10** tablet, packaged as scripts that run directly on Windows.

| Item | Value |
| --- | --- |
| Device | Jumper EZPad M10 (`EZpad_M10_EEA`) |
| SoC | Unisoc T618 / UMS512 |
| OS | Android 11, firmware V1.1.2 (build 29540) |
| Status | Unlocked, root verified |

This workflow was verified on this specific device. All tools are vendored in the repository, so no network downloads are required at runtime.

> **Warning**: Unlocking wipes all data on the device, and flashing may brick it. Back up before proceeding and proceed at your own risk. See the [Disclaimer](DISCLAIMER.md).

## Features

- **End-to-end flow**: Unlock and root are two independent stages; already-unlocked devices can skip directly to root.
- **Vendored tools**: platform-tools, Zadig, two spd_dump builds, FDLs, Magisk, avbtool and the signing key are all included.
- **Automated scripts**: Scripts auto-elevate, check device state, prompt at each step, and report clear success or failure.
- **Thorough troubleshooting**: The appendix documents every issue encountered during the original session and its fix.
- **Layered documentation**: A clean main workflow; failure records are moved to the appendix.

## Verified Result

After rooting, the following output was obtained on the device:

```text
$ adb shell su -c id
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0

$ adb shell su -c magisk -v
31.1:MAGISK:R

$ adb shell getprop ro.boot.verifiedbootstate
orange

$ adb shell getprop ro.boot.flash.locked
0
```

## Quick Start

### Prerequisites

1. A Windows PC with Python 3 installed and added to PATH.
2. For unlocking: run `tools\工具包\解锁工具\安装解锁工具.bat` (network required only once).
3. For rooting: run `tools\0_安装驱动向导.bat` and follow the prompts to install the WinUSB driver for download mode.

> Run `tools\0_查看设备状态.bat` at any time to check whether the device is in system, fastboot, or download mode.

### Stage 1: Bootloader Unlock

Skip this stage if the device is already unlocked (`verifiedbootstate=orange`).

```bat
tools\解锁\0_解锁Bootloader.bat
tools\解锁\1_验证解锁状态.bat
```

How it works: read the device's Identifier Token, sign it with the leaked Unisoc key `rsa4096_vbmeta.pem`, then send it through a custom fastboot command. The standard `fastboot flashing unlock` does not work on this device.

### Stage 2: Root

Run the following in order:

| Step | Action |
| --- | --- |
| 1 | `tools\1_导出原厂boot.bat` — dump and back up the stock boot (required) |
| 2 | `tools\2_安装Magisk并推送boot.bat` — install Magisk and push the boot image |
| 3 | On the tablet: Magisk → Install → Select and Patch a File → choose `Download/boot.img` |
| 4 | `tools\3_签名boot.bat` — re-sign with the Unisoc key (required on Android 11; do not modify vbmeta) |
| 5 | `tools\4_刷入boot.bat` — write back to `boot_a` via BROM |
| 6 | `tools\5_验证root.bat` — confirm `uid=0(root)` |

> The indicator for download mode is the **rear flashlight (LED next to the camera) staying on**; the screen may be off.

See the [detailed guide](docs/ROOT_GUIDE.md) for full steps and theory.

## Repository Layout

```text
.
├── README.md                  This file
├── ACKNOWLEDGEMENTS.md        Third-party credits and licenses
├── DISCLAIMER.md              Disclaimer
├── LICENSE                    MIT license (with third-party exception)
├── docs/
│   └── ROOT_GUIDE.md          Detailed operation guide
└── tools/
    ├── 解锁/                  Unlock scripts
    ├── 0_安装驱动向导.bat
    ├── 0_查看设备状态.bat
    ├── 1_导出原厂boot.bat
    ├── 2_安装Magisk并推送boot.bat
    ├── 3_签名boot.bat
    ├── 4_刷入boot.bat
    ├── 5_验证root.bat
    └── 工具包/                Vendored tools
        ├── platform-tools/
        ├── 驱动/
        ├── spd_导出用/
        ├── spd_刷入用/
        ├── 解锁工具/
        ├── 签名工具/
        └── Magisk-v31.1.apk
```

Runtime artifacts such as boot images and logs are not committed; see `.gitignore`.

## License

The original content of this project (documentation and scripts) is licensed under the [MIT License](LICENSE). Third-party tools vendored in this repository retain their own licenses and are not covered by this project's MIT license; see [LICENSE](LICENSE) and [Acknowledgements](ACKNOWLEDGEMENTS.md).

## Disclaimer

This project is for educational and technical reference only. No guarantee is made that it applies to other devices or firmware versions. Flashing is risky — back up your data and proceed at your own risk. See [DISCLAIMER.md](DISCLAIMER.md).
