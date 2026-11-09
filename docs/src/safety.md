# Safety Function

## Active Protection Module (MESH)

### MESH Introduction

To enhance the chip's resistance to attacks, particularly invasive attacks (such as decapsulation), the chip incorporates an active protective layer detection functionality known as MESH. The MESH module features a metal protective grid positioned on the top layer of the chip, designed to prevent modifications to the chip's logic and counteract invasive attacks. When the MESH module detects external physical tampering, it can trigger protective measures such as interrupt alerts or system resets, thereby ensuring robust protection for the chip.

### MESH Main Features

- Attack detection:
  - Real-time monitoring of Mesh sensor integrity under attack
  - Parity bit configuration in critical registers to detect laser fault injection attacks
- 64 mesh lines
- 64 active points input enables for each line
- CPU-controlled interface for adjusting Mesh line voltage levels
- Status registers enabling the CPU to query Mesh line attack status
- Hardware-based Mesh detection: in hardware detection mode, Mesh integrity checks are immediately triggered upon wakeup from DeepSleep state.

### MESHC Registers

Base address: `0x4005_2000`

| Register Name | Offset | Size  | Type | Access | Default    | Description                          |
|---------------|--------|-------|------|--------|------------|--------------------------------------|
| CR_MLDRV      | 0x0000 | 64    | CR   | R/W    | 0x00000000 | Mesh line control                    |
| CR_MLIE       | 0x0010 | 64    | CR   | R/W    | 0x00000000 | Mesh line - active point input enable |
| SR_MLSR       | 0x0020 | 32×8  | SR   | R/W    | 0x00000000 | Mesh line error                      |

#### CR_MLDRV — Mesh Line Control Register

- **Address offset:** `0x0000`
- **Reset value:** `0x0000_0000`

| Bits    | Field             | Description           |
|---------|-------------------|-------------------------|
| [61:0]  | Mesh line control | Mesh line control     |

#### CR_MLIE — Mesh Line Input Enable Control Register

- **Address offset:** `0x0010`
- **Reset value:** `0x0000_0000`

| Bits    | Field         | Description                              |
|---------|---------------|--------------------------------------------|
| [61:0]  | Mesh line ie  | Mesh line - active point input enable    |

#### SR_MLSR — Mesh Line Error Register

- **Address offset:** `0x0020`–`0x003C`
- **Reset value:** `0x0000_0000`

| Bits    | Field            | Description          |
|---------|------------------|------------------------|
| [31:0]  | Mesh line error  | Mesh line error      |

Each register covers a group of 8 active points (8 ap/group).

## Safety Environment Control Unit (SEC)

### SEC Introduction

The SEC module is primarily responsible for:

- External crystal oscillator frequency monitoring
- High/low voltage detection
- Optical sensing attack detection (e.g., laser fault injection)
- Temperature monitoring
- Voltage Regulator (VR) integrity checks
- Power-On Reset (POR) validation
- Light detection
- Glue logic validation

These functions counteract tampering attempts, notify the CPU of the system's real-time status, and initiate protective resets or interrupt signals when threats are detected.

### SENSORC Registers

Base address: `0x4005_3000`

| Register Name | Offset     | Size | Type | Access | Default    | Description        |
|---------------|------------|------|------|--------|------------|--------------------|
| CR_VDMASK0    | 0x0000     | 32   | CR   | R/W    | 0x0000003F | Voltage detection  |
| CR_VDMASK1    | 0x0004     | 32   | CR   | R/W    | 0x0000003F |                    |
| CR_VDSR       | 0x0008     | 32   | CR   | R/W    | 0x00000000 |                    |
| CR_LDMASK     | 0x0010     | 32   | SR   | R/W    | 0x00000000 | Light detection    |
| CR_LDSR       | 0x0014     | 32   | CR   | R/W    | 0x00000000 |                    |
| CR_LDCFG      | 0x0018     | 32   | CR   | R/W    | 0x00000000 |                    |
| CR_VDCFGx     | 0x0020–0x003C | 32 | CR   | R/W    | 0x00000000 |                    |
| CR_VDENA      | 0x0040     | 32   | CR   | R/W    | 0x0000000F |                    |
| CR_VDTST      | 0x0044     | 32   | CR   | R/W    | 0x00000000 |                    |
| CR_LDTST      | 0x0048     | 32   | CR   | R/W    | 0x00000000 |                    |
| CR_LDFD       | 0x004C     | 32   | CR   | R/W    | 0x000001FF |                    |

#### CR_VDMASK0 — Voltage Detection Mask Register 0

- **Address offset:** `0x0000`
- **Reset value:** `0x0000_003F`

| Bits   | Field        | Description     |
|--------|--------------|--------------------|
| [5:0]  | cr_vdmask0   | Voltage detect mask 0 |

