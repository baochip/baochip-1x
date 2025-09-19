UDMA_SDIO
=========

Register Listing for UDMA_SDIO
------------------------------

+----------------------------------------------------------------+------------------------------------------------+
| Register                                                       | Address                                        |
+================================================================+================================================+
| :ref:`UDMA_SDIO_REG_RX_SADDR <UDMA_SDIO_REG_RX_SADDR>`         | :ref:`0x5010d000 <UDMA_SDIO_REG_RX_SADDR>`     |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RX_SIZE <UDMA_SDIO_REG_RX_SIZE>`           | :ref:`0x5010d004 <UDMA_SDIO_REG_RX_SIZE>`      |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RX_CFG <UDMA_SDIO_REG_RX_CFG>`             | :ref:`0x5010d008 <UDMA_SDIO_REG_RX_CFG>`       |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_TX_SADDR <UDMA_SDIO_REG_TX_SADDR>`         | :ref:`0x5010d010 <UDMA_SDIO_REG_TX_SADDR>`     |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_TX_SIZE <UDMA_SDIO_REG_TX_SIZE>`           | :ref:`0x5010d014 <UDMA_SDIO_REG_TX_SIZE>`      |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_TX_CFG <UDMA_SDIO_REG_TX_CFG>`             | :ref:`0x5010d018 <UDMA_SDIO_REG_TX_CFG>`       |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_CMD_OP <UDMA_SDIO_REG_CMD_OP>`             | :ref:`0x5010d020 <UDMA_SDIO_REG_CMD_OP>`       |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_DATA_SETUP <UDMA_SDIO_REG_DATA_SETUP>`     | :ref:`0x5010d028 <UDMA_SDIO_REG_DATA_SETUP>`   |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_START <UDMA_SDIO_REG_START>`               | :ref:`0x5010d02c <UDMA_SDIO_REG_START>`        |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RSP0 <UDMA_SDIO_REG_RSP0>`                 | :ref:`0x5010d030 <UDMA_SDIO_REG_RSP0>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RSP1 <UDMA_SDIO_REG_RSP1>`                 | :ref:`0x5010d034 <UDMA_SDIO_REG_RSP1>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RSP2 <UDMA_SDIO_REG_RSP2>`                 | :ref:`0x5010d038 <UDMA_SDIO_REG_RSP2>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_RSP3 <UDMA_SDIO_REG_RSP3>`                 | :ref:`0x5010d03c <UDMA_SDIO_REG_RSP3>`         |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_CLK_DIV <UDMA_SDIO_REG_CLK_DIV>`           | :ref:`0x5010d040 <UDMA_SDIO_REG_CLK_DIV>`      |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_STATUS <UDMA_SDIO_REG_STATUS>`             | :ref:`0x5010d044 <UDMA_SDIO_REG_STATUS>`       |
+----------------------------------------------------------------+------------------------------------------------+
| :ref:`UDMA_SDIO_REG_DATA_TIMEOUT <UDMA_SDIO_REG_DATA_TIMEOUT>` | :ref:`0x5010d048 <UDMA_SDIO_REG_DATA_TIMEOUT>` |
+----------------------------------------------------------------+------------------------------------------------+

UDMA_SDIO_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x0 = 0x5010d000`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RX_SADDR

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

UDMA_SDIO_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x4 = 0x5010d004`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RX_SIZE

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

UDMA_SDIO_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x8 = 0x5010d008`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RX_CFG

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

UDMA_SDIO_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x10 = 0x5010d010`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_TX_SADDR

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

UDMA_SDIO_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x14 = 0x5010d014`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_TX_SIZE

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

