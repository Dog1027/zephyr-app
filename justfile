set allow-duplicate-variables
set allow-duplicate-recipes

import "zephyr.just"

# --- Board-specific settings (edit per project) ---
board := "esp32_devkitc/esp32/procpu"
baud  := "921600"
# Serial port. The host's /dev is mounted at /host/dev in the dev container, so use
# /host/dev/... here; a /host/dev/serial/by-id/... path is stable across re-plugs.
# USB-UART bridge boards (CP210x/CH340, e.g. ESP32-DevKitC) show up as ttyUSB*;
# chips with native USB-Serial-JTAG (ESP32-C3/S3/C6, ...) show up as ttyACM*.
# One-off override: just port=/host/dev/ttyACM0 flash
port  := "/host/dev/ttyUSB0"

flash_args := "--esp-device " + port + " --esp-baud-rate " + baud

# Open serial monitor
monitor:
    {{west}} espressif monitor -p {{port}}
