UDMA_I2S
========

Register Listing for UDMA_I2S
-----------------------------

+----------------------------------------------------------------------+---------------------------------------------------+
| Register                                                             | Address                                           |
+======================================================================+===================================================+
| :ref:`UDMA_I2S_REG_RX_SADDR <UDMA_I2S_REG_RX_SADDR>`                 | :ref:`0x5010e000 <UDMA_I2S_REG_RX_SADDR>`         |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_RX_SIZE <UDMA_I2S_REG_RX_SIZE>`                   | :ref:`0x5010e004 <UDMA_I2S_REG_RX_SIZE>`          |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_RX_CFG <UDMA_I2S_REG_RX_CFG>`                     | :ref:`0x5010e008 <UDMA_I2S_REG_RX_CFG>`           |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_TX_SADDR <UDMA_I2S_REG_TX_SADDR>`                 | :ref:`0x5010e010 <UDMA_I2S_REG_TX_SADDR>`         |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_TX_SIZE <UDMA_I2S_REG_TX_SIZE>`                   | :ref:`0x5010e014 <UDMA_I2S_REG_TX_SIZE>`          |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_TX_CFG <UDMA_I2S_REG_TX_CFG>`                     | :ref:`0x5010e018 <UDMA_I2S_REG_TX_CFG>`           |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_I2S_CLKCFG_SETUP <UDMA_I2S_REG_I2S_CLKCFG_SETUP>` | :ref:`0x5010e020 <UDMA_I2S_REG_I2S_CLKCFG_SETUP>` |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_I2S_SLV_SETUP <UDMA_I2S_REG_I2S_SLV_SETUP>`       | :ref:`0x5010e024 <UDMA_I2S_REG_I2S_SLV_SETUP>`    |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_I2S_MST_SETUP <UDMA_I2S_REG_I2S_MST_SETUP>`       | :ref:`0x5010e028 <UDMA_I2S_REG_I2S_MST_SETUP>`    |
+----------------------------------------------------------------------+---------------------------------------------------+
| :ref:`UDMA_I2S_REG_I2S_PDM_SETUP <UDMA_I2S_REG_I2S_PDM_SETUP>`       | :ref:`0x5010e02c <UDMA_I2S_REG_I2S_PDM_SETUP>`    |
+----------------------------------------------------------------------+---------------------------------------------------+

UDMA_I2S_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x0 = 0x5010e000`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_RX_SADDR

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

UDMA_I2S_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x4 = 0x5010e004`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_RX_SIZE

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

UDMA_I2S_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x8 = 0x5010e008`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"name": "r_rx_datasize",  "bits": 2},
                {"bits": 1},
                {"name": "r_rx_en",  "bits": 1},
                {"name": "r_rx_clr",  "bits": 1},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [0]   | R_RX_CONTINUOUS | r_rx_continuous |
+-------+-----------------+-----------------+
| [2:1] | R_RX_DATASIZE   | r_rx_datasize   |
+-------+-----------------+-----------------+
| [4]   | R_RX_EN         | r_rx_en         |
+-------+-----------------+-----------------+
| [5]   | R_RX_CLR        | r_rx_clr        |
+-------+-----------------+-----------------+

UDMA_I2S_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x10 = 0x5010e010`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_TX_SADDR

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

