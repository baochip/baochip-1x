SCEDMA
======

Register Listing for SCEDMA
---------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`SCEDMA_SFR_SCHSTART_AR <SCEDMA_SFR_SCHSTART_AR>`           | :ref:`0x40029000 <SCEDMA_SFR_SCHSTART_AR>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_FUNC <SCEDMA_SFR_XCH_FUNC>`                 | :ref:`0x40029010 <SCEDMA_SFR_XCH_FUNC>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_OPT <SCEDMA_SFR_XCH_OPT>`                   | :ref:`0x40029014 <SCEDMA_SFR_XCH_OPT>`          |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_AXSTART <SCEDMA_SFR_XCH_AXSTART>`           | :ref:`0x40029018 <SCEDMA_SFR_XCH_AXSTART>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_SEGID <SCEDMA_SFR_XCH_SEGID>`               | :ref:`0x4002901c <SCEDMA_SFR_XCH_SEGID>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_SEGSTART <SCEDMA_SFR_XCH_SEGSTART>`         | :ref:`0x40029020 <SCEDMA_SFR_XCH_SEGSTART>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_XCH_TRANSIZE <SCEDMA_SFR_XCH_TRANSIZE>`         | :ref:`0x40029024 <SCEDMA_SFR_XCH_TRANSIZE>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_FUNC <SCEDMA_SFR_SCH_FUNC>`                 | :ref:`0x40029030 <SCEDMA_SFR_SCH_FUNC>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_OPT <SCEDMA_SFR_SCH_OPT>`                   | :ref:`0x40029034 <SCEDMA_SFR_SCH_OPT>`          |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_AXSTART <SCEDMA_SFR_SCH_AXSTART>`           | :ref:`0x40029038 <SCEDMA_SFR_SCH_AXSTART>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_SEGID <SCEDMA_SFR_SCH_SEGID>`               | :ref:`0x4002903c <SCEDMA_SFR_SCH_SEGID>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_SEGSTART <SCEDMA_SFR_SCH_SEGSTART>`         | :ref:`0x40029040 <SCEDMA_SFR_SCH_SEGSTART>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_SCH_TRANSIZE <SCEDMA_SFR_SCH_TRANSIZE>`         | :ref:`0x40029044 <SCEDMA_SFR_SCH_TRANSIZE>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_ICH_OPT <SCEDMA_SFR_ICH_OPT>`                   | :ref:`0x40029050 <SCEDMA_SFR_ICH_OPT>`          |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_ICH_SEGID <SCEDMA_SFR_ICH_SEGID>`               | :ref:`0x40029054 <SCEDMA_SFR_ICH_SEGID>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_ICH_RPSTART <SCEDMA_SFR_ICH_RPSTART>`           | :ref:`0x40029058 <SCEDMA_SFR_ICH_RPSTART>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_ICH_WPSTART <SCEDMA_SFR_ICH_WPSTART>`           | :ref:`0x4002905c <SCEDMA_SFR_ICH_WPSTART>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_ICH_TRANSIZE <SCEDMA_SFR_ICH_TRANSIZE>`         | :ref:`0x40029060 <SCEDMA_SFR_ICH_TRANSIZE>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_WDATABYPASS_MODE <SCEDMA_SFR_WDATABYPASS_MODE>` | :ref:`0x40029070 <SCEDMA_SFR_WDATABYPASS_MODE>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCEDMA_SFR_WDATABYPASS_DATA <SCEDMA_SFR_WDATABYPASS_DATA>` | :ref:`0x40029074 <SCEDMA_SFR_WDATABYPASS_DATA>` |
+------------------------------------------------------------------+-------------------------------------------------+

SCEDMA_SFR_SCHSTART_AR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x0 = 0x40029000`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCHSTART_AR

        {
            "reg": [
                {"name": "sfr_schstart_ar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------------+---------------------------------------------------------+
| Field  | Name            | Description                                             |
+========+=================+=========================================================+
| [31:0] | SFR_SCHSTART_AR | sfr_schstart_ar performs action on write of value: 0xaa |
+--------+-----------------+---------------------------------------------------------+

SCEDMA_SFR_XCH_FUNC
^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x10 = 0x40029010`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_FUNC

        {
            "reg": [
                {"name": "xchcr_func",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [0]   | XCHCR_FUNC | xchcr_func read/write control register |
+-------+------------+----------------------------------------+

SCEDMA_SFR_XCH_OPT
^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x14 = 0x40029014`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_OPT

        {
            "reg": [
                {"name": "xchcr_opt",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [9:0] | XCHCR_OPT | xchcr_opt read/write control register |
+-------+-----------+---------------------------------------+

SCEDMA_SFR_XCH_AXSTART
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x18 = 0x40029018`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_AXSTART

        {
            "reg": [
                {"name": "xchcr_axstart",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [31:0] | XCHCR_AXSTART | xchcr_axstart read/write control register |
+--------+---------------+-------------------------------------------+

SCEDMA_SFR_XCH_SEGID
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x1c = 0x4002901c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_SEGID

        {
            "reg": [
                {"name": "xchcr_segid",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [7:0] | XCHCR_SEGID | xchcr_segid read/write control register |
+-------+-------------+-----------------------------------------+

SCEDMA_SFR_XCH_SEGSTART
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x20 = 0x40029020`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_SEGSTART

        {
            "reg": [
                {"name": "xchcr_segstart",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [11:0] | XCHCR_SEGSTART | xchcr_segstart read/write control register |
+--------+----------------+--------------------------------------------+

SCEDMA_SFR_XCH_TRANSIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x24 = 0x40029024`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_XCH_TRANSIZE

        {
            "reg": [
                {"name": "xchcr_transize",  "bits": 30},
                {"bits": 2}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [29:0] | XCHCR_TRANSIZE | xchcr_transize read/write control register |
+--------+----------------+--------------------------------------------+

SCEDMA_SFR_SCH_FUNC
^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x30 = 0x40029030`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_FUNC

        {
            "reg": [
                {"name": "schcr_func",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [0]   | SCHCR_FUNC | schcr_func read/write control register |
+-------+------------+----------------------------------------+

SCEDMA_SFR_SCH_OPT
^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x34 = 0x40029034`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_OPT

        {
            "reg": [
                {"name": "schcr_opt",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [9:0] | SCHCR_OPT | schcr_opt read/write control register |
+-------+-----------+---------------------------------------+

SCEDMA_SFR_SCH_AXSTART
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x38 = 0x40029038`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_AXSTART

        {
            "reg": [
                {"name": "schcr_axstart",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [31:0] | SCHCR_AXSTART | schcr_axstart read/write control register |
+--------+---------------+-------------------------------------------+

SCEDMA_SFR_SCH_SEGID
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x3c = 0x4002903c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_SEGID

        {
            "reg": [
                {"name": "schcr_segid",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [7:0] | SCHCR_SEGID | schcr_segid read/write control register |
+-------+-------------+-----------------------------------------+

SCEDMA_SFR_SCH_SEGSTART
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x40 = 0x40029040`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_SEGSTART

        {
            "reg": [
                {"name": "schcr_segstart",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [11:0] | SCHCR_SEGSTART | schcr_segstart read/write control register |
+--------+----------------+--------------------------------------------+

SCEDMA_SFR_SCH_TRANSIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x44 = 0x40029044`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_SCH_TRANSIZE

        {
            "reg": [
                {"name": "schcr_transize",  "bits": 30},
                {"bits": 2}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [29:0] | SCHCR_TRANSIZE | schcr_transize read/write control register |
+--------+----------------+--------------------------------------------+

SCEDMA_SFR_ICH_OPT
^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x50 = 0x40029050`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_ICH_OPT

        {
            "reg": [
                {"name": "sfr_ich_opt",  "bits": 4},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [3:0] | SFR_ICH_OPT | sfr_ich_opt read/write control register |
+-------+-------------+-----------------------------------------+

SCEDMA_SFR_ICH_SEGID
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x54 = 0x40029054`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_ICH_SEGID

        {
            "reg": [
                {"name": "sfr_ich_segid",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [15:0] | SFR_ICH_SEGID | sfr_ich_segid read/write control register |
+--------+---------------+-------------------------------------------+

SCEDMA_SFR_ICH_RPSTART
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x58 = 0x40029058`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_ICH_RPSTART

        {
            "reg": [
                {"name": "ichcr_rpstart",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [11:0] | ICHCR_RPSTART | ichcr_rpstart read/write control register |
+--------+---------------+-------------------------------------------+

SCEDMA_SFR_ICH_WPSTART
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x5c = 0x4002905c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_ICH_WPSTART

        {
            "reg": [
                {"name": "ichcr_wpstart",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [11:0] | ICHCR_WPSTART | ichcr_wpstart read/write control register |
+--------+---------------+-------------------------------------------+

SCEDMA_SFR_ICH_TRANSIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x60 = 0x40029060`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_ICH_TRANSIZE

        {
            "reg": [
                {"name": "ichcr_transize",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [11:0] | ICHCR_TRANSIZE | ichcr_transize read/write control register |
+--------+----------------+--------------------------------------------+

SCEDMA_SFR_WDATABYPASS_MODE
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x70 = 0x40029070`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_WDATABYPASS_MODE

        {
            "reg": [
                {"name": "sfr_wdatabypass_mode",  "bits": 2},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------------------+--------------------------------------------------+
| Field | Name                 | Description                                      |
+=======+======================+==================================================+
| [1:0] | SFR_WDATABYPASS_MODE | sfr_wdatabypass_mode read/write control register |
+-------+----------------------+--------------------------------------------------+

SCEDMA_SFR_WDATABYPASS_DATA
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40029000 + 0x74 = 0x40029074`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/scedma.sv

    .. wavedrom::
        :caption: SCEDMA_SFR_WDATABYPASS_DATA

        {
            "reg": [
                {"name": "sfr_wdatabypass_data",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------------+--------------------------------------------------+
| Field  | Name                 | Description                                      |
+========+======================+==================================================+
| [31:0] | SFR_WDATABYPASS_DATA | sfr_wdatabypass_data read/write control register |
+--------+----------------------+--------------------------------------------------+

