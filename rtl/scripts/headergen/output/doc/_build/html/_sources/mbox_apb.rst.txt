MBOX_APB
========

Register Listing for MBOX_APB
-----------------------------

+--------------------------------------------------+-----------------------------------------+
| Register                                         | Address                                 |
+==================================================+=========================================+
| :ref:`MBOX_APB_SFR_WDATA <MBOX_APB_SFR_WDATA>`   | :ref:`0x40013000 <MBOX_APB_SFR_WDATA>`  |
+--------------------------------------------------+-----------------------------------------+
| :ref:`MBOX_APB_SFR_RDATA <MBOX_APB_SFR_RDATA>`   | :ref:`0x40013004 <MBOX_APB_SFR_RDATA>`  |
+--------------------------------------------------+-----------------------------------------+
| :ref:`MBOX_APB_SFR_STATUS <MBOX_APB_SFR_STATUS>` | :ref:`0x40013008 <MBOX_APB_SFR_STATUS>` |
+--------------------------------------------------+-----------------------------------------+
| :ref:`MBOX_APB_SFR_ABORT <MBOX_APB_SFR_ABORT>`   | :ref:`0x40013018 <MBOX_APB_SFR_ABORT>`  |
+--------------------------------------------------+-----------------------------------------+
| :ref:`MBOX_APB_SFR_DONE <MBOX_APB_SFR_DONE>`     | :ref:`0x4001301c <MBOX_APB_SFR_DONE>`   |
+--------------------------------------------------+-----------------------------------------+

MBOX_APB_SFR_WDATA
^^^^^^^^^^^^^^^^^^

`Address: 0x40013000 + 0x0 = 0x40013000`

    See file:///F:/code/cram-nto/../../modules/vexriscv/lib/mbox_v0.1.sv

    .. wavedrom::
        :caption: MBOX_APB_SFR_WDATA

        {
            "reg": [
                {"name": "sfr_wdata",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+---------------------------------------+
| Field  | Name      | Description                           |
+========+===========+=======================================+
| [31:0] | SFR_WDATA | sfr_wdata read/write control register |
+--------+-----------+---------------------------------------+

MBOX_APB_SFR_RDATA
^^^^^^^^^^^^^^^^^^

`Address: 0x40013000 + 0x4 = 0x40013004`

    See file:///F:/code/cram-nto/../../modules/vexriscv/lib/mbox_v0.1.sv

    .. wavedrom::
        :caption: MBOX_APB_SFR_RDATA

        {
            "reg": [
                {"name": "sfr_rdata",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-------------------------------------+
| Field  | Name      | Description                         |
+========+===========+=====================================+
| [31:0] | SFR_RDATA | sfr_rdata read only status register |
+--------+-----------+-------------------------------------+

MBOX_APB_SFR_STATUS
^^^^^^^^^^^^^^^^^^^

`Address: 0x40013000 + 0x8 = 0x40013008`

    See file:///F:/code/cram-nto/../../modules/vexriscv/lib/mbox_v0.1.sv

    .. wavedrom::
        :caption: MBOX_APB_SFR_STATUS

        {
            "reg": [
                {"name": "rx_avail",  "bits": 1},
                {"name": "tx_free",  "bits": 1},
                {"name": "abort_in_progress",  "bits": 1},
                {"name": "abort_ack",  "bits": 1},
                {"name": "tx_err",  "bits": 1},
                {"name": "rx_err",  "bits": 1},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------------+---------------------------------------------+
| Field | Name              | Description                                 |
+=======+===================+=============================================+
| [0]   | RX_AVAIL          | rx_avail read only status register          |
+-------+-------------------+---------------------------------------------+
| [1]   | TX_FREE           | tx_free read only status register           |
+-------+-------------------+---------------------------------------------+
| [2]   | ABORT_IN_PROGRESS | abort_in_progress read only status register |
+-------+-------------------+---------------------------------------------+
| [3]   | ABORT_ACK         | abort_ack read only status register         |
+-------+-------------------+---------------------------------------------+
| [4]   | TX_ERR            | tx_err read only status register            |
+-------+-------------------+---------------------------------------------+
| [5]   | RX_ERR            | rx_err read only status register            |
+-------+-------------------+---------------------------------------------+

MBOX_APB_SFR_ABORT
^^^^^^^^^^^^^^^^^^

`Address: 0x40013000 + 0x18 = 0x40013018`

    See file:///F:/code/cram-nto/../../modules/vexriscv/lib/mbox_v0.1.sv

    .. wavedrom::
        :caption: MBOX_APB_SFR_ABORT

        {
            "reg": [
                {"name": "sfr_abort",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------------------+
| Field  | Name      | Description                                      |
+========+===========+==================================================+
| [31:0] | SFR_ABORT | sfr_abort performs action on write of value: 0x1 |
+--------+-----------+--------------------------------------------------+

MBOX_APB_SFR_DONE
^^^^^^^^^^^^^^^^^

`Address: 0x40013000 + 0x1c = 0x4001301c`

    See file:///F:/code/cram-nto/../../modules/vexriscv/lib/mbox_v0.1.sv

    .. wavedrom::
        :caption: MBOX_APB_SFR_DONE

        {
            "reg": [
                {"name": "sfr_done",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------------------------------------------+
| Field  | Name     | Description                                     |
+========+==========+=================================================+
| [31:0] | SFR_DONE | sfr_done performs action on write of value: 0x1 |
+--------+----------+-------------------------------------------------+

