#!/bin/bash
# 一键构建 MiMo Code TUI 飞牛安装包
set -euo pipefail

UPSTREAM_VERSION="${UPSTREAM_VERSION:-0.1.14}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK:-/tmp/mimocode-build}"

echo "=== 1. 获取官方源码 v${UPSTREAM_VERSION} ==="
rm -rf "${WORK}"
git clone --depth 1 --branch "v${UPSTREAM_VERSION}" \
  https://github.com/XiaomiMiMo/MiMo-Code.git "${WORK}"

echo "=== 2. 应用飞牛适配补丁 ==="
cd "${WORK}"
git apply "${REPO_ROOT}/src/patches/fnos-adaptation.patch"

echo "=== 3. 安装依赖 ==="
bun install --ignore-scripts --backend=copyfile

echo "=== 4. 构建引擎 ==="
cd "${WORK}/packages/opencode"
MIMOCODE_CHANNEL=local MIMOCODE_VERSION=local bun run script/build.ts --single --skip-install

echo "=== 5. 组装 fpk ==="
mkdir -p "${REPO_ROOT}/src/fpk_tui/app/bin"
cp "${WORK}/packages/opencode/dist/mimocode-linux-x64/bin/mimo" \
   "${REPO_ROOT}/src/fpk_tui/app/bin/mimo"

if [ ! -f "${REPO_ROOT}/src/fpk_tui/app/bin/ttyd" ]; then
  echo "下载 ttyd..."
  curl -L -o "${REPO_ROOT}/src/fpk_tui/app/bin/ttyd" \
    https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
fi
chmod +x "${REPO_ROOT}/src/fpk_tui/app/bin/"*

echo "=== 6. 打包 ==="
cd "${REPO_ROOT}/src/fpk_tui"
fnpack build
mkdir -p "${REPO_ROOT}/dist"
mv mimocode-tui.fpk "${REPO_ROOT}/dist/mimocode-tui-${UPSTREAM_VERSION}-x86_64.fpk"

echo "=== 完成 ==="
ls -lh "${REPO_ROOT}/dist/"
