SENSORC
=======

Register Listing for SENSORC
----------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`SENSORC_SFR_VDMASK0 <SENSORC_SFR_VDMASK0>`                 | :ref:`0x40053000 <SENSORC_SFR_VDMASK0>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDMASK1 <SENSORC_SFR_VDMASK1>`                 | :ref:`0x40053004 <SENSORC_SFR_VDMASK1>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDSR <SENSORC_SFR_VDSR>`                       | :ref:`0x40053008 <SENSORC_SFR_VDSR>`            |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDFR <SENSORC_SFR_VDFR>`                       | :ref:`0x4005300c <SENSORC_SFR_VDFR>`            |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_LDMASK <SENSORC_SFR_LDMASK>`                   | :ref:`0x40053010 <SENSORC_SFR_LDMASK>`          |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_LDSR <SENSORC_SFR_LDSR>`                       | :ref:`0x40053014 <SENSORC_SFR_LDSR>`            |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_LDCFG <SENSORC_SFR_LDCFG>`                     | :ref:`0x40053018 <SENSORC_SFR_LDCFG>`           |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG0 <SENSORC_SFR_VDCFG_CR_VDCFG0>` | :ref:`0x40053020 <SENSORC_SFR_VDCFG_CR_VDCFG0>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG1 <SENSORC_SFR_VDCFG_CR_VDCFG1>` | :ref:`0x40053024 <SENSORC_SFR_VDCFG_CR_VDCFG1>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG2 <SENSORC_SFR_VDCFG_CR_VDCFG2>` | :ref:`0x40053028 <SENSORC_SFR_VDCFG_CR_VDCFG2>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG3 <SENSORC_SFR_VDCFG_CR_VDCFG3>` | :ref:`0x4005302c <SENSORC_SFR_VDCFG_CR_VDCFG3>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG4 <SENSORC_SFR_VDCFG_CR_VDCFG4>` | :ref:`0x40053030 <SENSORC_SFR_VDCFG_CR_VDCFG4>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG5 <SENSORC_SFR_VDCFG_CR_VDCFG5>` | :ref:`0x40053034 <SENSORC_SFR_VDCFG_CR_VDCFG5>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG6 <SENSORC_SFR_VDCFG_CR_VDCFG6>` | :ref:`0x40053038 <SENSORC_SFR_VDCFG_CR_VDCFG6>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDCFG_CR_VDCFG7 <SENSORC_SFR_VDCFG_CR_VDCFG7>` | :ref:`0x4005303c <SENSORC_SFR_VDCFG_CR_VDCFG7>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDIP_ENA <SENSORC_SFR_VDIP_ENA>`               | :ref:`0x40053040 <SENSORC_SFR_VDIP_ENA>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_VDIP_TEST <SENSORC_SFR_VDIP_TEST>`             | :ref:`0x40053044 <SENSORC_SFR_VDIP_TEST>`       |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_LDIP_TEST <SENSORC_SFR_LDIP_TEST>`             | :ref:`0x40053048 <SENSORC_SFR_LDIP_TEST>`       |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SENSORC_SFR_LDIP_FD <SENSORC_SFR_LDIP_FD>`                 | :ref:`0x4005304c <SENSORC_SFR_LDIP_FD>`         |
+------------------------------------------------------------------+-------------------------------------------------+

SENSORC_SFR_VDMASK0
^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x0 = 0x40053000`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDMASK0

        {
            "reg": [
                {"name": "cr_vdmask0",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | CR_VDMASK0 | cr_vdmask0 read/write control register |
+-------+------------+----------------------------------------+

SENSORC_SFR_VDMASK1
^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x4 = 0x40053004`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDMASK1

        {
            "reg": [
                {"name": "cr_vdmask1",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | CR_VDMASK1 | cr_vdmask1 read/write control register |
+-------+------------+----------------------------------------+

SENSORC_SFR_VDSR
^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x8 = 0x40053008`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDSR

        {
            "reg": [
                {"name": "vdflag",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+--------+----------------------------------+
| Field | Name   | Description                      |
+=======+========+==================================+
| [7:0] | VDFLAG | vdflag read only status register |
+-------+--------+----------------------------------+

SENSORC_SFR_VDFR
^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0xc = 0x4005300c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDFR

        {
            "reg": [
                {"name": "vdflag",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+--------+----------------------------------------------------------------------------------+
| Field | Name   | Description                                                                      |
+=======+========+==================================================================================+
| [7:0] | VDFLAG | vdflag flag register. `1` means event happened, write back `1` in respective bit |
|       |        | position to clear the flag                                                       |
+-------+--------+----------------------------------------------------------------------------------+

SENSORC_SFR_LDMASK
^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x10 = 0x40053010`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_LDMASK

        {
            "reg": [
                {"name": "cr_ldmask",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [3:0] | CR_LDMASK | cr_ldmask read/write control register |
+-------+-----------+---------------------------------------+

SENSORC_SFR_LDSR
^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x14 = 0x40053014`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_LDSR

        {
            "reg": [
                {"name": "sr_ldsr",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+---------+-----------------------------------+
| Field | Name    | Description                       |
+=======+=========+===================================+
| [3:0] | SR_LDSR | sr_ldsr read only status register |
+-------+---------+-----------------------------------+

SENSORC_SFR_LDCFG
^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x18 = 0x40053018`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_LDCFG

        {
            "reg": [
                {"name": "sfr_ldcfg",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [3:0] | SFR_LDCFG | sfr_ldcfg read/write control register |
+-------+-----------+---------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG0
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x20 = 0x40053020`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG0

        {
            "reg": [
                {"name": "cr_vdcfg0",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG0 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG1
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x24 = 0x40053024`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG1

        {
            "reg": [
                {"name": "cr_vdcfg1",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG1 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG2
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x28 = 0x40053028`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG2

        {
            "reg": [
                {"name": "cr_vdcfg2",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG2 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG3
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x2c = 0x4005302c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG3

        {
            "reg": [
                {"name": "cr_vdcfg3",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG3 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG4
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x30 = 0x40053030`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG4

        {
            "reg": [
                {"name": "cr_vdcfg4",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG4 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG5
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x34 = 0x40053034`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG5

        {
            "reg": [
                {"name": "cr_vdcfg5",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG5 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG6
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x38 = 0x40053038`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG6

        {
            "reg": [
                {"name": "cr_vdcfg6",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG6 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDCFG_CR_VDCFG7
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x3c = 0x4005303c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDCFG_CR_VDCFG7

        {
            "reg": [
                {"name": "cr_vdcfg7",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+--------------------------------------+
| Field | Name      | Description                          |
+=======+===========+======================================+
| [3:0] | CR_VDCFG7 | cr_vdcfg read/write control register |
+-------+-----------+--------------------------------------+

SENSORC_SFR_VDIP_ENA
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x40 = 0x40053040`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDIP_ENA

        {
            "reg": [
                {"name": "vdena",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------+-----------------------------------+
| Field | Name  | Description                       |
+=======+=======+===================================+
| [5:0] | VDENA | vdena read/write control register |
+-------+-------+-----------------------------------+

SENSORC_SFR_VDIP_TEST
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x44 = 0x40053044`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_VDIP_TEST

        {
            "reg": [
                {"name": "vdtst",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-------+-----------------------------------+
| Field | Name  | Description                       |
+=======+=======+===================================+
| [7:0] | VDTST | vdtst read/write control register |
+-------+-------+-----------------------------------+

SENSORC_SFR_LDIP_TEST
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x48 = 0x40053048`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_LDIP_TEST

        {
            "reg": [
                {"name": "ldtst",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------+-----------------------------------+
| Field | Name  | Description                       |
+=======+=======+===================================+
| [3:0] | LDTST | ldtst read/write control register |
+-------+-------+-----------------------------------+

SENSORC_SFR_LDIP_FD
^^^^^^^^^^^^^^^^^^^

`Address: 0x40053000 + 0x4c = 0x4005304c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/sensorc.sv

    .. wavedrom::
        :caption: SENSORC_SFR_LDIP_FD

        {
            "reg": [
                {"name": "sfr_ldip_fd",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+-----------------------------------------+
| Field  | Name        | Description                             |
+========+=============+=========================================+
| [15:0] | SFR_LDIP_FD | sfr_ldip_fd read/write control register |
+--------+-------------+-----------------------------------------+

