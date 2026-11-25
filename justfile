set allow-duplicate-variables
set allow-duplicate-recipes

import "zephyr.just"

# --- Board-specific settings (edit per project) ---
board := "esp32_devkitc/esp32/procpu"
baud  := "921600"
# Serial port: set ZEPHYR_PORT on the host (passed into the dev container too).
# USB-UART bridge boards (CP210x/CH340, e.g. ESP32-DevKitC) show up as /dev/ttyUSB*;
# chips with native USB-Serial-JTAG (ESP32-C3/S3/C6, ...) show up as /dev/ttyACM*.
port  := env("ZEPHYR_PORT", "/dev/ttyUSB0")

flash_args := "--esp-device " + port + " --esp-baud-rate " + baud

# Open serial monitor
monitor:
    {{west}} espressif monitor -p {{port}}
