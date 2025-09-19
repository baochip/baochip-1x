SCE_GLBSFR
==========

Register Listing for SCE_GLBSFR
-------------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`SCE_GLBSFR_SFR_SUBEN <SCE_GLBSFR_SFR_SUBEN>`               | :ref:`0x40028004 <SCE_GLBSFR_SFR_SUBEN>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_APBS <SCE_GLBSFR_SFR_APBS>`                 | :ref:`0x40028008 <SCE_GLBSFR_SFR_APBS>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_SRBUSY <SCE_GLBSFR_SFR_SRBUSY>`             | :ref:`0x40028010 <SCE_GLBSFR_SFR_SRBUSY>`       |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FRDONE <SCE_GLBSFR_SFR_FRDONE>`             | :ref:`0x40028014 <SCE_GLBSFR_SFR_FRDONE>`       |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FRERR <SCE_GLBSFR_SFR_FRERR>`               | :ref:`0x40028018 <SCE_GLBSFR_SFR_FRERR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_ARCLR <SCE_GLBSFR_SFR_ARCLR>`               | :ref:`0x4002801c <SCE_GLBSFR_SFR_ARCLR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TICKCYC <SCE_GLBSFR_SFR_TICKCYC>`           | :ref:`0x40028020 <SCE_GLBSFR_SFR_TICKCYC>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TICKCNT <SCE_GLBSFR_SFR_TICKCNT>`           | :ref:`0x40028024 <SCE_GLBSFR_SFR_TICKCNT>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFEN <SCE_GLBSFR_SFR_FFEN>`                 | :ref:`0x40028030 <SCE_GLBSFR_SFR_FFEN>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCLR <SCE_GLBSFR_SFR_FFCLR>`               | :ref:`0x40028034 <SCE_GLBSFR_SFR_FFCLR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF0 <SCE_GLBSFR_SFR_FFCNT_SR_FF0>` | :ref:`0x40028040 <SCE_GLBSFR_SFR_FFCNT_SR_FF0>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF1 <SCE_GLBSFR_SFR_FFCNT_SR_FF1>` | :ref:`0x40028044 <SCE_GLBSFR_SFR_FFCNT_SR_FF1>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF2 <SCE_GLBSFR_SFR_FFCNT_SR_FF2>` | :ref:`0x40028048 <SCE_GLBSFR_SFR_FFCNT_SR_FF2>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF3 <SCE_GLBSFR_SFR_FFCNT_SR_FF3>` | :ref:`0x4002804c <SCE_GLBSFR_SFR_FFCNT_SR_FF3>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF4 <SCE_GLBSFR_SFR_FFCNT_SR_FF4>` | :ref:`0x40028050 <SCE_GLBSFR_SFR_FFCNT_SR_FF4>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FFCNT_SR_FF5 <SCE_GLBSFR_SFR_FFCNT_SR_FF5>` | :ref:`0x40028054 <SCE_GLBSFR_SFR_FFCNT_SR_FF5>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_FRACERR <SCE_GLBSFR_SFR_FRACERR>`           | :ref:`0x40028060 <SCE_GLBSFR_SFR_FRACERR>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TS_SR_TS0 <SCE_GLBSFR_SFR_TS_SR_TS0>`       | :ref:`0x400280e0 <SCE_GLBSFR_SFR_TS_SR_TS0>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TS_SR_TS1 <SCE_GLBSFR_SFR_TS_SR_TS1>`       | :ref:`0x400280e4 <SCE_GLBSFR_SFR_TS_SR_TS1>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TS_SR_TS2 <SCE_GLBSFR_SFR_TS_SR_TS2>`       | :ref:`0x400280e8 <SCE_GLBSFR_SFR_TS_SR_TS2>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`SCE_GLBSFR_SFR_TS_SR_TS3 <SCE_GLBSFR_SFR_TS_SR_TS3>`       | :ref:`0x400280ec <SCE_GLBSFR_SFR_TS_SR_TS3>`    |
+------------------------------------------------------------------+-------------------------------------------------+

SCE_GLBSFR_SFR_SUBEN
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x4 = 0x40028004`

    See `sce_glbsfra.sv#L76 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L76>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_SUBEN

        {
            "reg": [
                {"name": "cr_suben",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------+
| Field  | Name     | Description                          |
+========+==========+======================================+
| [15:0] | CR_SUBEN | cr_suben read/write control register |
+--------+----------+--------------------------------------+

SCE_GLBSFR_SFR_APBS
^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x8 = 0x40028008`

    See `sce_glbsfra.sv#L77 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L77>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_APBS

        {
            "reg": [
                {"name": "cr_apbsopt",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [4:0] | CR_APBSOPT | cr_apbsopt read/write control register |
+-------+------------+----------------------------------------+

SCE_GLBSFR_SFR_SRBUSY
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x10 = 0x40028010`

    See `sce_glbsfra.sv#L79 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L79>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_SRBUSY

        {
            "reg": [
                {"name": "sr_busy",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-----------------------------------+
| Field  | Name    | Description                       |
+========+=========+===================================+
| [15:0] | SR_BUSY | sr_busy read only status register |
+--------+---------+-----------------------------------+

SCE_GLBSFR_SFR_FRDONE
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x14 = 0x40028014`

    See `sce_glbsfra.sv#L80 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L80>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FRDONE

        {
            "reg": [
                {"name": "fr_done",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-------------------------------------------------------------------------------+
| Field  | Name    | Description                                                                   |
+========+=========+===============================================================================+
| [15:0] | FR_DONE | fr_done flag register. `1` means event happened, write back `1` in respective |
|        |         | bit position to clear the flag                                                |
+--------+---------+-------------------------------------------------------------------------------+

SCE_GLBSFR_SFR_FRERR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x18 = 0x40028018`

    See `sce_glbsfra.sv#L81 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L81>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FRERR

        {
            "reg": [
                {"name": "fr_err",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+----------------------------------------------------------------------------------+
| Field  | Name   | Description                                                                      |
+========+========+==================================================================================+
| [15:0] | FR_ERR | fr_err flag register. `1` means event happened, write back `1` in respective bit |
|        |        | position to clear the flag                                                       |
+--------+--------+----------------------------------------------------------------------------------+

SCE_GLBSFR_SFR_ARCLR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x1c = 0x4002801c`

    See `sce_glbsfra.sv#L84 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L84>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_ARCLR

        {
            "reg": [
                {"name": "ar_clrram",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------------------+
| Field  | Name      | Description                                       |
+========+===========+===================================================+
| [31:0] | AR_CLRRAM | ar_clrram performs action on write of value: 0xa5 |
+--------+-----------+---------------------------------------------------+

SCE_GLBSFR_SFR_TICKCYC
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x20 = 0x40028020`

    See `sce_glbsfra.sv#L116 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L116>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TICKCYC

        {
            "reg": [
                {"name": "sfr_tickcyc",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [7:0] | SFR_TICKCYC | sfr_tickcyc read/write control register |
+-------+-------------+-----------------------------------------+

SCE_GLBSFR_SFR_TICKCNT
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x24 = 0x40028024`

    See `sce_glbsfra.sv#L117 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L117>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TICKCNT

        {
            "reg": [
                {"name": "sfr_tickcnt",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+---------------------------------------+
| Field  | Name        | Description                           |
+========+=============+=======================================+
| [31:0] | SFR_TICKCNT | sfr_tickcnt read only status register |
+--------+-------------+---------------------------------------+

SCE_GLBSFR_SFR_FFEN
^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x30 = 0x40028030`

    See `sce_glbsfra.sv#L90 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L90>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFEN

        {
            "reg": [
                {"name": "cr_ffen",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+---------+-------------------------------------+
| Field | Name    | Description                         |
+=======+=========+=====================================+
| [5:0] | CR_FFEN | cr_ffen read/write control register |
+-------+---------+-------------------------------------+

SCE_GLBSFR_SFR_FFCLR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x34 = 0x40028034`

    See `sce_glbsfra.sv#L96 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L96>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCLR

        {
            "reg": [
                {"name": "ar_ffclr",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+----------------------------------------------------------+
| Field  | Name     | Description                                              |
+========+==========+==========================================================+
| [31:0] | AR_FFCLR | ar_ffclr performs action on write of value: (32'hff00+i) |
+--------+----------+----------------------------------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF0
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x40 = 0x40028040`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF0

        {
            "reg": [
                {"name": "sr_ff0",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF0 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF1
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x44 = 0x40028044`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF1

        {
            "reg": [
                {"name": "sr_ff1",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF1 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF2
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x48 = 0x40028048`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF2

        {
            "reg": [
                {"name": "sr_ff2",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF2 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF3
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x4c = 0x4002804c`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF3

        {
            "reg": [
                {"name": "sr_ff3",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF3 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF4
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x50 = 0x40028050`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF4

        {
            "reg": [
                {"name": "sr_ff4",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF4 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FFCNT_SR_FF5
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x54 = 0x40028054`

    See `sce_glbsfra.sv#L91 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L91>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FFCNT_SR_FF5

        {
            "reg": [
                {"name": "sr_ff5",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [15:0] | SR_FF5 | sr_ff read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_FRACERR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0x60 = 0x40028060`

    See `sce_glbsfra.sv#L86 <https://github.com/baochip/baochip-1x/blob/main/rtl/mod
    ules/crypto_top/rtl/sce_glbsfra.sv#L86>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_FRACERR

        {
            "reg": [
                {"name": "fr_acerr",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+----------+--------------------------------------------------------------------------------+
| Field | Name     | Description                                                                    |
+=======+==========+================================================================================+
| [7:0] | FR_ACERR | fr_acerr flag register. `1` means event happened, write back `1` in respective |
|       |          | bit position to clear the flag                                                 |
+-------+----------+--------------------------------------------------------------------------------+

SCE_GLBSFR_SFR_TS_SR_TS0
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0xe0 = 0x400280e0`

    See `sce_glbsfra.sv#L100 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L100>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TS_SR_TS0

        {
            "reg": [
                {"name": "sr_ts0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [31:0] | SR_TS0 | sr_ts read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_TS_SR_TS1
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0xe4 = 0x400280e4`

    See `sce_glbsfra.sv#L100 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L100>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TS_SR_TS1

        {
            "reg": [
                {"name": "sr_ts1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [31:0] | SR_TS1 | sr_ts read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_TS_SR_TS2
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0xe8 = 0x400280e8`

    See `sce_glbsfra.sv#L100 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L100>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TS_SR_TS2

        {
            "reg": [
                {"name": "sr_ts2",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [31:0] | SR_TS2 | sr_ts read only status register |
+--------+--------+---------------------------------+

SCE_GLBSFR_SFR_TS_SR_TS3
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40028000 + 0xec = 0x400280ec`

    See `sce_glbsfra.sv#L100 <https://github.com/baochip/baochip-1x/blob/main/rtl/mo
    dules/crypto_top/rtl/sce_glbsfra.sv#L100>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: SCE_GLBSFR_SFR_TS_SR_TS3

        {
            "reg": [
                {"name": "sr_ts3",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+---------------------------------+
| Field  | Name   | Description                     |
+========+========+=================================+
| [31:0] | SR_TS3 | sr_ts read only status register |
+--------+--------+---------------------------------+

