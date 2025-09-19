ALU
===

Register Listing for ALU
------------------------

+--------------------------------------------------------------+-----------------------------------------------+
| Register                                                     | Address                                       |
+==============================================================+===============================================+
| :ref:`ALU_SFR_CRFUNC <ALU_SFR_CRFUNC>`                       | :ref:`0x4002f000 <ALU_SFR_CRFUNC>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_AR <ALU_SFR_AR>`                               | :ref:`0x4002f004 <ALU_SFR_AR>`                |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SRMFSM <ALU_SFR_SRMFSM>`                       | :ref:`0x4002f008 <ALU_SFR_SRMFSM>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_FR <ALU_SFR_FR>`                               | :ref:`0x4002f00c <ALU_SFR_FR>`                |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_CRDIVLEN <ALU_SFR_CRDIVLEN>`                   | :ref:`0x4002f010 <ALU_SFR_CRDIVLEN>`          |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SRDIVLEN <ALU_SFR_SRDIVLEN>`                   | :ref:`0x4002f014 <ALU_SFR_SRDIVLEN>`          |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_OPT <ALU_SFR_OPT>`                             | :ref:`0x4002f018 <ALU_SFR_OPT>`               |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_OPTLTX <ALU_SFR_OPTLTX>`                       | :ref:`0x4002f01c <ALU_SFR_OPTLTX>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SEGPTR_CR_SEGCFG0 <ALU_SFR_SEGPTR_CR_SEGCFG0>` | :ref:`0x4002f030 <ALU_SFR_SEGPTR_CR_SEGCFG0>` |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SEGPTR_CR_SEGCFG1 <ALU_SFR_SEGPTR_CR_SEGCFG1>` | :ref:`0x4002f034 <ALU_SFR_SEGPTR_CR_SEGCFG1>` |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SEGPTR_CR_SEGCFG2 <ALU_SFR_SEGPTR_CR_SEGCFG2>` | :ref:`0x4002f038 <ALU_SFR_SEGPTR_CR_SEGCFG2>` |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`ALU_SFR_SEGPTR_CR_SEGCFG3 <ALU_SFR_SEGPTR_CR_SEGCFG3>` | :ref:`0x4002f03c <ALU_SFR_SEGPTR_CR_SEGCFG3>` |
+--------------------------------------------------------------+-----------------------------------------------+

ALU_SFR_CRFUNC
^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x0 = 0x4002f000`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_CRFUNC

        {
            "reg": [
                {"name": "sfr_crfunc",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | SFR_CRFUNC | sfr_crfunc read/write control register |
+-------+------------+----------------------------------------+

ALU_SFR_AR
^^^^^^^^^^

`Address: 0x4002f000 + 0x4 = 0x4002f004`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_AR

        {
            "reg": [
                {"name": "sfr_ar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------+------------------------------------------------+
| Field  | Name   | Description                                    |
+========+========+================================================+
| [31:0] | SFR_AR | sfr_ar performs action on write of value: 0x5a |
+--------+--------+------------------------------------------------+

ALU_SFR_SRMFSM
^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x8 = 0x4002f008`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SRMFSM

        {
            "reg": [
                {"name": "mfsm",  "bits": 8},
                {"name": "crreg",  "bits": 1},
                {"bits": 23}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------+---------------------------------+
| Field | Name  | Description                     |
+=======+=======+=================================+
| [7:0] | MFSM  | mfsm read only status register  |
+-------+-------+---------------------------------+
| [8]   | CRREG | crreg read only status register |
+-------+-------+---------------------------------+

ALU_SFR_FR
^^^^^^^^^^

`Address: 0x4002f000 + 0xc = 0x4002f00c`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_FR

        {
            "reg": [
                {"name": "mfsm_done",  "bits": 1},
                {"name": "div_done",  "bits": 1},
                {"name": "chnlo_done",  "bits": 1},
                {"name": "chnli_done",  "bits": 1},
                {"name": "qs0err",  "bits": 1},
                {"name": "aluinvld",  "bits": 1},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------------------------------------------------+
| Field | Name       | Description                                                                      |
+=======+============+==================================================================================+
| [0]   | MFSM_DONE  | mfsm_done flag register. `1` means event happened, write back `1` in respective  |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [1]   | DIV_DONE   | div_done flag register. `1` means event happened, write back `1` in respective   |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [2]   | CHNLO_DONE | chnlo_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [3]   | CHNLI_DONE | chnli_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [4]   | QS0ERR     | qs0err flag register. `1` means event happened, write back `1` in respective bit |
|       |            | position to clear the flag                                                       |
+-------+------------+----------------------------------------------------------------------------------+
| [5]   | ALUINVLD   | aluinvld flag register. `1` means event happened, write back `1` in respective   |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+

ALU_SFR_CRDIVLEN
^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x10 = 0x4002f010`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_CRDIVLEN

        {
            "reg": [
                {"name": "sfr_crdivlen",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+------------------------------------------+
| Field  | Name         | Description                              |
+========+==============+==========================================+
| [15:0] | SFR_CRDIVLEN | sfr_crdivlen read/write control register |
+--------+--------------+------------------------------------------+

ALU_SFR_SRDIVLEN
^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x14 = 0x4002f014`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SRDIVLEN

        {
            "reg": [
                {"name": "sfr_srdivlen",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+----------------------------------------+
| Field  | Name         | Description                            |
+========+==============+========================================+
| [15:0] | SFR_SRDIVLEN | sfr_srdivlen read only status register |
+--------+--------------+----------------------------------------+

ALU_SFR_OPT
^^^^^^^^^^^

`Address: 0x4002f000 + 0x18 = 0x4002f018`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_OPT

        {
            "reg": [
                {"name": "sfr_opt",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+---------+-------------------------------------+
| Field  | Name    | Description                         |
+========+=========+=====================================+
| [31:0] | SFR_OPT | sfr_opt read/write control register |
+--------+---------+-------------------------------------+

ALU_SFR_OPTLTX
^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x1c = 0x4002f01c`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_OPTLTX

        {
            "reg": [
                {"name": "sfr_optltx",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | SFR_OPTLTX | sfr_optltx read/write control register |
+-------+------------+----------------------------------------+

ALU_SFR_SEGPTR_CR_SEGCFG0
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x30 = 0x4002f030`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SEGPTR_CR_SEGCFG0

        {
            "reg": [
                {"name": "cr_segcfg0",  "bits": 20},
                {"bits": 12}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+---------------------------------------+
| Field  | Name       | Description                           |
+========+============+=======================================+
| [19:0] | CR_SEGCFG0 | cr_segcfg read/write control register |
+--------+------------+---------------------------------------+

ALU_SFR_SEGPTR_CR_SEGCFG1
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x34 = 0x4002f034`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SEGPTR_CR_SEGCFG1

        {
            "reg": [
                {"name": "cr_segcfg1",  "bits": 20},
                {"bits": 12}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+---------------------------------------+
| Field  | Name       | Description                           |
+========+============+=======================================+
| [19:0] | CR_SEGCFG1 | cr_segcfg read/write control register |
+--------+------------+---------------------------------------+

ALU_SFR_SEGPTR_CR_SEGCFG2
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x38 = 0x4002f038`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SEGPTR_CR_SEGCFG2

        {
            "reg": [
                {"name": "cr_segcfg2",  "bits": 20},
                {"bits": 12}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+---------------------------------------+
| Field  | Name       | Description                           |
+========+============+=======================================+
| [19:0] | CR_SEGCFG2 | cr_segcfg read/write control register |
+--------+------------+---------------------------------------+

ALU_SFR_SEGPTR_CR_SEGCFG3
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002f000 + 0x3c = 0x4002f03c`

    See file:///F:/code/cram-nto/../../modules/crypto_alu/rtl/alu.sv

    .. wavedrom::
        :caption: ALU_SFR_SEGPTR_CR_SEGCFG3

        {
            "reg": [
                {"name": "cr_segcfg3",  "bits": 20},
                {"bits": 12}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+---------------------------------------+
| Field  | Name       | Description                           |
+========+============+=======================================+
| [19:0] | CR_SEGCFG3 | cr_segcfg read/write control register |
+--------+------------+---------------------------------------+

