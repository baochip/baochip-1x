QFC
===

Register Listing for QFC
------------------------

+----------------------------------------------------------+---------------------------------------------+
| Register                                                 | Address                                     |
+==========================================================+=============================================+
| :ref:`QFC_SFR_IO <QFC_SFR_IO>`                           | :ref:`0x40010000 <QFC_SFR_IO>`              |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_SFR_AR <QFC_SFR_AR>`                           | :ref:`0x40010004 <QFC_SFR_AR>`              |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_SFR_IODRV <QFC_SFR_IODRV>`                     | :ref:`0x40010008 <QFC_SFR_IODRV>`           |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_ADDRMODE <QFC_CR_XIP_ADDRMODE>`         | :ref:`0x40010010 <QFC_CR_XIP_ADDRMODE>`     |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_OPCODE <QFC_CR_XIP_OPCODE>`             | :ref:`0x40010014 <QFC_CR_XIP_OPCODE>`       |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_WIDTH <QFC_CR_XIP_WIDTH>`               | :ref:`0x40010018 <QFC_CR_XIP_WIDTH>`        |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_SSEL <QFC_CR_XIP_SSEL>`                 | :ref:`0x4001001c <QFC_CR_XIP_SSEL>`         |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_DUMCYC <QFC_CR_XIP_DUMCYC>`             | :ref:`0x40010020 <QFC_CR_XIP_DUMCYC>`       |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_XIP_CFG <QFC_CR_XIP_CFG>`                   | :ref:`0x40010024 <QFC_CR_XIP_CFG>`          |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_AESKEY_AESKEYIN0 <QFC_CR_AESKEY_AESKEYIN0>` | :ref:`0x40010040 <QFC_CR_AESKEY_AESKEYIN0>` |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_AESKEY_AESKEYIN1 <QFC_CR_AESKEY_AESKEYIN1>` | :ref:`0x40010044 <QFC_CR_AESKEY_AESKEYIN1>` |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_AESKEY_AESKEYIN2 <QFC_CR_AESKEY_AESKEYIN2>` | :ref:`0x40010048 <QFC_CR_AESKEY_AESKEYIN2>` |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_AESKEY_AESKEYIN3 <QFC_CR_AESKEY_AESKEYIN3>` | :ref:`0x4001004c <QFC_CR_AESKEY_AESKEYIN3>` |
+----------------------------------------------------------+---------------------------------------------+
| :ref:`QFC_CR_AESENA <QFC_CR_AESENA>`                     | :ref:`0x40010050 <QFC_CR_AESENA>`           |
+----------------------------------------------------------+---------------------------------------------+

QFC_SFR_IO
^^^^^^^^^^

`Address: 0x40010000 + 0x0 = 0x40010000`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_SFR_IO

        {
            "reg": [
                {"name": "sfr_io",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+--------+------------------------------------+
| Field | Name   | Description                        |
+=======+========+====================================+
| [7:0] | SFR_IO | sfr_io read/write control register |
+-------+--------+------------------------------------+

QFC_SFR_AR
^^^^^^^^^^

`Address: 0x40010000 + 0x4 = 0x40010004`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_SFR_AR

        {
            "reg": [
                {"name": "sfr_ar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+------------------------------------------------+
| Field  | Name   | Description                                    |
+========+========+================================================+
| [31:0] | SFR_AR | sfr_ar performs action on write of value: 0x5a |
+--------+--------+------------------------------------------------+

QFC_SFR_IODRV
^^^^^^^^^^^^^

`Address: 0x40010000 + 0x8 = 0x40010008`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_SFR_IODRV

        {
            "reg": [
                {"name": "paddrvsel",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [11:0] | PADDRVSEL | paddrvsel read/write control register |
+--------+-----------+---------------------------------------+

QFC_CR_XIP_ADDRMODE
^^^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x10 = 0x40010010`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_ADDRMODE

        {
            "reg": [
                {"name": "cr_xip_addrmode",  "bits": 2},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+---------------------------------------------+
| Field | Name            | Description                                 |
+=======+=================+=============================================+
| [1:0] | CR_XIP_ADDRMODE | cr_xip_addrmode read/write control register |
+-------+-----------------+---------------------------------------------+

QFC_CR_XIP_OPCODE
^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x14 = 0x40010014`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_OPCODE

        {
            "reg": [
                {"name": "cr_xip_opcode",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [31:0] | CR_XIP_OPCODE | cr_xip_opcode read/write control register |
+--------+---------------+-------------------------------------------+

QFC_CR_XIP_WIDTH
^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x18 = 0x40010018`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_WIDTH

        {
            "reg": [
                {"name": "cr_xip_width",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+------------------------------------------+
| Field | Name         | Description                              |
+=======+==============+==========================================+
| [5:0] | CR_XIP_WIDTH | cr_xip_width read/write control register |
+-------+--------------+------------------------------------------+

QFC_CR_XIP_SSEL
^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x1c = 0x4001001c`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_SSEL

        {
            "reg": [
                {"name": "cr_xip_ssel",  "bits": 7},
                {"bits": 25}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [6:0] | CR_XIP_SSEL | cr_xip_ssel read/write control register |
+-------+-------------+-----------------------------------------+

QFC_CR_XIP_DUMCYC
^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x20 = 0x40010020`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_DUMCYC

        {
            "reg": [
                {"name": "cr_xip_dumcyc",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [15:0] | CR_XIP_DUMCYC | cr_xip_dumcyc read/write control register |
+--------+---------------+-------------------------------------------+

QFC_CR_XIP_CFG
^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x24 = 0x40010024`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_XIP_CFG

        {
            "reg": [
                {"name": "cr_xip_cfg",  "bits": 15},
                {"bits": 17}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+----------------------------------------+
| Field  | Name       | Description                            |
+========+============+========================================+
| [14:0] | CR_XIP_CFG | cr_xip_cfg read/write control register |
+--------+------------+----------------------------------------+

QFC_CR_AESKEY_AESKEYIN0
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x40 = 0x40010040`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_AESKEY_AESKEYIN0

        {
            "reg": [
                {"name": "aeskeyin0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | AESKEYIN0 | cr_aeskey read/write control register |
+--------+-----------+---------------------------------------+

QFC_CR_AESKEY_AESKEYIN1
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x44 = 0x40010044`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_AESKEY_AESKEYIN1

        {
            "reg": [
                {"name": "aeskeyin1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | AESKEYIN1 | cr_aeskey read/write control register |
+--------+-----------+---------------------------------------+

QFC_CR_AESKEY_AESKEYIN2
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x48 = 0x40010048`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_AESKEY_AESKEYIN2

        {
            "reg": [
                {"name": "aeskeyin2",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | AESKEYIN2 | cr_aeskey read/write control register |
+--------+-----------+---------------------------------------+

QFC_CR_AESKEY_AESKEYIN3
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40010000 + 0x4c = 0x4001004c`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_AESKEY_AESKEYIN3

        {
            "reg": [
                {"name": "aeskeyin3",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | AESKEYIN3 | cr_aeskey read/write control register |
+--------+-----------+---------------------------------------+

QFC_CR_AESENA
^^^^^^^^^^^^^

`Address: 0x40010000 + 0x50 = 0x40010050`

    See file:///F:/code/cram-nto/../../modules/core/rtl/qfc.sv

    .. wavedrom::
        :caption: QFC_CR_AESENA

        {
            "reg": [
                {"name": "cr_aesena",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [0]   | CR_AESENA | cr_aesena read/write control register |
+-------+-----------+---------------------------------------+

