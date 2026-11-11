set allow-duplicate-variables
set allow-duplicate-recipes

import "zephyr.just"

# --- Board-specific settings (edit per project) ---
board := "esp32_devkitc/esp32/procpu"
baud  := "921600"
port  := "/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0"

flash_args := "--esp-device " + port + " --esp-baud-rate " + baud

# Open serial monitor
monitor:
    {{west}} espressif monitor -p {{port}}
