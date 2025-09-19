MESH
====

Register Listing for MESH
-------------------------

+------------------------------------------------------------+----------------------------------------------+
| Register                                                   | Address                                      |
+============================================================+==============================================+
| :ref:`MESH_SFR_MLDRV_CR_MLDRV0 <MESH_SFR_MLDRV_CR_MLDRV0>` | :ref:`0x40052000 <MESH_SFR_MLDRV_CR_MLDRV0>` |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLDRV_CR_MLDRV1 <MESH_SFR_MLDRV_CR_MLDRV1>` | :ref:`0x40052004 <MESH_SFR_MLDRV_CR_MLDRV1>` |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLIE_CR_MLIE0 <MESH_SFR_MLIE_CR_MLIE0>`     | :ref:`0x40052010 <MESH_SFR_MLIE_CR_MLIE0>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLIE_CR_MLIE1 <MESH_SFR_MLIE_CR_MLIE1>`     | :ref:`0x40052014 <MESH_SFR_MLIE_CR_MLIE1>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR0 <MESH_SFR_MLSR_SR_MLSR0>`     | :ref:`0x40052020 <MESH_SFR_MLSR_SR_MLSR0>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR1 <MESH_SFR_MLSR_SR_MLSR1>`     | :ref:`0x40052024 <MESH_SFR_MLSR_SR_MLSR1>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR2 <MESH_SFR_MLSR_SR_MLSR2>`     | :ref:`0x40052028 <MESH_SFR_MLSR_SR_MLSR2>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR3 <MESH_SFR_MLSR_SR_MLSR3>`     | :ref:`0x4005202c <MESH_SFR_MLSR_SR_MLSR3>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR4 <MESH_SFR_MLSR_SR_MLSR4>`     | :ref:`0x40052030 <MESH_SFR_MLSR_SR_MLSR4>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR5 <MESH_SFR_MLSR_SR_MLSR5>`     | :ref:`0x40052034 <MESH_SFR_MLSR_SR_MLSR5>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR6 <MESH_SFR_MLSR_SR_MLSR6>`     | :ref:`0x40052038 <MESH_SFR_MLSR_SR_MLSR6>`   |
+------------------------------------------------------------+----------------------------------------------+
| :ref:`MESH_SFR_MLSR_SR_MLSR7 <MESH_SFR_MLSR_SR_MLSR7>`     | :ref:`0x4005203c <MESH_SFR_MLSR_SR_MLSR7>`   |
+------------------------------------------------------------+----------------------------------------------+

MESH_SFR_MLDRV_CR_MLDRV0
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x0 = 0x40052000`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLDRV_CR_MLDRV0

        {
            "reg": [
                {"name": "cr_mldrv0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------+
| Field  | Name      | Description                          |
+========+===========+======================================+
| [31:0] | CR_MLDRV0 | cr_mldrv read/write control register |
+--------+-----------+--------------------------------------+

MESH_SFR_MLDRV_CR_MLDRV1
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x4 = 0x40052004`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLDRV_CR_MLDRV1

        {
            "reg": [
                {"name": "cr_mldrv1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------+
| Field  | Name      | Description                          |
+========+===========+======================================+
| [31:0] | CR_MLDRV1 | cr_mldrv read/write control register |
+--------+-----------+--------------------------------------+

MESH_SFR_MLIE_CR_MLIE0
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x10 = 0x40052010`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLIE_CR_MLIE0

        {
            "reg": [
                {"name": "cr_mlie0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------------------------------+
| Field  | Name     | Description                         |
+========+==========+=====================================+
| [31:0] | CR_MLIE0 | cr_mlie read/write control register |
+--------+----------+-------------------------------------+

MESH_SFR_MLIE_CR_MLIE1
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x14 = 0x40052014`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLIE_CR_MLIE1

        {
            "reg": [
                {"name": "cr_mlie1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------------------------------+
| Field  | Name     | Description                         |
+========+==========+=====================================+
| [31:0] | CR_MLIE1 | cr_mlie read/write control register |
+--------+----------+-------------------------------------+

MESH_SFR_MLSR_SR_MLSR0
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x20 = 0x40052020`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR0

        {
            "reg": [
                {"name": "sr_mlsr0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR0 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR1
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x24 = 0x40052024`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR1

        {
            "reg": [
                {"name": "sr_mlsr1",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR1 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR2
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x28 = 0x40052028`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR2

        {
            "reg": [
                {"name": "sr_mlsr2",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR2 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR3
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x2c = 0x4005202c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR3

        {
            "reg": [
                {"name": "sr_mlsr3",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR3 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR4
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x30 = 0x40052030`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR4

        {
            "reg": [
                {"name": "sr_mlsr4",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR4 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR5
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x34 = 0x40052034`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR5

        {
            "reg": [
                {"name": "sr_mlsr5",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR5 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR6
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x38 = 0x40052038`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR6

        {
            "reg": [
                {"name": "sr_mlsr6",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR6 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

MESH_SFR_MLSR_SR_MLSR7
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40052000 + 0x3c = 0x4005203c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/mesh.sv

    .. wavedrom::
        :caption: MESH_SFR_MLSR_SR_MLSR7

        {
            "reg": [
                {"name": "sr_mlsr7",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | SR_MLSR7 | sr_mlsr read only status register |
+--------+----------+-----------------------------------+

