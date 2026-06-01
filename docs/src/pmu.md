# Power Management Unit - PMU

## I/O Connections

![Power I/O diagram showing VDD input and output supply connections](images/pmu-power-io-diagram.png)

**VDD inputs:**

- **PMU** (2.7 V – 3.6 V): VDD33
- **I/O** (3.3 V / 1.8 V):
  - VDD33_BCPAD, VDD33_DPAD, VDD33_QFCPAD: tied to VDDIO in package
  - VDD33_AOPAD, VDD33_TESTPAD, VDD33_EPAD, VDD33_APAD: tied to VDD33 in package.
- **RRAM** (2.7 V – 3.6 V): VDDRR0, VDDRR1: tied to VDD33R on stand-alone ball
- **USB**:
  - USBVCC33 (2.7 V – 3.6 V) tied to VDD33 in package
  - USBVCCCORE (0.80 V) - tied to VDD85 in package
- **PLL**:
  - PLL25VPAD (2.5 V) - Tied to VDD25 ball
  - PLL09VPAD (0.80 V) - tied to VDD85 in package
- **ADC**: ADCAVDD (2.5 V) - Tied to VDD25 ball

**VDD outputs:**

- VDD85D, VDD85A - ganged to VDD85 inside package
- VDDAO
- ANA_VDD25A tied to PLL25VPAD, ADCAVDD 2.5V

**GND:**

- All grounds ganged together in package
  - VSS, DVSS, VSSA
  - VSSPLL
  - ADCAVSS

### Power Pad Description

| I/O Power Pad | Description |
|---------------|-------------|
| VDD33_APAD | I/O power pad for GPIO_PA\<7:0\> (tied to VDD33) |
| VDD33_BCPAD | I/O power pad for GPIO_PB\<15:0\> and GPIO_PC\<15:0\> (tied to VDDIO) |
| VDD33_DPAD | I/O power pad for GPIO_PD\<15:0\> (tied to VDDIO) |
| VDD33_EPAD | I/O power pad for GPIO_PE\<15:0\>, XTAL48M_IN, XTAL48M_OUT (tied to VDD33) |
| VDD33_QFCPAD | I/O power pad for GPIO_QFCSIO\<7:0\>, QFC_RSTS0, QFC_RSTM0, QFC_INT, QFC_SS\<1:0\>, QFC_QDS, QFC_SCKN, QFC_SCK (tied to VDDIO) |
| VDD33_AOPAD | I/O power pad for GPIO_PF\<9:0\>, PAD_AOXRSTn, XTAL32K_IN, XTAL32K_OUT (tied to VDD33) |
| VDD33_TESTPAD | I/O power pad for test pads: WMS\<2:0\>, XRSTn, DUART, SWDIO, SWDCK, JTCK, JTMS, JTDI, JTDO, JTRST (tied to VDD33) |
| VDDRR0 | 3.3 V power pad for RRAM0 (tied to VDD33R) |
| VDDRR1 | 3.3 V power pad for RRAM1 (tied to VDD33R) |
| VDD33 | 3.3 V power pad for PMU (tied to VDD33) |
| USBVCC33 | 3.3 V power pad for USB PHY (3.3 V signalling) (tied to VDD33R)|
| USBVCCCORE | 0.8 V power pad for USB PHY (0.8 V core) (tied to VDD85) |
| ADCAVDD | 2.5 V analog power supply for temperature/voltage sensor (tied to VDD25) |
| PLL25VPAD | 2.5 V analog supply voltage for PLL (tied to VDD25) |
| PLL09VPAD | 0.8 V core supply voltage for PLL (tied to VDD85) |
| ANA_VDD25 | PMU regulator output at 2.5 V for ADC and PLL (tied to VDD25) |
| VDD85D | PMU regulator output at 0.8 V / 0.95 V for I/O core power, SoC, and OSC32M (tied to VDD85) |
| VDD85A | PMU regulator output at 0.8 V / 0.95 V for I/O core power, USB PHY, PLL, ADC, RNG cell (tied to VDD85) |
| VDDAO | PMU regulator output at 0.8 V for I/O core power, AO domain, and OSC32K (tied to VDDAO) |

