CORESUB_SRAMTRM
===============

Register Listing for CORESUB_SRAMTRM
------------------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`CORESUB_SRAMTRM_SFR_CACHE <CORESUB_SRAMTRM_SFR_CACHE>`     | :ref:`0x40014000 <CORESUB_SRAMTRM_SFR_CACHE>`   |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_ITCM <CORESUB_SRAMTRM_SFR_ITCM>`       | :ref:`0x40014004 <CORESUB_SRAMTRM_SFR_ITCM>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_DTCM <CORESUB_SRAMTRM_SFR_DTCM>`       | :ref:`0x40014008 <CORESUB_SRAMTRM_SFR_DTCM>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_SRAM0 <CORESUB_SRAMTRM_SFR_SRAM0>`     | :ref:`0x4001400c <CORESUB_SRAMTRM_SFR_SRAM0>`   |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_SRAM1 <CORESUB_SRAMTRM_SFR_SRAM1>`     | :ref:`0x40014010 <CORESUB_SRAMTRM_SFR_SRAM1>`   |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_VEXRAM <CORESUB_SRAMTRM_SFR_VEXRAM>`   | :ref:`0x40014014 <CORESUB_SRAMTRM_SFR_VEXRAM>`  |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_SRAMERR <CORESUB_SRAMTRM_SFR_SRAMERR>` | :ref:`0x40014020 <CORESUB_SRAMTRM_SFR_SRAMERR>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`CORESUB_SRAMTRM_SFR_RAMSEC <CORESUB_SRAMTRM_SFR_RAMSEC>`   | :ref:`0x40014030 <CORESUB_SRAMTRM_SFR_RAMSEC>`  |
+------------------------------------------------------------------+-------------------------------------------------+

CORESUB_SRAMTRM_SFR_CACHE
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x0 = 0x40014000`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_CACHE

        {
            "reg": [
                {"name": "sfr_cache",  "bits": 3},
                {"bits": 29}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [2:0] | SFR_CACHE | sfr_cache read/write control register |
+-------+-----------+---------------------------------------+

CORESUB_SRAMTRM_SFR_ITCM
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x4 = 0x40014004`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_ITCM

        {
            "reg": [
                {"name": "sfr_itcm",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------+--------------------------------------+
| Field | Name     | Description                          |
+=======+==========+======================================+
| [4:0] | SFR_ITCM | sfr_itcm read/write control register |
+-------+----------+--------------------------------------+

CORESUB_SRAMTRM_SFR_DTCM
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x8 = 0x40014008`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_DTCM

        {
            "reg": [
                {"name": "sfr_dtcm",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------+--------------------------------------+
| Field | Name     | Description                          |
+=======+==========+======================================+
| [4:0] | SFR_DTCM | sfr_dtcm read/write control register |
+-------+----------+--------------------------------------+

CORESUB_SRAMTRM_SFR_SRAM0
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0xc = 0x4001400c`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_SRAM0

        {
            "reg": [
                {"name": "sfr_sram0",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [4:0] | SFR_SRAM0 | sfr_sram0 read/write control register |
+-------+-----------+---------------------------------------+

CORESUB_SRAMTRM_SFR_SRAM1
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x10 = 0x40014010`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_SRAM1

        {
            "reg": [
                {"name": "sfr_sram1",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [4:0] | SFR_SRAM1 | sfr_sram1 read/write control register |
+-------+-----------+---------------------------------------+

CORESUB_SRAMTRM_SFR_VEXRAM
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x14 = 0x40014014`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_VEXRAM

        {
            "reg": [
                {"name": "sfr_vexram",  "bits": 3},
                {"bits": 29}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [2:0] | SFR_VEXRAM | sfr_vexram read/write control register |
+-------+------------+----------------------------------------+

CORESUB_SRAMTRM_SFR_SRAMERR
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x20 = 0x40014020`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_SRAMERR

        {
            "reg": [
                {"name": "srambankerr",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+------------------------------------------------------------------------+
| Field | Name        | Description                                                            |
+=======+=============+========================================================================+
| [3:0] | SRAMBANKERR | srambankerr flag register. `1` means event happened, write back `1` in |
|       |             | respective bit position to clear the flag                              |
+-------+-------------+------------------------------------------------------------------------+

CORESUB_SRAMTRM_SFR_RAMSEC
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40014000 + 0x30 = 0x40014030`

    See file:///F:/code/cram-nto/../../modules/core/rtl/coresub_sramtrm.sv

    .. wavedrom::
        :caption: CORESUB_SRAMTRM_SFR_RAMSEC

        {
            "reg": [
                {"name": "ramsec",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+------------------------------------+
| Field | Name   | Description                        |
+=======+========+====================================+
| [3:0] | RAMSEC | ramsec read/write control register |
+-------+--------+------------------------------------+

