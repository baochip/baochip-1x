DUART
=====

Register Listing for DUART
--------------------------

+----------------------------------------+------------------------------------+
| Register                               | Address                            |
+========================================+====================================+
| :ref:`DUART_SFR_TXD <DUART_SFR_TXD>`   | :ref:`0x40042000 <DUART_SFR_TXD>`  |
+----------------------------------------+------------------------------------+
| :ref:`DUART_SFR_CR <DUART_SFR_CR>`     | :ref:`0x40042004 <DUART_SFR_CR>`   |
+----------------------------------------+------------------------------------+
| :ref:`DUART_SFR_SR <DUART_SFR_SR>`     | :ref:`0x40042008 <DUART_SFR_SR>`   |
+----------------------------------------+------------------------------------+
| :ref:`DUART_SFR_ETUC <DUART_SFR_ETUC>` | :ref:`0x4004200c <DUART_SFR_ETUC>` |
+----------------------------------------+------------------------------------+

DUART_SFR_TXD
^^^^^^^^^^^^^

`Address: 0x40042000 + 0x0 = 0x40042000`

    See file:///F:/code/cram-nto/../../modules/core/rtl/duart.sv

    .. wavedrom::
        :caption: DUART_SFR_TXD

        {
            "reg": [
                {"name": "sfr_txd",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+---------+-------------------------------------+
| Field | Name    | Description                         |
+=======+=========+=====================================+
| [7:0] | SFR_TXD | sfr_txd read/write control register |
+-------+---------+-------------------------------------+

DUART_SFR_CR
^^^^^^^^^^^^

`Address: 0x40042000 + 0x4 = 0x40042004`

    See file:///F:/code/cram-nto/../../modules/core/rtl/duart.sv

    .. wavedrom::
        :caption: DUART_SFR_CR

        {
            "reg": [
                {"name": "sfr_cr",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+------------------------------------+
| Field | Name   | Description                        |
+=======+========+====================================+
| [0]   | SFR_CR | sfr_cr read/write control register |
+-------+--------+------------------------------------+

DUART_SFR_SR
^^^^^^^^^^^^

`Address: 0x40042000 + 0x8 = 0x40042008`

    See file:///F:/code/cram-nto/../../modules/core/rtl/duart.sv

    .. wavedrom::
        :caption: DUART_SFR_SR

        {
            "reg": [
                {"name": "sfr_sr",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+----------------------------------+
| Field | Name   | Description                      |
+=======+========+==================================+
| [0]   | SFR_SR | sfr_sr read only status register |
+-------+--------+----------------------------------+

DUART_SFR_ETUC
^^^^^^^^^^^^^^

`Address: 0x40042000 + 0xc = 0x4004200c`

    See file:///F:/code/cram-nto/../../modules/core/rtl/duart.sv

    .. wavedrom::
        :caption: DUART_SFR_ETUC

        {
            "reg": [
                {"name": "sfr_etuc",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------+
| Field  | Name     | Description                          |
+========+==========+======================================+
| [15:0] | SFR_ETUC | sfr_etuc read/write control register |
+--------+----------+--------------------------------------+

