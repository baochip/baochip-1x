AES
===

Register Listing for AES
------------------------

+--------------------------------------------------------------+-----------------------------------------------+
| Register                                                     | Address                                       |
+==============================================================+===============================================+
| :ref:`AES_SFR_CRFUNC <AES_SFR_CRFUNC>`                       | :ref:`0x4002d000 <AES_SFR_CRFUNC>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_AR <AES_SFR_AR>`                               | :ref:`0x4002d004 <AES_SFR_AR>`                |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_SRMFSM <AES_SFR_SRMFSM>`                       | :ref:`0x4002d008 <AES_SFR_SRMFSM>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_FR <AES_SFR_FR>`                               | :ref:`0x4002d00c <AES_SFR_FR>`                |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_OPT <AES_SFR_OPT>`                             | :ref:`0x4002d010 <AES_SFR_OPT>`               |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_OPT1 <AES_SFR_OPT1>`                           | :ref:`0x4002d014 <AES_SFR_OPT1>`              |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_OPTLTX <AES_SFR_OPTLTX>`                       | :ref:`0x4002d018 <AES_SFR_OPTLTX>`            |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_MASKSEED <AES_SFR_MASKSEED>`                   | :ref:`0x4002d020 <AES_SFR_MASKSEED>`          |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_MASKSEEDAR <AES_SFR_MASKSEEDAR>`               | :ref:`0x4002d024 <AES_SFR_MASKSEEDAR>`        |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_SEGPTR_PTRID_IV <AES_SFR_SEGPTR_PTRID_IV>`     | :ref:`0x4002d030 <AES_SFR_SEGPTR_PTRID_IV>`   |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_SEGPTR_PTRID_AKEY <AES_SFR_SEGPTR_PTRID_AKEY>` | :ref:`0x4002d034 <AES_SFR_SEGPTR_PTRID_AKEY>` |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_SEGPTR_PTRID_AIB <AES_SFR_SEGPTR_PTRID_AIB>`   | :ref:`0x4002d038 <AES_SFR_SEGPTR_PTRID_AIB>`  |
+--------------------------------------------------------------+-----------------------------------------------+
| :ref:`AES_SFR_SEGPTR_PTRID_AOB <AES_SFR_SEGPTR_PTRID_AOB>`   | :ref:`0x4002d03c <AES_SFR_SEGPTR_PTRID_AOB>`  |
+--------------------------------------------------------------+-----------------------------------------------+

AES_SFR_CRFUNC
^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x0 = 0x4002d000`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_CRFUNC

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

AES_SFR_AR
^^^^^^^^^^

`Address: 0x4002d000 + 0x4 = 0x4002d004`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_AR

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

