AO_SYSCTRL
==========

Register Listing for AO_SYSCTRL
-------------------------------

+------------------------------------------------------------------+-------------------------------------------------+
| Register                                                         | Address                                         |
+==================================================================+=================================================+
| :ref:`AO_SYSCTRL_CR_CR <AO_SYSCTRL_CR_CR>`                       | :ref:`0x40060000 <AO_SYSCTRL_CR_CR>`            |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_CR_CLK1HZFD <AO_SYSCTRL_CR_CLK1HZFD>`           | :ref:`0x40060004 <AO_SYSCTRL_CR_CLK1HZFD>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_CR_WKUPMASK <AO_SYSCTRL_CR_WKUPMASK>`           | :ref:`0x40060008 <AO_SYSCTRL_CR_WKUPMASK>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_CR_RSTCRMASK <AO_SYSCTRL_CR_RSTCRMASK>`         | :ref:`0x4006000c <AO_SYSCTRL_CR_RSTCRMASK>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUCSR <AO_SYSCTRL_SFR_PMUCSR>`             | :ref:`0x40060010 <AO_SYSCTRL_SFR_PMUCSR>`       |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUCRLP <AO_SYSCTRL_SFR_PMUCRLP>`           | :ref:`0x40060014 <AO_SYSCTRL_SFR_PMUCRLP>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUCRPD <AO_SYSCTRL_SFR_PMUCRPD>`           | :ref:`0x40060018 <AO_SYSCTRL_SFR_PMUCRPD>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUDFTSR <AO_SYSCTRL_SFR_PMUDFTSR>`         | :ref:`0x4006001c <AO_SYSCTRL_SFR_PMUDFTSR>`     |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUTRM0CSR <AO_SYSCTRL_SFR_PMUTRM0CSR>`     | :ref:`0x40060020 <AO_SYSCTRL_SFR_PMUTRM0CSR>`   |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUTRM1CSR <AO_SYSCTRL_SFR_PMUTRM1CSR>`     | :ref:`0x40060024 <AO_SYSCTRL_SFR_PMUTRM1CSR>`   |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUTRMLP0 <AO_SYSCTRL_SFR_PMUTRMLP0>`       | :ref:`0x40060028 <AO_SYSCTRL_SFR_PMUTRMLP0>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUTRMLP1 <AO_SYSCTRL_SFR_PMUTRMLP1>`       | :ref:`0x4006002c <AO_SYSCTRL_SFR_PMUTRMLP1>`    |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_OSCCR <AO_SYSCTRL_SFR_OSCCR>`               | :ref:`0x40060034 <AO_SYSCTRL_SFR_OSCCR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUSR <AO_SYSCTRL_SFR_PMUSR>`               | :ref:`0x40060038 <AO_SYSCTRL_SFR_PMUSR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUFR <AO_SYSCTRL_SFR_PMUFR>`               | :ref:`0x4006003c <AO_SYSCTRL_SFR_PMUFR>`        |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_AOFR <AO_SYSCTRL_SFR_AOFR>`                 | :ref:`0x40060040 <AO_SYSCTRL_SFR_AOFR>`         |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_PMUPDAR <AO_SYSCTRL_SFR_PMUPDAR>`           | :ref:`0x40060044 <AO_SYSCTRL_SFR_PMUPDAR>`      |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_AR_AOPERI_CLRINT <AO_SYSCTRL_AR_AOPERI_CLRINT>` | :ref:`0x40060050 <AO_SYSCTRL_AR_AOPERI_CLRINT>` |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_IOX <AO_SYSCTRL_SFR_IOX>`                   | :ref:`0x40060060 <AO_SYSCTRL_SFR_IOX>`          |
+------------------------------------------------------------------+-------------------------------------------------+
| :ref:`AO_SYSCTRL_SFR_AOPADPU <AO_SYSCTRL_SFR_AOPADPU>`           | :ref:`0x40060064 <AO_SYSCTRL_SFR_AOPADPU>`      |
+------------------------------------------------------------------+-------------------------------------------------+