#### CR_VDMASK1 — Voltage Detection Mask Register 1

- **Address offset:** `0x0004`
- **Reset value:** `0x0000_003F`

| Bits   | Field        | Description     |
|--------|--------------|--------------------|
| [5:0]  | cr_vdmask1   | Voltage detect mask 1 |

#### CR_VDSR — Voltage Detection Status Register

- **Address offset:** `0x0008`
- **Reset value:** `0x0000_0000`

| Bits   | Field      | Description          |
|--------|------------|--------------------------|
| [5:0]  | cr_vdsr    | Voltage detect status  |

#### CR_LDMASK — Light Detection Mask Register

- **Address offset:** `0x0010`
- **Reset value:** `0x0000_0000`

| Bits   | Field        | Description                              |
|--------|--------------|----------------------------------------------|
| [1:0]  | cr_ldmask    | Light detection mask: `0` = enable, `1` = masked/disable |

#### CR_LDSR — Light Detection Status Register

- **Address offset:** `0x0014`
- **Reset value:** `0x0000_0000`

| Bits   | Field      | Description                |
|--------|------------|--------------------------------|
| [1:0]  | cr_ldsr    | Light detection status       |

#### CR_LDCFG — Light Detection Configuration Register

- **Address offset:** `0x0018`
- **Reset value:** `0x0000_0000`

| Bits   | Field       | Description                    |
|--------|-------------|------------------------------------|
| [1:0]  | cr_ldcfg    | Light detection configuration    |

#### CR_VDCFGx — Voltage Detection Configuration Registers

- **Address offset:** `0x0020 + X×4` (x = 0–7)
- **Reset value:** `0x0000_0000`

| Bits   | Field       | Description                   |
|--------|-------------|-----------------------------------|
| [5:0]  | cr_vdcfg    | Voltage detection configuration |

#### CR_VDENA — Voltage Detection Enable Register

- **Address offset:** `0x0040`
- **Reset value:** `0x0000_000F`

| Bits   | Field       | Description                 |
|--------|-------------|---------------------------------|
| [4:0]  | cr_vdena    | Voltage detection enable      |

#### CR_VDTST — Voltage Detection Test Register

- **Address offset:** `0x0044`
- **Reset value:** `0x0000_0000`

| Bits   | Field       | Description                |
|--------|-------------|--------------------------------|
| [4:0]  | cr_vdtst    | Voltage detection test       |

#### CR_LDTST — Light Detection Test Register

- **Address offset:** `0x0048`
- **Reset value:** `0x0000_0000`

| Bits   | Field       | Description              |
|--------|-------------|------------------------------|
| [4:0]  | cr_ldtst    | Light detection test       |

#### CR_LDFD — Light Detection Filter Duration Register

- **Address offset:** `0x004C`
- **Reset value:** `0x0000_01FF`

| Bits    | Field      | Description                            |
|---------|------------|--------------------------------------------|
| [15:0]  | ldfd       | Light detection filter duration          |

### GLU Registers

Base address: `0x4005_4000`

| Register Name | Offset | Size | Type | Access | Default    | Description       |
|---------------|--------|------|------|--------|------------|-------------------|
| CR_GCMASK     | 0x0000 | 64   | CR   | R/W    | 0x00000000 | Gluecell mask     |
| GLUE_REG      | 0x0008 | 64   | SR   | R/W    | 0x00000000 | Gluecell register |
| GLUE_RST      | 0x0010 | 64   | CR   | R/W    | 0x00000000 | Gluecell reset    |
| GLUE_TEST     | 0x0018 | 64   | CR   | R/W    | 0x00000000 | Gluecell test     |

#### CR_GCMASK — Gluecell Mask Register

- **Address offset:** `0x0000`
- **Reset value:** `0x0000_0000`

| Bits    | Field       | Description            |
|---------|-------------|----------------------------|
| [63:0]  | cr_gcmask   | Gluecell mask            |

#### GLUE_REG — Gluecell Register

- **Address offset:** `0x0008`
- **Reset value:** `0x0000_0000`

| Bits    | Field      | Description               |
|---------|------------|-------------------------------|
| [63:0]  | glue_reg   | Gluecell register status    |

#### GLUE_RST — Gluecell Reset Register

- **Address offset:** `0x0010`
- **Reset value:** `0x0000_0000`

| Bits    | Field       | Description           |
|---------|-------------|---------------------------|
| [63:0]  | glue_rst    | Gluecell reset          |

#### GLUE_TEST — Gluecell Test Register

- **Address offset:** `0x0018`
- **Reset value:** `0x0000_0000`

