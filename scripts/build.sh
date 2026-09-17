#!/usr/bin/env bash
# MiMo Code TUI 飞牛打包脚本 — fnpack build + 交付
#
# 用法（在项目根目录运行）：
#   bash scripts/build.sh              # 用当前 app/bin 二进制直接打包
#   BUILD_AUTO=1 bash scripts/build.sh # 跳过确认（CI 用）
#   UPSTREAM_VERSION=0.1.14 bash scripts/build.sh --from-source  # 从源码全量构建
#
# 前置条件：
#   - app/bin/mimo  官方引擎二进制（--from-source 时自动构建）
#   - app/bin/ttyd  Web 终端网关（缺失时自动下载）
#   - fnpack >= 1.2.4
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FPK_DIR="/vol1/1000/fnOS App/fpk/mimocode"
OLDFPK_DIR="/vol1/1000/fnOS App/fpk/oldfpk"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || echo 0.1.14)}"
ARCH="${ARCH:-x86}"

# ARCH 决定：上游构建目标目录 + manifest 的 platform 字段
# 注意：fnOS 只接受 x86 / arm / loongarch / risc-v / all
case "$ARCH" in
    x86|x86_64) BIN_ARCH="linux-x64";   PLATFORM="x86" ;;
    arm|arm64)  BIN_ARCH="linux-arm64"; PLATFORM="arm" ;;
    *) echo "ERROR: 不支持的架构 $ARCH（可选 x86 / arm）" >&2; exit 1 ;;
esac

# --- 可选：从源码全量构建引擎 ---
if [ "${1:-}" = "--from-source" ]; then
    WORK="${WORK:-/tmp/mimocode-build}"
    echo "=== 从源码构建 MiMo Code v${UPSTREAM_VERSION} ==="
    rm -rf "$WORK"
    git clone --depth 1 --branch "v${UPSTREAM_VERSION}" \
        https://github.com/XiaomiMiMo/MiMo-Code.git "$WORK"
    (cd "$WORK" && git apply "$ROOT/docs/patches/fnos-adaptation.patch")
    (cd "$WORK" && bun install --ignore-scripts --backend=copyfile)
    (cd "$WORK/packages/opencode" && \
        MIMOCODE_CHANNEL=local MIMOCODE_VERSION=local \
        bun run script/build.ts --single --skip-install)
    mkdir -p "$ROOT/app/bin"
    cp "$WORK/packages/opencode/dist/mimocode-${BIN_ARCH}/bin/mimo" "$ROOT/app/bin/mimo"
    echo "✓ 引擎已构建"
fi

# --- 依赖准备 ---
mkdir -p "$ROOT/app/bin"

if [ ! -x "$ROOT/app/bin/mimo" ]; then
    echo "ERROR: app/bin/mimo 缺失。请先运行：bash scripts/build.sh --from-source" >&2
    exit 1
fi

if [ ! -x "$ROOT/app/bin/ttyd" ]; then
    echo "ℹ️  ttyd 缺失，自动下载..."
    case "$PLATFORM" in
        x86) TTYD_URL="https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64" ;;
        arm) TTYD_URL="https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.aarch64" ;;
    esac
    curl -fL -o "$ROOT/app/bin/ttyd" "$TTYD_URL"
    chmod +x "$ROOT/app/bin/ttyd"
    echo "✓ ttyd 已下载"
fi
chmod +x "$ROOT/app/bin/"* 2>/dev/null || true

# --- 同步版本号与 platform ---
bash "$ROOT/scripts/sync-version.sh"
if grep -qE '^platform[[:space:]]*=' "$ROOT/manifest"; then
    sed -i "s/^platform[[:space:]]*=.*/platform              = ${PLATFORM}/" "$ROOT/manifest"
else
    # 没有 platform 行则在 version 之后插入
    sed -i "/^version/a platform              = ${PLATFORM}" "$ROOT/manifest"
fi
echo "✓ platform = ${PLATFORM}"

# --- 打包确认 ---
echo "📦 即将打包：mimocode-tui v${UPSTREAM_VERSION} (${PLATFORM})"
if [ "${BUILD_AUTO:-0}" != "1" ]; then
    read -r -p "确认打包? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "已取消"; exit 1; }
fi

# --- fnpack build ---
cd "$ROOT"
rm -f mimocode-tui.fpk
fnpack build >/dev/null
[ -f mimocode-tui.fpk ] || { echo "ERROR: 打包失败" >&2; exit 1; }

OUT="mimocode-tui-${UPSTREAM_VERSION}-${PLATFORM}.fpk"
mv mimocode-tui.fpk "$OUT"
echo "✓ 构建完成：$OUT ($(du -h "$OUT" | cut -f1))"

# --- 生成校验和 ---
mkdir -p "$ROOT/dist"
mv "$OUT" "$ROOT/dist/$OUT"
(cd "$ROOT/dist" && sha256sum "$OUT" > SHA256SUMS)
echo "✓ 校验和：$(cat "$ROOT/dist/SHA256SUMS")"

# --- 交付（仅本地环境存在该路径时）---
if [ -d "$(dirname "$FPK_DIR")" ]; then
    mkdir -p "$FPK_DIR" "$OLDFPK_DIR"
    mv "$FPK_DIR"/mimocode-tui-*.fpk "$OLDFPK_DIR"/ 2>/dev/null || true
    cp "$ROOT/dist/$OUT" "$FPK_DIR/"
    echo "✓ 已交付：$FPK_DIR/$OUT"
    echo "✓ 旧包已归档：$OLDFPK_DIR/"
fi

echo "✅ 全部完成"
