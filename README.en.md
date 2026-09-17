# MiMo Code TUI for fnOS

Bring **Xiaomi MiMo Code**'s official TUI to your fnOS NAS — click the desktop icon and start using it.

| | |
| :--- | :--- |
| **Developer** | [XiaomiMiMo](https://github.com/XiaomiMiMo/MiMo-Code) (MiMo Code by Xiaomi) |
| **Publisher** | [techysy](https://github.com/techysy/mimocode-fnos) (fnOS packaging) |

> This project only **packages and adapts** MiMo Code for fnOS. The engine is Xiaomi's unmodified official binary.
> Upstream: <https://github.com/XiaomiMiMo/MiMo-Code>

[![Release](https://img.shields.io/github/v/release/techysy/mimocode-fnos.svg?label=Latest&color=blue)](https://github.com/techysy/mimocode-fnos/releases)
[![Downloads](https://img.shields.io/github/downloads/techysy/mimocode-fnos/total?label=Downloads&color=green)](https://github.com/techysy/mimocode-fnos/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![fnOS](https://img.shields.io/badge/fnOS-1.1.31xx-blue)](https://developer.fnnas.com/docs/guide)
[![Upstream](https://img.shields.io/github/v/release/XiaomiMiMo/MiMo-Code.svg?label=Upstream&color=purple)](https://github.com/XiaomiMiMo/MiMo-Code/releases)

- [中文文档](./README.md)

---

## 📥 Download

**➡️ [Get the latest release on GitHub](https://github.com/techysy/mimocode-fnos/releases/latest)**

Pick the package matching your NAS CPU architecture:

| Arch | File | Devices |
| :--- | :--- | :--- |
| **x86 / x86_64** | [`mimocode-tui-0.1.14-x86.fpk`](https://github.com/techysy/mimocode-fnos/releases/download/v0.1.14/mimocode-tui-0.1.14-x86.fpk) | Most fnOS NAS units (Intel / AMD) |
| **ARM / aarch64** | [`mimocode-tui-0.1.14-arm.fpk`](https://github.com/techysy/mimocode-fnos/releases/download/v0.1.14/mimocode-tui-0.1.14-arm.fpk) | ARM devices (e.g. R5S, Raspberry Pi class) |

**Not sure which one?** Run `uname -m` on your NAS:

- `x86_64` → choose **x86**
- `aarch64` / `arm64` → choose **arm**

Every package is CI-verified (ELF arch, `platform` field, integrity) and ships with `SHA256SUMS-{x86,arm}`.

---

## What is this

Xiaomi's [MiMo Code](https://github.com/XiaomiMiMo/MiMo-Code) focuses its development on the **TUI (terminal interface)** and engine core. The Web and Desktop surfaces are explicitly marked as unmaintained upstream.

This project packages the **official TUI** as an fnOS application:

- **Engine**: Xiaomi's official MiMo Code v0.1.14 (unmodified binary)
- **Interface**: the official TUI, wrapped as a web terminal via [ttyd](https://github.com/tsl0922/ttyd)
- **Entry point**: fnOS desktop icon or browser

**No interface was rewritten** — what you see is the official TUI itself.

## Features

| Feature | Description |
| :--- | :--- |
| ✅ Official TUI | Uses the official `mimo` binary, not a reimplementation |
| ✅ fnOS desktop integration | One-click icon, embedded iframe |
| ✅ Data isolation | Dedicated user `mimocode-tui`, data in `/vol4/@appdata/mimocode-tui/` |
| ✅ Coexists with Web UI version | Separate appname, port 19281, no conflicts |
| ✅ Clipboard fix | Fixes ttyd copy failure inside iframes |
| ✅ Branding | Xiaomi MiMo icon + fixed page title |
| ✅ License agreement wizard | Requires accepting 7 terms before install |

## Install

### Via App Center

1. Download the `.fpk` for your architecture (see [Download](#-download) above)
2. fnOS → **App Center** → **Manual Install** (top right) → select the `.fpk`

### Manual

1. Upload the `.fpk` to any directory on your NAS
2. fnOS → **App Center** → **Manual Install** → select the file
3. Accept the license agreement in the wizard → finish

Then click the **MiMo Code TUI** icon on the fnOS desktop.

> **Note**: the appname is `mimocode-tui`, which does not conflict with the Web UI version (`mimocode`). Both can be installed together.

## Usage

On first launch you need to configure model credentials:

```
/models
```

The default working directory is `/vol4/@appdata/mimocode-tui/workspace`. To point it at your own repo:

```bash
export MIMOCODE_WORKSPACE=/vol1/1000/your-project
```

## Ports & Paths

| Item | Value |
| :--- | :--- |
| Port | `19281` |
| Data dir | `/vol4/@appdata/mimocode-tui/` |
| Workspace | `/vol4/@appdata/mimocode-tui/workspace/` |
| Install dir | `/vol4/@appcenter/mimocode-tui/` |
| Log | `/vol4/@appdata/mimocode-tui/mimocode-tui.log` |

## Directory Structure

```
mimocode-fnos/
├── manifest              # fnOS app manifest (version follows upstream)
├── VERSION               # Version number
├── cmd/
│   └── main              # Lifecycle script (start/stop/status/restart)
├── config/
│   ├── privilege         # Dedicated user mimocode-tui
│   └── resource          # Data volume permission declaration
├── wizard/
│   └── install           # Install-time license agreement wizard
├── app/
│   ├── bin/              # mimo (official binary) + ttyd (fetched at build)
│   ├── ui/               # fnOS desktop icon & entry config
│   └── web/index.html    # Branded ttyd page (with clipboard fix)
├── docs/patches/         # Upstream adaptation patch
├── scripts/build.sh      # One-command build
└── ICON.PNG / ICON_256.PNG
```

## Build from Source

### One-command build

```bash
# Full build from upstream source (clone → patch → deps → engine → ttyd → package)
bash scripts/build.sh --from-source

# Re-package only (requires app/bin/mimo already present)
bash scripts/build.sh
```

Environment variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `UPSTREAM_VERSION` | Upstream MiMo Code version | reads `VERSION` |
| `ARCH` | Target arch (`x86_64` / `arm64`) | `x86_64` |
| `BUILD_AUTO=1` | Skip interactive confirmation (for CI) | off |
| `WORK` | Temp dir for source build | `/tmp/mimocode-build` |

The script syncs the version, prepares dependencies, runs `fnpack build`, writes the artifact plus `SHA256SUMS` to `dist/`, and (when the local path exists) delivers to `/vol1/1000/fnOS App/fpk/mimocode/`.

### Version sync

`VERSION` is the single source of truth:

```bash
bash scripts/sync-version.sh            # VERSION -> manifest
bash scripts/sync-version.sh 0.1.15     # set a version and sync
```

### Manual build

```bash
git clone --depth 1 --branch v0.1.14 https://github.com/XiaomiMiMo/MiMo-Code.git
cd MiMo-Code
git apply ../docs/patches/fnos-adaptation.patch
bun install --ignore-scripts --backend=copyfile
cd packages/opencode
MIMOCODE_CHANNEL=local MIMOCODE_VERSION=local bun run script/build.ts --single --skip-install

cp dist/mimocode-linux-x64/bin/mimo <repo>/app/bin/mimo
curl -L -o <repo>/app/bin/ttyd \
  https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
chmod +x <repo>/app/bin/*
cd <repo> && fnpack build
```

Requirements: `fnpack` ≥ 1.2.4, `bun` ≥ 1.3.0, `git`.

## Automatic Build (GitHub Actions)

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds **both x86 and ARM**:

| Trigger | Behavior |
| :--- | :--- |
| **Tag push** (e.g. `v0.1.14`) | Build x86 + arm → verify → upload artifact → **publish Release** |
| **Manual** (Actions → Run workflow) | Choose arch (all / x86 / arm) and upstream version |

Pipeline:

1. **Matrix build**: `x86` on `ubuntu-24.04`, `arm` on native `ubuntu-24.04-arm` (no cross-compilation)
2. **Install fnpack**: downloaded from the official mirror with SHA256 verification
3. **Build engine**: clone upstream → apply patch → `bun install` → build target-arch binary → fetch matching ttyd
4. **Set platform**: writes `manifest`'s `platform` (x86 / arm)
5. **Package**: remove symlinks, then `fnpack build`
6. **Verify artifact** (fails the build on any error): package layout, binaries, all 10 `cmd/` lifecycle scripts (`bash -n`), no hardcoded volume paths, valid `platform`, ELF arch match, version consistency
7. **Release**: never overwrites an existing Release body (manual notes are preserved)

### Release a new version

```bash
bash scripts/sync-version.sh 0.1.15
git commit -am "release: v0.1.15"
git tag v0.1.15
git push origin master --tags    # CI builds both arches and publishes
```

### Artifact naming

```
mimocode-tui-0.1.15-x86.fpk
mimocode-tui-0.1.15-arm.fpk
SHA256SUMS-x86 / SHA256SUMS-arm
```

## Upstream Changes

Only minimal adaptations to upstream source (**engine logic untouched**):

| File | Change | Reason |
| :--- | :--- | :--- |
| `packages/opencode/script/build.ts` | Re-enable embedded Web UI | Disabled upstream |
| `packages/script/src/index.ts` | Relax bun version to `>=1.3.0` | Build compatibility |
| `packages/opencode/src/server/routes/ui.ts` | Relax CSP `frame-ancestors` | iframe embedding |
| `packages/opencode/src/server/middleware.ts` | Whitelist static assets | Page loads correctly |
| `packages/app/index.html` | Title `OpenCode` → `MiMo Code` | Upstream leftover string |

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Security Notice

This app provides **full shell execution** on port 19281, bound to `0.0.0.0` by default. **Never expose it to the public internet.** For remote access use fnOS FN Connect or a reverse proxy with authentication.

## License Agreement

The installer requires accepting 7 terms (non-official, copyright, warranty, risk, permissions, network, license). Defined in [`wizard/install`](wizard/install).

## Disclaimer

- This is an **unofficial third-party port**, not affiliated with Xiaomi Corporation
- MiMo Code is copyright **Xiaomi Corporation**, licensed under MIT
- The engine binary is official and unmodified

## License

[MIT](LICENSE) — original Xiaomi copyright notices preserved.

```
Copyright (c) 2026 MiMo Code, Xiaomi Corporation
Copyright (c) 2025 opencode
```