| Bits    | Field        | Description          |
|---------|--------------|--------------------------|
| [63:0]  | glue_test    | Gluecell test          |

## Usage Notes

### Baochip-1x Sensor Features

#### Voltage Detector

Baochip-1x is equipped with 6 Voltage Detectors (VDs), as listed below:

| VD     | Description                                                                                   |
|--------|-----------------------------------------------------------------------------------------------|
| VDD09L | Monitors whether the voltage of internal power supply VDD85 is below the threshold; triggers an alarm if yes. |
| VDD09H | Monitors whether the voltage of internal power supply VDD85 is above the threshold; triggers an alarm if yes. |
| VDD25L | Monitors whether the voltage of internal power supply VDD25 is below the threshold; triggers an alarm if yes. |
| VDD25H | Monitors whether the voltage of internal power supply VDD25 is above the threshold; triggers an alarm if yes. |
| VDD33L | Monitors whether the voltage of external power supply VDD33 is below the threshold; triggers an alarm if yes. |
| VDD33H | Monitors whether the voltage of external power supply VDD33 is above the threshold; triggers an alarm if yes. |

Key features of Baochip-1x's built-in voltage detectors (VDs):

- 6 independent voltage sensors
- Monitors both internal and external power supplies, covering core voltages that ensure system functionality
- Independent on/off control for each VD IP to reduce power consumption
- Independent and configurable filtering for each VD to avoid false alarms caused by glitches
- Configurable interrupt output when each VD triggers an alarm
- Configurable reset trigger when each VD triggers an alarm
- Independent self-test function for each VD
- Independent real-time status bit for each VD
- Independent alarm flag bit for each VD

Summary table:

| Power | Internal / External | VD     | Threshold | On/Off | Filter Count | Int/Rst |
|-------|---------------------|--------|-----------|--------|--------------|---------|
| VDD85 | Int.                | VDD09L | 0.66V     | Cfg.   | Cfg.         | Cfg.    |
| VDD85 | Int.                | VDD09H | 1.08V     | Cfg.   | Cfg.         | Cfg.    |
| VDD25 | Int.                | VDD25L | 2.2V      | Cfg.   | Cfg.         | Cfg.    |
| VDD25 | Int.                | VDD25H | 2.82V     | Cfg.   | Cfg.         | Cfg.    |
| VDD33 | Ext.                | VDD33L | 2.5V      | Cfg.   | Cfg.         | Cfg.    |
| VDD33 | Ext.                | VDD33H | 4V        | Cfg.   | Cfg.         | Cfg.    |

#### Light Detector

Baochip-1x's internal visible light sensors have the following features:

1. Two visible light sensors for redundant backup
2. Distributed at the chip corners for better sensitivity to light changes
3. Independent on/off control for each LD to reduce power consumption
4. Independent and configurable filtering for each LD to avoid false alarms caused by glitches
5. The light detection duration is configurable
6. Independent self-test function for each LD
7. Independent real-time status bit for each LD

#### Mesh

Baochip-1x's Mesh has the following features:

1. 64 mesh lines
2. 32 active point basic units on each mesh line
3. Configurable input enable for each mesh line
4. Every 8 active points form a group, with alarm status bits for a total of 256 groups

#### Glue Chain

Baochip-1x's glue chain has the following features:

1. 64 glue chains
2. Independent on/off control for each glue chain
3. Independent status bit for each glue chain
4. Independent reset capability for each glue chain
5. Independent test value setting for each glue chain

### Baochip-1x Sensor Configuration Registers

Base address: `0x4005_0000` (security control). Register offsets below are relative to the block base address listed in each group row.

