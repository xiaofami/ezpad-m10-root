# Jumper EZPad M10（展锐 T618）解锁 + Root 全流程操作手册

适用机型：**Jumper EZPad M10 / EZpad_M10_EEA**，Android 11，固件 V1.1.2（build 29540）。

本手册实现**从解锁 Bootloader 到 Root 的完整流程**。解锁与 Root 是两件独立的事：
- **解锁 Bootloader**：用 `unisoc-unlock` 的 token 签名方案（Windows 可复现，原流程在 macOS 上实测成功）
- **Root**：导出原厂 boot → Magisk 打补丁 → 重新签名 → BROM 刷入

> 若你的设备**已经解锁**（`ro.boot.verifiedbootstate=orange`），可跳过第三章解锁部分，直接从第四章 Root 开始。

---

## 一、一次看完全流程

```
准备（一次性）
  ├─ 装 USB 驱动（Zadig → WinUSB，仅 root 环节需要）
  │   → tools\0_安装驱动向导.bat（自动抓下载模式的 timing）
  └─ 工具已全部放在本项目 tools/ 目录，无需再下载

第一阶段：解锁 Bootloader（若已解锁可跳过）
  0. 解锁             → tools\解锁\0_解锁Bootloader.bat
  1. 验证解锁状态      → tools\解锁\1_验证解锁状态.bat
     （解锁会清空数据，128GB 擦除约 10 分钟）

第二阶段：Root
  2. 导出原厂 boot    → tools\1_导出原厂boot.bat
  3. 装 Magisk + 推送 → tools\2_安装Magisk并推送boot.bat
  4. Magisk 打补丁    → 在平板屏幕上点几下
  5. 重新签名         → tools\3_签名boot.bat
  6. 刷入             → tools\4_刷入boot.bat
  7. 验证 root        → tools\5_验证root.bat
```

随时可用 `tools\0_查看设备状态.bat` 确认平板处于哪个模式。

> 全程：解锁约 15 分钟（含擦除），Root 约 10 分钟。每一节对应一次操作，照着做即可。

---

## 二、准备工作（只做一次）

### 2.1 确认机型
平板进系统，电脑执行：
```
platform-tools\adb.exe shell getprop ro.product.model
```
应显示 `EZpad M10`。再确认版本：
```
platform-tools\adb.exe shell getprop ro.build.version.release   → 11
platform-tools\adb.exe shell getprop ro.build.version.incremental → 29540
```

### 2.2 安装 USB 驱动（关键，否则电脑认不到平板）

> **核心难点：`VID_1782 / PID_4D00` 这个设备只在平板处于「下载模式」时才会出现在电脑上。安卓系统正常开机时看不到它。** 所以必须先让平板进下载模式，并在设备在线的窗口期内完成 Zadig 操作（抓 timing）。

**为什么会“抓不到”**：平板进下载模式后，如果没按住音量键，可能很快退出下载模式、设备随即消失；或者电脑弹出“无法识别的 USB 设备”。所以操作顺序很重要——**先把 Zadig 打开准备好，再让平板进下载模式**，设备一出现就立刻选它安装。

**推荐用向导脚本**（自动检测 timing、一步步提示）：
- 双击 `tools\0_安装驱动向导.bat`（推荐，自动检测 timing）
- 脚本会：先提示你打开 Zadig 并勾选 List All Devices → 检测下载模式设备是否在线 → 在线时提示你立刻在 Zadig 里选设备装驱动 → 装完自动验证

**手动步骤**（若不用向导）：
1. **先**双击 `tools\工具包\驱动\zadig.exe`（UAC 点“是”），菜单 **Options → List All Devices** 打勾，把 Zadig 窗口放一边待命。**保持 Zadig 开着**。
2. **再**让平板进下载模式：平板完全关机 → 按住 **音量减** → 插 USB 线 → 保持按住 **15 秒**（闪光点常亮）。
3. 平板进入下载模式后，**立刻回到 Zadig**：下拉框会刷新出设备，选含 **VID_1782 / PID_4D00** 的那一项（可能显示为 `Unknown Device (1782, 4D00)` 或 `Gadget Serial`）。
   - 若下拉框没有：确认平板闪光点仍常亮、按住音量减；换回能识别的 USB 口；Zadig 菜单 **Options → List All Devices** 确认已打勾，必要时重开 Zadig。
