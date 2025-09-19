UDMA_ADC
========

Register Listing for UDMA_ADC
-----------------------------

+------------------------------------------------------+-------------------------------------------+
| Register                                             | Address                                   |
+======================================================+===========================================+
| :ref:`UDMA_ADC_REG_RX_SADDR <UDMA_ADC_REG_RX_SADDR>` | :ref:`0x50114000 <UDMA_ADC_REG_RX_SADDR>` |
+------------------------------------------------------+-------------------------------------------+
| :ref:`UDMA_ADC_REG_RX_SIZE <UDMA_ADC_REG_RX_SIZE>`   | :ref:`0x50114004 <UDMA_ADC_REG_RX_SIZE>`  |
+------------------------------------------------------+-------------------------------------------+
| :ref:`UDMA_ADC_REG_RX_CFG <UDMA_ADC_REG_RX_CFG>`     | :ref:`0x50114008 <UDMA_ADC_REG_RX_CFG>`   |
+------------------------------------------------------+-------------------------------------------+
| :ref:`UDMA_ADC_REG_CR_ADC <UDMA_ADC_REG_CR_ADC>`     | :ref:`0x50114010 <UDMA_ADC_REG_CR_ADC>`   |
+------------------------------------------------------+-------------------------------------------+

UDMA_ADC_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50114000 + 0x0 = 0x50114000`

    See `udma_adc_ts_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/
    modules/ifsub/rtl/udma_adc_ts_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_ADC_REG_RX_SADDR

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

UDMA_ADC_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^

`Address: 0x50114000 + 0x4 = 0x50114004`

    See `udma_adc_ts_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/
    modules/ifsub/rtl/udma_adc_ts_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_ADC_REG_RX_SIZE

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

UDMA_ADC_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^

`Address: 0x50114000 + 0x8 = 0x50114008`

    See `udma_adc_ts_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/
    modules/ifsub/rtl/udma_adc_ts_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_ADC_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"bits": 3},
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
| [4]   | R_RX_EN         | r_rx_en         |
+-------+-----------------+-----------------+
| [5]   | R_RX_CLR        | r_rx_clr        |
+-------+-----------------+-----------------+

UDMA_ADC_REG_CR_ADC
^^^^^^^^^^^^^^^^^^^

`Address: 0x50114000 + 0x10 = 0x50114010`

    See `udma_adc_ts_reg_if.sv <https://github.com/baochip/baochip-1x/blob/main/rtl/
    modules/ifsub/rtl/udma_adc_ts_reg_if.sv>`__

    .. wavedrom::
        :caption: UDMA_ADC_REG_CR_ADC

        {
            "reg": [
                {"name": "cr_adc",  "bits": 28},
                {"bits": 4}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+-------------+
| Field  | Name   | Description |
+========+========+=============+
| [27:0] | CR_ADC | cr_adc      |
+--------+--------+-------------+