### Ground Pad Description

All ground pads tied to common GND bus in package.

| I/O Ground Pad | Description |
|----------------|-------------|
| VSS | Ground pad for the whole chip except PMU, RRAM0, RRAM1, ADC, PLL, USB PHY |
| DVSS | Ground pad for I/O, PMU, RRAM0, and RRAM1 |
| VSSA | Ground pad for USB PHY |
| VSSPLL | Ground pad for PLL |
| ADCAVSS | Ground pad for ADC |

### I/O Power Domain Groups

There are two I/O power domains. One is fixed at 3.3V (tied to VDD33 internally), and the other is tied to VDDIO.

There are more I/Os on the die than are broken out in the CSP package due to ball count limitation on the package type. For higher-I/O count devices, please consult with Crossbar for an alternative, high-pin count BGA packaged device.

| # | Pad Group | I/O Power Pad | Description |
|---|-----------|---------------|-------------|
| 2 | PB, PC | VDDIO | GPIO_PB\<15:0\> and GPIO_PC\<15:0\> |
| 3 | PD | VDDIO | GPIO_PD\<15:0\> |
| 7 | QFC | VDDIO | (unavailable) |
| 1 | PA | VDD33 | GPIO_PA\<7:0\> (some I/Os ganged to PF pins) |
| 4 | PE, TEST | VDD33 | XTAL48M_IN, XTAL48M_OUT. VDD33_TESTPAD: WMS\<2:0\>, XRSTn, DUART |
| 5 | RRAM0 | VDDRR0 | VDD33R |
| 6 | RRAM1 | VDDRR1 | VDD33R |
| 8 | PF | VDD33 | GPIO_PF\<9:0\> (some I/Os ganged to PA pins), PAD_AOXRSTn, XTAL32K_IN, XTAL32K_OUT |
| 9 | TV / PLL / PHY / PMU | VDD33 | 3.0 V pad for PMU and USB PHY. |

Below is the raw chip floorplan showing the location of the I/O power domains on-die. The power is further routed through an RDL (redistribution layer) and broken out to a limited number of CSP balls.

![Chip floorplan showing the location of each I/O power domain group](images/pmu-io-power-domain-groups.png)

### Power Timing Sequence

The following diagram shows the recommended power-on sequence for VDD33(I/O) and VDD33:

- **VDD33(I/O):** VDD33_APAD, VDD33_BCPAD, VDD33_DPAD, VDD33_EPAD, VDD33_AOPAD, VDD33_QFCPAD, VDD33_TESTPAD
- **VDD33:** VDD33, VDDRR0, VDDRR1, USBVCC33

![Power timing sequence diagram showing recommended power-on ordering for VDD33(I/O) and VDD33](images/pmu-power-timing-sequence.png)

- Stand-alone VDDIO may rise after VDD33 as the internal VDD33-bound I/O are tied to VDD33 and guaranteed to be valid on VDD33 rise.
- t2 should be >0.

## Power Modes

Besides the regular active mode, the device provides three reduced power modes:

- Sleep mode
- Power-down mode

The following modes are listed from maximum to minimum power consumption.

### Active Mode

In active mode, all clocks to the CPU cores, memories, and peripherals are enabled. The chip enters active mode after reset, with default power trimming determined by the ReRAM IFR power-on initialization. Power and clocks to selected peripherals and crypto engines can be optimized during runtime. All low-power modes can be entered from active mode.

### Sleep Mode

In sleep mode, all clocks to the CPU cores are stopped and instruction execution is suspended until a reset or interrupt occurs. Selected functional blocks (peripherals, crypto engines) can continue operating at normal or reduced frequency and may generate interrupts as wake-up sources. SRAM contents are retained in sleep mode.

**Entering sleep mode:**

Sleep mode is entered by executing a `WFI` instruction after optionally configuring lower-frequency clock settings. Crypto engines, peripherals, and memories remain operational.

**Waking up from sleep mode:**

Any interrupt or RESET wakes the device from sleep mode. GPIO interrupts and selected peripherals (SPI, I2C, etc.) can serve as wake-up sources. The chip resumes using the same power configuration it had before sleep.

#### Power-Down Mode