4. 右侧驱动选 **WinUSB**。
5. 点 **Install Driver**，等安装完成（UAC 点“是”）。装完即使平板退出下载模式也没关系，驱动绑定已保存在系统里，以后进下载模式会自动生效。
6. 验证：双击 `tools\0_查看设备状态.bat`，让平板进下载模式，应显示“下载模式：在线”。

> 一句话口诀：**Zadig 先开着 → 平板进下载模式 → 设备一冒头马上选它装 WinUSB**。

### 2.3 本机自带工具（无需下载，链接失效也不影响）
| 位置 | 内容 |
|---|---|
| `tools\工具包\platform-tools\` | adb.exe、fastboot.exe |
| `tools\工具包\驱动\` | zadig.exe（WinUSB 驱动工具） |
| `tools\工具包\spd_导出用\` | 原版 spd_dump + FDL（导出 boot 用） |
| `tools\工具包\spd_刷入用\` | TomKing062 版 spd_dump + FDL（刷入 boot 用） |
| `tools\工具包\Magisk-v31.1.apk` | Magisk 安装包 |
| `tools\工具包\签名工具\` | avbtool、rsa4096_boot.pem（签名用） |
| `tools\工具包\解锁工具\` | unisoc-unlock 及依赖（独立 venv，解锁用，免联网） |

> 说明：导出和刷入用**两个不同版本**的 spd_dump，各自配好自己的 FDL，脚本已分别指向正确目录，不要混用。

### 2.3.1 关于两套工具的 USB 驱动是否冲突（已实测：不冲突）
解锁工具和 root 工具工作在**不同的 USB 设备身份**上，互不干扰：

| 工具 | 设备模式 | USB 身份 | 驱动 |
|---|---|---|---|
| unisoc-unlock（解锁） | fastboot | `VID_18D1&PID_4EE0` | WinUSB（系统自动绑定） |
| spd_dump（root） | 下载模式/BROM | `VID_1782&PID_4D00` | WinUSB（Zadig 手动装） |

两种模式互斥、不会同时出现，驱动绑定在不同 VID/PID 上，因此**不冲突**。实测 fastboot 的 `18D1:4EE0` 驱动服务为 WinUSB，解锁工具的 libusb 可直接访问。Zadig 装的 WinUSB 只针对下载模式 `4D00`，不影响解锁。

### 2.4 其他要求
- 电脑需装 **Python 3**（签名脚本用）。没有的话装一个并勾选“Add Python to PATH”。解锁工具已自带独立 venv，无需额外装 Python 依赖。
- 判断是否需要解锁：进系统后 `adb shell getprop ro.boot.verifiedbootstate` — 若是 `green` 需先解锁，若是 `orange` 可跳过第三章。

---

## 三、第一阶段：解锁 Bootloader（已解锁可跳过）

> 本机原始流程在 macOS 上实测成功（token 签名方案）。Windows 上用同一工具 `unisoc-unlock`，已本地化到 `tools\工具包\解锁工具\`，无需联网安装。

### 3.1 解锁原理（简述）
展锐 bootloader 的标准解锁命令（`fastboot flashing unlock` / `fastboot oem unlock`）在这台设备上无效。正确做法是用 `unisoc-unlock`：
1. 读取设备的 **Identifier Token**（本机是序列号的十六进制）
2. 用**泄露的私钥 `rsa4096_vbmeta.pem`** 对该 token 签名（该密钥对 UMS512/T618 有效）
3. 通过定制 fastboot 命令把签名发给设备完成解锁

### 3.2 解锁步骤
1. 平板进系统，插好 USB，开启 USB 调试并在弹窗点“允许”
2. 双击 `tools\解锁\0_解锁Bootloader.bat`
3. 脚本自动：开启 OEM unlocking → 重启进 fastboot → 执行解锁
4. 出现 `Unlock bootloader, pls follow instructions on device screen` 时，在**平板屏幕**上按**音量键**确认
5. 屏幕显示 `Begin to erase user data` 后开始擦除 128GB（**约 10 分钟，别断电、保持 USB**）
6. 擦除完自动重启，完成开机向导，重新开启开发者选项 + USB 调试 + 重新授权弹窗

### 3.3 解锁注意事项
- **标准 fastboot 解锁命令无效**，必须用 token 签名方案（脚本已封装）。
- **必须先开 OEM unlocking**（脚本已做 `settings put global oem_unlock_enabled 1`）。
- **确认要在 60 秒内按音量键**：工具默认超时 60 秒，若超时报 `ReadFailedError`，但只要你按了键，设备端解锁照样执行，不算失败（已知现象）。
- **擦除很慢**：128GB 全量擦除约 10 分钟，`fastboot reboot` 可能耗时 600 多秒才返回，属正常，耐心等。

### 3.4 验证解锁
双击 `tools\解锁\1_验证解锁状态.bat`，三项全部符合即成功：
```
ro.boot.verifiedbootstate  = orange
ro.boot.flash.locked       = 0
ro.boot.vbmeta.device_state = unlocked
```
确认后进入第四章 Root。

---

## 四、第二阶段：Root（主线操作）

### 进入下载模式的方法（步骤 1 和步骤 5 会用到）
1. 平板**完全关机**
2. 按住 **音量减** 不放
3. 插入 USB 线，继续按住 **15 秒**后松开
4. **平板后置闪光灯（摄像头旁的 LED）常亮** = 成功进入下载模式（此时屏幕可能是黑的）

> 用 `tools\0_查看设备状态.bat` 可确认“下载模式：在线”。

### 步骤 1：导出原厂 boot（备份，必须做）
1. 让平板进入下载模式（见上）
2. 双击 `tools\1_导出原厂boot.bat`（UAC 点“是”）
3. 按提示确认后，脚本自动导出
4. 看到 `[成功] 原厂 boot 已导出：67108864 字节` 即完成
5. 产出：`stock_boot_a.img`（这就是你的原厂 boot 备份，务必留好）

脚本会自动确认设备在线；若提示未检测到，重新进下载模式再运行。

### 步骤 2：安装 Magisk 并推送 boot
1. 拔掉 USB，长按电源键开机进系统，再插回 USB
2. 屏幕上若弹“允许 USB 调试”，点允许并勾选“一律允许”
3. 双击 `tools\2_安装Magisk并推送boot.bat`
4. 自动安装 Magisk，并把 `stock_boot_a.img` 推到平板 `/sdcard/Download/boot.img`
5. 看到提示后，进入步骤 3

### 步骤 3：在平板上用 Magisk 打补丁
1. 平板打开 **Magisk** App
2. 点底部 **安装**
3. 点 **选择并修补一个文件 / Select and Patch a File**
4. 选 `Download` 目录里的 **boot.img**
5. 等修补完成，会生成 `magisk_patched-xxxxx.img`（记住即可，不用手动找）

### 步骤 4：重新签名
> Android 11 的 boot 必须带有效签名，否则卡开机 logo。本步自动完成，且**不改动 vbmeta**。

1. 双击 `tools\3_签名boot.bat`
2. 脚本自动：从平板取回补丁镜像 → 用展锐密钥签名 → 校验
3. 核对输出的 Salt 是 `6e7a76be...`（与原厂一致）
4. 看到 `[成功] 已签名镜像` 即完成

### 步骤 5：刷入
1. 拔掉 USB，关机，重新进入下载模式（后置闪光灯常亮）
2. **进入下载模式后不要运行其他 spd_dump 脚本**（见附录 A 说明）
3. 双击 `tools\4_刷入boot.bat`（UAC 点“是”）
4. 看到 `[成功] 刷入完成！` 即完成

### 步骤 6：验证 root
1. 拔 USB，长按电源键开机进系统
2. 打开 Magisk → **Superuser** → 给 **[SharedUID] Shell** 授权
   > Magisk v31 没有授权弹窗，必须手动预先授权，否则 `su` 会被拒绝
3. 双击 `tools\5_验证root.bat`
4. 看到 `uid=0(root) ... context=u:r:magisk:s0` 即**root 成功**

---

## 五、备份与恢复

导出/签名过程中产生的重要文件（都在项目根目录）：

| 文件 | 说明 |
|---|---|
| `stock_boot_a.img` | 原厂 boot 备份，去 root 或救砖用 |
| `magisk_patched.img` | 已签名的 root boot |
| `boot_a_root.img` / `boot_b_root.img` | root 后从设备回读的双槽位镜像，用于校验 |
| `spd2\part.xml` | 完整分区表（76 个分区） |

**去 root / 恢复原厂**：重新导出或取回原厂 boot，用 `spd_dump` 的 `w` 命令刷回 `boot_a` 即可（可参考步骤 5，把镜像换成 `stock_boot_a.img`）。去 root 后若卡开机动画，在 recovery 里做一次 factory reset。

**重要提醒**：不要 OTA 升级——会覆盖 patched boot 导致失去 root。升级前先刷回原厂 boot。

---

## 六、目录结构

```
<项目根目录>\
├─ README.md                  项目说明（中英双语）
├─ docs\ROOT_GUIDE.md         本手册
├─ tools\
│  ├─ 解锁\
│  │  ├─ 0_解锁Bootloader.bat
│  │  └─ 1_验证解锁状态.bat
│  ├─ 0_安装驱动向导.bat      抓下载模式 timing 装 WinUSB
│  ├─ 0_查看设备状态.bat
│  ├─ 1_导出原厂boot.bat
│  ├─ 2_安装Magisk并推送boot.bat
│  ├─ 3_签名boot.bat
│  ├─ 4_刷入boot.bat
│  ├─ 5_验证root.bat
│  └─ 工具包\                 全部工具已本地化保存
│     ├─ platform-tools\      adb / fastboot
│     ├─ 驱动\                zadig.exe
│     ├─ spd_导出用\          原版 spd_dump + FDL
│     ├─ spd_刷入用\          TomKing062 版 spd_dump + FDL
│     ├─ 解锁工具\            requirements.txt + 安装脚本（安装 unisoc-unlock）
│     ├─ Magisk-v31.1.apk
│     └─ 签名工具\            avbtool、rsa4096_boot.pem
└─ 生成的本地产物（不入仓库）：
   stock_boot_a.img           原厂 boot 备份
   magisk_patched.img         已签名 root boot
   boot_a_root.img / boot_b_root.img  回读校验用
   part.xml                   分区表
