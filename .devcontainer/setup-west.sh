#!/usr/bin/env bash
# Create or join the shared west workspace in the parent directory of this repo.
#
# The workspace (zephyr + modules) lives in a named volume shared by every project
# built from this template. Its manifest is Zephyr's own west.yml.
#
#   ZEPHYR_REVISION    Zephyr revision used when the workspace is first created.
#                      An existing workspace is never moved; a mismatch only warns.
#   WORKSPACE_MODULES  Comma/space separated modules this project needs
#                      (e.g. "hal_espressif"). Added to the workspace's project filter.
set -euo pipefail

ZEPHYR_REVISION="${ZEPHYR_REVISION:-072fd9442fe12568bcc3d3c61e4f390ed5cf35a3}"
WORKSPACE_MODULES="${WORKSPACE_MODULES:-}"

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
ws_dir="$(dirname "$repo_dir")"

cd "$ws_dir"
[ -w . ] || sudo chown "$(id -u):$(id -g)" .

# Serialise setup when several containers start at once
exec 9>"$ws_dir/.west-setup.lock"
flock 9

if [ ! -d .west ]; then
    west init -m https://github.com/zephyrproject-rtos/zephyr --mr "$ZEPHYR_REVISION" .
    # Start with no optional modules; projects opt in via WORKSPACE_MODULES
    west config manifest.project-filter -- '-.*'
else
    manifest_path="$(west config manifest.path)"
    if [ "$manifest_path" != "zephyr" ]; then
        echo "error: $ws_dir/.west uses manifest '$manifest_path', expected 'zephyr'." >&2
        echo "       This workspace was created by a project with its own west.yml." >&2
        echo "       Convert it with: west config manifest.path zephyr && west config manifest.project-filter -- '-.*'" >&2
        exit 1
    fi
    current="$(git -C zephyr rev-parse HEAD)"
    wanted="$(git -C zephyr rev-parse --verify --quiet "$ZEPHYR_REVISION^{commit}" || echo "$ZEPHYR_REVISION")"
    if [ "$current" != "$wanted" ]; then
        echo "warning: shared workspace is at zephyr $current, this project expects $ZEPHYR_REVISION" >&2
    fi
fi

# Add this project's modules to the shared filter
filter="$(west config manifest.project-filter 2>/dev/null || true)"
for m in ${WORKSPACE_MODULES//,/ }; do
    case ",$filter," in
        *",+$m,"*) ;;
        *) filter="${filter:+$filter,}+$m" ;;
    esac
done
[ -n "$filter" ] && west config manifest.project-filter -- "$filter"

west update --narrow -o=--depth=1
# No module argument: fetch blobs for every active module
west blobs fetch
