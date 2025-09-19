UDMA_I2C_3
==========

Register Listing for UDMA_I2C_3
-------------------------------

+------------------------------------------------------------+----------------------------------------------+
| Register                                                   | Address                                      |
+============================================================+==============================================+
| :ref:`UDMA_I2C_3_REG_RX_SADDR <UDMA_I2C_3_REG_RX_SADDR>`   | :ref:`0x5010c000 <UDMA_I2C_3_REG_RX_SADDR>`  |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_RX_SIZE <UDMA_I2C_3_REG_RX_SIZE>`     | :ref:`0x5010c004 <UDMA_I2C_3_REG_RX_SIZE>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_RX_CFG <UDMA_I2C_3_REG_RX_CFG>`       | :ref:`0x5010c008 <UDMA_I2C_3_REG_RX_CFG>`    |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_TX_SADDR <UDMA_I2C_3_REG_TX_SADDR>`   | :ref:`0x5010c010 <UDMA_I2C_3_REG_TX_SADDR>`  |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_TX_SIZE <UDMA_I2C_3_REG_TX_SIZE>`     | :ref:`0x5010c014 <UDMA_I2C_3_REG_TX_SIZE>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_TX_CFG <UDMA_I2C_3_REG_TX_CFG>`       | :ref:`0x5010c018 <UDMA_I2C_3_REG_TX_CFG>`    |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_CMD_SADDR <UDMA_I2C_3_REG_CMD_SADDR>` | :ref:`0x5010c020 <UDMA_I2C_3_REG_CMD_SADDR>` |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_CMD_SIZE <UDMA_I2C_3_REG_CMD_SIZE>`   | :ref:`0x5010c024 <UDMA_I2C_3_REG_CMD_SIZE>`  |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_CMD_CFG <UDMA_I2C_3_REG_CMD_CFG>`     | :ref:`0x5010c028 <UDMA_I2C_3_REG_CMD_CFG>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_STATUS <UDMA_I2C_3_REG_STATUS>`       | :ref:`0x5010c030 <UDMA_I2C_3_REG_STATUS>`    |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_I2C_3_REG_ACK <UDMA_I2C_3_REG_ACK>`             | :ref:`0x5010c038 <UDMA_I2C_3_REG_ACK>`       |
+------------------------------------------------------------+----------------------------------------------+

UDMA_I2C_3_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x0 = 0x5010c000`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_RX_SADDR

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

UDMA_I2C_3_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x4 = 0x5010c004`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_RX_SIZE

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

UDMA_I2C_3_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x8 = 0x5010c008`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_rx_en",  "bits": 1},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [0]   | R_RX_CONTINUOUS | r_rx_continuous |
+-------+-----------------+-----------------+
| [4]   | R_RX_EN         | r_rx_en         |
+-------+-----------------+-----------------+

UDMA_I2C_3_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x10 = 0x5010c010`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_TX_SADDR

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

UDMA_I2C_3_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x14 = 0x5010c014`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_TX_SIZE

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

UDMA_I2C_3_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x18 = 0x5010c018`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_TX_CFG

        {
            "reg": [
                {"name": "r_tx_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_tx_en",  "bits": 1},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------------+-----------------+
| Field | Name            | Description     |
+=======+=================+=================+
| [0]   | R_TX_CONTINUOUS | r_tx_continuous |
+-------+-----------------+-----------------+
| [4]   | R_TX_EN         | r_tx_en         |
+-------+-----------------+-----------------+

UDMA_I2C_3_REG_CMD_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x20 = 0x5010c020`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_CMD_SADDR

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

UDMA_I2C_3_REG_CMD_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x24 = 0x5010c024`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_CMD_SIZE

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

UDMA_I2C_3_REG_CMD_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x28 = 0x5010c028`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_CMD_CFG

        {
            "reg": [
                {"name": "r_cmd_continuous",  "bits": 1},
                {"bits": 3},
                {"name": "r_cmd_en",  "bits": 1},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------------+------------------+
| Field | Name             | Description      |
+=======+==================+==================+
| [0]   | R_CMD_CONTINUOUS | r_cmd_continuous |
+-------+------------------+------------------+
| [4]   | R_CMD_EN         | r_cmd_en         |
+-------+------------------+------------------+

UDMA_I2C_3_REG_STATUS
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x30 = 0x5010c030`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_STATUS

        {
            "reg": [
                {"name": "r_busy",  "bits": 1},
                {"name": "r_al",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+-------------+
| Field | Name   | Description |
+=======+========+=============+
| [0]   | R_BUSY | r_busy      |
+-------+--------+-------------+
| [1]   | R_AL   | r_al        |
+-------+--------+-------------+

UDMA_I2C_3_REG_ACK
^^^^^^^^^^^^^^^^^^

`Address: 0x5010c000 + 0x38 = 0x5010c038`

    See `udma_i2c_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/ips
    /udma/udma_i2c/rtl/udma_i2c_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_I2C_3_REG_ACK

        {
            "reg": [
                {"name": "r_nack",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------+-------------+
| Field | Name   | Description |
+=======+========+=============+
| [0]   | R_NACK | r_nack      |
+-------+--------+-------------+

