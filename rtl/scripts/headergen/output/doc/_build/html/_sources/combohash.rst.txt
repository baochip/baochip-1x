COMBOHASH
=========

Register Listing for COMBOHASH
------------------------------

+----------------------------------------------------------------------------+------------------------------------------------------+
| Register                                                                   | Address                                              |
+============================================================================+======================================================+
| :ref:`COMBOHASH_SFR_CRFUNC <COMBOHASH_SFR_CRFUNC>`                         | :ref:`0x4002b000 <COMBOHASH_SFR_CRFUNC>`             |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_AR <COMBOHASH_SFR_AR>`                                 | :ref:`0x4002b004 <COMBOHASH_SFR_AR>`                 |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SRMFSM <COMBOHASH_SFR_SRMFSM>`                         | :ref:`0x4002b008 <COMBOHASH_SFR_SRMFSM>`             |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_FR <COMBOHASH_SFR_FR>`                                 | :ref:`0x4002b00c <COMBOHASH_SFR_FR>`                 |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_OPT1 <COMBOHASH_SFR_OPT1>`                             | :ref:`0x4002b010 <COMBOHASH_SFR_OPT1>`               |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_OPT2 <COMBOHASH_SFR_OPT2>`                             | :ref:`0x4002b014 <COMBOHASH_SFR_OPT2>`               |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_OPT3 <COMBOHASH_SFR_OPT3>`                             | :ref:`0x4002b018 <COMBOHASH_SFR_OPT3>`               |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_BLKT0 <COMBOHASH_SFR_BLKT0>`                           | :ref:`0x4002b01c <COMBOHASH_SFR_BLKT0>`              |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_LKEY <COMBOHASH_SFR_SEGPTR_SEGID_LKEY>`   | :ref:`0x4002b020 <COMBOHASH_SFR_SEGPTR_SEGID_LKEY>`  |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_KEY <COMBOHASH_SFR_SEGPTR_SEGID_KEY>`     | :ref:`0x4002b024 <COMBOHASH_SFR_SEGPTR_SEGID_KEY>`   |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_SCRT <COMBOHASH_SFR_SEGPTR_SEGID_SCRT>`   | :ref:`0x4002b02c <COMBOHASH_SFR_SEGPTR_SEGID_SCRT>`  |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_MSG <COMBOHASH_SFR_SEGPTR_SEGID_MSG>`     | :ref:`0x4002b030 <COMBOHASH_SFR_SEGPTR_SEGID_MSG>`   |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_HOUT <COMBOHASH_SFR_SEGPTR_SEGID_HOUT>`   | :ref:`0x4002b034 <COMBOHASH_SFR_SEGPTR_SEGID_HOUT>`  |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_SEGPTR_SEGID_HOUT2 <COMBOHASH_SFR_SEGPTR_SEGID_HOUT2>` | :ref:`0x4002b03c <COMBOHASH_SFR_SEGPTR_SEGID_HOUT2>` |
+----------------------------------------------------------------------------+------------------------------------------------------+
| :ref:`COMBOHASH_SFR_KEYIDX <COMBOHASH_SFR_KEYIDX>`                         | :ref:`0x4002b060 <COMBOHASH_SFR_KEYIDX>`             |
+----------------------------------------------------------------------------+------------------------------------------------------+

COMBOHASH_SFR_CRFUNC
^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x0 = 0x4002b000`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_CRFUNC

        {
            "reg": [
                {"name": "cr_func",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+---------+-------------------------------------+
| Field | Name    | Description                         |
+=======+=========+=====================================+
| [7:0] | CR_FUNC | cr_func read/write control register |
+-------+---------+-------------------------------------+

COMBOHASH_SFR_AR
^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x4 = 0x4002b004`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_AR

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

COMBOHASH_SFR_SRMFSM
^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x8 = 0x4002b008`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SRMFSM

        {
            "reg": [
                {"name": "mfsm",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------+--------------------------------+
| Field | Name | Description                    |
+=======+======+================================+
| [7:0] | MFSM | mfsm read only status register |
+-------+------+--------------------------------+

COMBOHASH_SFR_FR
^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0xc = 0x4002b00c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_FR

        {
            "reg": [
                {"name": "mfsm_done",  "bits": 1},
                {"name": "hash_done",  "bits": 1},
                {"name": "chnlo_done",  "bits": 1},
                {"name": "chnli_done",  "bits": 1},
                {"name": "chkdone",  "bits": 1},
                {"name": "chkpass",  "bits": 1},
                {"name": "chkfail",  "bits": 1},
                {"bits": 25}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+------------+----------------------------------------------------------------------------------+
| Field | Name       | Description                                                                      |
+=======+============+==================================================================================+
| [0]   | MFSM_DONE  | mfsm_done flag register. `1` means event happened, write back `1` in respective  |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [1]   | HASH_DONE  | hash_done flag register. `1` means event happened, write back `1` in respective  |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [2]   | CHNLO_DONE | chnlo_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [3]   | CHNLI_DONE | chnli_done flag register. `1` means event happened, write back `1` in respective |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [4]   | CHKDONE    | chkdone flag register. `1` means event happened, write back `1` in respective    |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [5]   | CHKPASS    | chkpass flag register. `1` means event happened, write back `1` in respective    |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+
| [6]   | CHKFAIL    | chkfail flag register. `1` means event happened, write back `1` in respective    |
|       |            | bit position to clear the flag                                                   |
+-------+------------+----------------------------------------------------------------------------------+

COMBOHASH_SFR_OPT1
^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x10 = 0x4002b010`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_OPT1

        {
            "reg": [
                {"name": "cr_opt_hashcnt",  "bits": 16},
                {"bits": 16}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------------+--------------------------------------------+
| Field  | Name           | Description                                |
+========+================+============================================+
| [15:0] | CR_OPT_HASHCNT | cr_opt_hashcnt read/write control register |
+--------+----------------+--------------------------------------------+

COMBOHASH_SFR_OPT2
^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x14 = 0x4002b014`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_OPT2

        {
            "reg": [
                {"name": "cr_opt_scrtchk",  "bits": 1},
                {"name": "cr_opt_ifsob",  "bits": 1},
                {"name": "cr_opt_ifstart",  "bits": 1},
                {"name": "opt_schnr1_0",  "bits": 1},
                {"name": "tsmode",  "bits": 1},
                {"name": "cr_opt_ifskey",  "bits": 1},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+----------------+--------------------------------------------+
| Field | Name           | Description                                |
+=======+================+============================================+
| [0]   | CR_OPT_SCRTCHK | cr_opt.scrtchk read/write control register |
+-------+----------------+--------------------------------------------+
| [1]   | CR_OPT_IFSOB   | cr_opt.ifsob read/write control register   |
+-------+----------------+--------------------------------------------+
| [2]   | CR_OPT_IFSTART | cr_opt.ifstart read/write control register |
+-------+----------------+--------------------------------------------+
| [3]   | OPT_SCHNR1_0   | opt_schnr[1:0] read/write control register |
+-------+----------------+--------------------------------------------+
| [4]   | TSMODE         | tsmode read/write control register         |
+-------+----------------+--------------------------------------------+
| [5]   | CR_OPT_IFSKEY  | cr_opt.ifskey read/write control register  |
+-------+----------------+--------------------------------------------+

COMBOHASH_SFR_OPT3
^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x18 = 0x4002b018`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_OPT3

        {
            "reg": [
                {"name": "sfr_opt3",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+----------+--------------------------------------+
| Field | Name     | Description                          |
+=======+==========+======================================+
| [7:0] | SFR_OPT3 | sfr_opt3 read/write control register |
+-------+----------+--------------------------------------+

COMBOHASH_SFR_BLKT0
^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x1c = 0x4002b01c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_BLKT0

        {
            "reg": [
                {"name": "sfr_blkt0",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-----------+---------------------------------------+
| Field | Name      | Description                           |
+=======+===========+=======================================+
| [7:0] | SFR_BLKT0 | sfr_blkt0 read/write control register |
+-------+-----------+---------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_LKEY
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x20 = 0x4002b020`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_LKEY

        {
            "reg": [
                {"name": "SEGID_LKEY",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+--------------------------------------------+
| Field  | Name       | Description                                |
+========+============+============================================+
| [11:0] | SEGID_LKEY | cr_segptrstart read/write control register |
+--------+------------+--------------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_KEY
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x24 = 0x4002b024`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_KEY

        {
            "reg": [
                {"name": "SEGID_KEY",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------------+
| Field  | Name      | Description                                |
+========+===========+============================================+
| [11:0] | SEGID_KEY | cr_segptrstart read/write control register |
+--------+-----------+--------------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_SCRT
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x2c = 0x4002b02c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_SCRT

        {
            "reg": [
                {"name": "SEGID_SCRT",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+--------------------------------------------+
| Field  | Name       | Description                                |
+========+============+============================================+
| [11:0] | SEGID_SCRT | cr_segptrstart read/write control register |
+--------+------------+--------------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_MSG
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x30 = 0x4002b030`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_MSG

        {
            "reg": [
                {"name": "SEGID_MSG",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+--------------------------------------------+
| Field  | Name      | Description                                |
+========+===========+============================================+
| [11:0] | SEGID_MSG | cr_segptrstart read/write control register |
+--------+-----------+--------------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_HOUT
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x34 = 0x4002b034`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_HOUT

        {
            "reg": [
                {"name": "SEGID_HOUT",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------+--------------------------------------------+
| Field  | Name       | Description                                |
+========+============+============================================+
| [11:0] | SEGID_HOUT | cr_segptrstart read/write control register |
+--------+------------+--------------------------------------------+

COMBOHASH_SFR_SEGPTR_SEGID_HOUT2
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x3c = 0x4002b03c`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_SEGPTR_SEGID_HOUT2

        {
            "reg": [
                {"name": "SEGID_HOUT2",  "bits": 12},
                {"bits": 20}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+--------------------------------------------+
| Field  | Name        | Description                                |
+========+=============+============================================+
| [11:0] | SEGID_HOUT2 | cr_segptrstart read/write control register |
+--------+-------------+--------------------------------------------+

COMBOHASH_SFR_KEYIDX
^^^^^^^^^^^^^^^^^^^^

`Address: 0x4002b000 + 0x60 = 0x4002b060`

    See file:///F:/code/cram-nto/../../modules/crypto_top/rtl/combohasha.sv

    .. wavedrom::
        :caption: COMBOHASH_SFR_KEYIDX

        {
            "reg": [
                {"name": "sfr_keyidx",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [9:0] | SFR_KEYIDX | sfr_keyidx read/write control register |
+-------+------------+----------------------------------------+

