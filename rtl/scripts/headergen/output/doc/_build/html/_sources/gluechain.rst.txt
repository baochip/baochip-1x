GLUECHAIN
=========

Register Listing for GLUECHAIN
------------------------------

+--------------------------------------------------------------------------+-----------------------------------------------------+
| Register                                                                 | Address                                             |
+==========================================================================+=====================================================+
| :ref:`GLUECHAIN_SFR_GCMASK_CR_GCMASK0 <GLUECHAIN_SFR_GCMASK_CR_GCMASK0>` | :ref:`0x40054000 <GLUECHAIN_SFR_GCMASK_CR_GCMASK0>` |
+--------------------------------------------------------------------------+-----------------------------------------------------+
| :ref:`GLUECHAIN_SFR_GCSR_GLUEREG0 <GLUECHAIN_SFR_GCSR_GLUEREG0>`         | :ref:`0x40054004 <GLUECHAIN_SFR_GCSR_GLUEREG0>`     |
+--------------------------------------------------------------------------+-----------------------------------------------------+
| :ref:`GLUECHAIN_SFR_GCRST_GLUERST0 <GLUECHAIN_SFR_GCRST_GLUERST0>`       | :ref:`0x40054008 <GLUECHAIN_SFR_GCRST_GLUERST0>`    |
+--------------------------------------------------------------------------+-----------------------------------------------------+
| :ref:`GLUECHAIN_SFR_GCTEST_GLUETEST0 <GLUECHAIN_SFR_GCTEST_GLUETEST0>`   | :ref:`0x4005400c <GLUECHAIN_SFR_GCTEST_GLUETEST0>`  |
+--------------------------------------------------------------------------+-----------------------------------------------------+

GLUECHAIN_SFR_GCMASK_CR_GCMASK0
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40054000 + 0x0 = 0x40054000`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/gluechain.sv

    .. wavedrom::
        :caption: GLUECHAIN_SFR_GCMASK_CR_GCMASK0

        {
            "reg": [
                {"name": "cr_gcmask0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+---------------------------------------+
| Field  | Name       | Description                           |
+========+============+=======================================+
| [31:0] | CR_GCMASK0 | cr_gcmask read/write control register |
+--------+------------+---------------------------------------+

GLUECHAIN_SFR_GCSR_GLUEREG0
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40054000 + 0x4 = 0x40054004`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/gluechain.sv

    .. wavedrom::
        :caption: GLUECHAIN_SFR_GCSR_GLUEREG0

        {
            "reg": [
                {"name": "gluereg0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-----------------------------------+
| Field  | Name     | Description                       |
+========+==========+===================================+
| [31:0] | GLUEREG0 | gluereg read only status register |
+--------+----------+-----------------------------------+

GLUECHAIN_SFR_GCRST_GLUERST0
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40054000 + 0x8 = 0x40054008`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/gluechain.sv

    .. wavedrom::
        :caption: GLUECHAIN_SFR_GCRST_GLUERST0

        {
            "reg": [
                {"name": "gluerst0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+-------------------------------------+
| Field  | Name     | Description                         |
+========+==========+=====================================+
| [31:0] | GLUERST0 | gluerst read/write control register |
+--------+----------+-------------------------------------+

GLUECHAIN_SFR_GCTEST_GLUETEST0
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40054000 + 0xc = 0x4005400c`

    See file:///F:/code/cram-nto/../../modules/sec/rtl/gluechain.sv

    .. wavedrom::
        :caption: GLUECHAIN_SFR_GCTEST_GLUETEST0

        {
            "reg": [
                {"name": "gluetest0",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------+
| Field  | Name      | Description                          |
+========+===========+======================================+
| [31:0] | GLUETEST0 | gluetest read/write control register |
+--------+-----------+--------------------------------------+

