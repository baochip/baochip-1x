TRNG
====

Register Listing for TRNG
-------------------------

+----------------------------------------------------------------+------------------------------------------------+
| Register                                                       | Address                                        |
+================================================================+================================================+
| :ref:`TRNG_SFR_CRSRC <TRNG_SFR_CRSRC>`                         | :ref:`0x4002e000 <TRNG_SFR_CRSRC>`             |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_CRANA <TRNG_SFR_CRANA>`                         | :ref:`0x4002e004 <TRNG_SFR_CRANA>`             |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_PP <TRNG_SFR_PP>`                               | :ref:`0x4002e008 <TRNG_SFR_PP>`                |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_OPT <TRNG_SFR_OPT>`                             | :ref:`0x4002e00c <TRNG_SFR_OPT>`               |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_SR <TRNG_SFR_SR>`                               | :ref:`0x4002e010 <TRNG_SFR_SR>`                |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_AR_GEN <TRNG_SFR_AR_GEN>`                       | :ref:`0x4002e014 <TRNG_SFR_AR_GEN>`            |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_FR <TRNG_SFR_FR>`                               | :ref:`0x4002e018 <TRNG_SFR_FR>`                |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_DRPSZ <TRNG_SFR_DRPSZ>`                         | :ref:`0x4002e020 <TRNG_SFR_DRPSZ>`             |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_DRGEN <TRNG_SFR_DRGEN>`                         | :ref:`0x4002e024 <TRNG_SFR_DRGEN>`             |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_DRRESEED <TRNG_SFR_DRRESEED>`                   | :ref:`0x4002e028 <TRNG_SFR_DRRESEED>`          |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_BUF <TRNG_SFR_BUF>`                             | :ref:`0x4002e030 <TRNG_SFR_BUF>`               |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_CHAIN_RNGCHAINEN0 <TRNG_SFR_CHAIN_RNGCHAINEN0>` | :ref:`0x4002e040 <TRNG_SFR_CHAIN_RNGCHAINEN0>` |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_CHAIN_RNGCHAINEN1 <TRNG_SFR_CHAIN_RNGCHAINEN1>` | :ref:`0x4002e044 <TRNG_SFR_CHAIN_RNGCHAINEN1>` |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_CHAIN_RNGCHAINEN2 <TRNG_SFR_CHAIN_RNGCHAINEN2>` | :ref:`0x4002e048 <TRNG_SFR_CHAIN_RNGCHAINEN2>` |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`TRNG_SFR_CHAIN_RNGCHAINEN3 <TRNG_SFR_CHAIN_RNGCHAINEN3>` | :ref:`0x4002e04c <TRNG_SFR_CHAIN_RNGCHAINEN3>` |
+----------------------------------------------------------------+------------------------------------------------+

TRNG_SFR_CRSRC
^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x0 = 0x4002e000`

    See `trng.sv#L105 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L105>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CRSRC

        {
            "reg": [
                {"name": "sfr_crsrc",  "bits": 13},
                {"bits": 19}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [12:0] | SFR_CRSRC | sfr_crsrc read/write control register |
+--------+-----------+---------------------------------------+

TRNG_SFR_CRANA
^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x4 = 0x4002e004`

    See `trng.sv#L106 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L106>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CRANA

        {
            "reg": [
                {"name": "sfr_crana",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [15:0] | SFR_CRANA | sfr_crana read/write control register |
+--------+-----------+---------------------------------------+

TRNG_SFR_PP
^^^^^^^^^^^

`Address: 0x4002e000 + 0x8 = 0x4002e008`

    See `trng.sv#L107 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L107>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_PP

        {
            "reg": [
                {"name": "sfr_pp",  "bits": 17},
                {"bits": 15}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+------------------------------------+
| Field  | Name   | Description                        |
+========+========+====================================+
| [16:0] | SFR_PP | sfr_pp read/write control register |
+--------+--------+------------------------------------+

TRNG_SFR_OPT
^^^^^^^^^^^^

`Address: 0x4002e000 + 0xc = 0x4002e00c`

    See `trng.sv#L108 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L108>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_OPT

        {
            "reg": [
                {"name": "sfr_opt",  "bits": 17},
                {"bits": 15}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-------------------------------------+
| Field  | Name    | Description                         |
+========+=========+=====================================+
| [16:0] | SFR_OPT | sfr_opt read/write control register |
+--------+---------+-------------------------------------+

TRNG_SFR_SR
^^^^^^^^^^^

`Address: 0x4002e000 + 0x10 = 0x4002e010`

    See `trng.sv#L114 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L114>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_SR

        {
            "reg": [
                {"name": "sr_rng",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+----------------------------------+
| Field  | Name   | Description                      |
+========+========+==================================+
| [31:0] | SR_RNG | sr_rng read only status register |
+--------+--------+----------------------------------+

TRNG_SFR_AR_GEN
^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x14 = 0x4002e014`

    See `trng.sv#L112 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L112>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_AR_GEN

        {
            "reg": [
                {"name": "sfr_ar_gen",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+----------------------------------------------------+
| Field  | Name       | Description                                        |
+========+============+====================================================+
| [31:0] | SFR_AR_GEN | sfr_ar_gen performs action on write of value: 0x55 |
+--------+------------+----------------------------------------------------+

TRNG_SFR_FR
^^^^^^^^^^^

`Address: 0x4002e000 + 0x18 = 0x4002e018`

    See `trng.sv#L115 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L115>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_FR

        {
            "reg": [
                {"name": "sfr_fr",  "bits": 3},
                {"bits": 29}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+----------------------------------------------------------------------------------+
| Field | Name   | Description                                                                      |
+=======+========+==================================================================================+
| [2:0] | SFR_FR | sfr_fr flag register. `1` means event happened, write back `1` in respective bit |
|       |        | position to clear the flag                                                       |
+-------+--------+----------------------------------------------------------------------------------+

TRNG_SFR_DRPSZ
^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x20 = 0x4002e020`

    See `trng.sv#L239 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L239>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_DRPSZ

        {
            "reg": [
                {"name": "sfr_drpsz",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | SFR_DRPSZ | sfr_drpsz read/write control register |
+--------+-----------+---------------------------------------+

TRNG_SFR_DRGEN
^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x24 = 0x4002e024`

    See `trng.sv#L240 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L240>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_DRGEN

        {
            "reg": [
                {"name": "sfr_drgen",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | SFR_DRGEN | sfr_drgen read/write control register |
+--------+-----------+---------------------------------------+

TRNG_SFR_DRRESEED
^^^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x28 = 0x4002e028`

    See `trng.sv#L241 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L241>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_DRRESEED

        {
            "reg": [
                {"name": "sfr_drreseed",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+------------------------------------------+
| Field  | Name         | Description                              |
+========+==============+==========================================+
| [31:0] | SFR_DRRESEED | sfr_drreseed read/write control register |
+--------+--------------+------------------------------------------+

TRNG_SFR_BUF
^^^^^^^^^^^^

`Address: 0x4002e000 + 0x30 = 0x4002e030`

    See `trng.sv#L242 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L242>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_BUF

        {
            "reg": [
                {"name": "sfr_buf",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-----------------------------------+
| Field  | Name    | Description                       |
+========+=========+===================================+
| [31:0] | SFR_BUF | sfr_buf read only status register |
+--------+---------+-----------------------------------+

TRNG_SFR_CHAIN_RNGCHAINEN0
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x40 = 0x4002e040`

    See `trng.sv#L117 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L117>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CHAIN_RNGCHAINEN0

        {
            "reg": [
                {"name": "rngchainen0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+----------------------------------------+
| Field  | Name        | Description                            |
+========+=============+========================================+
| [31:0] | RNGCHAINEN0 | rngchainen read/write control register |
+--------+-------------+----------------------------------------+

TRNG_SFR_CHAIN_RNGCHAINEN1
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x44 = 0x4002e044`

    See `trng.sv#L117 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L117>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CHAIN_RNGCHAINEN1

        {
            "reg": [
                {"name": "rngchainen1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+----------------------------------------+
| Field  | Name        | Description                            |
+========+=============+========================================+
| [31:0] | RNGCHAINEN1 | rngchainen read/write control register |
+--------+-------------+----------------------------------------+

TRNG_SFR_CHAIN_RNGCHAINEN2
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x48 = 0x4002e048`

    See `trng.sv#L117 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L117>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CHAIN_RNGCHAINEN2

        {
            "reg": [
                {"name": "rngchainen2",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+----------------------------------------+
| Field  | Name        | Description                            |
+========+=============+========================================+
| [31:0] | RNGCHAINEN2 | rngchainen read/write control register |
+--------+-------------+----------------------------------------+

TRNG_SFR_CHAIN_RNGCHAINEN3
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002e000 + 0x4c = 0x4002e04c`

    See `trng.sv#L117 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/c
    rypto_top/rtl/trng.sv#L117>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: TRNG_SFR_CHAIN_RNGCHAINEN3

        {
            "reg": [
                {"name": "rngchainen3",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+----------------------------------------+
| Field  | Name        | Description                            |
+========+=============+========================================+
| [31:0] | RNGCHAINEN3 | rngchainen read/write control register |
+--------+-------------+----------------------------------------+

