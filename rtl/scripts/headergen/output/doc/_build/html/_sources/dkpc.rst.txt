DKPC
====

Register Listing for DKPC
-------------------------

+--------------------------------------+-----------------------------------+
| Register                             | Address                           |
+======================================+===================================+
| :ref:`DKPC_SFR_CFG0 <DKPC_SFR_CFG0>` | :ref:`0x40064000 <DKPC_SFR_CFG0>` |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_CFG1 <DKPC_SFR_CFG1>` | :ref:`0x40064004 <DKPC_SFR_CFG1>` |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_CFG2 <DKPC_SFR_CFG2>` | :ref:`0x40064008 <DKPC_SFR_CFG2>` |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_CFG3 <DKPC_SFR_CFG3>` | :ref:`0x4006400c <DKPC_SFR_CFG3>` |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_SR0 <DKPC_SFR_SR0>`   | :ref:`0x40064010 <DKPC_SFR_SR0>`  |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_SR1 <DKPC_SFR_SR1>`   | :ref:`0x40064014 <DKPC_SFR_SR1>`  |
+--------------------------------------+-----------------------------------+
| :ref:`DKPC_SFR_CFG4 <DKPC_SFR_CFG4>` | :ref:`0x40064030 <DKPC_SFR_CFG4>` |
+--------------------------------------+-----------------------------------+

DKPC_SFR_CFG0
^^^^^^^^^^^^^

`Address: 0x40064000 + 0x0 = 0x40064000`

    See `dkpc.sv#L167 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L167>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_CFG0

        {
            "reg": [
                {"name": "KPOPO0",  "bits": 1},
                {"name": "KPOPO1",  "bits": 1},
                {"name": "KPOOE0",  "bits": 1},
                {"name": "KPOOE1",  "bits": 1},
                {"name": "dkpcen",  "bits": 1},
                {"name": "autosleepen",  "bits": 1},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [0]   | KPOPO0      | KPOPO0 read/write control register      |
+-------+-------------+-----------------------------------------+
| [1]   | KPOPO1      | KPOPO1 read/write control register      |
+-------+-------------+-----------------------------------------+
| [2]   | KPOOE0      | KPOOE0 read/write control register      |
+-------+-------------+-----------------------------------------+
| [3]   | KPOOE1      | KPOOE1 read/write control register      |
+-------+-------------+-----------------------------------------+
| [4]   | DKPCEN      | dkpcen read/write control register      |
+-------+-------------+-----------------------------------------+
| [5]   | AUTOSLEEPEN | autosleepen read/write control register |
+-------+-------------+-----------------------------------------+

DKPC_SFR_CFG1
^^^^^^^^^^^^^

`Address: 0x40064000 + 0x4 = 0x40064004`

    See `dkpc.sv#L168 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L168>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_CFG1

        {
            "reg": [
                {"name": "cfg_step",  "bits": 8},
                {"name": "cfg_filter",  "bits": 8},
                {"name": "cfg_cnt1ms",  "bits": 8},
                {"bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+---------+------------+----------------------------------------+
| Field   | Name       | Description                            |
+=========+============+========================================+
| [7:0]   | CFG_STEP   | cfg_step read/write control register   |
+---------+------------+----------------------------------------+
| [15:8]  | CFG_FILTER | cfg_filter read/write control register |
+---------+------------+----------------------------------------+
| [23:16] | CFG_CNT1MS | cfg_cnt1ms read/write control register |
+---------+------------+----------------------------------------+

DKPC_SFR_CFG2
^^^^^^^^^^^^^

`Address: 0x40064000 + 0x8 = 0x40064008`

    See `dkpc.sv#L169 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L169>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_CFG2

        {
            "reg": [
                {"name": "cfg_cnt",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-------------------------------------+
| Field  | Name    | Description                         |
+========+=========+=====================================+
| [31:0] | CFG_CNT | cfg_cnt read/write control register |
+--------+---------+-------------------------------------+

DKPC_SFR_CFG3
^^^^^^^^^^^^^

`Address: 0x40064000 + 0xc = 0x4006400c`

    See `dkpc.sv#L170 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L170>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_CFG3

        {
            "reg": [
                {"name": "kpnoderiseen",  "bits": 1},
                {"name": "kpnodefallen",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+------------------------------------------+
| Field | Name         | Description                              |
+=======+==============+==========================================+
| [0]   | KPNODERISEEN | kpnoderiseen read/write control register |
+-------+--------------+------------------------------------------+
| [1]   | KPNODEFALLEN | kpnodefallen read/write control register |
+-------+--------------+------------------------------------------+

DKPC_SFR_SR0
^^^^^^^^^^^^

`Address: 0x40064000 + 0x10 = 0x40064010`

    See `dkpc.sv#L173 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L173>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_SR0

        {
            "reg": [
                {"name": "kpnodereg",  "bits": 1},
                {"name": "kpi0_pi",  "bits": 1},
                {"name": "kpi1_pi",  "bits": 1},
                {"name": "kpi2_pi",  "bits": 1},
                {"name": "kpi3_pi",  "bits": 1},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+-------------------------------------+
| Field | Name      | Description                         |
+=======+===========+=====================================+
| [0]   | KPNODEREG | kpnodereg read only status register |
+-------+-----------+-------------------------------------+
| [1]   | KPI0_PI   | kpi[0].pi read only status register |
+-------+-----------+-------------------------------------+
| [2]   | KPI1_PI   | kpi[1].pi read only status register |
+-------+-----------+-------------------------------------+
| [3]   | KPI2_PI   | kpi[2].pi read only status register |
+-------+-----------+-------------------------------------+
| [4]   | KPI3_PI   | kpi[3].pi read only status register |
+-------+-----------+-------------------------------------+

DKPC_SFR_SR1
^^^^^^^^^^^^

`Address: 0x40064000 + 0x14 = 0x40064014`

    See `dkpc.sv#L174 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L174>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_SR1

        {
            "reg": [
                {"name": "sfr_sr1",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+---------+-----------------------------------+
| Field | Name    | Description                       |
+=======+=========+===================================+
| [0]   | SFR_SR1 | sfr_sr1 read only status register |
+-------+---------+-----------------------------------+

DKPC_SFR_CFG4
^^^^^^^^^^^^^

`Address: 0x40064000 + 0x30 = 0x40064030`

    See `dkpc.sv#L171 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/a
    o/rtl/dkpc.sv#L171>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: DKPC_SFR_CFG4

        {
            "reg": [
                {"name": "sfr_cfg4",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------+
| Field  | Name     | Description                          |
+========+==========+======================================+
| [15:0] | SFR_CFG4 | sfr_cfg4 read/write control register |
+--------+----------+--------------------------------------+

