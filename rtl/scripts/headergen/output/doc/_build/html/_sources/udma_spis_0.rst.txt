UDMA_SPIS_0
===========

Register Listing for UDMA_SPIS_0
--------------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`UDMA_SPIS_0_REG_RX_SADDR <UDMA_SPIS_0_REG_RX_SADDR>`       | :ref:`0x50112000 <UDMA_SPIS_0_REG_RX_SADDR>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_RX_SIZE <UDMA_SPIS_0_REG_RX_SIZE>`         | :ref:`0x50112004 <UDMA_SPIS_0_REG_RX_SIZE>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_RX_CFG <UDMA_SPIS_0_REG_RX_CFG>`           | :ref:`0x50112008 <UDMA_SPIS_0_REG_RX_CFG>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_TX_SADDR <UDMA_SPIS_0_REG_TX_SADDR>`       | :ref:`0x50112010 <UDMA_SPIS_0_REG_TX_SADDR>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_TX_SIZE <UDMA_SPIS_0_REG_TX_SIZE>`         | :ref:`0x50112014 <UDMA_SPIS_0_REG_TX_SIZE>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_TX_CFG <UDMA_SPIS_0_REG_TX_CFG>`           | :ref:`0x50112018 <UDMA_SPIS_0_REG_TX_CFG>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SPIS_SETUP <UDMA_SPIS_0_REG_SPIS_SETUP>`   | :ref:`0x50112020 <UDMA_SPIS_0_REG_SPIS_SETUP>`  |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SEOT_CNT <UDMA_SPIS_0_REG_SEOT_CNT>`       | :ref:`0x50112024 <UDMA_SPIS_0_REG_SEOT_CNT>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SPIS_IRQ_EN <UDMA_SPIS_0_REG_SPIS_IRQ_EN>` | :ref:`0x50112028 <UDMA_SPIS_0_REG_SPIS_IRQ_EN>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SPIS_RXCNT <UDMA_SPIS_0_REG_SPIS_RXCNT>`   | :ref:`0x5011202c <UDMA_SPIS_0_REG_SPIS_RXCNT>`  |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SPIS_TXCNT <UDMA_SPIS_0_REG_SPIS_TXCNT>`   | :ref:`0x50112030 <UDMA_SPIS_0_REG_SPIS_TXCNT>`  |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`UDMA_SPIS_0_REG_SPIS_DMCNT <UDMA_SPIS_0_REG_SPIS_DMCNT>`   | :ref:`0x50112034 <UDMA_SPIS_0_REG_SPIS_DMCNT>`  |
+------------------------------------------------------------------+-------------------------------------------------+

UDMA_SPIS_0_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x0 = 0x50112000`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_RX_SADDR

        {
            "reg": [
                {"name": "r_rx_startaddr",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+----------------+
| Field  | Name           | Description    |
+========+================+================+
| [11:0] | R_RX_STARTADDR | r_rx_startaddr |
+--------+----------------+----------------+

UDMA_SPIS_0_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x4 = 0x50112004`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_RX_SIZE

        {
            "reg": [
                {"name": "r_rx_size",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-------------+
| Field  | Name      | Description |
+========+===========+=============+
| [15:0] | R_RX_SIZE | r_rx_size   |
+--------+-----------+-------------+

UDMA_SPIS_0_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x8 = 0x50112008`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_rx_en",  "bits": 1},
                {"bits": 1},
                {"name": "r_rx_clr",  "bits": 1},
                {"bits": 25}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [0]   | R_RX_CONTINUOUS | r_rx_continuous |
+-------+-----------------+-----------------+
| [4]   | R_RX_EN         | r_rx_en         |
+-------+-----------------+-----------------+
| [6]   | R_RX_CLR        | r_rx_clr        |
+-------+-----------------+-----------------+

UDMA_SPIS_0_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x10 = 0x50112010`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_TX_SADDR

        {
            "reg": [
                {"name": "r_tx_startaddr",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+----------------+
| Field  | Name           | Description    |
+========+================+================+
| [11:0] | R_TX_STARTADDR | r_tx_startaddr |
+--------+----------------+----------------+

UDMA_SPIS_0_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x14 = 0x50112014`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_TX_SIZE

        {
            "reg": [
                {"name": "r_tx_size",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-------------+
| Field  | Name      | Description |
+========+===========+=============+
| [15:0] | R_TX_SIZE | r_tx_size   |
+--------+-----------+-------------+

UDMA_SPIS_0_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x18 = 0x50112018`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_TX_CFG

        {
            "reg": [
                {"name": "r_tx_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_tx_en",  "bits": 1},
                {"bits": 1},
                {"name": "r_tx_clr",  "bits": 1},
                {"bits": 25}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [0]   | R_TX_CONTINUOUS | r_tx_continuous |
+-------+-----------------+-----------------+
| [4]   | R_TX_EN         | r_tx_en         |
+-------+-----------------+-----------------+
| [6]   | R_TX_CLR        | r_tx_clr        |
+-------+-----------------+-----------------+

UDMA_SPIS_0_REG_SPIS_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x20 = 0x50112020`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SPIS_SETUP

        {
            "reg": [
                {"name": "cfgcpol",  "bits": 1},
                {"name": "cfgcpha",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+---------+-------------+
| Field | Name    | Description |
+=======+=========+=============+
| [0]   | CFGCPOL | cfgcpol     |
+-------+---------+-------------+
| [1]   | CFGCPHA | cfgcpha     |
+-------+---------+-------------+

UDMA_SPIS_0_REG_SEOT_CNT
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x24 = 0x50112024`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SEOT_CNT

        {
            "reg": [
                {"name": "sr_seot_cnt",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+-------------+
| Field  | Name        | Description |
+========+=============+=============+
| [15:0] | SR_SEOT_CNT | sr_seot_cnt |
+--------+-------------+-------------+

UDMA_SPIS_0_REG_SPIS_IRQ_EN
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x28 = 0x50112028`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SPIS_IRQ_EN

        {
            "reg": [
                {"name": "seot_irq_en",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-------------+
| Field | Name        | Description |
+=======+=============+=============+
| [0]   | SEOT_IRQ_EN | seot_irq_en |
+-------+-------------+-------------+

UDMA_SPIS_0_REG_SPIS_RXCNT
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x2c = 0x5011202c`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SPIS_RXCNT

        {
            "reg": [
                {"name": "cfgrxcnt",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------+
| Field  | Name     | Description |
+========+==========+=============+
| [15:0] | CFGRXCNT | cfgrxcnt    |
+--------+----------+-------------+

UDMA_SPIS_0_REG_SPIS_TXCNT
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x30 = 0x50112030`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SPIS_TXCNT

        {
            "reg": [
                {"name": "cfgtxcnt",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------+
| Field  | Name     | Description |
+========+==========+=============+
| [15:0] | CFGTXCNT | cfgtxcnt    |
+--------+----------+-------------+

UDMA_SPIS_0_REG_SPIS_DMCNT
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50112000 + 0x34 = 0x50112034`

    See `udma_spis_reg.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/modul
    es/ifsub/rtl/udma_spis_reg.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIS_0_REG_SPIS_DMCNT

        {
            "reg": [
                {"name": "cfgdmcnt",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------+
| Field  | Name     | Description |
+========+==========+=============+
| [15:0] | CFGDMCNT | cfgdmcnt    |
+--------+----------+-------------+