AES_SFR_SRMFSM
^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x8 = 0x4002d008`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_SRMFSM

        {
            "reg": [
                {"name": "sfr_srmfsm",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+--------------------------------------+
| Field | Name       | Description                          |
+=======+============+======================================+
| [7:0] | SFR_SRMFSM | sfr_srmfsm read only status register |
+-------+------------+--------------------------------------+

AES_SFR_FR
^^^^^^^^^^

`Address: 0x4002d000 + 0xc = 0x4002d00c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_FR

        {
            "reg": [
                {"name": "mfsm_done",  "bits": 1},
                {"name": "acore_done",  "bits": 1},
                {"name": "chnlo_done",  "bits": 1},
                {"name": "chnli_done",  "bits": 1},
                {"bits": 28}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------------------------------------------------+
| Field | Name       | Description                                                                      |
+=======+============+==================================================================================+
| [0]   | MFSM_DONE  | mfsm_done flag register. `1` means event happened, write back `1` in respective  |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [1]   | ACORE_DONE | acore_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [2]   | CHNLO_DONE | chnlo_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [3]   | CHNLI_DONE | chnli_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+

AES_SFR_OPT
^^^^^^^^^^^

`Address: 0x4002d000 + 0x10 = 0x4002d010`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_OPT

        {
            "reg": [
                {"name": "opt_klen0",  "bits": 4},
                {"name": "opt_mode0",  "bits": 4},
                {"name": "opt_ifstart0",  "bits": 1},
                {"bits": 23}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+------------------------------------------+
| Field | Name         | Description                              |
+=======+==============+==========================================+
| [3:0] | OPT_KLEN0    | opt_klen0 read/write control register    |
+-------+--------------+------------------------------------------+
| [7:4] | OPT_MODE0    | opt_mode0 read/write control register    |
+-------+--------------+------------------------------------------+
| [8]   | OPT_IFSTART0 | opt_ifstart0 read/write control register |
+-------+--------------+------------------------------------------+

AES_SFR_OPT1
^^^^^^^^^^^^

`Address: 0x4002d000 + 0x14 = 0x4002d014`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_OPT1

        {
            "reg": [
                {"name": "sfr_opt1",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------+
| Field  | Name     | Description                          |
+========+==========+======================================+
| [15:0] | SFR_OPT1 | sfr_opt1 read/write control register |
+--------+----------+--------------------------------------+

AES_SFR_OPTLTX
^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x18 = 0x4002d018`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_OPTLTX

        {
            "reg": [
                {"name": "sfr_optltx",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [5:0] | SFR_OPTLTX | sfr_optltx read/write control register |
+-------+------------+----------------------------------------+

AES_SFR_MASKSEED
^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x20 = 0x4002d020`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_MASKSEED

        {
            "reg": [
                {"name": "sfr_maskseed",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+--------------+------------------------------------------+
| Field  | Name         | Description                              |
+========+==============+==========================================+
| [31:0] | SFR_MASKSEED | sfr_maskseed read/write control register |
+--------+--------------+------------------------------------------+

AES_SFR_MASKSEEDAR
^^^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x24 = 0x4002d024`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_MASKSEEDAR

        {
            "reg": [
                {"name": "sfr_maskseedar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------------------+
| Field  | Name           | Description                                            |
+========+================+========================================================+
| [31:0] | SFR_MASKSEEDAR | sfr_maskseedar performs action on write of value: 0x5a |
+--------+----------------+--------------------------------------------------------+

AES_SFR_SEGPTR_PTRID_IV
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x30 = 0x4002d030`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_SEGPTR_PTRID_IV

        {
            "reg": [
                {"name": "PTRID_IV",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------------+
| Field  | Name     | Description                                |
+========+==========+============================================+
| [11:0] | PTRID_IV | cr_segptrstart read/write control register |
+--------+----------+--------------------------------------------+

AES_SFR_SEGPTR_PTRID_AKEY
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x34 = 0x4002d034`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_SEGPTR_PTRID_AKEY

        {
            "reg": [
                {"name": "PTRID_AKEY",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+--------------------------------------------+
| Field  | Name       | Description                                |
+========+============+============================================+
| [11:0] | PTRID_AKEY | cr_segptrstart read/write control register |
+--------+------------+--------------------------------------------+

AES_SFR_SEGPTR_PTRID_AIB
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x38 = 0x4002d038`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_SEGPTR_PTRID_AIB

        {
            "reg": [
                {"name": "PTRID_AIB",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------------+
| Field  | Name      | Description                                |
+========+===========+============================================+
| [11:0] | PTRID_AIB | cr_segptrstart read/write control register |
+--------+-----------+--------------------------------------------+

AES_SFR_SEGPTR_PTRID_AOB
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002d000 + 0x3c = 0x4002d03c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/aes.sv

    .. wavedrom::
        :caption: AES_SFR_SEGPTR_PTRID_AOB

        {
            "reg": [
                {"name": "PTRID_AOB",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------------+
| Field  | Name      | Description                                |
+========+===========+============================================+
| [11:0] | PTRID_AOB | cr_segptrstart read/write control register |
+--------+-----------+--------------------------------------------+