In power-down mode, all clocks, the CPU core, and all functional blocks are powered down except the always-on (AO) domain. External power supplies remain on. Most SRAM and register contents are not retained — only AO SRAMs and AO backup registers are preserved.

**Entering power-down mode:**

Configure AO wake-up sources, then write `0x0000_005A` to the `PMU_PDAR` register. The SoC power domain shuts off; only the AO domain remains powered.

**Waking up from power-down mode:**

Wake-up from power-down is triggered by asserting RESET, or by asserting PF0 or PF1 pins. On wake-up, the PMU powers on the SoC domain, the ReRAM IFR is re-read, RAMs reset to zero, and the CPU restarts from the beginning. Backup-registers, RTC and AORAM in the AO domain are preserved if the wake-up source is from the PF pins; if external reset is used, then these registers are cleared.

### Low-Power Mode Summary

| | Active | Sleep | Power-Down |
|---|--------|-------|------------|
| CPU cores | Running | Suspended (clocks stopped)  | Powered off |
| Functional blocks (crypto, peripherals) | Running | Running / reduced frequency (configurable)  | Powered off |
| Analog blocks | Running | Run / sleep / disabled (configurable)  | Powered off |
| SRAM (except AO) | Running | Retained  | Powered off |
| AO domain | Running | Running | Running |

> These modes should be activated using the low-power mode library API from the SDK software package. Power usage is primarily controlled by CGU clock settings, PMU regulator settings, and the CPU operating mode.

## Low-Power Control API Reference Flow

### Enter Sleep Mode

1. *(Optional)* Configure `PMU_CRLP` and `PMU_TRMLP*` registers with reduced power settings and trimmings for sleep entry.
2. *(Optional)* Configure `CGUFD_*` registers (`0x4004_0014` – `0x4004_003C`) with reduced clock frequencies for sleep entry.
3. *(Optional)* Write `0x3` to `CGULP` (`0x4004_0004`) to enable low-power frequency division and disable OSC/PLL on sleep entry.
4. Configure and enable wake-up sources.
5. Execute `WFI` / `WFE` instruction — CPU core clocks stop.
6. Device remains in sleep mode until a valid wake-up source triggers.
7. On wake-up, the CPU resumes execution from the next instruction.

As of Xous 0.10.1, the above sequence is already implemented and accessible via an API call to enter suspend via the Suspend/Resume manager:

```Rust,ignore
    let xns = xous_names::XousNames::new().unwrap();
    let susres = susres::Susres::new_without_hook(&xns).unwrap();
    susres.initiate_suspend().unwrap();
```

To access the `xous_names` and `susres` APIs, you will need this in your `Cargo.toml`:

```toml
   susres = { package = "xous-api-susres", version = "0.9.68" }
   xous-names = { package = "xous-api-names", version = "0.9.71" }
```

### Enter Power-Down Mode

1. *(Optional)* Configure `PMU_CRPD` register with power-down settings.
2. *(Optional)* Store any important data to AO backup registers or AORAM before entry.
3. Configure and enable AO wake-up sources.
4. Write `0x0000_005A` to `PMU_PDAR` — all SoC domain blocks shut off; only the AO domain remains powered.
5. Device remains in power-down until a valid AO wake-up source triggers.
6. On wake-up, the PMU powers on the SoC domain. The ReRAM IFR is re-read, RAMs reset to zero, and the CPU restarts from the beginning.

As of Xous 0.10.1, the above sequence is already implemented via an API call to enter power-down mode that requires a PlatformSpecific call:

```rust,ignore
    use num_traits::ToPrimitive;

    let xns = xous_names::XousNames::new().unwrap();
    let susres_conn =
        xns.request_connection_blocking(susres::api::SERVER_NAME_SUSRES).expect("Can't connect to SUSRES");
    xous::send_message(
        susres_conn,
        xous::Message::new_scalar(
            susres::api::Opcode::PlatformSpecific.to_usize().unwrap(),
            bao1x_hal::ClockOp::DeepSleep.to_usize().unwrap(),
            0,
            0,
            0,
        ),
    )
    .ok();
```

You'll need these crates to make the above call:

```toml
   xous = "0.9.70"
   susres = { package = "xous-api-susres", version = "0.9.68" }
   xous-names = { package = "xous-api-names", version = "0.9.71" }
   bao1x-hal = { features = [
       "std",
   ], git = "https://github.com/betrusted-io/xous-core", branch = "dev" }
   num-traits = { version = "0.2.14", default-features = false }
```
---

## PMU Regulator and Trim Block

### PMU Introduction

![PMU block diagram showing regulators, bandgap, POR/PDR, and current source](images/pmu-block-diagram.png)

- **2.5 V Regulator (VR25):** 2.55 V regulator powered from VDD. Supports power-down enable and ready status indication.
- **0.85 V Regulators for Analog/Digital (VRCOREA, VRCORED):** 0.85 V regulators powered from VDD. Support power-down enable, ready status indication, and overshoot enable.
- **0.8 V Always-On Regulator (VRAO):** 0.77 V regulator powered from VDD.
- **Current Source Output (IOUT):** Provides several current sources, including a 10 µA output to a test pin for calibration against an external resistor (enabling absolute-value accuracy rather than tracking integrated resistors).
- **Power On/Down Reset (PORPDR):** Provides power-on reset signal. Also triggers when power drops low enough to lose the always-on regulator.
- **Bandgap (BG):** Ready status indication. The 1.5 V (VOUT1P5), 1.2 V (VOUT1P2), and 0.6 V (VOUTP60) references are individually trimmable. CTAT and PTAT currents are trimmable.

### PMU Main Features

- Provides regulated supplies: VDD25, VDD85A, VDD85D, VDDAO.
- Generates power-on and power-down reset signals.
- Supports power-down mode.

| Cell | Power-Down Mode — On/Off | Power-Down Supply (µA) | Active Mode — On/Off | Active Supply (µA) |
|------|--------------------------|------------------------|----------------------|--------------------|
| VR25 | Off | 0.01 | On | 10 |
| VR85_A/D | Off | 0.01 | On | 10 |
| VR_AO | On | 1 | On | 1 |
| BG | On | 1.5 | On | 1 + current sources |
| POR/PDR | On | 1 | On | 1 |
| VD (four cells) | On (2 channels) | 2 | On (4 channels) | 4 |

---

## PMU & AO Control Registers

Base address: `0x4006_0000`

| Register Name | Offset | Size | Type | Access | Default | Description |
|---------------|--------|------|------|--------|---------|-------------|
| AO_CLK32K_SEL | 0x0000 | 32 | Config | R/W | 0x00000006 | AO 32 kHz clock source selection |
| AO_CLK1HZ_FD | 0x0004 | 32 | Config | R/W | 0x00003FFF | 1 Hz clock frequency divider |
| AO_WKUP_INTEN | 0x0008 | 32 | Config | R/W | 0x00000000 | Wakeup mask and interrupt enable |
| AO_RSTCR_MASK | 0x000C | 32 | Config | R/W | 0x00000000 | Reset mask control |
| PMU_CR | 0x0010 | 32 | Config | R/W | 0x000003F3 | PMU block control (active mode) |
| PMU_CRLP | 0x0014 | 32 | Config | R/W | 0x00003FFF | PMU block control (sleep / deep-sleep) |
| PMU_CRPD | 0x0018 | 32 | Config | R/W | 0x00000000 | PMU block control (power-down) |
| PMU_DFT | 0x001C | 32 | Config | R/W | — | PMU default test |
| PMU_TRM0 | 0x0020 | 32 | Config | R/W | 0x00000000 | PMU trimming low 32 bits (active) |
| PMU_TRM1 | 0x0024 | 32 | Config | R/W | 0x00003FFF | PMU trimming high 32 bits (active) |
| PMU_TRMLP0 | 0x0028 | 32 | Config | R/W | 0x00000000 | PMU trimming low 32 bits (low-power) |
| PMU_TRMLP1 | 0x002C | 32 | Config | R/W | 0x0000001F | PMU trimming high 32 bits (low-power) |
| AO_OSC_CR | 0x0034 | 32 | Config | R/W | 0x0001 2D2D | AO 32 kHz oscillator control |
| PMU_SR | 0x0038 | 32 | Config | R/W | 0x00000000 | PMU ready status register |
| PMU_FR | 0x003C | 32 | Config | R/W | 0x00000000 | PMU error flag register |
| AO_FR | 0x0040 | 32 | Config | R/W | — | AO domain interrupt flag register |
| PMU_PDAR | 0x0044 | 32 | Config | R/W | — | Power-down activation register |
| AO_PERI_CLR | 0x0050 | 32 | Config | R/W | — | Wakeup interrupt clear register |
| AO_IOX | 0x0060 | 32 | Config | R/W | 0x00000000 | Port F alternate function selection |
| AO_PADPU | 0x0064 | 32 | Config | R/W | 0x000003FF | Port F pull-up configuration |

