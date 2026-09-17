# 问题排查 / Troubleshooting

## 安装相关

### 安装时提示「必须同意以上全部条款才能继续安装」

这是预期行为。本应用使用飞牛安装向导的 `checkbox` 必选类型（`required: true`），需勾选协议才能继续。协议内容见 [`wizard/install`](wizard/install)。

### 安装后桌面图标点不开 / 页面空白

1. 检查服务是否在运行：
   ```bash
   ps -ef | grep ttyd | grep 19281
   ```
2. 检查端口是否被占用：
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:19281/
   # 期望 200
   ```
3. 查看日志：
   ```bash
   tail -n 50 /vol4/@appdata/mimocode-tui/mimocode-tui.log
   ```

### 端口 19281 被占用（实例起不来）

常见原因：之前装过旧版残留进程。清理方法：

```bash
# 查看占用
ps -ef | grep ttyd | grep 19281

# 若为旧实例，尝试停止
pkill -f "ttyd -p 19281"
```

> ⚠️ 若进程属主不是当前用户（如属 `mimocode` 用户），需要 root 权限。建议在**应用中心先卸载旧版本**再重装。

### 与 Web UI 版冲突吗

不会。两者 `appname` 不同：

| 应用 | appname | 端口 | 数据目录 |
| :--- | :--- | :--- | :--- |
| MiMo Code（Web UI） | `mimocode` | 19280 | `/vol4/@appdata/mimocode/` |
| **MiMo Code TUI** | **`mimocode-tui`** | **19281** | `/vol4/@appdata/mimocode-tui/` |

可同时安装、同时运行。

---

## 使用相关

### 复制不出来（选中文字后无法复制）

已修复。原理：ttyd 原仅用 `document.execCommand('copy')`，在飞牛桌面 iframe 中会**静默失败**。现改为三级降级：

1. `navigator.clipboard.writeText()`
2. 隐藏 textarea + `execCommand('copy')`
3. 原生 `execCommand('copy')`

若仍失败，可能原因：

- **浏览器限制**：部分浏览器在 HTTP（非 HTTPS）下禁用 `navigator.clipboard`。此时会自动走兜底 ②③。
- **iframe 沙箱**：若父页面设置了严格的 `sandbox` 属性，剪贴板可能仍被阻止。建议直接浏览器访问 `http://<NAS_IP>:19281`。

**临时方案**：全选后右键复制，或用键盘 `Ctrl+Shift+C`（部分终端支持）。

### Ctrl+C 变成中断信号而不是复制

这是终端的正常行为。判定逻辑：

- **有选区** → 复制（已增强）
- **无选区** → 发送 SIGINT（中断当前命令）

### 页面标题显示长路径

已修复。原 ttyd 会把终端上报的窗口标题拼接进 `document.title`，如：

```
MiMoCode | /vol4/@appcenter/mimocode-tui/workspace | MiMo Code
```

现固定为 `MiMo Code`，并加 `-t titleFixed=true`。

### 提示 Invalid API Key

TUI 需要配置模型凭据。首次进入后按提示配置，或：

```
/models
```

也可通过环境变量预设（在 `cmd/main` 中 export）。

### 想让 TUI 指向自己的代码目录

默认工作目录为 `<数据目录>/workspace`。改为自己的项目：

```bash
export MIMOCODE_WORKSPACE=/vol1/1000/你的项目
```

或在 `cmd/main` 的 `start()` 中修改 `WORKSPACE` 默认值后重启应用。

### 中文/特殊字符显示异常

ttyd 已设置 `TERM=xterm-256color`。若仍有问题，检查浏览器字体设置，或在 `cmd/main` 中增加：

```
-t "fontFamily=你的等宽字体"
```

---

## 安全相关

### 19281 端口谁能访问

默认绑定 `0.0.0.0`，**局域网内任何人**都可访问并执行命令。加固建议：

**加访问口令**（修改 `cmd/main`）：
```bash
nohup "${TTYD_BIN}" \
    -p "${PORT}" \
    -i "0.0.0.0" \
    -c "用户名:密码" \     # ← 新增
    -W \
    ...
```

**限制为仅本机**：把 `-i "0.0.0.0"` 改为 `-i "127.0.0.1"`。

**只读模式**：去掉 `-W` 参数（只读，不可输入）。

### 不要暴露到公网

本应用提供**完整的 shell 执行能力**。请勿直接端口映射到公网。远程访问建议走：

- 飞牛 FN Connect（带鉴权）
- 反向代理 + HTTPS + 认证

---

## 构建相关

### 自行构建时提示缺少 mio / ttyd 二进制

`.gitignore` 排除了 `app/bin/`（二进制不入库）。构建前需自行准备：

```bash
# ttyd
curl -L -o app/bin/ttyd \
  https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
chmod +x app/bin/ttyd

# mimo（从官方源码构建，见 scripts/build.sh）
```

或直接运行 `./scripts/build.sh` 全自动完成。

### fnpack build 报 JSON 校验失败

检查 `wizard/install` 的 JSON 格式。**已知坑**：`checkbox` 的 `options` 必须是**对象数组**：

```json
// ❌ 错误
"options": ["同意", "不同意"]

// ✅ 正确
"options": [{"label": "同意", "value": "agree"}]
```

### fnpack 有没有 install 子命令

没有。`fnpack` 仅有两个子命令：

```
build     Build fpk file
create    Create an app project
```

安装请走**飞牛应用中心 → 手动安装**。

---

## 日志位置

| 内容 | 路径 |
| :--- | :--- |
| 服务日志 | `/vol4/@appdata/mimocode-tui/mimocode-tui.log` |
| PID 文件 | `/vol4/@appdata/mimocode-tui/mimocode-tui.pid` |
| 数据目录 | `/vol4/@appdata/mimocode-tui/` |
| 工作目录 | `/vol4/@appdata/mimocode-tui/workspace/` |
| 应用安装目录 | `/vol4/@appcenter/mimocode-tui/` |
