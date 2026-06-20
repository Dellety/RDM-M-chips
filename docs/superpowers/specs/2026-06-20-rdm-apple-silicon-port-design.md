# RDM Apple Silicon 移植设计

- **日期**：2026-06-20
- **状态**：待批准
- **作者**：Doni（基于与用户的 brainstorming 对话）
- **目标项目**：[github.com/Dellety/RDM-M-chips](https://github.com/Dellety/RDM-M-chips)

## 1. 背景与动机

RDM (Retina Display Menu) 是一个 macOS 菜单栏工具，用于把 MacBook Pro Retina 屏幕切换到 Apple 官方未开放的原生高分辨率（例如 13" 切到 3360×2100）。原作者 Avi Alkalay 停留在 2.2 版本。

用户机器上安装的 `/Applications/RDM.app` 是 **2016 年的 RDM 2.2，纯 x86_64 二进制**，目前在 Apple Silicon (arm64) 的 macOS 26.5 上靠 Rosetta 2 转译运行。Apple 已开始要求所有软件提供原生 arm64 切片，Rosetta 2 终将被移除，因此系统提示"不再支持"。

本 fork 的目标：**移植为原生 arm64 应用**，在新 macOS 上不依赖 Rosetta 直接运行，并可在团队内部分发。

## 2. 可行性验证（已确认）

在 brainstorming 阶段已用真实代码验证，结论确定：

1. **核心私有 API 仍可用**。软件依赖 4 个私有 CGS 符号：
   - `CGSGetCurrentDisplayMode`
   - `CGSConfigureDisplayMode`
   - `CGSGetNumberOfDisplayModes`
   - `CGSGetDisplayModeDescriptionOfLength`

   在 macOS 26.5.1 的 **CoreGraphics** 框架中**全部仍导出**（用 `dyld_info -exports` 确认，每个符号 exports=1）。

2. **arm64 端到端编译运行成功**。用 `clang++ -arch arm64` 编写最小测试程序链接这 4 个符号并运行，成功返回主显示器的模式列表（236 个模式）和当前模式索引（137）。**零运行时报错**。

3. **"不再支持"的根因是架构，不是 API**。`Makefile` 第 10 行写死 `ARCH_FLAGS=-arch x86_64`，所以只产 Intel 切片。修正为 arm64 即可。

## 3. 范围

### 做

1. 重编译为 arm64，编译器从 `llvm-g++` 换为系统 `clang++`（Apple clang 21）
2. 启用 ARC (`-fobjc-arc`)，从源码中移除手动 `retain/release/autorelease`
3. 修复新工具链下的编译警告，达到 `-Wall -Wextra` 下零警告
4. Makefile 现代化（`build` / `pkg` / `dmg` 目标清晰，默认目标为 `build`）
5. 版本号升级至 **2.3**（`CFBundleShortVersionString` 与 `CFBundleVersion`），保留 bundle ID `net.alkalay.RDM`（覆盖式升级，保留用户偏好 `~/Library/Preferences/net.alkalay.RDM.plist`）
6. 重写 README：原作者说明转为 Markdown 引用块保留，删除所有图片
7. 产出原生 arm64 的 `RDM.app` 与 `RDM-2.3.dmg` 分发包

### 不做（明确排除以避免范围蔓延）

- ❌ 不迁 Swift，不引入 Xcode 工程（仅命令行 + CommandLineTools 即可）
- ❌ 不做 universal binary（纯 arm64，需要 x86_64 时直接用原作 2.2）
- ❌ 不改功能逻辑、不改 UI、不改私有 API 调用方式、不重构菜单构建逻辑
- ❌ 不做代码签名 / notarization（用户暂不办付费 Apple Developer 账号；分发靠同事首次放行）
- ❌ 不重构 `SRApplicationDelegate.mm` 中重复两遍的循环

## 4. 详细设计

### 4.1 构建系统（Makefile）

核心改动：

```makefile
# 原
CC=llvm-g++
ARCH_FLAGS=-arch x86_64
VERSION=2.2

# 新
CC=clang++
ARCH_FLAGS=-arch arm64
VERSION=2.3
```

附加现代化：

- 编译行加 `-fobjc-arc -Wall -Wextra -mmacosx-version-min=11.0`
  - arm64 mac 最低系统是 Big Sur (11.0)，`-mmacosx-version-min=11.0` 是合理下限
- 默认 `make` 目标 → `build`（生成 `RDM.app`）
- 目标层级：`build` → `pkg` → `dmg`，与原 Makefile 一致
- `make dmg` 产出 `RDM-2.3.dmg`

### 4.2 源码改动（ARC 迁移）

**只做与 ARC 相关的最小改动，不动逻辑**：

| 文件 | 改动 |
|---|---|
| `main.mm` | `NSAutoreleasePool* pool = [NSAutoreleasePool new]` + `[pool release]` → `@autoreleasepool { }` |
| `SRApplicationDelegate.mm` | 删除 `statusMenu`、`statusItem` 的 `retain`/`release`；`[statusMenu release]` 删除 |
| `SRApplicationDelegate.h` | 裸 ivar `statusMenu`/`statusItem` 在 ARC 下默认即为 strong，**结构无需改动**，仅确认行为 |
| `ResMenuItem.mm` | 删除 `[item autorelease]` 注释；实例变量在 ARC 下自动管理 |
| `cmdline.mm` | `NSAutoreleasePool* pool = [NSAutoreleasePool new]` + `[pool release]` → `@autoreleasepool { }` |
| `utils.mm` | `malloc`/`free` **保留**（C 内存，不走 ARC） |
| `SRApplicationDelegate.mm` / `cmdline.mm` 中调用 utils 的地方 | `free(modes)` **保留** |
| 全部 `.mm` | 修复 `-Wall -Wextra` 暴露的格式串/类型混用 warning（如 `cmdline.mm` 里 `uint16_t freq` 用 `%d` 打印需加 `(int)` cast），用 cast 而非改类型 |

**关键约束**：

- `modes_D4` 是 `malloc` 分配的 C 结构体，**不走 ARC**，保持手动 `malloc/free`。只清理 ObjC 对象的引用计数，绝不碰 C 指针。这是 ARC 迁移里最易出错处。
- **不改逻辑、不修已有 bug**。例如 `cmdline.mm` 第 158 行 `listDisplays` 循环中对所有显示器都读取同一个 `display` 变量（应为 `displays[i]`）是**既有 bug**，本次明确**不修**，保持"只做移植+现代化"的范围纪律。

### 4.3 版本与 Bundle ID

- `Info.plist`：
  - `CFBundleShortVersionString` = `2.3`
  - `CFBundleVersion` = `2.3`
- `CFBundleIdentifier` = `net.alkalay.RDM`（**不变**）

### 4.4 README 重写

**新结构**：

1. 标题 + 一句话简介：RDM 是 Retina Display Menu
2. 本 fork 的定位：原生 Apple Silicon (arm64) 版本，源自 RDM 2.2，面向新版 macOS
3. **⚠️ 原文引用区**：用 Markdown `>` 引用块保留原作者 Avi Alkalay 的原始说明（功能描述、HiDPI ⚡️ 标记含义、Login Items 提示），作为历史出处与致谢
4. 构建说明：依赖（macOS Command Line Tools）、`make build` / `make dmg` 用法
5. 下载与安装：从 GitHub Releases 下载 DMG，拖到 `/Applications`（覆盖旧版 RDM 2.2，偏好设置保留）
6. **分发给同事的首次打开说明**（因不签名）：右键 → 打开；或「系统设置 → 隐私与安全性 → 仍要打开」
7. 致谢 / License：沿用 GPLv3，注明原作者

**删除**：所有图片（`monitor.png` 截图引用、外链 cloud.githubusercontent 截图）、失效的 `avi.alkalay.net/software/RDM/` 下载链接。

**保留**：`Resources/` 目录里的图标资源不动（是 app 资源，不是 README 图片）；原作者功能说明文字以引用形式完整保留。

## 5. 验证清单

构建完成后逐项验证：

1. `file RDM.app/Contents/MacOS/SetResX` → 显示 `arm64`
2. `make` 全程 **0 warning**（`-Wall -Wextra` 下）
3. 双击运行 `RDM.app` → 菜单栏出现图标，无崩溃
4. 点开菜单 → 能列出显示器和分辨率模式（⚡️ 标记正常）
5. 切换一个分辨率 → 实际生效（需手动确认，涉及显示输出）
6. 切回原分辨率 → 正常
7. 系统不再提示"需要 Rosetta"

## 6. 交付物

- `RDM.app`（arm64，版本 2.3）
- `RDM-2.3.dmg`（可分发）
- 重写的 `README.md`
- 更新后的 `Makefile`、`Info.plist`、`.mm` 源文件（ARC）
- 本设计文档（存档）

## 7. 风险与回退

- **风险**：Apple 在未来 macOS 可能最终移除私有 CGS 符号。当前 (macOS 26.5) 仍可用，无法保证长期。
  - **缓解**：本设计不改变 API 调用方式，若未来失效，届时再评估是否迁移到公开 API（如 `CGDisplayMode` 系列，但功能可能受限，无法设置 Apple 未开放的高分辨率——这正是 RDM 的核心价值）。
- **回退**：所有改动可 `git revert`，或直接重新装回 `/Users/doni/Downloads/RDM-2.2.dmg` 的原版。