### Register Descriptions

#### AO_CLK32K_SEL — AO 32 kHz Clock Source Selection

- **Address offset:** `0x0000`
- **Reset value:** `0x0000_0006`

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | clk32k_sel | 32 kHz clock source: `0` = internal OSC 32 kHz, `1` = external XTAL 32 kHz |
| \[1\] | pdisoen | Isolation control on power-down entry: `0` = isolation disabled, `1` = isolation enabled |
| \[2\] | pclkicg | PCLK gate on power-down entry: `0` = PCLK from SoC domain enabled, `1` = PCLK from SoC domain disabled |

#### AO_CLK1HZ_FD — 1 Hz Clock Frequency Divider

- **Address offset:** `0x0004`
- **Reset value:** `0x0000_3FFF`

| Bits | Field | Description |
|------|-------|-------------|
| \[13:0\] | 1Hz fd | Frequency divider based on clk32k (OSC32K or XTAL32K). Formula: f_1Hz = f_32kHz / (2 × (fd + 1)). Default produces ≈ 0.976 Hz. For accurate 1 Hz set to `0x3E80`. |

#### AO_WKUP_INTEN — Wakeup Mask and Interrupt Enable

- **Address offset:** `0x0008`
- **Reset value:** `0x0000_0000`

Interrupt enable bits (0 = disabled, 1 = enabled):

| Bits | Source |
|------|--------|
| \[0\] | WDT reset source interrupt |
| \[1\] | RTC event interrupt |
| \[2\] | ATIMER event interrupt |
| \[3\] | WDT event interrupt |
| \[4\] | KPC event interrupt |
| \[5\] | KPC async source interrupt |
| \[7:6\] | Reserved |

Wakeup mask bits (0 = source can wake system, 1 = source **cannot** wake system):

| Bits | Source |
|------|--------|
| \[8\] | WDT reset source wakeup mask |
| \[9\] | RTC event wakeup mask |
| \[11\] | WDT event wakeup mask |
| \[12\] | KPC event wakeup mask |
| \[13\] | KPC async source wakeup mask |
| \[15:14\] | Reserved |
| \[16\] | PF1 pull-down event wakeup mask |
| \[17\] | PF0 pull-down event wakeup mask |

#### AO_RSTCR_MASK — Reset Mask Control Register

- **Address offset:** `0x000C`
- **Reset value:** `0x0000_001F`

Each bit masks a reset source (`0` = source can reset system, `1` = source **cannot** reset system):

| Bits | Reset source |
|------|-------------|
| \[0\] | PMU POR ready |
| \[1\] | PMU 0.8 V digital regulator ready |
| \[2\] | PMU 0.8 V analog regulator ready |
| \[3\] | PMU 2.5 V regulator ready |
| \[4\] | PMU bandgap ready |

#### PMU_CR — PMU Block Control Register (Active Mode)

- **Address offset:** `0x0010`
- **Reset value:** `0x0000_007C`

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | VR85D voltage | 0.8 V digital regulator voltage: `0` = 0.8 V, `1` = 0.95 V (higher performance) |
| \[1\] | VR85A voltage | 0.8 V analog regulator voltage: `0` = 0.8 V, `1` = 0.95 V (higher performance) |
| \[2\] | POC | Power-on control: `0` = disabled (forces POC_IO = 0), `1` = enabled |
| \[3\] | iout | Reference current circuit (ibias / test_top): `0` = disabled, `1` = enabled |
| \[4\] | VR85D enable | 0.8 V digital regulator: `0` = disabled, `1` = enabled |
| \[5\] | VR85A enable | 0.8 V analog regulator: `0` = disabled, `1` = enabled |
| \[6\] | VR25 enable | 2.5 V regulator: `0` = disabled, `1` = enabled |

