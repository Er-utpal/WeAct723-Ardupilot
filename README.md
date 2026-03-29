# WeAct Studio STM32H723VGT6 — ArduPilot Flight Controller

> **Open Source Custom Flight Controller** built from a $10 developer board

[![ArduPilot](https://img.shields.io/badge/ArduPilot-ArduCopter_v4.7.0--dev-blue)](https://ardupilot.org)
[![STM32](https://img.shields.io/badge/MCU-STM32H723VGT6-green)](https://www.st.com/en/microcontrollers-microprocessors/stm32h723vg.html)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

This project provides everything needed to run **ArduPilot ArduCopter** on the [WeAct Studio STM32H723VGT6](https://github.com/WeActStudio/WeActStudio.MiniSTM32H723) development board — including board definition files, source patches, build instructions, and a complete wiring guide.

---

## 📸 Board

![WeAct STM32H723VGT6](https://raw.githubusercontent.com/WeActStudio/WeActStudio.MiniSTM32H723/master/Images/STM32H7xx_1.jpg)

**WeAct Studio STM32H723VGT6** — Cortex-M7 @ 550MHz, 1MB Flash, 564KB RAM, onboard TFT display, MicroSD, USB-C.

---

## ✅ What Works

| Feature | Status | Notes |
|---------|--------|-------|
| USB MAVLink | ✅ Working | Mission Planner / QGroundControl |
| IMU (MPU9250) | ✅ Working | Accel + Gyro on SPI1 |
| Barometer (BMP280) | ✅ Working | I2C1, addr 0x76 |
| 8x PWM Motor Outputs | ✅ Working | Quad/Hexa/Octo frames |
| GPS (UART1) | ✅ Working | u-blox M8N/M10 |
| Telemetry (UART2) | ✅ Working | SiK radio / ESP32 |
| RC Input (UART4) | ✅ Working | ELRS, SBUS, CRSF, DSM |
| SD Card Logging | ✅ Working | Onboard MicroSD (FAT32) |
| Battery Monitoring | ✅ Working | ADC voltage + current |
| External Compass | ✅ Working | I2C2 PB10/PB11 |
| Onboard ST7735 Display | ❌ No driver | ArduPilot has no ST7735 support |
| Internal AK8963 Compass | ❌ Not detected | Use external I2C compass |

---

## 🔧 Hardware Required

| Component | Notes |
|-----------|-------|
| WeAct STM32H723VGT6 | Main board |
| MPU9250 module | SPI, 3.3V |
| BMP280 module | I2C, addr 0x76 (SDO=GND) |
| u-blox GPS module | UART, 9600 baud |
| ELRS / SBUS receiver | UART or SBUS |
| ST-Link V2 (optional) | For debugging |
| USB-C data cable | Must support data transfer |

---

## 📌 Pin Assignment

### IMU (MPU9250) — SPI1
| MPU9250 | STM32 Pin | Function |
|---------|-----------|---------|
| VCC | 3.3V | Power |
| GND | GND | Ground |
| NCS | **PA4** | Chip Select |
| SCK/SCL | PA5 | SPI Clock |
| SDO/AD0 | PA6 | SPI MISO |
| SDI/SDA | PA7 | SPI MOSI |
| INT | PB0 | Data Ready |

### Barometer (BMP280) — I2C1
| BMP280 | STM32 Pin |
|--------|-----------|
| SCL | PB6 |
| SDA | PB7 |
| CSB | 3.3V (I2C mode) |
| SDO | GND (addr 0x76) |

### Serial Ports
| Port | TX | RX | Use |
|------|----|----|-----|
| USB | PA12 | PA11 | GCS/MAVLink |
| USART1 (Serial1) | PA9 | PA10 | GPS |
| USART2 (Serial2) | PA2 | PA3 | Telemetry |
| UART4 (Serial3) | PB9 | PB8 | RC Receiver |

### RC Receiver (UART4)
| Receiver | Connect | Mission Planner Setting |
|----------|---------|------------------------|
| ExpressLRS (ELRS) | TX→PB8, RX→PB9 | SERIAL3_PROTOCOL=23 |
| SBUS | SBUS Out→PB8 | SERIAL3_PROTOCOL=23, SERIAL3_OPTIONS=3 |
| CRSF/Crossfire | TX→PB8, RX→PB9 | SERIAL3_PROTOCOL=23, SERIAL3_BAUD=416 |

### External Compass — I2C2
| Pin | Function |
|-----|---------|
| PB10 | SCL |
| PB11 | SDA |

Supported: QMC5883L, HMC5883L, IST8310, LIS3MDL

### Motor Outputs
| Output | Pin | Timer |
|--------|-----|-------|
| Motor 1 | PA0 | TIM2_CH1 |
| Motor 2 | PA1 | TIM2_CH2 |
| Motor 3 | PA8 | TIM1_CH1 |
| Motor 4 | PB1 | TIM3_CH4 |
| Motor 5 | PC6 | TIM8_CH1 |
| Motor 6 | PC7 | TIM8_CH2 |
| Motor 7 | PD12 | TIM4_CH1 |
| Motor 8 | PD13 | TIM4_CH2 |

---

## 🏗️ Build Instructions

### 1. Setup Environment

```bash
sudo apt-get install -y git python3 python3-pip python3-venv \
  arm-none-eabi-gcc arm-none-eabi-g++ arm-none-eabi-binutils \
  dfu-util openocd

git clone https://github.com/ArduPilot/ardupilot.git
cd ardupilot
git submodule update --init --recursive

python3 -m venv venv-ardupilot
source venv-ardupilot/bin/activate
pip install empy==3.3.4 pexpect future pymavlink MAVProxy
git checkout 5b498fca139f776c32234b2eff22e522337f2372
```

### 2. Apply Patches

```bash
#Step 1: clone Directory
cd ~
git clone https://github.com/Er-utpal/WeAct723-ArduPilot.git

# Step 2: Copy board definition files
mkdir -p ~/ardupilot1/libraries/AP_HAL_ChibiOS/hwdef/WeActH723
cp ~/WeActH723-Ardupilot/hwdef/WeAct723/hwdef.dat ~/ardupilot/libraries/AP_HAL_ChibiOS/hwdef/WeActH723/
cp ~/WeActH723-Ardupilot/hwdef/WeAct723/hwdef-bl.dat ~/ardupilot/libraries/AP_HAL_ChibiOS/hwdef/WeActH723/

# Step 5: Apply all patches
cd ~/ardupilot
git apply ~/WeAct723-Ardupilot/patches/STM32H723xx.py.patch
git apply ~/WeAct723-Ardupilot/patches/stm32h7_type2_mcuconf.h.patch
git apply ~/WeAct723-Ardupilot/patches/AnalogIn.cpp.patch
git apply ~/WeAct723-Ardupilot/patches/board.c.patch
git apply ~/WeAct723-Ardupilot/patches/support.cpp.patch

# ChibiOS patch (submodule)
cd ~/ardupilot/modules/ChibiOS
git apply ~/WeAct723-Ardupilot/patches/hal_usb_lld.c.patch
cd ~/ardupilot
```

> **Note:** The `patches/` directory must contain patch files generated with `scripts/generate_patches.sh`. See [patches/README.md](patches/README.md) for manual patch instructions.

### 3. Build Bootloader

```bash
cd ~/ardupilot
./waf configure --board WeActH723 --bootloader
./waf bootloader
cp build/WeActH723/bin/AP_Bootloader.bin Tools/bootloaders/WeActH723_bl.bin
```

### 4. Build Firmware

```bash
./waf distclean
./waf configure --board WeActH723
./waf copter
```

### 5. Flash Firmware

**Put board in DFU mode:** Hold BOOT0 button, plug USB-C, release BOOT0.

```bash
# Verify DFU mode
lsusb | grep "0483:df11"

# Flash bootloader
sudo dfu-util -a 0 --dfuse-address 0x08000000 \
  -D ~/ardupilot/build/WeActH723/bin/AP_Bootloader.bin

# Hold BOOT0 again, plug USB, then flash firmware
sudo dfu-util -a 0 --dfuse-address 0x08020000:leave \
  -D ~/ardupilot/build/WeActH723/bin/arducopter.bin

# Replug WITHOUT BOOT0 - should enumerate as ArduPilot
sleep 5 && lsusb | grep "1209:5741"
```

On Windows, use [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html) with `arducopter_with_bl.hex`.

---

## ⚙️ Mission Planner Setup

After connecting USB:

1. Select COM port → 115200 baud → Connect
2. Set serial protocols:
   - `SERIAL1_PROTOCOL = 5` (GPS)
   - `SERIAL2_PROTOCOL = 2` (MAVLink telemetry)
   - `SERIAL3_PROTOCOL = 23` (RC Input)
3. Run mandatory calibrations: Accelerometer → Compass → Radio → ESC
4. Set frame type: **X** for standard quadcopter

---

## 🗺️ Flash Memory Layout

```
0x08000000  ├── Sector 0 (128KB)  Bootloader
0x08020000  ├── Sector 1 (128KB)  ┐
0x08040000  ├── Sector 2 (128KB)  │
0x08060000  ├── Sector 3 (128KB)  │ Firmware (~740KB)
0x08080000  ├── Sector 4 (128KB)  │
0x080A0000  ├── Sector 5 (128KB)  ┘
0x080C0000  ├── Sector 6 (128KB)  ┐ Parameter Storage
0x080E0000  └── Sector 7 (128KB)  ┘ (STORAGE_FLASH_PAGE 6)
```

---

## 🔍 Required Source Patches

These patches fix STM32H723-specific differences from H743:

| File | Fix | Reason |
|------|-----|--------|
| `STM32H723xx.py` | RAM map: AXI SRAM first | Bootloader hard fault on firmware jump |
| `STM32H723xx.py` | USB pins AF0→AF10 | Wrong alternate function for OTG_HS |
| `stm32h7_type2_mcuconf.h` | Add 25MHz PLL config | No PLL config for 25MHz crystal |
| `stm32h7_type2_mcuconf.h` | Guard ADC3 config | H723 has no ADC3 peripheral |
| `AnalogIn.cpp` | Guard ADCD3 references | ADCD3 undeclared on H723 |
| `support.cpp` | `__attribute__((optimize("O0")))` on strlen | GCC 13.2 optimizes strlen to infinite loop |
| `board.c` | USB reset + CRS init | Stable USB after bootloader handoff |
| `hal_usb_lld.c` | TRDT_VALUE_FS: 5→9 | USB enumeration fails at 200MHz AHB |

See [patches/README.md](patches/README.md) for detailed patch instructions.

---

## 🐛 Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| No USB after flash | Wrong address | BL→0x08000000, FW→0x08020000 |
| Bootloader loops forever | No app descriptor | Add `define AP_CHECK_FIRMWARE_ENABLED 1` |
| USB error -110/-71 | CRS not enabled | Ensure board.c patch is applied |
| Hard fault on boot | Wrong RAM map | Fix STM32H723xx.py — AXI SRAM first |
| strlen infinite loop | GCC 13 optimizer | Add `__attribute__((optimize("O0")))` |
| IMU not detected | Wrong CS pin | CS = PA4, not PB0 |
| Linker overflow | Firmware > 640KB | Disable more features in hwdef.dat |

---

## 📄 Documentation

Full step-by-step guide: **[docs/WeActH723_ArduPilot_Guide_v1.1.docx](docs/WeActH723_ArduPilot_Guide_v1.1.docx)**

Covers: hardware wiring, all 8 source patches with before/after code, build commands, flash layout, ST-Link V2 debugging, Mission Planner setup, and verification checklist.

---

## 🙏 Credits

- [ArduPilot Project](https://ardupilot.org) — Open source autopilot
- [WeAct Studio](https://github.com/WeActStudio) — STM32H723 developer board
- [ChibiOS RTOS](https://www.chibios.org) — Real-time OS
- [MicroPython H723 port](https://github.com/jkorte-dev/micropython-board-STM32H723VGT6) — Reference for USB config

---

## 📜 License

MIT License — See [LICENSE](LICENSE) for details.

> ⚠️ **Safety Warning:** This is a developer/experimental build. Not certified for any safety-critical application. Always test thoroughly before flying. Never fly over people.