UDMA_I2S_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x14 = 0x5010e014`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_TX_SIZE

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

UDMA_I2S_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x18 = 0x5010e018`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_TX_CFG

        {
            "reg": [
                {"name": "r_tx_continuous",  "bits": 1},
                {"name": "r_tx_datasize",  "bits": 2},
                {"bits": 1},
                {"name": "r_tx_en",  "bits": 1},
                {"name": "r_tx_clr",  "bits": 1},
                {"bits": 26}
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
| [5]   | R_TX_CLR        | r_tx_clr        |
+-------+-----------------+-----------------+

UDMA_I2S_REG_I2S_CLKCFG_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x20 = 0x5010e020`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_I2S_CLKCFG_SETUP

        {
            "reg": [
                {"name": "r_master_gen_clk_div",  "bits": 8},
                {"name": "r_slave_gen_clk_div",  "bits": 8},
                {"name": "r_common_gen_clk_div",  "bits": 8},
                {"name": "r_slave_clk_en",  "bits": 1},
                {"name": "r_master_clk_en",  "bits": 1},
                {"name": "r_pdm_clk_en",  "bits": 1},
                {"bits": 1},
                {"name": "r_slave_sel_ext",  "bits": 1},
                {"name": "r_slave_sel_num",  "bits": 1},
                {"name": "r_master_sel_ext",  "bits": 1},
                {"name": "r_master_sel_num",  "bits": 1}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+----------------------+----------------------+
| Field   | Name                 | Description          |
+=========+======================+======================+
| [7:0]   | R_MASTER_GEN_CLK_DIV | r_master_gen_clk_div |
+---------+----------------------+----------------------+
| [15:8]  | R_SLAVE_GEN_CLK_DIV  | r_slave_gen_clk_div  |
+---------+----------------------+----------------------+
| [23:16] | R_COMMON_GEN_CLK_DIV | r_common_gen_clk_div |
+---------+----------------------+----------------------+
| [24]    | R_SLAVE_CLK_EN       | r_slave_clk_en       |
+---------+----------------------+----------------------+
| [25]    | R_MASTER_CLK_EN      | r_master_clk_en      |
+---------+----------------------+----------------------+
| [26]    | R_PDM_CLK_EN         | r_pdm_clk_en         |
+---------+----------------------+----------------------+
| [28]    | R_SLAVE_SEL_EXT      | r_slave_sel_ext      |
+---------+----------------------+----------------------+
| [29]    | R_SLAVE_SEL_NUM      | r_slave_sel_num      |
+---------+----------------------+----------------------+
| [30]    | R_MASTER_SEL_EXT     | r_master_sel_ext     |
+---------+----------------------+----------------------+
| [31]    | R_MASTER_SEL_NUM     | r_master_sel_num     |
+---------+----------------------+----------------------+

UDMA_I2S_REG_I2S_SLV_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x24 = 0x5010e024`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_I2S_SLV_SETUP

        {
            "reg": [
                {"name": "r_slave_i2s_words",  "bits": 3},
                {"bits": 5},
                {"name": "r_slave_i2s_bits_word",  "bits": 5},
                {"bits": 3},
                {"name": "r_slave_i2s_lsb_first",  "bits": 1},
                {"name": "r_slave_i2s_2ch",  "bits": 1},
                {"bits": 13},
                {"name": "r_slave_i2s_en",  "bits": 1}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+--------+-----------------------+-----------------------+
| Field  | Name                  | Description           |
+========+=======================+=======================+
| [2:0]  | R_SLAVE_I2S_WORDS     | r_slave_i2s_words     |
+--------+-----------------------+-----------------------+
| [12:8] | R_SLAVE_I2S_BITS_WORD | r_slave_i2s_bits_word |
+--------+-----------------------+-----------------------+
| [16]   | R_SLAVE_I2S_LSB_FIRST | r_slave_i2s_lsb_first |
+--------+-----------------------+-----------------------+
| [17]   | R_SLAVE_I2S_2CH       | r_slave_i2s_2ch       |
+--------+-----------------------+-----------------------+
| [31]   | R_SLAVE_I2S_EN        | r_slave_i2s_en        |
+--------+-----------------------+-----------------------+

UDMA_I2S_REG_I2S_MST_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x28 = 0x5010e028`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_I2S_MST_SETUP

        {
            "reg": [
                {"name": "r_master_i2s_words",  "bits": 3},
                {"bits": 5},
                {"name": "r_master_i2s_bits_word",  "bits": 5},
                {"bits": 3},
                {"name": "r_master_i2s_lsb_first",  "bits": 1},
                {"name": "r_master_i2s_2ch",  "bits": 1},
                {"bits": 13},
                {"name": "r_master_i2s_en",  "bits": 1}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+--------+------------------------+------------------------+
| Field  | Name                   | Description            |
+========+========================+========================+
| [2:0]  | R_MASTER_I2S_WORDS     | r_master_i2s_words     |
+--------+------------------------+------------------------+
| [12:8] | R_MASTER_I2S_BITS_WORD | r_master_i2s_bits_word |
+--------+------------------------+------------------------+
| [16]   | R_MASTER_I2S_LSB_FIRST | r_master_i2s_lsb_first |
+--------+------------------------+------------------------+
| [17]   | R_MASTER_I2S_2CH       | r_master_i2s_2ch       |
+--------+------------------------+------------------------+
| [31]   | R_MASTER_I2S_EN        | r_master_i2s_en        |
+--------+------------------------+------------------------+

UDMA_I2S_REG_I2S_PDM_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010e000 + 0x2c = 0x5010e02c`

    See `udma_i2s_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2s/rtl/udma_i2s_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2S_REG_I2S_PDM_SETUP

        {
            "reg": [
                {"name": "r_slave_pdm_shift",  "bits": 3},
                {"name": "r_slave_pdm_decimation",  "bits": 10},
                {"name": "r_slave_pdm_mode",  "bits": 2},
                {"bits": 16},
                {"name": "r_slave_pdm_en",  "bits": 1}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+------------------------+------------------------+
| Field   | Name                   | Description            |
+=========+========================+========================+
| [2:0]   | R_SLAVE_PDM_SHIFT      | r_slave_pdm_shift      |
+---------+------------------------+------------------------+
| [12:3]  | R_SLAVE_PDM_DECIMATION | r_slave_pdm_decimation |
+---------+------------------------+------------------------+
| [14:13] | R_SLAVE_PDM_MODE       | r_slave_pdm_mode       |
+---------+------------------------+------------------------+
| [31]    | R_SLAVE_PDM_EN         | r_slave_pdm_en         |
+---------+------------------------+------------------------+

