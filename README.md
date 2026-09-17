# MiMo Code TUI for fnOS

把 **小米 MiMo Code** 的官方 TUI 带到飞牛 NAS（fnOS）上，直接在飞牛桌面点开就能用。

> 📦 当前版本：**v0.1.14** — 内置官方 MiMo Code v0.1.14 引擎

---

## 这是什么

小米 [MiMo Code](https://github.com/XiaomiMiMo/MiMo-Code) 官方仓库的开发重心在 **TUI（终端界面）** 和引擎核心，Web/Desktop 界面已声明不再维护。

本项目把**官方原版 TUI** 打包成飞牛应用：

- **引擎**：小米官方 MiMo Code v0.1.14（未改动的官方二进制）
- **界面**：官方 TUI，通过 [ttyd](https://github.com/tsl0922/ttyd) 包装成网页终端
- **入口**：飞牛桌面图标 / 浏览器访问

**没有重写任何界面**——你看到的就是官方 TUI 本体。

## 特性

| 特性 | 说明 |
| :--- | :--- |
| ✅ 官方原版 TUI | 使用官方 `mimo` 二进制，非重制界面 |
| ✅ 飞牛桌面集成 | 桌面图标一键打开，iframe 内嵌 |
| ✅ 数据隔离 | 独立用户 `mimocode-tui`，数据存于 `/vol4/@appdata/mimocode-tui/` |
| ✅ 可与 Web UI 版共存 | appname 独立，端口 19281，不与其他版本冲突 |
| ✅ 剪贴板修复 | 修复 ttyd 在 iframe 中复制失效的问题 |
| ✅ 品牌化 | 小米 MiMo 图标 + 固定页面标题 |

## 安装

### 方式一：应用中心安装

1. 下载 [`mimocode-tui-0.1.14-x86_64.fpk`](../../releases/latest)
2. 飞牛 → **应用中心** → 右上角 **手动安装** → 选择 `.fpk` 文件

### 方式二：命令行

```bash
# 上传 fpk 到飞牛后
fnpack install -f mimocode-tui-0.1.14-x86_64.fpk
```

安装后从飞牛桌面点击 **MiMo Code TUI** 图标即可。

## 使用

首次进入 TUI 后需要配置模型凭据：

```
# 在 TUI 中按提示配置，或使用
/models
```

工作目录默认为 `/vol4/@appdata/mimocode-tui/workspace`。要指向自己的代码仓库：

```bash
# 编辑启动脚本或设置环境变量
export MIMOCODE_WORKSPACE=/vol1/1000/你的项目
```

## 目录结构

```
fpk_tui/
├── manifest              # 飞牛应用清单（版本号跟随官方）
├── cmd/
│   └── main              # 生命周期脚本（start/stop/status/restart）
├── config/
│   ├── privilege         # 独立运行用户 mimocode-tui
│   └── resource          # 数据卷权限声明
├── app/
│   ├── bin/
│   │   ├── mimo          # 官方引擎二进制（构建时注入）
│   │   └── ttyd          # Web 终端网关
│   ├── ui/               # 飞牛桌面图标与入口配置
│   └── web/
│       └── index.html    # 品牌化 ttyd 页面（含剪贴板修复）
└── ICON.PNG / ICON_256.PNG
```

## 自行构建

```bash
# 1. 获取官方源码（v0.1.14）
git clone --depth 1 --branch v0.1.14 https://github.com/XiaomiMiMo/MiMo-Code.git
cd MiMo-Code

# 2. 应用适配补丁
git apply ../src/patches/fnos-adaptation.patch

# 3. 安装依赖
bun install --ignore-scripts --backend=copyfile

# 4. 构建引擎
cd packages/opencode
MIMOCODE_CHANNEL=local MIMOCODE_VERSION=local bun run script/build.ts --single --skip-install

# 5. 组装 fpk
cp dist/mimocode-linux-x64/bin/mimo <repo>/src/fpk_tui/app/bin/mimo
# 下载 ttyd 静态二进制
curl -L -o <repo>/src/fpk_tui/app/bin/ttyd \
  https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
chmod +x <repo>/src/fpk_tui/app/bin/*

# 6. 打包
cd <repo>/src/fpk_tui && fnpack build
```

> 需要 `fnpack` ≥ 1.2.4 与 `bun` ≥ 1.3.0

## 对上游的改动

本项目仅对官方源码做**最小适配**（见 [`src/patches/`](src/patches/)）：

| 文件 | 改动 | 原因 |
| :--- | :--- | :--- |
| `script/build.ts` | 恢复内嵌 Web UI | 上游默认关闭 |
| `script/packages/index.ts` | 放宽 bun 版本约束 | 兼容构建环境 |
| `server/routes/ui.ts` | 放宽 CSP `frame-ancestors` | 支持 iframe 嵌入 |
| `server/middleware.ts` | 静态资源免鉴权 | 页面能正常加载 |
| `app/index.html` | 标题 `OpenCode` → `MiMo Code` | 上游遗留字符串 |

**引擎逻辑本身未做任何修改。**

## 已知问题

- **剪贴板**：已修复 iframe 内复制（多级兜底）；HTTPS 环境下体验最佳
- **HTTP 环境**：浏览器可能限制剪贴板 API，已提供 `execCommand` 兜底
- **仅支持 x86_64**：暂未构建 arm64 版本

## 安装协议授权

安装时会显示**使用协议与授权声明**，需勾选同意才能继续。条款如下：

| 条款 | 内容 |
| :--- | :--- |
| **非官方声明** | 本应用是非官方第三方适配，与小米公司无隶属、赞助或背书关系 |
| **版权归属** | MiMo Code 引擎版权归 Xiaomi Corporation，遵循 MIT 协议 |
| **无担保声明** | 按「现状」提供，不附带任何明示或暗示的担保 |
| **风险自担** | 数据丢失、服务中断、模型费用、密钥泄露等风险自负 |
| **权限说明** | 需访问 NAS 文件系统并以独立用户执行命令 |
| **网络安全** | 默认监听 19281，建议仅在内网使用，勿暴露公网 |
| **开源许可** | MIT 协议发布，保留小米原始版权声明 |

该协议由 [`wizard/install`](src/fpk_tui/wizard/install) 定义，使用 fnOS 安装向导的 `checkbox` 必选类型实现（`required: true`，不勾选则无法安装）。

## 免责声明

- 本项目是**非官方的第三方适配**，与小米公司无关
- MiMo Code 版权归 **Xiaomi Corporation** 所有，遵循 MIT 协议
- 引擎二进制为官方原版，未做修改

## License

[MIT](LICENSE) — 保留小米原始版权声明

Copyright (c) 2026 MiMo Code, Xiaomi Corporation
Copyright (c) 2025 opencode
