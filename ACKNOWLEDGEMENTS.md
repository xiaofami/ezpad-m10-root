# 致谢与第三方出处 / Credits and Third-Party Attributions

本项目本身是一份**操作手册与自动化脚本集合**。项目中的解锁思路、刷机方法、工具和密钥均来自下列开源项目与社区贡献者。在此一并致谢，并注明各自来源与许可证。

This project is a collection of documentation and automation scripts. The unlock method, flashing approach, tools and keys all come from the open-source projects and community contributors listed below. Credit is given where due, with sources and licenses noted.

---

## 1. 解锁方法 / Bootloader unlock

| 项目 | 用途 | 来源 | 许可证 |
|---|---|---|---|
| **unisoc-unlock** (patrislav1) | 读取 Identifier Token、用泄露密钥签名、发送解锁指令；本项目 Windows 解锁流程基于此工具 | https://github.com/patrislav1/unisoc-unlock | 仓库未声明许可证；本项目仅通过 `pip install` 引用，不随仓库分发其代码或二进制 |
| **Hovatek 论坛教程** (thread-32287) | Identifier Token 解锁原理参考 | https://www.hovatek.com/forum/thread-32287.html | 社区论坛内容 |
| **CVE-2022-38694** (TomKing062) | BROM 签名校验绕过（`exec_addr 0x3ee8`）的底层研究 | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader | 仓库未声明许可证 |

> 说明：解锁所用的 `rsa4096_vbmeta.pem` 是公开泄露的测试密钥，随 unisoc-unlock 包提供，本项目不单独分发该文件。
> Note: `rsa4096_vbmeta.pem` is a publicly leaked test key bundled with unisoc-unlock; it is not redistributed in this repository.

---

## 2. 导出与刷入工具 / Dump and flash tools

| 工具 | 用途 | 来源 | 许可证 |
|---|---|---|---|
| **spd_dump（原版）** (ilyakurdyukov/spreadtrum_flash) | 从 BROM 导出原厂 boot 分区（本项目的"导出用"版本） | https://github.com/ilyakurdyukov/spreadtrum_flash | **The Unlicense**（公有领域，允许自由再分发） |
| **spd_dump（TomKing062 版）** | BROM 写入补丁 boot（本项目的"刷入用"版本，`w` 命令） | https://github.com/TomKing062/action_spd_dump_it （预编译版构建） | 仓库未声明许可证；二进制来自其 CI 发布 |
| **FDL1 / FDL2（T618）** | 展锐下载模式第一/二阶段加载器，来自同芯片平台机型的固件包 | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/releases/tag/1.72 | 随上述发布包提供 |
| **custom_exec_no_verify_3ee8.bin** | BROM 签名校验绕过载荷（UMS512） | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader （`soc/ums512/`） | 同上 |

---

## 3. Root 与签名 / Root and signing

| 工具/资源 | 用途 | 来源 | 许可证 |
|---|---|---|---|
| **Magisk** (topjohnwu) | 打 boot 补丁、提供 root（本项目附带 v31.1 安装包） | https://github.com/topjohnwu/Magisk | **GPL-3.0**（Magisk 为开源软件，安装包按其许可证分发） |
| **avbtool** (TheGammaSqueeze/UnisocBypass 内置) | Android 11 boot 镜像 AVB 重新签名 | https://github.com/TheGammaSqueeze/UnisocBypass （`tools/avbtool`） | UnisocBypass 仓库为 **MIT**；avbtool 源自 AOSP（Apache-2.0） |
| **rsa4096_boot.pem** | 展锐公开的 boot 签名测试密钥 | https://github.com/TomKing062/vendor_sprd_proprietories-source_packimage （`sign_image/config-unisoc/`） | 公开测试密钥 |
| **AVB 签名方法** | Android 10/11 展锐设备 Magisk boot 签名的参数参考 | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/Magisk | 同上项目 Wiki |

---

## 4. 其他工具 / Other tools

| 工具 | 用途 | 来源 | 许可证 |
|---|---|---|---|
| **Zadig** (pbatard/libwdi) | 为下载模式设备安装 WinUSB 驱动（本项目附带 zadig.exe） | https://github.com/pbatard/libwdi/releases | **GPL-3.0**（Zadig 为开源软件） |
| **ADB / Fastboot** (Google) | 设备通信（本项目附带 platform-tools） | https://developer.android.com/tools/releases/platform-tools | Google 平台工具，按 Google 条款分发 |
| **libusb** | unisoc-unlock 与 spd_dump 的 USB 通信底层库 | https://libusb.info/ | **LGPL-2.1** |

---

## 5. 说明 / Notes

- 本项目**仅整理与复现**上述工具的使用流程，不修改、不重新打包任何第三方工具本体。
- 各第三方工具的版权归各自作者所有。使用前请阅读其许可证。
- 若你是某工具的作者且不希望被包含在项目中，请通过 Issue 联系，我们将移除相关引用。
- This project only documents and reproduces the usage workflow of the above tools; it does not modify or repackage the third-party tools themselves. All rights remain with their respective authors. Please review each license before use. If you are an author and wish to be removed, please open an issue.
