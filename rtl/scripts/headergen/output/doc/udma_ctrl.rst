UDMA_CTRL
=========

Register Listing for UDMA_CTRL
------------------------------

+------------------------------------------------------+-------------------------------------------+
| Register                                             | Address                                   |
+======================================================+===========================================+
| :ref:`UDMA_CTRL_REG_CG <UDMA_CTRL_REG_CG>`           | :ref:`0x50100000 <UDMA_CTRL_REG_CG>`      |
+------------------------------------------------------+-------------------------------------------+
| :ref:`UDMA_CTRL_REG_CFG_EVT <UDMA_CTRL_REG_CFG_EVT>` | :ref:`0x50100004 <UDMA_CTRL_REG_CFG_EVT>` |
+------------------------------------------------------+-------------------------------------------+
| :ref:`UDMA_CTRL_REG_RST <UDMA_CTRL_REG_RST>`         | :ref:`0x50100008 <UDMA_CTRL_REG_RST>`     |
+------------------------------------------------------+-------------------------------------------+

UDMA_CTRL_REG_CG
^^^^^^^^^^^^^^^^

`Address: 0x50100000 + 0x0 = 0x50100000`

    See file:///F:/code/cram-nto/../../ips/udma/udma_core/rtl/common/udma_ctrl.sv

    .. wavedrom::
        :caption: UDMA_CTRL_REG_CG

        {
            "reg": [
                {"name": "r_cg",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------+-------------+
| Field | Name | Description |
+=======+======+=============+
| [5:0] | R_CG | r_cg        |
+-------+------+-------------+

UDMA_CTRL_REG_CFG_EVT
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x50100000 + 0x4 = 0x50100004`

    See file:///F:/code/cram-nto/../../ips/udma/udma_core/rtl/common/udma_ctrl.sv

    .. wavedrom::
        :caption: UDMA_CTRL_REG_CFG_EVT

        {
            "reg": [
                {"name": "r_cmp_evt_0",  "bits": 8},
                {"name": "r_cmp_evt_1",  "bits": 8},
                {"name": "r_cmp_evt_2",  "bits": 8},
                {"name": "r_cmp_evt_3",  "bits": 8}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+---------+-------------+-------------+
| Field   | Name        | Description |
+=========+=============+=============+
| [7:0]   | R_CMP_EVT_0 | r_cmp_evt_0 |
+---------+-------------+-------------+
| [15:8]  | R_CMP_EVT_1 | r_cmp_evt_1 |
+---------+-------------+-------------+
| [23:16] | R_CMP_EVT_2 | r_cmp_evt_2 |
+---------+-------------+-------------+
| [31:24] | R_CMP_EVT_3 | r_cmp_evt_3 |
+---------+-------------+-------------+

UDMA_CTRL_REG_RST
^^^^^^^^^^^^^^^^^

`Address: 0x50100000 + 0x8 = 0x50100008`

    See file:///F:/code/cram-nto/../../ips/udma/udma_core/rtl/common/udma_ctrl.sv

    .. wavedrom::
        :caption: UDMA_CTRL_REG_RST

        {
            "reg": [
                {"name": "r_rst",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------+-------------+
| Field | Name  | Description |
+=======+=======+=============+
| [5:0] | R_RST | r_rst       |
+-------+-------+-------------+

