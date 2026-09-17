# CHANGELOG / 更新日志

本项目版本号**跟随上游 MiMo Code 官方版本**。

---

## v0.1.14 (2026-09-17)

首个飞牛（fnOS）发布版，对应官方 MiMo Code **v0.1.14**。

### ✨ 功能

- 🖥️ **官方原版 TUI**：直接使用官方 `mimo` 二进制的 TUI（终止子界面），**未重制界面**
- 🌐 **网页终端接入**：通过 ttyd 1.7.7 把 TUI 包装为网页终端，飞牛桌面 iframe 内直接使用
- 🖱️ **飞牛桌面集成**：桌面图标一键打开，`appname=mimocode-tui`
- 🔒 **数据隔离**：独立系统用户 `mimocode-tui`，数据存于 `/vol4/@appdata/mimocode-tui/`
- 🤝 **可与 Web UI 版共存**：与 Web UI 版（`appname=mimocode`）互不冲突，端口分别 19281 / 19280
- 📜 **安装协议授权向导**：首次安装需勾选同意 7 项条款（非官方/版权/担保/风险/权限/网络/许可）
- 🎨 **品牌化**：小米 MiMo 图标（64/128/256 三档）+ 固定页面标题 `MiMo Code`

### 🐛 修复

- 📋 **修复 iframe 内复制失效**：ttyd 原仅用 `document.execCommand('copy')`，在飞牛桌面 iframe 中静默失败。现改为三级降级链：
  1. `navigator.clipboard.writeText()`
  2. 隐藏 textarea + `execCommand('copy')`
  3. 原生 `execCommand('copy')`
  同时增强 `Ctrl/Cmd+C`（有选区时不被 xterm 吞掉）。
- 🏷️ **修复页面标题被工作目录覆盖**：TUI 会持续上报窗口标题（`MiMoCode | /vol4/...`），ttyd 将其拼接进 `document.title`，导致标签页显示长路径。现固定为 `MiMo Code`，并加 `-t titleFixed=true` 双保险。
- 📁 **修复工作目录问题**：原启动脚本未设置 cwd，飞牛以 `/` 启动时引擎报 `Access denied: filesystem root is not a valid project directory`。现显式 `cd` 到工作区（默认 `数据目录/workspace`，可用 `MIMOCODE_WORKSPACE` 覆盖）。

### 🔧 对上游的最小适配

仅对官方源码做必要适配，**引擎逻辑未改动**：

| 文件 | 改动 | 原因 |
| :--- | :--- | :--- |
| `packages/opencode/script/build.ts` | 恢复内嵌 Web UI | 上游默认关闭 |
| `packages/script/src/index.ts` | 放宽 bun 版本约束至 `>=1.3.0` | 兼容构建环境 |
| `packages/opencode/src/server/routes/ui.ts` | 放宽 CSP `frame-ancestors` | 支持 iframe 嵌入 |
| `packages/opencode/src/server/middleware.ts` | 静态资源免鉴权 | 页面正常加载 |
| `packages/app/index.html` | 标题 `OpenCode` → `MiMo Code` | 上游遗留字符串 |

完整补丁见 [`docs/patches/fnos-adaptation.patch`](docs/patches/fnos-adaptation.patch)。

---

## 版本对应关系

| 本项目 | 上游 MiMo Code | 说明 |
| :--- | :--- | :--- |
| v0.1.14 | v0.1.14 | 首个飞牛版本 |
