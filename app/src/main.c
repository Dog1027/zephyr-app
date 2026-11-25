#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/app_version.h>

LOG_MODULE_REGISTER(app, LOG_LEVEL_INF);

int main(void)
{
    LOG_INF("App v%s running on %s", APP_VERSION_STRING, CONFIG_BOARD_TARGET);

    return 0;
}