AO_SYSCTRL_CR_CR
^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x0 = 0x40060000`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_CR_CR

        {
            "reg": [
                {"name": "clk32kselreg",  "bits": 1},
                {"name": "pdisoen",  "bits": 1},
                {"name": "pclkicg",  "bits": 1},
                {"bits": 29}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+------------------------------------------+
| Field | Name         | Description                              |
+=======+==============+==========================================+
| [0]   | CLK32KSELREG | clk32kselreg read/write control register |
+-------+--------------+------------------------------------------+
| [1]   | PDISOEN      | pdisoen read/write control register      |
+-------+--------------+------------------------------------------+
| [2]   | PCLKICG      | pclkicg read/write control register      |
+-------+--------------+------------------------------------------+

AO_SYSCTRL_CR_CLK1HZFD
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x4 = 0x40060004`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_CR_CLK1HZFD

        {
            "reg": [
                {"name": "cr_clk1hzfd",  "bits": 14},
                {"bits": 18}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+-----------------------------------------+
| Field  | Name        | Description                             |
+========+=============+=========================================+
| [13:0] | CR_CLK1HZFD | cr_clk1hzfd read/write control register |
+--------+-------------+-----------------------------------------+

AO_SYSCTRL_CR_WKUPMASK
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x8 = 0x40060008`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_CR_WKUPMASK

        {
            "reg": [
                {"name": "inten",  "bits": 8},
                {"name": "wkupmask",  "bits": 10},
                {"bits": 14}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+----------+--------------------------------------+
| Field  | Name     | Description                          |
+========+==========+======================================+
| [7:0]  | INTEN    | inten read/write control register    |
+--------+----------+--------------------------------------+
| [17:8] | WKUPMASK | wkupmask read/write control register |
+--------+----------+--------------------------------------+

AO_SYSCTRL_CR_RSTCRMASK
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0xc = 0x4006000c`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_CR_RSTCRMASK

        {
            "reg": [
                {"name": "cr_rstcrmask",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+--------------+------------------------------------------+
| Field | Name         | Description                              |
+=======+==============+==========================================+
| [4:0] | CR_RSTCRMASK | cr_rstcrmask read/write control register |
+-------+--------------+------------------------------------------+

AO_SYSCTRL_SFR_PMUCSR
^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x10 = 0x40060010`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUCSR

        {
            "reg": [
                {"name": "pmucrreg",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+----------+------------------------------------+
| Field | Name     | Description                        |
+=======+==========+====================================+
| [7:0] | PMUCRREG | pmucrreg read only status register |
+-------+----------+------------------------------------+

AO_SYSCTRL_SFR_PMUCRLP
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x14 = 0x40060014`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUCRLP

        {
            "reg": [
                {"name": "sfrpmucrlp",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | SFRPMUCRLP | sfrpmucrlp read/write control register |
+-------+------------+----------------------------------------+

AO_SYSCTRL_SFR_PMUCRPD
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x18 = 0x40060018`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUCRPD

        {
            "reg": [
                {"name": "sfrpmucrpd",  "bits": 8},
                {"bits": 24}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+------------+----------------------------------------+
| Field | Name       | Description                            |
+=======+============+========================================+
| [7:0] | SFRPMUCRPD | sfrpmucrpd read/write control register |
+-------+------------+----------------------------------------+

AO_SYSCTRL_SFR_PMUDFTSR
^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x1c = 0x4006001c`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUDFTSR

        {
            "reg": [
                {"name": "pmudftreg",  "bits": 6},
                {"bits": 26}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+-------------------------------------+
| Field | Name      | Description                         |
+=======+===========+=====================================+
| [5:0] | PMUDFTREG | pmudftreg read only status register |
+-------+-----------+-------------------------------------+

AO_SYSCTRL_SFR_PMUTRM0CSR
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x20 = 0x40060020`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUTRM0CSR

        {
            "reg": [
                {"name": "pmutrmreg",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-----------+-------------------------------------+
| Field  | Name      | Description                         |
+========+===========+=====================================+
| [31:0] | PMUTRMREG | pmutrmreg read only status register |
+--------+-----------+-------------------------------------+

AO_SYSCTRL_SFR_PMUTRM1CSR
^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x24 = 0x40060024`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUTRM1CSR

        {
            "reg": [
                {"name": "pmutrmreg",  "bits": 2},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+-------------------------------------+
| Field | Name      | Description                         |
+=======+===========+=====================================+
| [1:0] | PMUTRMREG | pmutrmreg read only status register |
+-------+-----------+-------------------------------------+

AO_SYSCTRL_SFR_PMUTRMLP0
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x28 = 0x40060028`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUTRMLP0

        {
            "reg": [
                {"name": "sfrpmutrmlp",  "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+-----------------------------------------+
| Field  | Name        | Description                             |
+========+=============+=========================================+
| [31:0] | SFRPMUTRMLP | sfrpmutrmlp read/write control register |
+--------+-------------+-----------------------------------------+

AO_SYSCTRL_SFR_PMUTRMLP1
^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x2c = 0x4006002c`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUTRMLP1

        {
            "reg": [
                {"name": "sfrpmutrmlp",  "bits": 2},
                {"bits": 30}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [1:0] | SFRPMUTRMLP | sfrpmutrmlp read/write control register |
+-------+-------------+-----------------------------------------+

AO_SYSCTRL_SFR_OSCCR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x34 = 0x40060034`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_OSCCR

        {
            "reg": [
                {"name": "sfrosccr",  "bits": 1},
                {"name": "sfrosctrm",  "bits": 1},
                {"name": "sfrosccrlp",  "bits": 1},
                {"name": "sfrosctrmlp",  "bits": 1},
                {"name": "sfrosccrpd",  "bits": 1},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [0]   | SFROSCCR    | sfrosccr read/write control register    |
+-------+-------------+-----------------------------------------+
| [1]   | SFROSCTRM   | sfrosctrm read/write control register   |
+-------+-------------+-----------------------------------------+
| [2]   | SFROSCCRLP  | sfrosccrlp read/write control register  |
+-------+-------------+-----------------------------------------+
| [3]   | SFROSCTRMLP | sfrosctrmlp read/write control register |
+-------+-------------+-----------------------------------------+
| [4]   | SFROSCCRPD  | sfrosccrpd read/write control register  |
+-------+-------------+-----------------------------------------+

AO_SYSCTRL_SFR_PMUSR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x38 = 0x40060038`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUSR

        {
            "reg": [
                {"name": "sfr_pmusr",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+-------------------------------------+
| Field | Name      | Description                         |
+=======+===========+=====================================+
| [4:0] | SFR_PMUSR | sfr_pmusr read only status register |
+-------+-----------+-------------------------------------+

AO_SYSCTRL_SFR_PMUFR
^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x3c = 0x4006003c`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUFR

        {
            "reg": [
                {"name": "sfr_pmufr",  "bits": 5},
                {"bits": 27}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+-----------+---------------------------------------------------------------------------------+
| Field | Name      | Description                                                                     |
+=======+===========+=================================================================================+
| [4:0] | SFR_PMUFR | sfr_pmufr flag register. `1` means event happened, write back `1` in respective |
|       |           | bit position to clear the flag                                                  |
+-------+-----------+---------------------------------------------------------------------------------+

AO_SYSCTRL_SFR_AOFR
^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x40 = 0x40060040`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_AOFR

        {
            "reg": [
                {"name": "sfr_aofr",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+----------+--------------------------------------------------------------------------------+
| Field | Name     | Description                                                                    |
+=======+==========+================================================================================+
| [9:0] | SFR_AOFR | sfr_aofr flag register. `1` means event happened, write back `1` in respective |
|       |          | bit position to clear the flag                                                 |
+-------+----------+--------------------------------------------------------------------------------+

AO_SYSCTRL_SFR_PMUPDAR
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x44 = 0x40060044`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_PMUPDAR

        {
            "reg": [
                {"name": "sfr_pmupdar",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+-------------+-----------------------------------------------------+
| Field  | Name        | Description                                         |
+========+=============+=====================================================+
| [31:0] | SFR_PMUPDAR | sfr_pmupdar performs action on write of value: 0x5a |
+--------+-------------+-----------------------------------------------------+

AO_SYSCTRL_AR_AOPERI_CLRINT
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x50 = 0x40060050`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_AR_AOPERI_CLRINT

        {
            "reg": [
                {"name": "ar_aoperi_clrint",  "type": 4, "bits": 32}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+--------+------------------+----------------------------------------------------------+
| Field  | Name             | Description                                              |
+========+==================+==========================================================+
| [31:0] | AR_AOPERI_CLRINT | ar_aoperi_clrint performs action on write of value: 0xaa |
+--------+------------------+----------------------------------------------------------+

AO_SYSCTRL_SFR_IOX
^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x60 = 0x40060060`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_IOX

        {
            "reg": [
                {"name": "sfr_iox",  "bits": 1},
                {"bits": 31}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 4 }, "options": {"hspace": 400, "bits": 32, "lanes": 4}
        }


+-------+---------+-------------------------------------+
| Field | Name    | Description                         |
+=======+=========+=====================================+
| [0]   | SFR_IOX | sfr_iox read/write control register |
+-------+---------+-------------------------------------+

AO_SYSCTRL_SFR_AOPADPU
^^^^^^^^^^^^^^^^^^^^^^

`Address: 0x40060000 + 0x64 = 0x40060064`

    See file:///F:/code/cram-nto/../../modules/ao/rtl/ao_sysctrl.sv

    .. wavedrom::
        :caption: AO_SYSCTRL_SFR_AOPADPU

        {
            "reg": [
                {"name": "sfr_aopadpu",  "bits": 10},
                {"bits": 22}
            ], "config": {"hspace": 400, "bits": 32, "lanes": 1 }, "options": {"hspace": 400, "bits": 32, "lanes": 1}
        }


+-------+-------------+-----------------------------------------+
| Field | Name        | Description                             |
+=======+=============+=========================================+
| [9:0] | SFR_AOPADPU | sfr_aopadpu read/write control register |
+-------+-------------+-----------------------------------------+

