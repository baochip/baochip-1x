UDMA_SPIM_3
===========

Register Listing for UDMA_SPIM_3
--------------------------------

+--------------------------------------------------------------+-----------------------------------------------+
| Register                                                     | Address                                       |
+==============================================================+===============================================+
| :ref:`UDMA_SPIM_3_REG_RX_SADDR <UDMA_SPIM_3_REG_RX_SADDR>`   | :ref:`0x50108000 <UDMA_SPIM_3_REG_RX_SADDR>`  |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_RX_SIZE <UDMA_SPIM_3_REG_RX_SIZE>`     | :ref:`0x50108004 <UDMA_SPIM_3_REG_RX_SIZE>`   |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_RX_CFG <UDMA_SPIM_3_REG_RX_CFG>`       | :ref:`0x50108008 <UDMA_SPIM_3_REG_RX_CFG>`    |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_TX_SADDR <UDMA_SPIM_3_REG_TX_SADDR>`   | :ref:`0x50108010 <UDMA_SPIM_3_REG_TX_SADDR>`  |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_TX_SIZE <UDMA_SPIM_3_REG_TX_SIZE>`     | :ref:`0x50108014 <UDMA_SPIM_3_REG_TX_SIZE>`   |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_TX_CFG <UDMA_SPIM_3_REG_TX_CFG>`       | :ref:`0x50108018 <UDMA_SPIM_3_REG_TX_CFG>`    |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_CMD_SADDR <UDMA_SPIM_3_REG_CMD_SADDR>` | :ref:`0x50108020 <UDMA_SPIM_3_REG_CMD_SADDR>` |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_CMD_SIZE <UDMA_SPIM_3_REG_CMD_SIZE>`   | :ref:`0x50108024 <UDMA_SPIM_3_REG_CMD_SIZE>`  |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_CMD_CFG <UDMA_SPIM_3_REG_CMD_CFG>`     | :ref:`0x50108028 <UDMA_SPIM_3_REG_CMD_CFG>`   |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`UDMA_SPIM_3_REG_STATUS <UDMA_SPIM_3_REG_STATUS>`       | :ref:`0x50108030 <UDMA_SPIM_3_REG_STATUS>`    |
+--------------------------------------------------------------+-----------------------------------------------+

UDMA_SPIM_3_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x0 = 0x50108000`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_RX_SADDR

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

UDMA_SPIM_3_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x4 = 0x50108004`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_RX_SIZE

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

UDMA_SPIM_3_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x8 = 0x50108008`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"name": "r_rx_datasize",  "bits": 2},
                {"bits": 1},
                {"name": "r_rx_en",  "bits": 1},
                {"bits": 1},
                {"name": "r_rx_clr",  "bits": 1},
                {"name": "r_rx_backpressure",  "bits": 1},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------------+-------------------+
| Field | Name              | Description       |
+=======+===================+===================+
| [0]   | R_RX_CONTINUOUS   | r_rx_continuous   |
+-------+-------------------+-------------------+
| [2:1] | R_RX_DATASIZE     | r_rx_datasize     |
+-------+-------------------+-------------------+
| [4]   | R_RX_EN           | r_rx_en           |
+-------+-------------------+-------------------+
| [6]   | R_RX_CLR          | r_rx_clr          |
+-------+-------------------+-------------------+
| [7]   | R_RX_BACKPRESSURE | r_rx_backpressure |
+-------+-------------------+-------------------+

UDMA_SPIM_3_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x10 = 0x50108010`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_TX_SADDR

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

UDMA_SPIM_3_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x14 = 0x50108014`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_TX_SIZE

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

UDMA_SPIM_3_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x18 = 0x50108018`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_TX_CFG

        {
            "reg": [
                {"name": "r_tx_continuous",  "bits": 1},
                {"name": "r_tx_datasize",  "bits": 2},
                {"bits": 1},
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
| [2:1] | R_TX_DATASIZE   | r_tx_datasize   |
+-------+-----------------+-----------------+
| [4]   | R_TX_EN         | r_tx_en         |
+-------+-----------------+-----------------+
| [6]   | R_TX_CLR        | r_tx_clr        |
+-------+-----------------+-----------------+

UDMA_SPIM_3_REG_CMD_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x20 = 0x50108020`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_CMD_SADDR

        {
            "reg": [
                {"name": "r_cmd_startaddr",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------------+-----------------+
| Field  | Name            | Description     |
+========+=================+=================+
| [11:0] | R_CMD_STARTADDR | r_cmd_startaddr |
+--------+-----------------+-----------------+

UDMA_SPIM_3_REG_CMD_SIZE
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x24 = 0x50108024`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_CMD_SIZE

        {
            "reg": [
                {"name": "r_cmd_size",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+-------------+
| Field  | Name       | Description |
+========+============+=============+
| [15:0] | R_CMD_SIZE | r_cmd_size  |
+--------+------------+-------------+

UDMA_SPIM_3_REG_CMD_CFG
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x28 = 0x50108028`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_CMD_CFG

        {
            "reg": [
                {"name": "r_cmd_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_cmd_en",  "bits": 1},
                {"bits": 1},
                {"name": "r_cmd_clr",  "bits": 1},
                {"bits": 25}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------------+------------------+
| Field | Name             | Description      |
+=======+==================+==================+
| [0]   | R_CMD_CONTINUOUS | r_cmd_continuous |
+-------+------------------+------------------+
| [4]   | R_CMD_EN         | r_cmd_en         |
+-------+------------------+------------------+
| [6]   | R_CMD_CLR        | r_cmd_clr        |
+-------+------------------+------------------+

UDMA_SPIM_3_REG_STATUS
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50108000 + 0x30 = 0x50108030`

    See `udma_spim_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_qspi/rtl/udma_spim_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SPIM_3_REG_STATUS

        {
            "reg": [
                {"name": "status_i",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------+-------------+
| Field | Name     | Description |
+=======+==========+=============+
| [0]   | STATUS_I | status_i    |
+-------+----------+-------------+

