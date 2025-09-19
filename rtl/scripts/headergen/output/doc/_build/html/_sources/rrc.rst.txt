RRC
===

Register Listing for RRC
------------------------

+------------------------------------------------+----------------------------------------+
| Register                                       | Address                                |
+================================================+========================================+
| :ref:`RRC_SFR_RRCCR <RRC_SFR_RRCCR>`           | :ref:`0x40000000 <RRC_SFR_RRCCR>`      |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCFD <RRC_SFR_RRCFD>`           | :ref:`0x40000004 <RRC_SFR_RRCFD>`      |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR <RRC_SFR_RRCSR>`           | :ref:`0x40000008 <RRC_SFR_RRCSR>`      |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCFR <RRC_SFR_RRCFR>`           | :ref:`0x4000000c <RRC_SFR_RRCFR>`      |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_SET0 <RRC_SFR_RRCSR_SET0>` | :ref:`0x40000014 <RRC_SFR_RRCSR_SET0>` |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_SET1 <RRC_SFR_RRCSR_SET1>` | :ref:`0x40000018 <RRC_SFR_RRCSR_SET1>` |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_RST0 <RRC_SFR_RRCSR_RST0>` | :ref:`0x4000001c <RRC_SFR_RRCSR_RST0>` |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_RST1 <RRC_SFR_RRCSR_RST1>` | :ref:`0x40000020 <RRC_SFR_RRCSR_RST1>` |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_RD0 <RRC_SFR_RRCSR_RD0>`   | :ref:`0x40000024 <RRC_SFR_RRCSR_RD0>`  |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCSR_RD1 <RRC_SFR_RRCSR_RD1>`   | :ref:`0x40000028 <RRC_SFR_RRCSR_RD1>`  |
+------------------------------------------------+----------------------------------------+
| :ref:`RRC_SFR_RRCAR <RRC_SFR_RRCAR>`           | :ref:`0x400000f0 <RRC_SFR_RRCAR>`      |
+------------------------------------------------+----------------------------------------+

RRC_SFR_RRCCR
^^^^^^^^^^^^^

`Address: 0x40000000 + 0x0 = 0x40000000`

    See `rrc.sv#L261 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L261>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCCR

        {
            "reg": [
                {"name": "sfr_rrccr",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | SFR_RRCCR | sfr_rrccr read/write control register |
+--------+-----------+---------------------------------------+

RRC_SFR_RRCFD
^^^^^^^^^^^^^

`Address: 0x40000000 + 0x4 = 0x40000004`

    See `rrc.sv#L262 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L262>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCFD

        {
            "reg": [
                {"name": "sfr_rrcfd",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [4:0] | SFR_RRCFD | sfr_rrcfd read/write control register |
+-------+-----------+---------------------------------------+

RRC_SFR_RRCSR
^^^^^^^^^^^^^

`Address: 0x40000000 + 0x8 = 0x40000008`

    See `rrc.sv#L263 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L263>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR

        {
            "reg": [
                {"name": "sfr_rrcsr",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-----------+-------------------------------------+
| Field | Name      | Description                         |
+=======+===========+=====================================+
| [9:0] | SFR_RRCSR | sfr_rrcsr read only status register |
+-------+-----------+-------------------------------------+

RRC_SFR_RRCFR
^^^^^^^^^^^^^

`Address: 0x40000000 + 0xc = 0x4000000c`

    See `rrc.sv#L264 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L264>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCFR

        {
            "reg": [
                {"name": "sfr_rrcfr",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------------------------------------------------+
| Field | Name      | Description                                                                     |
+=======+===========+=================================================================================+
| [4:0] | SFR_RRCFR | sfr_rrcfr flag register. `1` means event happened, write back `1` in respective |
|       |           | bit position to clear the flag                                                  |
+-------+-----------+---------------------------------------------------------------------------------+

RRC_SFR_RRCSR_SET0
^^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x14 = 0x40000014`

    See `rrc.sv#L266 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L266>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_SET0

        {
            "reg": [
                {"name": "trc_set_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------------+-------------------------------------------+
| Field  | Name            | Description                               |
+========+=================+===========================================+
| [31:0] | TRC_SET_FAILURE | trc_set_failure read only status register |
+--------+-----------------+-------------------------------------------+

RRC_SFR_RRCSR_SET1
^^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x18 = 0x40000018`

    See `rrc.sv#L267 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L267>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_SET1

        {
            "reg": [
                {"name": "trc_set_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------------+-------------------------------------------+
| Field  | Name            | Description                               |
+========+=================+===========================================+
| [31:0] | TRC_SET_FAILURE | trc_set_failure read only status register |
+--------+-----------------+-------------------------------------------+

RRC_SFR_RRCSR_RST0
^^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x1c = 0x4000001c`

    See `rrc.sv#L268 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L268>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_RST0

        {
            "reg": [
                {"name": "trc_reset_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------------+---------------------------------------------+
| Field  | Name              | Description                                 |
+========+===================+=============================================+
| [31:0] | TRC_RESET_FAILURE | trc_reset_failure read only status register |
+--------+-------------------+---------------------------------------------+

RRC_SFR_RRCSR_RST1
^^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x20 = 0x40000020`

    See `rrc.sv#L269 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L269>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_RST1

        {
            "reg": [
                {"name": "trc_reset_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------------+---------------------------------------------+
| Field  | Name              | Description                                 |
+========+===================+=============================================+
| [31:0] | TRC_RESET_FAILURE | trc_reset_failure read only status register |
+--------+-------------------+---------------------------------------------+

RRC_SFR_RRCSR_RD0
^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x24 = 0x40000024`

    See `rrc.sv#L270 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L270>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_RD0

        {
            "reg": [
                {"name": "trc_fourth_read_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------------------+---------------------------------------------------+
| Field  | Name                    | Description                                       |
+========+=========================+===================================================+
| [31:0] | TRC_FOURTH_READ_FAILURE | trc_fourth_read_failure read only status register |
+--------+-------------------------+---------------------------------------------------+

RRC_SFR_RRCSR_RD1
^^^^^^^^^^^^^^^^^

`Address: 0x40000000 + 0x28 = 0x40000028`

    See `rrc.sv#L271 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L271>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCSR_RD1

        {
            "reg": [
                {"name": "trc_fourth_read_failure",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------------------+---------------------------------------------------+
| Field  | Name                    | Description                                       |
+========+=========================+===================================================+
| [31:0] | TRC_FOURTH_READ_FAILURE | trc_fourth_read_failure read only status register |
+--------+-------------------------+---------------------------------------------------+

RRC_SFR_RRCAR
^^^^^^^^^^^^^

`Address: 0x40000000 + 0xf0 = 0x400000f0`

    See `rrc.sv#L273 <https://github.com/baochip/baochip-1x/blob/main/rtl/modules/rr
    c/rtl/rrc.sv#L273>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RRC_SFR_RRCAR

        {
            "reg": [
                {"name": "sfr_rrcar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-----------------------------------------------------+
| Field  | Name      | Description                                         |
+========+===========+=====================================================+
| [31:0] | SFR_RRCAR | sfr_rrcar performs action on write of value: 0x2468 |
+--------+-----------+-----------------------------------------------------+

