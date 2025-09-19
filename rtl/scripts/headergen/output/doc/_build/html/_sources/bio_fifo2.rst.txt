BIO_FIFO2
=========

Register Listing for BIO_FIFO2
------------------------------

+----------------------------------------------------------------+------------------------------------------------+
| Register                                                       | Address                                        |
+================================================================+================================================+
| :ref:`BIO_FIFO2_SFR_FLEVEL <BIO_FIFO2_SFR_FLEVEL>`             | :ref:`0x5012b00c <BIO_FIFO2_SFR_FLEVEL>`       |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`BIO_FIFO2_SFR_TXF2 <BIO_FIFO2_SFR_TXF2>`                 | :ref:`0x5012b018 <BIO_FIFO2_SFR_TXF2>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`BIO_FIFO2_SFR_RXF2 <BIO_FIFO2_SFR_RXF2>`                 | :ref:`0x5012b028 <BIO_FIFO2_SFR_RXF2>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`BIO_FIFO2_SFR_EVENT_SET <BIO_FIFO2_SFR_EVENT_SET>`       | :ref:`0x5012b038 <BIO_FIFO2_SFR_EVENT_SET>`    |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`BIO_FIFO2_SFR_EVENT_CLR <BIO_FIFO2_SFR_EVENT_CLR>`       | :ref:`0x5012b03c <BIO_FIFO2_SFR_EVENT_CLR>`    |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`BIO_FIFO2_SFR_EVENT_STATUS <BIO_FIFO2_SFR_EVENT_STATUS>` | :ref:`0x5012b040 <BIO_FIFO2_SFR_EVENT_STATUS>` |
+----------------------------------------------------------------+------------------------------------------------+

BIO_FIFO2_SFR_FLEVEL
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0xc = 0x5012b00c`

    See `bio_bdma.sv#L492 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L492>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_FLEVEL

        {
            "reg": [
                {"name": "pclk_regfifo_level0",  "bits": 4},
                {"name": "pclk_regfifo_level1",  "bits": 4},
                {"name": "pclk_regfifo_level2",  "bits": 4},
                {"name": "pclk_regfifo_level3",  "bits": 4},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+---------------------+-------------------------------------------------+
| Field   | Name                | Description                                     |
+=========+=====================+=================================================+
| [3:0]   | PCLK_REGFIFO_LEVEL0 | pclk_regfifo_level[0] read only status register |
+---------+---------------------+-------------------------------------------------+
| [7:4]   | PCLK_REGFIFO_LEVEL1 | pclk_regfifo_level[1] read only status register |
+---------+---------------------+-------------------------------------------------+
| [11:8]  | PCLK_REGFIFO_LEVEL2 | pclk_regfifo_level[2] read only status register |
+---------+---------------------+-------------------------------------------------+
| [15:12] | PCLK_REGFIFO_LEVEL3 | pclk_regfifo_level[3] read only status register |
+---------+---------------------+-------------------------------------------------+

BIO_FIFO2_SFR_TXF2
^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0x18 = 0x5012b018`

    See `bio_bdma.sv#L495 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L495>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_TXF2

        {
            "reg": [
                {"name": "fdin",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------+----------------------------------+
| Field  | Name | Description                      |
+========+======+==================================+
| [31:0] | FDIN | fdin read/write control register |
+--------+------+----------------------------------+

BIO_FIFO2_SFR_RXF2
^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0x28 = 0x5012b028`

    See `bio_bdma.sv#L499 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L499>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_RXF2

        {
            "reg": [
                {"name": "fdout",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------+---------------------------------+
| Field  | Name  | Description                     |
+========+=======+=================================+
| [31:0] | FDOUT | fdout read only status register |
+--------+-------+---------------------------------+

BIO_FIFO2_SFR_EVENT_SET
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0x38 = 0x5012b038`

    See `bio_bdma.sv#L504 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L504>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_EVENT_SET

        {
            "reg": [
                {"name": "sfr_event_set",  "bits": 24},
                {"bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [23:0] | SFR_EVENT_SET | sfr_event_set read/write control register |
+--------+---------------+-------------------------------------------+

BIO_FIFO2_SFR_EVENT_CLR
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0x3c = 0x5012b03c`

    See `bio_bdma.sv#L505 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L505>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_EVENT_CLR

        {
            "reg": [
                {"name": "sfr_event_clr",  "bits": 24},
                {"bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------+-------------------------------------------+
| Field  | Name          | Description                               |
+========+===============+===========================================+
| [23:0] | SFR_EVENT_CLR | sfr_event_clr read/write control register |
+--------+---------------+-------------------------------------------+

BIO_FIFO2_SFR_EVENT_STATUS
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5012b000 + 0x40 = 0x5012b040`

    See `bio_bdma.sv#L506 <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/bio_bdma/rtl/bio_bdma.sv#L506>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: BIO_FIFO2_SFR_EVENT_STATUS

        {
            "reg": [
                {"name": "sfr_event_status",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------------+--------------------------------------------+
| Field  | Name             | Description                                |
+========+==================+============================================+
| [31:0] | SFR_EVENT_STATUS | sfr_event_status read only status register |
+--------+------------------+--------------------------------------------+

