UDMA_CAMERA
===========

Register Listing for UDMA_CAMERA
--------------------------------

+--------------------------------------------------------------------------------+--------------------------------------------------------+
| Register                                                                       | Address                                                |
+================================================================================+========================================================+
| :ref:`UDMA_CAMERA_REG_RX_SADDR <UDMA_CAMERA_REG_RX_SADDR>`                     | :ref:`0x5010f000 <UDMA_CAMERA_REG_RX_SADDR>`           |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_RX_SIZE <UDMA_CAMERA_REG_RX_SIZE>`                       | :ref:`0x5010f004 <UDMA_CAMERA_REG_RX_SIZE>`            |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_RX_CFG <UDMA_CAMERA_REG_RX_CFG>`                         | :ref:`0x5010f008 <UDMA_CAMERA_REG_RX_CFG>`             |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_CFG_GLOB <UDMA_CAMERA_REG_CAM_CFG_GLOB>`             | :ref:`0x5010f020 <UDMA_CAMERA_REG_CAM_CFG_GLOB>`       |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_CFG_LL <UDMA_CAMERA_REG_CAM_CFG_LL>`                 | :ref:`0x5010f024 <UDMA_CAMERA_REG_CAM_CFG_LL>`         |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_CFG_UR <UDMA_CAMERA_REG_CAM_CFG_UR>`                 | :ref:`0x5010f028 <UDMA_CAMERA_REG_CAM_CFG_UR>`         |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_CFG_SIZE <UDMA_CAMERA_REG_CAM_CFG_SIZE>`             | :ref:`0x5010f02c <UDMA_CAMERA_REG_CAM_CFG_SIZE>`       |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_CFG_FILTER <UDMA_CAMERA_REG_CAM_CFG_FILTER>`         | :ref:`0x5010f030 <UDMA_CAMERA_REG_CAM_CFG_FILTER>`     |
+--------------------------------------------------------------------------------+--------------------------------------------------------+
| :ref:`UDMA_CAMERA_REG_CAM_VSYNC_POLARITY <UDMA_CAMERA_REG_CAM_VSYNC_POLARITY>` | :ref:`0x5010f034 <UDMA_CAMERA_REG_CAM_VSYNC_POLARITY>` |
+--------------------------------------------------------------------------------+--------------------------------------------------------+

UDMA_CAMERA_REG_RX_SADDR
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x0 = 0x5010f000`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_RX_SADDR

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

UDMA_CAMERA_REG_RX_SIZE
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x4 = 0x5010f004`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_RX_SIZE

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

UDMA_CAMERA_REG_RX_CFG
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x8 = 0x5010f008`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_RX_CFG

        {
            "reg": [
                {"name": "r_rx_continuous",  "bits": 1},
                {"name": "r_rx_datasize",  "bits": 2},
                {"bits": 1},
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
| [2:1] | R_RX_DATASIZE   | r_rx_datasize   |
+-------+-----------------+-----------------+
| [4]   | R_RX_EN         | r_rx_en         |
+-------+-----------------+-----------------+
| [6]   | R_RX_CLR        | r_rx_clr        |
+-------+-----------------+-----------------+

UDMA_CAMERA_REG_CAM_CFG_GLOB
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x20 = 0x5010f020`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_CFG_GLOB

        {
            "reg": [
                {"name": "r_cam_cfg",  "bits": 30},
                {"name": "cfg_cam_ip_en_i",  "bits": 1},
                {"bits": 1}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+--------+-----------------+-----------------+
| Field  | Name            | Description     |
+========+=================+=================+
| [29:0] | R_CAM_CFG       | r_cam_cfg       |
+--------+-----------------+-----------------+
| [30]   | CFG_CAM_IP_EN_I | cfg_cam_ip_en_i |
+--------+-----------------+-----------------+

UDMA_CAMERA_REG_CAM_CFG_LL
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x24 = 0x5010f024`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_CFG_LL

        {
            "reg": [
                {"name": "r_cam_cfg_ll",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+--------------+
| Field  | Name         | Description  |
+========+==============+==============+
| [31:0] | R_CAM_CFG_LL | r_cam_cfg_ll |
+--------+--------------+--------------+

UDMA_CAMERA_REG_CAM_CFG_UR
^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x28 = 0x5010f028`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_CFG_UR

        {
            "reg": [
                {"name": "r_cam_cfg_ur",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+--------------+
| Field  | Name         | Description  |
+========+==============+==============+
| [31:0] | R_CAM_CFG_UR | r_cam_cfg_ur |
+--------+--------------+--------------+

UDMA_CAMERA_REG_CAM_CFG_SIZE
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x2c = 0x5010f02c`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_CFG_SIZE

        {
            "reg": [
                {"name": "r_cam_cfg_size",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+----------------+
| Field  | Name           | Description    |
+========+================+================+
| [31:0] | R_CAM_CFG_SIZE | r_cam_cfg_size |
+--------+----------------+----------------+

UDMA_CAMERA_REG_CAM_CFG_FILTER
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x30 = 0x5010f030`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_CFG_FILTER

        {
            "reg": [
                {"name": "r_cam_cfg_filter",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------------+------------------+
| Field  | Name             | Description      |
+========+==================+==================+
| [31:0] | R_CAM_CFG_FILTER | r_cam_cfg_filter |
+--------+------------------+------------------+

UDMA_CAMERA_REG_CAM_VSYNC_POLARITY
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x5010f000 + 0x34 = 0x5010f034`

    See file:///F:/code/cram-nto/../../ips/udma/udma_camera/rtl/camera_reg_if.sv

    .. wavedrom::
        :caption: UDMA_CAMERA_REG_CAM_VSYNC_POLARITY

        {
            "reg": [
                {"name": "r_cam_vsync_polarity",  "bits": 1},
                {"name": "r_cam_hsync_polarity",  "bits": 1},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------------------+----------------------+
| Field | Name                 | Description          |
+=======+======================+======================+
| [0]   | R_CAM_VSYNC_POLARITY | r_cam_vsync_polarity |
+-------+----------------------+----------------------+
| [1]   | R_CAM_HSYNC_POLARITY | r_cam_hsync_polarity |
+-------+----------------------+----------------------+

