# RDM（Retina Display Menu）

一个菜单栏工具，用于将 MacBook Pro Retina 屏幕切换到 Apple 在系统设置中未开放的原生高分辨率。

**本 fork** 是 RDM 2.2 的原生 **Apple Silicon (arm64)** 移植版。上游 2.2 二进制仅支持 Intel（x86_64），在新款 Mac 上需通过 Rosetta 2 运行，而 Apple 正在逐步淘汰 Rosetta 2。本版本原生编译为 arm64，在新版 macOS 上无需 Rosetta 即可运行。

- 架构：**arm64**（原生 Apple Silicon）
- 语言：Objective-C++（与上游一致）
- macOS 部署目标：11.0（Big Sur）及以上

## 功能

通过菜单栏可选择硬件上报的任意显示模式——包括 Apple 界面隐藏的 HiDPI / 2× 模式。例如，13 寸 Retina MacBook Pro 可设置为原生 3360×2100，而非 Apple 上限的 1680×1050。

## 从 Release 安装

1. 从 [Releases 页面](../../releases) 下载 `RDM-2.3.dmg`。
2. 打开 DMG，你会看到 `RDM.app` 和一个 `Applications` 文件夹快捷方式。
3. **把 `RDM.app` 拖到 `Applications` 文件夹上。** 即安装到 `/Applications`。若已存在旧版 RDM 2.2，会被原地替换——你的偏好设置会保留（bundle ID 相同，为 `net.alkalay.RDM`）。
4. 推出 DMG，从 `/Applications`（或聚焦搜索）启动 `RDM.app`。菜单栏会出现一个显示器图标。

### 在同事的 Mac 上首次启动（未签名版本）

本版本**未进行代码签名**（未购买付费 Apple Developer 账号），因此 macOS Gatekeeper 会提示"无法验证开发者"。首次打开请采用以下方式之一：

- **右键点击** `RDM.app` → **打开** → 在弹窗中确认。首次之后即可正常打开。
- 若已被拦截：打开 **系统设置 → 隐私与安全性**，找到 RDM 提示，点击 **仍要打开**。

首次确认后，Gatekeeper 会记住该 app，之后不再询问。

### 开机自启

将 `RDM.app` 加入登录项以自动启动：
**系统设置 → 通用 → 登录项与扩展** → 在"开机时打开"下添加 RDM。

## 从源码构建

需要：macOS Command Line Tools（无需完整 Xcode）。

```sh
make build      # 生成 RDM.app
make dmg        # 生成 RDM-2.3.dmg（拖拽式分发）
make clean      # 清理构建产物
```

它使用 CoreGraphics 的私有 `CGS*` 符号
（`CGSGetCurrentDisplayMode`、`CGSConfigureDisplayMode`、
`CGSGetNumberOfDisplayModes`、`CGSGetDisplayModeDescriptionOfLength`）——在当前
macOS 中仍导出——来枚举和切换显示模式。

## 致谢与原始说明

RDM 最初由 **Avi Alkalay** 编写。下方引用块为上游原始 README，原文保留用于致谢：

> This is a tool that lets you use MacBook Pro Retina's highest and unsupported resolutions.
> As an example, a Retina MacBook Pro 13" can be set to 3360×2100 maximum resolution, as
> opposed to Apple's max supported 1680×1050. It is accessible from the menu bar.
>
> You should prefer resolutions marked with ⚡️ (lightning), which indicates the resolution
> is HiDPI or 2× or more dense in pixels.
>
> For more practical results, add RDM.app to your Login Items in **System Preferences ➡ Users & Groups ➡ Login Items**.
> This way RDM will run automatically on startup.
>
> This software was studied and released [here](http://garethjenkins.com/2012/07/01/investigating-a-high-resolution-retina-utility-for-macbook-pro-1x-and-2x-modes/#comment-623)
> and [here](http://www.reddit.com/r/apple/comments/vi9yf/set_your_retina_macbook_pros_resolution_to/)
> by its original authors. I just improved the build system and Makefile, fixed the icon,
> added support for easy installable package (PKG, DMG) and improved the way menu is
> displayed. I don't know what is the license by its authors because it came 100%
> uncommented and undocumented. But I'm sure they would enjoy you to freely use it. Me too.

## License 与版权归属

**上游 RDM 未附带明确的 license。** 上游仓库
（[avibrazil/RDM](https://github.com/avibrazil/RDM)）没有 LICENSE 文件，也没有任何
license 声明；其 README 表示原作者对代码的 license 不确定，因为"它百分之百没有注释和文档"。
此前 `Info.plist` 中"Distributed under GNU General Public License v3.0"的声明毫无依据，
已被移除。

已知信息：

- 上游作者明确欢迎自由使用：*"I'm sure they would enjoy you to freely use it. Me too."*
- 本软件不提供任何担保或支持。

本 fork 沿用同样的非正式"自由使用、无担保"约定，仅供个人和小团队使用。如需明确的
license 用于再分发或商业用途，需联系原作者。

本 fork 的贡献：

- **v2.3** — 原生 Apple Silicon (arm64) 移植：用 clang++ 重新编译，迁移到 ARC，修复
  `-Wall -Wextra` 警告。（[@Dellety](https://github.com/Dellety)）
