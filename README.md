# Zephyr App Template

A minimal Zephyr application template. It uses the west T2 (star) topology — this repo is the
manifest repository, so each project has its own workspace and pins its own Zephyr version —
with a dev container for the toolchain and [just](https://just.systems) for
build / flash / monitor.

## Layout

```
.
├── .devcontainer/
│   ├── devcontainer.json      # Workspace volume, serial port passthrough
│   ├── Dockerfile             # zephyr-build image + just
│   └── setup-west.sh          # west init -l / update / blobs fetch (runs on container create)
├── app/                       # Zephyr application
│   ├── boards/                # Board-specific files, applied automatically by Zephyr
│   │   └── esp32_devkitc_procpu.overlay
│   ├── include/               # Application headers
│   ├── src/main.c
│   ├── CMakeLists.txt         # Add new sources to target_sources()
│   ├── Kconfig                # Application options (CONFIG_APP_*)
│   ├── prj.conf               # Common Kconfig settings
│   └── VERSION                # Application version -> <zephyr/app_version.h>
├── west.yml                   # West manifest: Zephyr revision + modules (name-allowlist)
├── zephyr.just                # Shared, board-agnostic recipes
└── justfile                   # Per-project settings: board, port, baud, flash/monitor
```

> **Note:** if `app/boards/<board>.overlay` exists, Zephyr does **not** use `app.overlay`.

## Requirements

- Podman (rootless). The container uses `--group-add=keep-groups` for serial port access,
  which Docker does not support; for Docker, replace it in `.devcontainer/devcontainer.json`
  with `--group-add=dialout` (or your distro's serial group).
- VS Code with the Dev Containers extension (or the `devcontainer` CLI),
  configured to use Podman (`"dev.containers.dockerPath": "podman"`)

The Zephyr SDK, west and just are all provided by the container.

## Getting started

1. Set the serial port of your board on the **host**, preferably a stable
   `/dev/serial/by-id/...` path. If unset, `/dev/ttyUSB0` is used.

   ```sh
   # fish
   set -Ux ZEPHYR_PORT /dev/serial/by-id/<your-device>
   # bash / zsh
   export ZEPHYR_PORT=/dev/serial/by-id/<your-device>
   ```

   VS Code reads this when it starts, so restart VS Code after setting it.

   > Boards with a USB-UART bridge (CP210x / CH340, e.g. ESP32-DevKitC) appear as
   > `/dev/ttyUSB*`. Chips with native USB-Serial-JTAG (ESP32-C3 / S3 / C6, ...) appear as
   > `/dev/ttyACM*`, so the `/dev/ttyUSB0` default won't find them.

2. Plug in the board, then open the repo in VS Code and choose **Reopen in Container**.

   > The device must be connected when the container starts, otherwise the container fails to
   > start. If you plug it in later, rebuild / restart the container.

3. On first creation, `setup-west.sh` runs `west init -l`, `west update` and
   `west blobs fetch`. This takes a while.

## West workspace

Each project has its own workspace. Inside the container, `/workdir` is that workspace, stored
in a per-project named volume (`<repo folder name>-west`) so it survives container rebuilds.
The repo is bind-mounted into it and is the manifest repository:

```
/workdir/                  # named volume: <repo>-west
├── .west/                 # manifest = <repo>/west.yml
├── zephyr/
├── modules/hal/espressif/
└── <repo>/                # this repo (bind mount)
```

- **Zephyr version and modules** are pinned in `west.yml`, tracked in git with the project.
- **Toolchain** comes from the pinned `zephyr-build` image in `.devcontainer/Dockerfile`.
  Its Zephyr SDK must match `zephyr/SDK_VERSION` of the pinned Zephyr revision.
- **Upgrading Zephyr:** change `revision` in `west.yml`, then run `west update && west blobs fetch`
  and `just rebuild`. If the new revision's `SDK_VERSION` changed, also bump the `zephyr-build`
  tag in `.devcontainer/Dockerfile` and rebuild the container. Other projects are not affected.

## Usage

Run these inside the container:

```sh
just build        # Build (output in ./build)
just rebuild      # Pristine rebuild
just config       # menuconfig
just flash        # Flash
just monitor      # Serial monitor
just upload       # build + flash
just run          # build + flash + monitor
just clean        # Remove ./build
```

Extra arguments are passed through to `west build`, e.g.
`just build -- -DEXTRA_CONF_FILE=debug.conf`.

## Versioning

`app/VERSION` is read by Zephyr at configure time and generates `<zephyr/app_version.h>`:

| Macro | Example | Use |
|---|---|---|
| `APP_VERSION_STRING` | `"0.1.0"` | Display / logs |
| `APP_VERSION_EXTENDED_STRING` | `"0.1.0-rc1"` | Includes `EXTRAVERSION` |
| `APP_VERSION_TWEAK_STRING` | `"0.1.0+0"` | Includes tweak |
| `APP_VERSION_NUMBER` | `0x000100` | Numeric comparison |
| `APP_BUILD_VERSION` | `git describe` output | Trace a build to a commit |

With MCUboot, `CONFIG_MCUBOOT_IMGTOOL_SIGN_VERSION` defaults to this version, which is written
into the signed image header and used for upgrade / downgrade decisions.

## Starting a new project from this template

1. Copy the repo. The folder name is used for the container workspace path and volume name,
   so it must be unique across your projects.
2. Edit `justfile`: `board`, `baud`, `flash_args`, `monitor`.
3. Set `ZEPHYR_PORT` on the host for your board's serial port
   (`/dev/ttyUSB*` for USB-UART bridges, `/dev/ttyACM*` for native USB-Serial-JTAG chips).
4. Put board-specific `.overlay` / `.conf` files in `app/boards/`.
   The file name is the board target with `/` replaced by `_`; the SoC part can be dropped when it
   repeats the board name, e.g. `esp32_devkitc/esp32/procpu` → `esp32_devkitc_procpu`.
5. When switching SoC families, add the matching modules to `name-allowlist` in `west.yml`
   (e.g. `hal_nordic`, `hal_stm32`, plus any others such as `cmsis_6`), then run `west update`.
   `setup-west.sh` fetches blobs for whatever modules are listed.
6. Update `app/VERSION`.
