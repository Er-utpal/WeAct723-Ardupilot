# Patches

This directory contains diff patches for ArduPilot source files required for STM32H723VGT6 support.

## Generating Patch Files

Run from your ArduPilot root **after** applying all manual changes:

```bash
cd ~/ardupilot
bash /path/to/WeActH723-ArduPilot/scripts/generate_patches.sh
```

## Manual Patch Instructions

If patch files are missing or fail to apply, apply changes manually:

---

### 1. STM32H723xx.py — RAM Map + USB AF

**File:** `libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32H723xx.py`

**Change 1:** Reorder RAM_MAP so AXI SRAM is first:
```python
# BEFORE:
'RAM_MAP' : [
    (0x20000000, 128, 2), # DTCM
    (0x24000000, 128, 4), # AXI SRAM

# AFTER:
'RAM_MAP' : [
    (0x24000000, 320, 4), # AXI SRAM - main RAM (must be first)
    (0x20000000, 128, 2), # DTCM - fast, no DMA
```

**Change 2:** Fix USB pin alternate functions (find the PA11/PA12 entries):
```python
# BEFORE:
"PA11:OTG_HS_DM"  :  0,
"PA12:OTG_HS_DP"  :  0,

# AFTER:
"PA11:OTG_HS_DM"  :  10,
"PA12:OTG_HS_DP"  :  10,
"PA11:OTG_FS_DM"  :  10,   # add this line
"PA12:OTG_FS_DP"  :  10,   # add this line
```

---

### 2. stm32h7_type2_mcuconf.h — 25MHz PLL + ADC3 Guard

**File:** `libraries/AP_HAL_ChibiOS/hwdef/common/stm32h7_type2_mcuconf.h`

**Change 1:** Add 25MHz PLL block. Find the line `#else` before `#error "Unsupported HSE clock"` and add before it:
```c
#elif STM32_HSECLK == 25000000
// 25MHz HSE -> 400MHz SYSCLK
// PLL1: 25/5=5MHz VCO_in, 5*80=400MHz VCO_out
#define STM32_PLL1_DIVM_VALUE  5
#define STM32_PLL1_DIVN_VALUE  80
#define STM32_PLL1_DIVP_VALUE  1
#define STM32_PLL1_DIVQ_VALUE  8
#define STM32_PLL1_DIVR_VALUE  2
#define STM32_PLL2_DIVM_VALUE  5
#define STM32_PLL2_DIVN_VALUE  128
#define STM32_PLL2_DIVP_VALUE  3
#define STM32_PLL2_DIVQ_VALUE  8
#define STM32_PLL2_DIVR_VALUE  2
#define STM32_PLL3_DIVM_VALUE  5
#define STM32_PLL3_DIVN_VALUE  76
#define STM32_PLL3_DIVP_VALUE  2
#define STM32_PLL3_DIVQ_VALUE  2
#define STM32_PLL3_DIVR_VALUE  4
```

**Change 2:** Guard ADC3 config (H723 has no ADC3). Find the ADC3 DMA priority lines:
```c
// BEFORE:
#define STM32_ADC_ADC3_DMA_PRIORITY         2
#define STM32_ADC_ADC3_IRQ_PRIORITY         5

// AFTER:
#ifndef STM32H723_MCUCONF
#define STM32_ADC_ADC3_DMA_PRIORITY         2
#define STM32_ADC_ADC3_IRQ_PRIORITY         5
#endif
```

Also guard ADC3 clock mode:
```c
// BEFORE:
#define STM32_ADC_ADC3_CLOCK_MODE           ADC_CCR_CKMODE_AHB_DIV4

// AFTER:
#if !defined(STM32H723_MCUCONF) && !defined(STM32_ADC_ADC3_CLOCK_MODE)
#define STM32_ADC_ADC3_CLOCK_MODE           ADC_CCR_CKMODE_AHB_DIV4
#endif
```

And wrap ADC12 DMA stream to prevent redefinition:
```c
// BEFORE:
#define STM32_ADC_ADC12_DMA_STREAM STM32_ADC_ADC1_DMA_STREAM

// AFTER:
#ifndef STM32_ADC_ADC12_DMA_STREAM
#define STM32_ADC_ADC12_DMA_STREAM STM32_ADC_ADC1_DMA_STREAM
#endif
```

---

### 3. AnalogIn.cpp — ADCD3 Guard

**File:** `libraries/AP_HAL_ChibiOS/AnalogIn.cpp`

Run: `grep -n "ADCD3" libraries/AP_HAL_ChibiOS/AnalogIn.cpp`

Wrap all 5 occurrences:

```cpp
// Line ~402 (get_adc_index):
#ifdef ADCD3
    if (adcp == &ADCD3) {
#else
    if (false) {
#endif

// Line ~468:
#ifdef ADCD3
        adcp = &ADCD3;
#endif

// Lines ~525-527:
#ifdef ADCD3
        adcSTM32EnableVREF(&ADCD3);
        adcSTM32EnableTS(&ADCD3);
        adcSTM32EnableVBAT(&ADCD3);
#endif
```

---

### 4. support.cpp — strlen Fix

**File:** `Tools/AP_Bootloader/support.cpp`

Find the `strlen` function (around line 428):
```cpp
// BEFORE:
size_t strlen(const char *s1)

// AFTER:
__attribute__((optimize("O0"))) size_t strlen(const char *s1)
```

---

### 5. board.c — USB Reset + CRS Init

**File:** `libraries/AP_HAL_ChibiOS/hwdef/common/board.c`

Find `void boardInit(void)` and add inside the function body:
```c
void boardInit(void) {
  HAL_BOARD_INIT_HOOK_CALL

#if defined(STM32H723xx) || defined(STM32H7xx)
  // Reset USB OTG_HS peripheral to clear bootloader state
  RCC->AHB1RSTR |= RCC_AHB1RSTR_USB1OTGHSRST;
  volatile uint32_t dummy = RCC->AHB1RSTR;
  (void)dummy;
  RCC->AHB1RSTR &= ~RCC_AHB1RSTR_USB1OTGHSRST;

  // Enable CRS: sync HSI48 to USB SOF for stable enumeration
  RCC->APB1HENR |= RCC_APB1HENR_CRSEN;
  CRS->CFGR = (2U << 28);  // SYNCSRC = USB SOF
  CRS->CR |= CRS_CR_AUTOTRIMEN | CRS_CR_CEN;
#endif
}
```

---

### 6. hal_usb_lld.c — USB Turnaround Time

**File:** `modules/ChibiOS/os/hal/ports/STM32/LLD/OTGv1/hal_usb_lld.c`

```c
// BEFORE:
#define TRDT_VALUE_FS           5

// AFTER:
#define TRDT_VALUE_FS           9
```

---

## Why These Patches Are Needed

The STM32H723 differs from the H743 that ArduPilot normally targets:

- **RAM map**: H723 bootloader validation expects main stack in AXI SRAM (0x24000000), not DTCM (0x20000000)
- **USB pins**: OTG_HS on PA11/PA12 uses AF10, not AF0 as the pin table incorrectly states
- **Crystal**: 25MHz HSE needs its own PLL configuration — none existed
- **ADC3**: H723 only has ADC1+ADC2, no ADC3 peripheral
- **strlen**: GCC 13.2 with -O2 miscompiles the custom strlen in the bootloader
- **USB stability**: CRS must sync HSI48 to USB SOF; without it USB enumerates unreliably
- **TRDT**: H7 at 200MHz AHB needs longer USB turnaround time than F4
