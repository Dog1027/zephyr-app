# Zephyr App Template

A minimal Zephyr application template. Projects created from it share one west workspace
(Zephyr + modules) inside a dev container, and use [just](https://just.systems) for
build / flash / monitor.

## Layout

```
.
├── .devcontainer/
│   ├── devcontainer.json      # Shared workspace volume, serial port, WORKSPACE_MODULES
│   ├── Dockerfile             # zephyr-build image + just
│   └── setup-west.sh          # Create / join the shared workspace (runs on container create)
├── app/                       # Zephyr application
│   ├── boards/                # Board-specific files, applied automatically by Zephyr
│   │   └── esp32_devkitc_procpu.overlay
│   ├── include/               # Application headers
│   ├── src/main.c
│   ├── CMakeLists.txt         # Add new sources to target_sources()
│   ├── Kconfig                # Application options (CONFIG_APP_*)
│   ├── prj.conf               # Common Kconfig settings
│   └── VERSION                # Application version -> <zephyr/app_version.h>
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

2. Plug in the board, then open the repo in VS Code and choose **Reopen in Container**.

   > The device must be connected when the container starts, otherwise the container fails to
   > start. If you plug it in later, rebuild / restart the container.

3. On container creation, `setup-west.sh` creates the shared workspace if it doesn't exist yet
   (the first time this takes a while), adds this project's modules, then runs `west update`
   and `west blobs fetch`.

## Shared west workspace

All projects use the same named volume, `zephyr-workspace`, mounted at `/workdir`. Each
project is bind-mounted into it, so `west` finds the workspace from the project directory:

```
/workdir/                  # named volume: zephyr-workspace
├── .west/                 # manifest = zephyr/west.yml
├── zephyr/
├── modules/hal/espressif/ # only modules some project asked for
├── project-a/             # bind mount
└── project-b/             # bind mount
```

- **Manifest:** Zephyr's own `west.yml`. Projects don't have a `west.yml`.
- **Zephyr version:** shared by every project. `ZEPHYR_REVISION` in `setup-west.sh` is only
  used when the workspace is first created; if an existing workspace is at a different
  revision, setup prints a warning and leaves it alone.
- **Modules:** each project lists what it needs in `WORKSPACE_MODULES` in
  `.devcontainer/devcontainer.json`. Setup adds them to the workspace's
  `manifest.project-filter`, so the workspace only downloads modules some project uses.
- **Upgrading Zephyr** affects every project:

  ```sh
  cd /workdir/zephyr && git fetch origin <rev> && git checkout FETCH_HEAD
  west update && west blobs fetch
  ```

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

1. Copy the repo. The folder name is used as its path inside the workspace (`/workdir/<name>`),
   so it must be unique across your projects.
2. Edit `justfile`: `board`, `baud`, `flash_args`, `monitor`.
3. Set `ZEPHYR_PORT` on the host for your board's serial port.
4. Put board-specific `.overlay` / `.conf` files in `app/boards/`.
   The file name is the board target with `/` replaced by `_`; the SoC part can be dropped when it
   repeats the board name, e.g. `esp32_devkitc/esp32/procpu` → `esp32_devkitc_procpu`.
5. When switching SoC families, set `WORKSPACE_MODULES` in `.devcontainer/devcontainer.json`
   (e.g. `hal_nordic`, `hal_stm32`, plus any other modules such as `cmsis_6`), then rebuild the
   container.
6. Update `app/VERSION`.
