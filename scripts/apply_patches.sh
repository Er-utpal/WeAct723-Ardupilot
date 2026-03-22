#!/bin/bash
# apply_patches.sh
# Apply all required source code patches to ArduPilot for STM32H723VGT6 support
# Run from the root of the ArduPilot repository
#
# Usage:
#   cd ~/ardupilot
#   bash /path/to/WeActH723-ArduPilot/scripts/apply_patches.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/../patches"
ARDUPILOT_ROOT="$(pwd)"

echo "=== WeAct STM32H723 ArduPilot Patch Script ==="
echo "ArduPilot root: $ARDUPILOT_ROOT"
echo ""

# Verify we're in ArduPilot root
if [ ! -f "wscript" ] || [ ! -d "ArduCopter" ]; then
    echo "ERROR: Run this script from the ArduPilot root directory"
    exit 1
fi

apply_patch() {
    local file="$1"
    local description="$2"
    echo "Patching: $description"
    if [ -f "$PATCHES_DIR/$(basename $file).patch" ]; then
        patch -p1 < "$PATCHES_DIR/$(basename $file).patch" && echo "  ✓ OK" || echo "  ✗ FAILED (may already be applied)"
    else
        echo "  ✗ Patch file not found: $PATCHES_DIR/$(basename $file).patch"
    fi
}

echo "--- Applying patches ---"
apply_patch "libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32H723xx.py" "RAM map + USB AF fix"
apply_patch "libraries/AP_HAL_ChibiOS/hwdef/common/stm32h7_type2_mcuconf.h" "25MHz PLL + ADC3 guard"
apply_patch "libraries/AP_HAL_ChibiOS/AnalogIn.cpp" "ADCD3 guard for H723"
apply_patch "Tools/AP_Bootloader/support.cpp" "strlen optimizer bug fix"
apply_patch "libraries/AP_HAL_ChibiOS/hwdef/common/board.c" "USB reset + CRS init"
apply_patch "modules/ChibiOS/os/hal/ports/STM32/LLD/OTGv1/hal_usb_lld.c" "USB turnaround time"

echo ""
echo "--- Copying board definition files ---"
BOARD_DEST="$ARDUPILOT_ROOT/libraries/AP_HAL_ChibiOS/hwdef/WeActH723"
mkdir -p "$BOARD_DEST"
cp "$SCRIPT_DIR/../hwdef/WeActH723/hwdef.dat" "$BOARD_DEST/"
cp "$SCRIPT_DIR/../hwdef/WeActH723/hwdef-bl.dat" "$BOARD_DEST/"
echo "  ✓ Copied hwdef files to $BOARD_DEST"

echo ""
echo "=== All patches applied ==="
echo ""
echo "Next steps:"
echo "  1. Build bootloader:"
echo "     ./waf configure --board WeActH723 --bootloader && ./waf bootloader"
echo "     cp build/WeActH723/bin/AP_Bootloader.bin Tools/bootloaders/WeActH723_bl.bin"
echo ""
echo "  2. Build firmware:"
echo "     ./waf distclean"
echo "     ./waf configure --board WeActH723"
echo "     ./waf copter"
echo ""
echo "  3. Flash (DFU mode - hold BOOT0 while plugging USB):"
echo "     sudo dfu-util -a 0 --dfuse-address 0x08000000 -D build/WeActH723/bin/AP_Bootloader.bin"
echo "     sudo dfu-util -a 0 --dfuse-address 0x08020000:leave -D build/WeActH723/bin/arducopter.bin"
