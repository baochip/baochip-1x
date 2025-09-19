UDMA_SCIF
=========

Register Listing for UDMA_SCIF
------------------------------

+------------------------------------------------------------+----------------------------------------------+
| Register                                                   | Address                                      |
+============================================================+==============================================+
| :ref:`UDMA_SCIF_REG_RX_SADDR <UDMA_SCIF_REG_RX_SADDR>`     | :ref:`0x50111000 <UDMA_SCIF_REG_RX_SADDR>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_RX_SIZE <UDMA_SCIF_REG_RX_SIZE>`       | :ref:`0x50111004 <UDMA_SCIF_REG_RX_SIZE>`    |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_RX_CFG <UDMA_SCIF_REG_RX_CFG>`         | :ref:`0x50111008 <UDMA_SCIF_REG_RX_CFG>`     |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_TX_SADDR <UDMA_SCIF_REG_TX_SADDR>`     | :ref:`0x50111010 <UDMA_SCIF_REG_TX_SADDR>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_TX_SIZE <UDMA_SCIF_REG_TX_SIZE>`       | :ref:`0x50111014 <UDMA_SCIF_REG_TX_SIZE>`    |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_TX_CFG <UDMA_SCIF_REG_TX_CFG>`         | :ref:`0x50111018 <UDMA_SCIF_REG_TX_CFG>`     |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_STATUS <UDMA_SCIF_REG_STATUS>`         | :ref:`0x50111020 <UDMA_SCIF_REG_STATUS>`     |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_SCIF_SETUP <UDMA_SCIF_REG_SCIF_SETUP>` | :ref:`0x50111024 <UDMA_SCIF_REG_SCIF_SETUP>` |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_ERROR <UDMA_SCIF_REG_ERROR>`           | :ref:`0x50111028 <UDMA_SCIF_REG_ERROR>`      |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_IRQ_EN <UDMA_SCIF_REG_IRQ_EN>`         | :ref:`0x5011102c <UDMA_SCIF_REG_IRQ_EN>`     |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_VALID <UDMA_SCIF_REG_VALID>`           | :ref:`0x50111030 <UDMA_SCIF_REG_VALID>`      |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_DATA <UDMA_SCIF_REG_DATA>`             | :ref:`0x50111034 <UDMA_SCIF_REG_DATA>`       |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`UDMA_SCIF_REG_SCIF_ETU <UDMA_SCIF_REG_SCIF_ETU>`     | :ref:`0x50111038 <UDMA_SCIF_REG_SCIF_ETU>`   |
+------------------------------------------------------------+----------------------------------------------+

UDMA_SCIF_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x0 = 0x50111000`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_RX_SADDR

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

UDMA_SCIF_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x4 = 0x50111004`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_RX_SIZE

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

UDMA_SCIF_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x8 = 0x50111008`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_RX_CFG

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

UDMA_SCIF_REG_TX_SADDR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x10 = 0x50111010`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_TX_SADDR

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

UDMA_SCIF_REG_TX_SIZE
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x14 = 0x50111014`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_TX_SIZE

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

UDMA_SCIF_REG_TX_CFG
^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x18 = 0x50111018`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_TX_CFG

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

UDMA_SCIF_REG_STATUS
^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x20 = 0x50111020`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_STATUS

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

UDMA_SCIF_REG_SCIF_SETUP
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x24 = 0x50111024`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_SCIF_SETUP

        {
            "reg": [
                {"name": "r_scif_parity_en",  "bits": 1},
                {"name": "r_scif_bits",  "bits": 2},
                {"name": "r_scif_stop_bits",  "bits": 1},
                {"name": "r_scif_rx_polling_en",  "bits": 1},
                {"name": "r_scif_rx_clean_fifo",  "bits": 1},
                {"bits": 2},
                {"name": "r_scif_en_tx",  "bits": 1},
                {"name": "r_scif_en_rx",  "bits": 1},
                {"bits": 4},
                {"name": "r_scif_clksel",  "bits": 2},
                {"name": "r_scif_div",  "bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+---------+----------------------+----------------------+
| Field   | Name                 | Description          |
+=========+======================+======================+
| [0]     | R_SCIF_PARITY_EN     | r_scif_parity_en     |
+---------+----------------------+----------------------+
| [2:1]   | R_SCIF_BITS          | r_scif_bits          |
+---------+----------------------+----------------------+
| [3]     | R_SCIF_STOP_BITS     | r_scif_stop_bits     |
+---------+----------------------+----------------------+
| [4]     | R_SCIF_RX_POLLING_EN | r_scif_rx_polling_en |
+---------+----------------------+----------------------+
| [5]     | R_SCIF_RX_CLEAN_FIFO | r_scif_rx_clean_fifo |
+---------+----------------------+----------------------+
| [8]     | R_SCIF_EN_TX         | r_scif_en_tx         |
+---------+----------------------+----------------------+
| [9]     | R_SCIF_EN_RX         | r_scif_en_rx         |
+---------+----------------------+----------------------+
| [15:14] | R_SCIF_CLKSEL        | r_scif_clksel        |
+---------+----------------------+----------------------+
| [31:16] | R_SCIF_DIV           | r_scif_div           |
+---------+----------------------+----------------------+

UDMA_SCIF_REG_ERROR
^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x28 = 0x50111028`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_ERROR

        {
            "reg": [
                {"name": "r_err_overflow",  "bits": 1},
                {"name": "r_err_parity",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------------+----------------+
| Field | Name           | Description    |
+=======+================+================+
| [0]   | R_ERR_OVERFLOW | r_err_overflow |
+-------+----------------+----------------+
| [1]   | R_ERR_PARITY   | r_err_parity   |
+-------+----------------+----------------+

UDMA_SCIF_REG_IRQ_EN
^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x2c = 0x5011102c`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_IRQ_EN

        {
            "reg": [
                {"name": "r_scif_rx_irq_en",  "bits": 1},
                {"name": "r_scif_err_irq_en",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------------+-------------------+
| Field | Name              | Description       |
+=======+===================+===================+
| [0]   | R_SCIF_RX_IRQ_EN  | r_scif_rx_irq_en  |
+-------+-------------------+-------------------+
| [1]   | R_SCIF_ERR_IRQ_EN | r_scif_err_irq_en |
+-------+-------------------+-------------------+

UDMA_SCIF_REG_VALID
^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x30 = 0x50111030`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_VALID

        {
            "reg": [
                {"name": "r_scif_rx_data_valid",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------------------+----------------------+
| Field | Name                 | Description          |
+=======+======================+======================+
| [0]   | R_SCIF_RX_DATA_VALID | r_scif_rx_data_valid |
+-------+----------------------+----------------------+

UDMA_SCIF_REG_DATA
^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x34 = 0x50111034`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_DATA

        {
            "reg": [
                {"name": "r_scif_rx_data",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+----------------+----------------+
| Field | Name           | Description    |
+=======+================+================+
| [7:0] | R_SCIF_RX_DATA | r_scif_rx_data |
+-------+----------------+----------------+

UDMA_SCIF_REG_SCIF_ETU
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50111000 + 0x38 = 0x50111038`

    See file:///F:/code/cram-nto/../../modules/ifsub/rtl/udma_scif_reg.sv

    .. wavedrom::
        :caption: UDMA_SCIF_REG_SCIF_ETU

        {
            "reg": [
                {"name": "r_scif_etu",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+-------------+
| Field  | Name       | Description |
+========+============+=============+
| [15:0] | R_SCIF_ETU | r_scif_etu  |
+--------+------------+-------------+