UDMA_SDIO_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x18 = 0x5010d018`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_TX_CFG

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

UDMA_SDIO_REG_CMD_OP
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x20 = 0x5010d020`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_CMD_OP

        {
            "reg": [
                {"name": "r_cmd_rsp_type",  "bits": 3},
                {"bits": 5},
                {"name": "r_cmd_op",  "bits": 6},
                {"bits": 2},
                {"name": "r_cmd_stopopt",  "bits": 2},
                {"bits": 14}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+----------------+----------------+
| Field   | Name           | Description    |
+=========+================+================+
| [2:0]   | R_CMD_RSP_TYPE | r_cmd_rsp_type |
+---------+----------------+----------------+
| [13:8]  | R_CMD_OP       | r_cmd_op       |
+---------+----------------+----------------+
| [17:16] | R_CMD_STOPOPT  | r_cmd_stopopt  |
+---------+----------------+----------------+

UDMA_SDIO_REG_DATA_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x28 = 0x5010d028`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_DATA_SETUP

        {
            "reg": [
                {"name": "r_data_en",  "bits": 1},
                {"name": "r_data_rwn",  "bits": 1},
                {"name": "r_data_quad",  "bits": 1},
                {"bits": 5},
                {"name": "r_data_block_num",  "bits": 8},
                {"name": "r_data_block_size",  "bits": 10},
                {"bits": 6}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+-------------------+-------------------+
| Field   | Name              | Description       |
+=========+===================+===================+
| [0]     | R_DATA_EN         | r_data_en         |
+---------+-------------------+-------------------+
| [1]     | R_DATA_RWN        | r_data_rwn        |
+---------+-------------------+-------------------+
| [2]     | R_DATA_QUAD       | r_data_quad       |
+---------+-------------------+-------------------+
| [15:8]  | R_DATA_BLOCK_NUM  | r_data_block_num  |
+---------+-------------------+-------------------+
| [25:16] | R_DATA_BLOCK_SIZE | r_data_block_size |
+---------+-------------------+-------------------+

UDMA_SDIO_REG_START
^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x2c = 0x5010d02c`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_START

        {
            "reg": [
                {"name": "r_sdio_start",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+--------------+
| Field | Name         | Description  |
+=======+==============+==============+
| [0]   | R_SDIO_START | r_sdio_start |
+-------+--------------+--------------+

UDMA_SDIO_REG_RSP0
^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x30 = 0x5010d030`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RSP0

        {
            "reg": [
                {"name": "cfg_rsp_data_i_31_0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------------------+---------------------+
| Field  | Name                | Description         |
+========+=====================+=====================+
| [31:0] | CFG_RSP_DATA_I_31_0 | cfg_rsp_data_i_31_0 |
+--------+---------------------+---------------------+

UDMA_SDIO_REG_RSP1
^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x34 = 0x5010d034`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RSP1

        {
            "reg": [
                {"name": "cfg_rsp_data_i_63_32",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------------+----------------------+
| Field  | Name                 | Description          |
+========+======================+======================+
| [31:0] | CFG_RSP_DATA_I_63_32 | cfg_rsp_data_i_63_32 |
+--------+----------------------+----------------------+

UDMA_SDIO_REG_RSP2
^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x38 = 0x5010d038`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RSP2

        {
            "reg": [
                {"name": "cfg_rsp_data_i_95_64",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------------+----------------------+
| Field  | Name                 | Description          |
+========+======================+======================+
| [31:0] | CFG_RSP_DATA_I_95_64 | cfg_rsp_data_i_95_64 |
+--------+----------------------+----------------------+

UDMA_SDIO_REG_RSP3
^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x3c = 0x5010d03c`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_RSP3

        {
            "reg": [
                {"name": "cfg_rsp_data_i_127_96",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------------------+-----------------------+
| Field  | Name                  | Description           |
+========+=======================+=======================+
| [31:0] | CFG_RSP_DATA_I_127_96 | cfg_rsp_data_i_127_96 |
+--------+-----------------------+-----------------------+

UDMA_SDIO_REG_CLK_DIV
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x40 = 0x5010d040`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_CLK_DIV

        {
            "reg": [
                {"name": "r_clk_div_data",  "bits": 8},
                {"name": "r_clk_div_valid",  "bits": 1},
                {"bits": 23}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [7:0] | R_CLK_DIV_DATA  | r_clk_div_data  |
+-------+-----------------+-----------------+
| [8]   | R_CLK_DIV_VALID | r_clk_div_valid |
+-------+-----------------+-----------------+

UDMA_SDIO_REG_STATUS
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x44 = 0x5010d044`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_STATUS

        {
            "reg": [
                {"name": "r_eot",  "bits": 1},
                {"name": "r_err",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------+-------------+
| Field | Name  | Description |
+=======+=======+=============+
| [0]   | R_EOT | r_eot       |
+-------+-------+-------------+
| [1]   | R_ERR | r_err       |
+-------+-------+-------------+

UDMA_SDIO_REG_DATA_TIMEOUT
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010d000 + 0x48 = 0x5010d048`

    See `udma_sdio_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ip
    s/udma/udma_sdio/rtl/udma_sdio_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_SDIO_REG_DATA_TIMEOUT

        {
            "reg": [
                {"name": "r_data_timeout",  "bits": 20},
                {"bits": 12}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+----------------+
| Field  | Name           | Description    |
+========+================+================+
| [19:0] | R_DATA_TIMEOUT | r_data_timeout |
+--------+----------------+----------------+

