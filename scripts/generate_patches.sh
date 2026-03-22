#!/bin/bash
# generate_patches.sh
# Run from ArduPilot root AFTER applying all manual patches
# This generates the .patch files for the patches/ directory
#
# Usage:
#   cd ~/ardupilot
#   bash /path/to/WeActH723-ArduPilot/scripts/generate_patches.sh /path/to/WeActH723-ArduPilot

set -e

OUTPUT_DIR="${1:-./WeActH723-ArduPilot/patches}"
mkdir -p "$OUTPUT_DIR"

echo "Generating patch files to: $OUTPUT_DIR"

generate() {
    local file="$1"
    local name="$(basename $file)"
    echo "  $name..."
    git diff "$file" > "$OUTPUT_DIR/$name.patch"
    if [ -s "$OUTPUT_DIR/$name.patch" ]; then
        echo "  ✓ $name.patch ($(wc -l < "$OUTPUT_DIR/$name.patch") lines)"
    else
        echo "  ! $name.patch is empty (no changes detected)"
    fi
}

generate "libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32H723xx.py"
generate "libraries/AP_HAL_ChibiOS/hwdef/common/stm32h7_type2_mcuconf.h"
generate "libraries/AP_HAL_ChibiOS/AnalogIn.cpp"
generate "Tools/AP_Bootloader/support.cpp"
generate "libraries/AP_HAL_ChibiOS/hwdef/common/board.c"
generate "modules/ChibiOS/os/hal/ports/STM32/LLD/OTGv1/hal_usb_lld.c"

echo ""
echo "Done. Patch files saved to: $OUTPUT_DIR"
