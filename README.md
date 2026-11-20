# NextUI Nintendo 64 Pak (`N64.pak`)

A Nintendo 64 emulator pak for [NextUI](https://github.com/LoveRetro/NextUI) powered by [ParaLLEl N64](https://github.com/libretro/parallel-n64) (`aarch64` Ari64 dynarec + OpenGL ES 3.0) and Minarch hardware-accelerated rendering (`SET_HW_RENDER`).

Supports `tg5040` (TrimUI Smart Pro, TrimUI Brick, TrimUI Brick Pro), `tg5050` (TrimUI Smart Pro S), and `h700` (Anbernic RG35XX series) devices running NextUI.

---

## Features

- **AArch64 Dynamic Recompiler**: Uses the unified Ari64 `aarch64` dynarec (`NEW_DYNAREC=4`) tuned for Cortex-A53 handhelds.
- **OpenGL ES 3.0 Hardware Rendering**: Direct GLES3 rendering via Minarch's `SET_HW_RENDER` pipeline.
- **Handheld-Focused Video Plugins**: Ships slimmed down to **Glide64** (default, high compatibility) and **Rice** (fastest on Cortex-A53 handhelds) — no heavy desktop/software plugins compiled in.
- **D-Pad to Analog Stick Mapping**: Built-in curved quadratic ease-in D-Pad-to-Control-Stick mapping enabled by default on stickless handhelds (`default.cfg`, `default-brick.cfg`, `default-brickpro.cfg`).
- **RetroAchievements Ready**: Exposes N64 RDRAM (`RETRO_MEMORY_SYSTEM_RAM`) for RetroAchievements support.

---

## Requirements

- **NextUI `v6.15.0+`** — this pre-release bundles a patched `minarch.elf` (`SET_HW_RENDER`, the `SND_batchSamples` audio batch frame-count fix, and Nintendo 64 RetroAchievements console mapping) under `bin/$PLATFORM/minarch.elf`, so no NextUI system files need to be replaced.
- Compatible handheld:
  - **tg5040**: TrimUI Smart Pro, TrimUI Brick, TrimUI Brick Pro (Allwinner A133p / PowerVR GE8300)
  - **tg5050**: TrimUI Smart Pro S (Allwinner A523 / Mali-G57 MC1)
  - **h700**: Anbernic RG35XX Plus, RG35XX H, RG35XX SP, RG40XX (Allwinner H700 / Mali-G31 MP2)

---

## Installation

### Manual Installation
1. Download `N64.pak.zip` from releases or build it from source.
2. Extract the archive into your SD card under your platform's emulator directory:
   - For TrimUI Smart Pro / Brick / Brick Pro: `/mnt/SDCARD/Emus/tg5040/N64.pak/`
   - For TrimUI Smart Pro S: `/mnt/SDCARD/Emus/tg5050/N64.pak/`
   - For Anbernic RG35XX series: `/mnt/SDCARD/Emus/h700/N64.pak/`
3. Alternatively, extract the unified multi-platform layout directly to `/mnt/SDCARD/Emus/$PLATFORM/N64.pak/`.

---

## ROM Paths and Formats

Place Nintendo 64 ROM images in:
```
/mnt/SDCARD/Roms/Nintendo 64 (N64)/
```

Supported formats:
- **`.z64`**, **`.n64`**, **`.v64`** (uncompressed ROMs)
- **`.ndd`** (64DD disk images)
- **`.zip`**, **`.7z`** (compressed archives)

---

## Default Controls & Options

### Default Controls (N64 Port 1)
| NextUI Handheld | N64 Button |
| :--- | :--- |
| **D-Pad** | D-Pad (and Control Stick when `Map D-Pad to Analog Stick` is enabled) |
| **Left Analog Stick** | Control Stick (on stick-equipped devices) |
| **Right Analog Stick** | C-Buttons (on dual-stick devices) |
| **B** (South) | A Button (or **C-Down** while holding **R2**) |
| **Y** (West) | B Button (or **C-Left** while holding **R2**) |
| **A** (East) | **C-Right** (direct, or while holding **R2**) |
| **X** (North) | **C-Up** (direct, or while holding **R2**) |
| **L1** | L Trigger |
| **R1** | R Trigger |
| **L2** | Z Trigger |
| **R2** | C-Buttons Mode (hold + **B** for **C-Down**, **Y** for **C-Left**; direct `C-Down`/`C-Left` slots are also available to bind in Controls) |
| **Start** | Start |
| **Select** | **Toggle D-Pad/Stick** (enabled on stickless devices; unbound by default on dual-stick devices) |
| **Menu** | MinArch Quick Menu |

> **Tip (Single-stick / stickless handhelds)**: You can enable **Independent C-button Controls** (`parallel-n64-alt-map = enabled`) in **Options -> Emulator -> Input** (restart required) to map the four C-buttons directly to `X` (C-Up), `A` (C-Down), `L1` (C-Left), and `R1` (C-Right), with `SELECT` as L Trigger and `R2` as R Trigger.

### Switching Video Plugins (Glide64 vs Rice)
**Glide64** (`parallel-n64-gfxplugin = glide64`, tuned with `parallel-n64-gfxplugin-accuracy = medium` and `bilinear` filtering) is enabled by default for high compatibility and visual accuracy.

If a game needs extra CPU/GPU headroom on lower-clocked devices, open the MinArch menu (**Options -> Emulator -> System -> RDP Plugin**) and switch `parallel-n64-gfxplugin` to **`rice`** (`Rice`). Save as a per-game override if you only want Rice for specific titles.

### Key Default Options
- `minarch_cpu_speed = Performance`, `minarch_sync_reference = Auto`, `minarch_rewind_enable = Off`: Keeps CPU clocks maxed, adapts frame sync cleanly, and avoids rewind state overhead.
- `parallel-n64-cpucore = dynamic_recompiler`: Uses the Ari64 `aarch64` dynarec.
- `parallel-n64-rspplugin = hle`: Fast HLE RSP audio/graphics processing.
- `parallel-n64-disable_expmem = enabled`: Enables 8 MB Expansion Pak RAM.
- `parallel-n64-pak1 = memory`: Attaches a Controller Pak (MemPak) to Port 1.
- `parallel-n64-screensize = 320x240`: Native N64 render resolution for handheld GPU performance (raise to `640x480` per game if headroom permits).
- `parallel-n64-glide64-overscan`: Crops black overscan borders in native 240p lines (`0`–`16` px) with zero extra render pass overhead when using Glide64, supporting both **All Sides (4:3)** and **Top & Bottom Only** (`parallel-n64-glide64-overscan-mode`) aspect modes.
- `parallel-n64-dpad-to-analog`: Maps D-Pad inputs to the N64 Control Stick (`disabled`, `analog` for Control Stick only, or `both` for Control Stick + D-Pad), with a quadratic ease-in ramp (`parallel-n64-dpad-to-analog-ramp`, defaults to `medium` 220 ms) and max deflection (`parallel-n64-dpad-to-analog-sensitivity`, defaults to `100%`). Enabled (`analog`) by default on `default.cfg`, `default-brick.cfg`, and `default-brickpro.cfg`, and `disabled` on `default-smartpro.cfg` and `default-smartpros.cfg`.

---

## Building from Source

### Prerequisites
- `make`
- `podman` or `docker`
- `jq`, `zip`

The build system uses official LoveRetro cross-compiler toolchains:
- `ghcr.io/loveretro/tg5040-toolchain:latest` (GCC 8.3.0 + GLIBC)
- `ghcr.io/loveretro/tg5050-toolchain:latest` (GCC + GLIBC)
- `ghcr.io/loveretro/h700-toolchain:latest` (GCC 8.3.0 + GLIBC)

### Build Targets
```bash
# Build tg5040, tg5050, and h700 cores and create dist/N64.pak.zip
make release

# Build a single platform core
make build-tg5040
make build-tg5050
make build-h700

# Package release zip and standalone platform folders
make package

# Clean build artifacts
make clean
```

---

## License

This project packages [ParaLLEl N64](https://github.com/libretro/parallel-n64), which is licensed under the GNU General Public License v2 (GPL-2.0). See [LICENSE](LICENSE) for full details.