#### PMU_CRLP — PMU Block Control Register (Sleep / Deep-Sleep)

- **Address offset:** `0x0014`
- **Reset value:** `0x0000_007C`

Same bit definition as `PMU_CR`. These are separate configuration values applied when entering sleep or deep-sleep mode.

#### PMU_CRPD — PMU Block Control Register (Power-Down)

- **Address offset:** `0x0018`
- **Reset value:** `0x0000_007C`

Same bit definition as `PMU_CR`. These are separate configuration values applied when entering power-down mode.

#### PMU_DFT — PMU Default Test Register

- **Address offset:** `0x001C`
- **Reset value:** `0x0000_0002`

| Bits | Field | Description |
|------|-------|-------------|
| \[2:0\] | test mode | Output selection on PMU_ANA_TEST pin: `010` = disabled (default), `000` = monitor VDD25, `001` = monitor SOURCE_10UA, `1xx` = monitor selection from PMU_TEST_SEL (bits \[5:3\]) |
| \[5:3\] | PMU_TEST_SEL | Reference bias selection when bits \[2:0\] = `1xx`: `000` = VSS, `001` = VP60V (0.6 V), `010` = VDD_AO (0.8 V), `011` = VP60A (0.6 V), `100` = VP60D (0.6 V), `101` = VOLT1 (1.0 V), `110` = VOUT1P2 (1.2 V), `111` = VDD2 (2.0 V) |

#### PMU_TRM0 — PMU Trimming Low 32-bit Register (Active Mode)

- **Address offset:** `0x0020`
- **Reset value:** `0x0842_1080`

