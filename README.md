# Zephyr App Template

最小化的 Zephyr freestanding application 模板，搭配 [just](https://just.systems) 管理 build / flash。

## 前置需求

- 一個 west workspace（預設 `~/Projects/zephyrproject`，含 `.venv`）
  - 其他路徑：設定環境變數 `ZEPHYR_WORKSPACE`
- Zephyr SDK
- `just`、`uv`

## 目錄結構

```
.
├── CMakeLists.txt         # 新增原始碼加到 target_sources
├── Kconfig                # App 自訂 Kconfig 選項（CONFIG_APP_*）
├── prj.conf               # 通用 Kconfig 設定
├── VERSION                # App 版本，產生 <zephyr/app_version.h>
├── boards/                # 板子專屬設定，Zephyr 自動套用
│   ├── <board>.overlay    #   例：esp32_devkitc_procpu.overlay
│   └── <board>.conf       #   例：esp32_devkitc_procpu.conf
├── include/               # App 標頭檔
├── src/main.c
├── zephyr.just            # 通用 recipes（不含板子資訊）
└── justfile               # 本專案的板子 / port / flash 參數
```

> 注意：只要 `boards/<board>.overlay` 存在，Zephyr 就**不會**讀 `app.overlay`。

## 使用

```sh
just build        # 建置（輸出到 ./build）
just rebuild      # pristine 重建
just config       # menuconfig
just flash        # 燒錄
just monitor      # 序列埠監看
just run          # build + flash + monitor
just clean
```

額外參數可直接傳給 west build，例如 `just build -- -DEXTRA_CONF_FILE=debug.conf`。

## 從模板開新專案

1. 複製這個目錄
2. 修改 `justfile`：`board`、`port`、`baud`、`flash_args`、`monitor`
3. 在 `boards/` 放對應板子的 `.overlay` / `.conf`
   （檔名＝board target 把 `/` 換成 `_`，SoC 名稱若與板名重複可省略，
   如 `esp32_devkitc/esp32/procpu` → `esp32_devkitc_procpu`）
4. 修改 `VERSION`
