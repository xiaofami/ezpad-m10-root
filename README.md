# EZpad M10 Bootloader Unlock & Root

> 展锐 T618 平板的解锁 + Root 全流程复现手册 / Reproducible bootloader unlock + root guide for Unisoc T618 tablets

[![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)]()
[![Device](https://img.shields.io/badge/device-EZpad%20M10-orange.svg)]()
[![SoC](https://img.shields.io/badge/SoC-Unisoc%20T618%20(UMS512)-green.svg)]()
[![Android](https://img.shields.io/badge/Android-11-lightgrey.svg)]()
[![Status](https://img.shields.io/badge/status-verified%20(root)-brightgreen.svg)]()

---

## 简介 / Overview

**中文**：本项目记录并封装了一台 **Jumper EZPad M10**（展锐 T618 / UMS512，Android 11，固件 V1.1.2 / build 29540）从**解锁 Bootloader 到 Root** 的完整、可复现流程。所有工具已本地化保存，配套傻瓜式脚本（自动提权、自检、明确提示），无需再依赖网络下载。

**English**: This repository documents and packages a complete, reproducible workflow — **from bootloader unlock to root** — for the **Jumper EZPad M10** (Unisoc T618 / UMS512, Android 11, firmware V1.1.2 / build 29540). All tools are vendored locally and paired with beginner-friendly scripts (auto-elevation, pre-checks, clear prompts), so no network downloads are needed at runtime.

> ⚠️ **风险提示 / Disclaimer**：解锁会清空设备全部数据；Root 有变砖风险。请自行备份并承担后果。详见 [DISCLAIMER.md](DISCLAIMER.md)。
> Unlocking wipes all data; rooting may brick your device. Back up and proceed at your own risk.

---

## 特性 / Features

- ✅ **解锁 + Root 全流程**：两阶段独立脚本，已解锁设备可跳过解锁阶段。
  - Full unlock + root flow: two independent stages; skip unlock if already unlocked.
- ✅ **工具全本地化**：platform-tools、Zadig、两版 spd_dump、FDL、Magisk、avbtool、签名密钥均随仓库提供。
  - All tools vendored locally: platform-tools, Zadig, two spd_dump builds, FDLs, Magisk, avbtool, signing key.
- ✅ **傻瓜式脚本**：自动请求管理员权限、自检设备状态、逐条提示、成功/失败明确反馈。
  - Beginner-friendly scripts: auto-elevation, device pre-checks, step-by-step prompts, clear success/failure feedback.
- ✅ **详细的排错记录**：附完整失败记录与解决方案（如 `Fetching super` 卡死、`ver expected`、USB timing 等）。
  - Extensive troubleshooting: documented pitfalls and fixes (e.g. `Fetching super` hang, `ver expected`, USB timing).
- ✅ **清晰主线文档**：正文一条主线，失败记录归入附录，不干扰阅读。
  - Clear main-line documentation; failures moved to appendix.

---

## 验证结果 / Verified result

实操已在该机型上成功 root，验证输出：

```
adb shell su -c id
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
adb shell su -c magisk -v
31.1:MAGISK:R
ro.boot.verifiedbootstate = orange
ro.boot.flash.locked       = 0
```

---

## 目录 / Table of Contents

- [准备工作](#-准备工作--prerequisites)
- [第一阶段：解锁](#-第一阶段解锁--stage-1-unlock)
- [第二阶段：Root](#-第二阶段root--stage-2-root)
- [目录结构](#-目录结构--repository-layout)
- [致谢与出处](#-致谢与出处--credits)
- [许可证](#-许可证--license)
- [免责声明](#-免责声明--disclaimer)

---

## 🔧 准备工作 / Prerequisites

1. **Windows 电脑**，安装 Python 3（勾选 Add Python to PATH）。
   Windows PC with Python 3 installed (add to PATH).
2. **安装解锁工具**（仅解锁阶段需要）：
   ```
   tools\工具包\解锁工具\安装解锁工具.bat
   ```
   （联网执行一次，创建本地 venv；运行时无需网络）
3. **安装下载模式驱动**（仅 Root 阶段需要）：运行 `tools\0_安装驱动向导.bat`，按提示抓 timing 安装 WinUSB。
   Install the download-mode driver via the wizard script; it helps you catch the timing.

> 💡 随时用 `tools\0_查看设备状态.bat` 确认平板当前处于哪个模式（系统 / fastboot / 下载模式）。

---

## 🔓 第一阶段：解锁 / Stage 1: Unlock

> 已解锁（`ro.boot.verifiedbootstate=orange`）可跳过。Skip if already unlocked.

```
tools\解锁\0_解锁Bootloader.bat        # 执行解锁（会清空数据）
tools\解锁\1_验证解锁状态.bat          # 验证：orange / 0 / unlocked
```

解锁原理：读取设备 Identifier Token → 用展锐泄露密钥签名 → 通过定制 fastboot 命令解锁。标准 `fastboot flashing unlock` 在此机型无效。
Method: read Identifier Token → sign with leaked Unisoc key → send via custom fastboot command. Standard `fastboot flashing unlock` does not work on this device.

---

## 🌱 第二阶段：Root / Stage 2: Root

按顺序执行 / Run in order:

| 步骤 / Step | 操作 / Action |
|---|---|
| 1 | `tools\1_导出原厂boot.bat` — 导出原厂 boot 备份（必须） |
| 2 | `tools\2_安装Magisk并推送boot.bat` — 安装 Magisk 并推送 boot |
| 3 | 平板屏幕上：Magisk → 安装 → 选择并修补文件 → 选 `Download/boot.img` |
| 4 | `tools\3_签名boot.bat` — 用展锐密钥重新签名（Android 11 必须，不动 vbmeta） |
| 5 | `tools\4_刷入boot.bat` — BROM 写回 boot_a |
| 6 | `tools\5_验证root.bat` — 验证 `uid=0(root)` |

> 关键提示：进入下载模式的标志是**平板后置闪光灯（摄像头旁 LED）常亮**，此时屏幕可能是黑的。
> The download-mode indicator is the **rear flashlight (LED next to camera) staying on**; the screen may be off.

详细步骤与原理见 [docs/ROOT_GUIDE.md](docs/ROOT_GUIDE.md)。
See [docs/ROOT_GUIDE.md](docs/ROOT_GUIDE.md) for full details and theory.

---

## 📁 目录结构 / Repository Layout

```
.
├── README.md                  本文件 / this file
├── ACKNOWLEDGEMENTS.md        第三方出处与致谢 / credits & attributions
├── DISCLAIMER.md              免责声明 / disclaimer
├── docs/
│   └── ROOT_GUIDE.md          详细操作手册（中）/ detailed guide (Chinese)
└── tools/
    ├── 解锁/                  解锁脚本 / unlock scripts
    ├── 0_安装驱动向导.bat     驱动安装 / driver wizard
    ├── 0_查看设备状态.bat     设备状态 / device status
    ├── 1_导出原厂boot.bat     导出 / dump
    ├── 2_安装Magisk并推送boot.bat
    ├── 3_签名boot.bat         签名 / sign
    ├── 4_刷入boot.bat         刷入 / flash
    ├── 5_验证root.bat         验证 / verify
    └── 工具包/                本地化工具 / vendored tools
        ├── platform-tools/    adb / fastboot
        ├── 驱动/              Zadig
        ├── spd_导出用/        spd_dump + FDL (dump)
        ├── spd_刷入用/        spd_dump + FDL (flash)
        ├── 解锁工具/          unisoc-unlock (via requirements.txt)
        ├── 签名工具/          avbtool + rsa4096_boot.pem
        └── Magisk-v31.1.apk
```

> 注：运行时生成的 boot 镜像、日志等产物不入仓库（见 `.gitignore`）。
> Runtime artifacts (boot images, logs) are not committed (see `.gitignore`).

---

## 🙏 致谢与出处 / Credits

本项目的解锁方法与工具来自多个开源项目，全部出处与许可证见 [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md)。
The unlock method and tools come from multiple open-source projects; all sources and licenses are listed in [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md).

---

## 📄 许可证 / License

**中文**：本项目自身的原创内容（文档、脚本）采用 **MIT 许可证**，见 [LICENSE](LICENSE)。仓库内附带的第三方工具（Magisk、Zadig、platform-tools、spd_dump、unisoc-unlock 等）保留各自原始许可证，不属于本项目 MIT 授权范围，详见 [LICENSE](LICENSE) 的例外条款与 [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md)。

**English**: The original content of this project (documentation, scripts) is licensed under **MIT** — see [LICENSE](LICENSE). Third-party tools vendored in this repository (Magisk, Zadig, platform-tools, spd_dump, unisoc-unlock, etc.) retain their own licenses and are not covered by this project's MIT license; see the exception clause in [LICENSE](LICENSE) and [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md).

---

## ⚠️ 免责声明 / Disclaimer

本项目仅供学习与技术参考，**不保证**适用于其他设备或固件版本。刷机有风险，操作前请备份数据并自行承担后果。详见 [DISCLAIMER.md](DISCLAIMER.md)。
For educational/reference use only. **No guarantee** of applicability to other devices or firmware versions. Flashing is risky — back up and proceed at your own risk.