```

---

# 附录

## 附录 A：失败记录与排查（操作时不需要看，遇到问题再查）

本次实操踩过的坑，按现象列出：

| 现象 | 原因 | 解决 |
|---|---|---|
| 解锁：`fastboot flashing unlock` 报 unknown cmd | 展锐 LK 不支持标准解锁命令 | 用 token 签名方案（脚本已封装） |
| 解锁：`fastboot oem unlock` 报 Unlock bootloader fail | 同上 | 同上 |
| 解锁：未开 OEM unlocking 导致失败 | `oem_unlock_enabled` 为 null | 脚本已执行 `settings put global oem_unlock_enabled 1` |
| 解锁工具报 `ReadFailedError` 超时 | 60 秒内没按音量键 | 只要已在平板上按了音量键，设备端解锁照常执行，不算失败 |
| 解锁后 128GB 擦除很慢 | 全量擦除正常现象（约 10 分钟） | 耐心等，别断电，保持 USB |
| 解锁后 ADB 失效 | 擦除清掉了 USB 调试授权 | 重新开开发者选项 + USB 调试 + 重新授权弹窗 |
| `adb devices` 显示 unauthorized | 未点 USB 调试授权 | 平板点“允许”，勾选“一律允许” |
| `adb root` 报 `cannot run as root in production builds` | 用户版系统 | 正常，必须走 BROM 导出 |
| `fastboot fetch` / `oem pull` 为 unknown cmd | 展锐 LK 是精简版 | 放弃 fastboot 读分区 |
| `fastboot flash` 卡在 `Fetching super` | 展锐 LK bug，会去读 4.3GB 的 super 分区 | 放弃 fastboot，改 BROM 写入 |
| 导出报 `ver expected` | 原版 spd_dump 必须先跑 `partition_list` 完成握手 | 导出命令里保留 `partition_list`（脚本已含） |
| 刷入报 `ver expected` | spd_dump 每运行一次，设备就退出下载模式；探测后紧接着刷必然失败 | 刷入前重新进下载模式，且**不要先跑探测脚本** |
| `libusb_open_device failed` | 设备不在线或驱动问题 | 检查“下载模式：在线”，重装 Zadig 驱动 |
| `LIBUSB_ERROR_PIPE` / `usb_send failed` | USB 不稳 | 换回能识别的 USB 口，重新进下载模式 |
| 换 USB 口后“无法识别的 USB 设备” | USB 枚举失败 | 换回原来的口，重新进下载模式 |
| `write_part` 报 `unknown command` | 原版工具写入命令是 `write_part` 不是 `w`；且原版写入不稳（PIPE） | 刷入改用 TomKing062 版 `w` 命令（脚本已含） |
| `adb shell su` 报 Permission denied | Magisk v31 需预先授权 Shell | Magisk → Superuser → 授权 `[SharedUID] Shell` |
| PowerShell 脚本被拦 | 执行策略限制 | `powershell.exe -ExecutionPolicy Bypass -File xxx.ps1` |
| 提权脚本没执行、日志时间戳没变 | UAC 弹窗没点“是” | 每次请求管理员权限都要点“是” |
| 刷完卡开机 logo | boot 与机型/固件不匹配，或没签名 | 确认 V1.1.2/29540，刷回原厂 boot |
| 后置闪光灯常亮但电脑检测不到 | USB 枚举失败 | 重新进下载模式，换回能识别的 USB 口 |

### 关键教训（供参考）
- **两个 spd_dump 版本不能混用**：导出用原版（在 `spd_导出用`），刷入用 TomKing062 版（在 `spd_刷入用`）。
- **一次运行一个动作**：spd_dump 跑完设备就退出下载模式，所以刷入前必须重新进下载模式，且中间不要跑探测命令。
- **fastboot 在这台设备上刷 boot 不可用**，只能走 BROM。

## 附录 B：关于"长时间验证 user 分区"的问题（已解决）

本次实操曾遇到两处卡顿，整理后的主线流程已**彻底绕开**，不会再遇到：

1. **fastboot 刷入卡在 `Fetching super`**：展锐 LK 的 `fastboot flash` 有 bug，会错误地读取 4.3GB 的 super 分区导致假死。
   → 本流程**不使用 fastboot 刷写**，`4_刷入boot.bat` 改走 BROM 的 `w boot_a`，只写 64MB 的 boot 分区。

2. **spd_dump 读整盘卡在 12.5%**：不列分区表时，工具会退化成读取整个 `user_partition`（128GB），很快报 `LIBUSB_ERROR_PIPE`。
   → 本流程的 `1_导出原厂boot.bat` **保留了 `partition_list` 步骤**，随后精确 `read_part boot_a 0 64M`，只读 64MB，不触碰 user 区。

结论：主线脚本全程只读写 64MB 的 boot_a，不访问 user/super 分区，因此不会出现长时间验证或卡死。若你仍遇到类似卡顿，通常是设备没真正进入下载模式或 USB 不稳，见附录 A。

## 附录 C：原理简述（可选阅读）

- **boot.img**：开机加载的内核+ramdisk。Magisk 把自身注入其中实现 root。
- **AVB 签名**：Android 11 会校验 boot 签名，补丁镜像必须重新签名，但不要动 vbmeta。
- **A/B 槽位**：设备有 `boot_a`/`boot_b`，当前用 `_a`。B 槽保留原厂可作救命槽。
- **BROM / FDL1 / FDL2**：芯片最底层的下载通道。系统没有 root 时，通过它导出/写入分区。

## 附录 D：工具出处与校验值（可选）

### 工具出处（本地已保存，链接仅供溯源/日后替换）

| 工具 | 本地位置 | 原始出处 |
|---|---|---|
| adb / fastboot | `tools\工具包\platform-tools\` | https://dl.google.com/android/repository/platform-tools-latest-windows.zip |
| Zadig（WinUSB 驱动工具） | `tools\工具包\驱动\zadig.exe` | https://github.com/pbatard/libwdi/releases/download/v1.5.1/zadig-2.9.exe |
| spd_dump 原版（导出用） | `tools\工具包\spd_导出用\` | https://github.com/ilyakurdyukov/spreadtrum_flash/releases （spd_dump64.zip） |
| spd_dump TomKing062 版（刷入用） | `tools\工具包\spd_刷入用\` | https://nightly.link/TomKing062/action_spd_dump_it/workflows/build/main/spd_dump_it_main_251_e49d4de_x64_Release.zip |
| FDL1 / FDL2（T618） | 上述两个 spd_dump 目录内 | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/releases/tag/1.72 （`ums512_for_android10_alldocube_iplay_50_repack.zip` 及 `ums512_infinix_hot_12_play_nfc.zip`） |
| custom_exec_no_verify_3ee8.bin | `tools\工具包\spd_刷入用\` | https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader （`soc/ums512/`） |
| Magisk v31.1 | `tools\工具包\Magisk-v31.1.apk` | https://github.com/topjohnwu/Magisk/releases/download/v31.1/Magisk-v31.1.apk |
| avbtool | `tools\工具包\签名工具\avbtool` | https://raw.githubusercontent.com/TheGammaSqueeze/UnisocBypass/main/tools/avbtool |
| rsa4096_boot.pem（展锐签名密钥） | `tools\工具包\签名工具\rsa4096_boot.pem` | https://github.com/TomKing062/vendor_sprd_proprietories-source_packimage （`sign_image/config-unisoc/`） |
| unisoc-unlock（解锁工具，含 libusb1/pycryptodome 依赖） | `tools\工具包\解锁工具\venv\` | https://github.com/patrislav1/unisoc-unlock （`pip install unisoc-unlock`） |
| rsa4096_vbmeta.pem（解锁用泄露密钥，已打包在 unisoc-unlock 内） | 在解锁工具 venv 的 site-packages 内 | https://raw.githubusercontent.com/patrislav1/unisoc-unlock/main/src/unisoc_unlock/rsa4096_vbmeta.pem |

> 工具均来自上述开源项目，已下载并本地化保存到 `tools\工具包\`。原始链接仅用于溯源或日后更新替换；即使链接失效，本地副本仍可正常完成本流程。

### 主要文件校验值（SHA256）

| 文件 | SHA256 |
|---|---|
| stock_boot_a.img | `249F80C9D3D0B22242EA9F6D60065B8AE7262DBB097CDDBA7A89C4D8F5525388` |
| magisk_patched.img | `6724ABDE823B31BD84D66E9DA324F37231BC382F40524217EC66409E72F48FE9` |
| boot_a_root.img | 同上（证明补丁已正确刷入 A 槽） |
| boot_b_root.img | 同上原厂值（B 槽保持原厂） |
| Magisk-v31.1.apk | `89CEFAC0A318AFA39FB3880C45C87B036C05BC1EBF02A7A715B7F8D7C26AC6E7` |
| avbtool | `6F5BA8590B01DFD03430ECC02F3E583DE18C2A2469BE5746992C8ED417AEBE1D` |
| rsa4096_boot.pem | `D7352AA740A6D73DD9A454DB98ED9B018580BFC2940CC7F38512B2918ABAE97C` |