| Bits | Field | Description |
|------|-------|-------------|
| \[2:0\] | VDDAO trim | VDDAO voltage: `000` = 0.8 V, `001` = 0.75 V, `010` = 0.7 V, `011` = 0.65 V, `1xx` = 0.6 V |
| \[7:3\] | VR85D bias trim | 0.6 V reference for 0.8 V digital regulator. `10000` = 0.8 V (default). See [VDD85 Trim Table below](./pmu.md#vdd85-trim-table). |
| \[12:8\] | VR85A bias trim | 0.6 V reference for 0.8 V analog regulator. `10000` = 0.8 V (default). |
| \[17:13\] | VR25 bias trim | 0.6 V reference for 2.5 V regulator. `10000` = 0.8 V (default). |
| \[22:18\] | BG CTAT trim | Bandgap CTAT parameter. `10000` = 0.8 V (default). |
| \[27:23\] | BG PTAT trim | Bandgap PTAT parameter. `10000` = 0.8 V (default). |
| \[31:28\] | IREF trim \[3:0\] | Bits \[3:0\] of reference current trim for SINK_1uA / SOURCE_10uA. Must be combined with `PMU_TRM1[1:0]` for the full 6-bit value. |

#### PMU_TRM1 — PMU Trimming High 32-bit Register (Active Mode)

- **Address offset:** `0x0024`
- **Reset value:** `0x0000_0002`

| Bits | Field | Description |
|------|-------|-------------|
| \[1:0\] | IREF trim \[5:4\] | Bits \[5:4\] of reference current trim. Full value = `{PMU_TRM1[1:0], PMU_TRM0[31:28]}`. `100000` = 10.002 µA (default). This value is set by chip test and should not be adjusted. |

#### PMU_TRMLP0 — PMU Trimming Low 32-bit Register (Low-Power)

- **Address offset:** `0x0028`
- **Reset value:** `0x0842_1080`

Same bit definition as `PMU_TRM0`. Applied during sleep and deep-sleep mode.

#### PMU_TRMLP1 — PMU Trimming High 32-bit Register (Low-Power)

- **Address offset:** `0x002C`
- **Reset value:** `0x0000_001F`

Same bit definition as `PMU_TRM1`. Applied during sleep and deep-sleep mode.

#### AO_OSC_CR — AO 32 kHz Oscillator Control Register

- **Address offset:** `0x0034`
- **Reset value:** `0x0001_2D2D`

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | Active mode enable | OSC32K enable for active mode: `0` = disabled, `1` = enabled |
| \[7:1\] | Active mode trim | OSC32K trimming for active mode. `0100110` = 33 kHz (default). This value is set by chip test and should not be adjusted. |
| \[8\] | Sleep/deep-sleep enable | OSC32K enable for sleep and deep-sleep: `0` = disabled, `1` = enabled |
| \[15:9\] | Sleep/deep-sleep trim | OSC32K trimming for sleep and deep-sleep. `0100110` = 33 kHz (default). |
| \[16\] | Power-down enable | OSC32K enable for power-down mode: `0` = disabled, `1` = enabled |

#### PMU_SR — PMU Ready Status Register

- **Address offset:** `0x0038`
- **Reset value:** `0x0000_001F`
- **Access:** Read-only (real-time status)

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | POR ready | `0` = VDD below 1.3 V, `1` = VDD above 1.3 V |
| \[1\] | VR85D ready | `0` = VR85D below target, `1` = VR85D ready (≥ 0.8 V default) |
| \[2\] | VR85A ready | `0` = VR85A below target, `1` = VR85A ready (≥ 0.8 V default) |
| \[3\] | VR25 ready | `0` = VR25 below target, `1` = VR25 ready (≥ 2.5 V default) |
| \[4\] | BG ready | `0` = bandgap below target, `1` = bandgap ready |

#### PMU_FR — PMU Error Flag Register

- **Address offset:** `0x003C`
- **Reset value:** `0x0000_0000`

Bits are set if the corresponding supply was below its threshold after power-on. Write `1` to a bit to clear it.

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | POR error | `1` = VDD was below 1.3 V after power-on |
| \[1\] | VR85D error | `1` = VR85D was below 0.8 V target after power-on |
| \[2\] | VR85A error | `1` = VR85A was below 0.8 V target after power-on |
| \[3\] | VR25 error | `1` = VR25 was below 2.5 V target after power-on |
| \[4\] | BG error | `1` = bandgap was below 0.6 V target after power-on |

#### AO_FR — AO Domain Interrupt Flag Register

- **Address offset:** `0x0040`
- **Reset value:** `0x0000_0000`

Write `1` to a bit to clear it.

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | WDT reset flag | `1` = WDT reset interrupt occurred |
| \[1\] | RTC event flag | `1` = RTC event interrupt occurred |
| \[2\] | ATIMER event flag | `1` = ATIMER event interrupt occurred |
| \[3\] | WDT event flag | `1` = WDT event interrupt occurred |
| \[4\] | KPC event flag | `1` = KPC event interrupt occurred |
| \[5\] | KPC async flag | `1` = KPC async source interrupt occurred |
| \[7:6\] | Reserved | — |
| \[8\] | PF1 pull-down flag | `1` = PF1 pull-down event occurred |
| \[9\] | PF0 pull-down flag | `1` = PF0 pull-down event occurred |

#### PMU_PDAR — Power-Down Activation Register

- **Address offset:** `0x0044`
- **Type:** AR (action register)
- **Reset value:** `0x0000_0000` (always reads zero)

| Bits | Field | Description |
|------|-------|-------------|
| \[31:0\] | — | Write `0x0000_005A` to enter power-down mode |

#### AO_PERI_CLR — Wakeup Interrupt Clear Register

- **Address offset:** `0x0050`
- **Type:** AR (action register, always reads zero)

| Bits | Field | Description |
|------|-------|-------------|
| \[31:0\] | — | Write `0x0000_00AA` to clear all wakeup interrupt flags |

#### AO_IOX — Port F Alternate Function Selection Register

- **Address offset:** `0x0060`
- **Reset value:** `0x0000_0000`

| Bits | Field | Description |
|------|-------|-------------|
| \[0\] | AF select | `0` = GPIO (AF0, default) for Port F, `1` = Keypad (AF1): PF\[5:2\] as KPI\[3:0\], PF\[9:6\] as KPO\[3:0\] |

> **Note:** Use `AO_IOX` to configure Port F alternate function selection. The `AFSEL` registers for Port F (`0x5012_F028`, `0x5012_F02C`) are **not** used.

#### AO_PADPU — Port F Pull-Up Configuration Register

- **Address offset:** `0x0064`
- **Reset value:** `0x0000_03FF` (all pull-ups enabled by default)

Each bit controls pull-up for the corresponding Port F pin (`0` = floating when undriven, `1` = weak pull-up when undriven):

| Bits | Pin |
|------|-----|
| \[0\] | PF0 |
| \[1\] | PF1 |
| \[2\] | PF2 |
| \[3\] | PF3 |
| \[4\] | PF4 |
| \[5\] | PF5 |
| \[6\] | PF6 |
| \[7\] | PF7 |
| \[8\] | PF8 |
| \[9\] | PF9 |

> **Note:** Use `AO_PADPU` to configure Port F pull-ups. The `GPIOPU` register for Port F (`0x5012_F174`) is **not** used.

### VDD85 Trim Table

| pmu_TRM_DP60[4] | pmu_TRM_DP60[3] | pmu_TRM_DP60[2] | pmu_TRM_DP60[1] | pmu_TRM_DP60[0] | VOUTP60 (mV) | VDD85A (800 mV) | VDD85A (950 mV) |
|:-:|:-:|:-:|:-:|:-:|--:|--:|--:|
| 0 | 0 | 0 | 0 | 0 | 520 | 693 | 823 |
| 0 | 0 | 0 | 0 | 1 | 525 | 700 | 831 |
| 0 | 0 | 0 | 1 | 0 | 530 | 706 | 839 |
| 0 | 0 | 0 | 1 | 1 | 535 | 713 | 847 |
| 0 | 0 | 1 | 0 | 0 | 540 | 720 | 855 |
| 0 | 0 | 1 | 0 | 1 | 545 | 726 | 862 |
| 0 | 0 | 1 | 1 | 0 | 550 | 733 | 870 |
| 0 | 0 | 1 | 1 | 1 | 555 | 740 | 878 |
| 0 | 1 | 0 | 0 | 0 | 560 | 746 | 886 |
| 0 | 1 | 0 | 0 | 1 | 565 | 753 | 894 |
| 0 | 1 | 0 | 1 | 0 | 570 | 760 | 902 |
| 0 | 1 | 0 | 1 | 1 | 575 | 766 | 910 |
| 0 | 1 | 1 | 0 | 0 | 580 | 773 | 918 |
| 0 | 1 | 1 | 0 | 1 | 585 | 780 | 926 |
| 0 | 1 | 1 | 1 | 0 | 590 | 786 | 934 |
| 0 | 1 | 1 | 1 | 1 | 595 | 793 | 942 |
| 1 | 0 | 0 | 0 | 0 | 600 | 800 | 950 |
| 1 | 0 | 0 | 0 | 1 | 605 | 806 | 957 |
| 1 | 0 | 0 | 1 | 0 | 610 | 813 | 965 |
| 1 | 0 | 0 | 1 | 1 | 615 | 820 | 973 |
| 1 | 0 | 1 | 0 | 0 | 620 | 826 | 981 |
| 1 | 0 | 1 | 0 | 1 | 625 | 833 | 989 |
| 1 | 0 | 1 | 1 | 0 | 630 | 840 | 997 |
| 1 | 0 | 1 | 1 | 1 | 635 | 846 | 1005 |
| 1 | 1 | 0 | 0 | 0 | 640 | 853 | 1013 |
| 1 | 1 | 0 | 0 | 1 | 645 | 860 | 1021 |
| 1 | 1 | 0 | 1 | 0 | 650 | 866 | 1029 |
| 1 | 1 | 0 | 1 | 1 | 655 | 873 | 1037 |
| 1 | 1 | 1 | 0 | 0 | 660 | 880 | 1045 |
| 1 | 1 | 1 | 0 | 1 | 665 | 886 | 1052 |
| 1 | 1 | 1 | 1 | 0 | 670 | 893 | 1060 |
| 1 | 1 | 1 | 1 | 1 | 675 | 900 | 1068 |