| SFR Name   | Offset Addr  | Reset Value | Type | Bitwidth  | Function Description                                    |
|------------|--------------|-------------|------|-----------|----------------------------------------------------------|
| **meshc**  | **0x2000**   |             |      |           | Mesh is 64 lines × 32 active points                     |
| cr_mldrv   | 0x000~0x004  | 0x00000000  | CR   | [31:0] ×2 | Mesh line drive value                                    |
| cr_mlie    | 0x010~0x014  | 0x00000000  | CR   | [31:0] ×2 | Mesh line - active point input enable                    |
| sr_mlsr    | 0x020~0x03C  | 0x00000000  | SR   | [31:0] ×8 | Mesh line real-time error status                         |
| **sensorc**| **0x3000**   |             |      |           | 6 VDs: VD09L, VD09H, VD25L, VD25H, VD33L, VD33H          |
| cr_vdmask0 | 0x000        | 0x0000003F  | CR   | [5:0]     | VD IRQ mask: `=0` enable; `=1` masked/disable            |
| cr_vdmask1 | 0x004        | 0x0000003F  | CR   | [5:0]     | VD reset mask: `=0` enable; `=1` masked/disable          |
| sr_vdsr    | 0x008        | 0x00000000  | SR   | [5:0]     | VD real-time error status                                |
| sfr_vdfr   | 0x00C        | 0x00000000  | FR   | [5:0]     | VD error flag, write `1` to clear                        |
| cr_vdcfg   | 0x020~0x03C  | 0x00000000  | CR   | [5:0]     | VD filter counter                                        |
| vdena      | 0x040        | 0x0000000F  | CR   | [4:0]     | VD enable                                                |
| vdtst      | 0x044        | 0x00000000  | CR   | [5:0]     | VD self-test                                             |
| **sensorc**| **0x3000**   |             |      |           | 2 LDs                                                    |
| cr_ldmask  | 0x010        | 0x00000000  | CR   | [1:0]     | LD mask: `=0` enable; `=1` masked/disable                |
| sr_ldsr    | 0x014        | 0x00000000  | SR   | [1:0]     | LD real-time error status                                |
| cr_ldcfg   | 0x018        | 0x00000000  | CR   | [3:0]     | LD filter counter                                        |
| ldtst      | 0x048        | 0x00000000  | CR   | [1:0]     | LD self-test                                             |
| ldfd       | 0x04C        | 0x000001FF  | CR   | [15:0]    | Light detection duration                                 |
| **glc**    | **0x4000**   |             |      |           | 64 glue chains                                           |
| cr_gcmask  | 0x000        | 0x00000000  | CR   | [63:0]    | Glue chain mask: `=0` enable; `=1` masked/disable        |
| gluereg    | 0x008        | 0x00000000  | SR   | [63:0]    | Glue chain value                                         |
| gluerst    | 0x010        | 0x00000000  | CR   | [63:0]    | Glue chain reset                                         |
| gluetest   | 0x018        | 0x00000000  | CR   | [63:0]    | Glue chain self-test                                     |

### Baochip-1x Sensor Programming Guide

#### Voltage Detector — Self-test

Perform a self-test on the VD when powering on to check if the function is intact. The software process is as follows:

1. Configure the VD.
2. Enable the VD self-test.
3. Enable the VD.
4. Check whether the flag bits meet the expectations.

The corresponding pseudo-code is as follows:

```text
cr_vdcfg  = 0xc;      // vd filter counter
cr_vdmask0 = 0x3f;    // irq disable
cr_vdmask1 = 0x0;     // reset disable
vdtst     = 0x3f;     // enable self-test
vdena     = 0x1f;     // enable vd
if (sr_vdsr == 0x3f)  // check status result
    sfr_vdfr == 0x3f; // clear flag
else
    return error;
```

#### Light Detector — Self-test

Perform a self-test on the LD when powering on to check if the function is intact. The software process is as follows:

1. Configure the LD.
2. Enable the LD self-test.
3. Enable the LD.
4. Check whether the flag bits meet the expectations.

The corresponding pseudo-code is as follows:

```text
cr_ldcfg  = 0xc;      // ld filter counter
ldfd      = 0x55aa;
ldtst     = 0x3;      // enable self-test
cr_ldmask = 0x0;      // enable ld
if (sr_ldsr == 0x3)   // check status result
    return ok;
else
    return error;
```

#### Mesh

1. Set the mesh active point input enable to 0.
2. Set the mesh line value.
3. Delay for 100 ms.
4. Set the mesh active point input enable to 1.
5. In case of alarm interruption, handle accordingly based on the alarm event level.

The pseudo-code is as follows:

```text
cr_mlie  = 0x0;       // disable mesh line - active point input enable
cr_mldrv = 0x55aa;    // mesh line value
delay 100ms;
cr_mlie  = 0xffff;    // mesh line - active point input enable

if (| sr_mlsr == 1)   // if error status
    suspend and record log in NVM

if ((+sr_mlsr > 1) || (| sr_mlsr == 1 and sustain 50ms in 100ms))  // error or sustain
{
    clear sensitive data in reg/ram or reset;

    if ((+ mlsr > 3) & (| sr_mlsr == 1 > 6 in 100ms))
        enter lock state or erase sensitive data in nvm or erase all data in memory;
}
else
    return;
```

#### Glue Chain — Self-test

Perform a self-test on the glue chain when powering on to check if the function is intact. The software process is as follows:

1. Reset the glue chain.
2. Configure the glue chain self-test.
3. Enable the glue chain.
4. Check whether the flag bits meet the expectations.

The corresponding pseudo-code is as follows:

```text
gluerst   = 0xffff;   // reset glue chain
gluetest  = 0xffff;   // enable self-test
cr_gcmask = 0x0;      // enable
if (gluereg == 0xffff) // check status result
    return ok;
else
    return error;
```
