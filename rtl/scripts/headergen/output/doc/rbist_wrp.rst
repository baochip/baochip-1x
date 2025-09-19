RBIST_WRP
=========

Register Listing for RBIST_WRP
------------------------------

+--------------------------------------------------+-----------------------------------------+
| Register                                         | Address                                 |
+==================================================+=========================================+
| :ref:`RBIST_WRP_SFRCR_TRM <RBIST_WRP_SFRCR_TRM>` | :ref:`0x40045000 <RBIST_WRP_SFRCR_TRM>` |
+--------------------------------------------------+-----------------------------------------+
| :ref:`RBIST_WRP_SFRSR_TRM <RBIST_WRP_SFRSR_TRM>` | :ref:`0x40045004 <RBIST_WRP_SFRSR_TRM>` |
+--------------------------------------------------+-----------------------------------------+
| :ref:`RBIST_WRP_SFRAR_TRM <RBIST_WRP_SFRAR_TRM>` | :ref:`0x40045008 <RBIST_WRP_SFRAR_TRM>` |
+--------------------------------------------------+-----------------------------------------+

RBIST_WRP_SFRCR_TRM
^^^^^^^^^^^^^^^^^^^

`Address: 0x40045000 + 0x0 = 0x40045000`

    See `rbist_wrp.sv#L174 <https://github.com/baochip/baochip-1x/blob/main/rtl/modu
    les/rbist/rtl/rbist_wrp.sv#L174>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RBIST_WRP_SFRCR_TRM

        {
            "reg": [
                {"name": "sfrcr_trm",  "bits": 24},
                {"bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [23:0] | SFRCR_TRM | sfrcr_trm read/write control register |
+--------+-----------+---------------------------------------+

RBIST_WRP_SFRSR_TRM
^^^^^^^^^^^^^^^^^^^

`Address: 0x40045000 + 0x4 = 0x40045004`

    See `rbist_wrp.sv#L175 <https://github.com/baochip/baochip-1x/blob/main/rtl/modu
    les/rbist/rtl/rbist_wrp.sv#L175>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RBIST_WRP_SFRSR_TRM

        {
            "reg": [
                {"name": "sfrsr_trm",  "bits": 24},
                {"bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-------------------------------------+
| Field  | Name      | Description                         |
+========+===========+=====================================+
| [23:0] | SFRSR_TRM | sfrsr_trm read only status register |
+--------+-----------+-------------------------------------+

RBIST_WRP_SFRAR_TRM
^^^^^^^^^^^^^^^^^^^

`Address: 0x40045000 + 0x8 = 0x40045008`

    See `rbist_wrp.sv#L176 <https://github.com/baochip/baochip-1x/blob/main/rtl/modu
    les/rbist/rtl/rbist_wrp.sv#L176>`__ (line numbers are approximate)

    .. wavedrom::
        :caption: RBIST_WRP_SFRAR_TRM

        {
            "reg": [
                {"name": "sfrar_trm",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------------------+
| Field  | Name      | Description                                       |
+========+===========+===================================================+
| [31:0] | SFRAR_TRM | sfrar_trm performs action on write of value: 0x5a |
+--------+-----------+---------------------------------------------------+

