// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

module powerpad (

        output wire rto_pa,
        output wire sns_pa,
        output wire rto_pbc,
        output wire sns_pbc,
        output wire rto_pd,
        output wire sns_pd,
        output wire rto_pe,
        output wire sns_pe,
        output wire rto_ao,
        output wire sns_ao,
        output wire rto_qfc,
        output wire sns_qfc,
        output wire rto_rr1,
        output wire sns_rr1,
        output wire rto_rr0,
        output wire sns_rr0,
        output wire rto_pmu,
        output wire sns_pmu,

        input wire pvsense_reton,
        input wire pvsense_retoff

);


// PA:
            PDVDD_33_33_NT_DR_H      gvdd33_h_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PDVSS_33_33_NT_DR_H      gvss33_h_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PDVSS_33_33_NT_DR_V      gvss33_v_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));

            PVSS_09_09_NT_DR_H      gvss09_h_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PVDD_09_09_NT_DR_H      gvdd09_h_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PVSS_09_09_NT_DR_V      gvss09_v_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));
            PVDD_09_09_NT_DR_V      gvdd09_v_0__u_pa ( .RTO( rto_pa ), .SNS( sns_pa ));

// always on:

            PDVDD_33_33_NT_DR_V      gvdd33_v_0__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PDVSS_33_33_NT_DR_V      gvss33_v_0__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PDVSS_33_33_NT_DR_V      gvss33_v_2__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PVSS_09_09_NT_DR_V       gvss09_v_0__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PVSS_09_09_NT_DR_V       gvss09_v_1__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PVDD_09_09_NT_DR_V       gvdd09_v_0__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PVDD_09_09_NT_DR_V       gvdd09_v_1__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));
            PDVDDTIE_33_33_NT_DR_V   gvddtie_v__u_ao ( .RTO( rto_ao ), .SNS( sns_ao ));

// QFC:
            PDVDD_33_33_NT_DR_H      gvdd33_h_0__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_0__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_1__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_1__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_2__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_2__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_3__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_3__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_4__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_4__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_5__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_5__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));

            PVDD_09_09_NT_DR_H      gvdd09_h_0__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PVSS_09_09_NT_DR_H      gvss09_h_0__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PVDD_09_09_NT_DR_H      gvdd09_h_1__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));
            PVSS_09_09_NT_DR_H      gvss09_h_1__u_qfc ( .RTO( rto_qfc ), .SNS( sns_qfc ));

// PB&PC
            PDVDD_33_33_NT_DR_H      gvdd33_h_0__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_0__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_1__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_1__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_2__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_2__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_3__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_3__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_4__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_4__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_5__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PDVSS_33_33_NT_DR_H      gvss33_h_5__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));

            PVSS_09_09_NT_DR_H      gvss09_h_0__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVDD_09_09_NT_DR_H      gvdd09_h_0__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVSS_09_09_NT_DR_H      gvss09_h_1__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVDD_09_09_NT_DR_H      gvdd09_h_1__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVSS_09_09_NT_DR_H      gvss09_h_2__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVDD_09_09_NT_DR_H      gvdd09_h_2__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVSS_09_09_NT_DR_H      gvss09_h_3__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));
            PVDD_09_09_NT_DR_H      gvdd09_h_3__u_pbc ( .RTO( rto_pbc ), .SNS( sns_pbc ));

// PD:
            //PDVSS_33_33_NT_DR_H      gvss33_h_0__u_pd ( .RTO( rto_px ), .SNS( sns_px ));
            PDVSS_33_33_NT_DR_V      gvss33_v_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PDVSS_33_33_NT_DR_V      gvss33_v_2__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_2__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));

            PVDD_09_09_NT_DR_H      gvdd09_h_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PVSS_09_09_NT_DR_H      gvss09_h_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PVDD_09_09_NT_DR_V      gvdd09_v_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));
            PVSS_09_09_NT_DR_V      gvss09_v_0__u_pd ( .RTO( rto_pd ), .SNS( sns_pd ));

// PE:
            PVSS_09_09_NT_DR_H       gvss09_h_0__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVDD_09_09_NT_DR_H       gvdd09_h_0__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVSS_09_09_NT_DR_H       gvss09_h_1__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVDD_09_09_NT_DR_H       gvdd09_h_1__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVSS_33_33_NT_DR_H      gvss33_h_0__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_0__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVSS_33_33_NT_DR_H      gvss33_h_1__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_1__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVSS_33_33_NT_DR_H      gvss33_h_2__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_H      gvdd33_h_2__u_pe ( .RTO( rto_pe ), .SNS( sns_pe ));

// TESTPAD:

            PVDD_09_09_NT_DR_V       gvdd09_v_0__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVSS_09_09_NT_DR_V       gvss09_v_0__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVSS_09_09_NT_DR_V       gvss09_v_1__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PVDD_09_09_NT_DR_V       gvdd09_v_1__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));

            PDVSS_33_33_NT_DR_V      gvss33_v_0__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_0__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_2__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));
            PDVSS_33_33_NT_DR_V      gvss33_v_2__u_test ( .RTO( rto_pe ), .SNS( sns_pe ));


// RRAM1:
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_2__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));//zmj 20231002
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PDVSS_33_33_NT_DR_V      gvss33_v_2__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PDVSS_33_33_NT_DR_V      gvss33_v_3__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));//zmj 20231003
            PDVSS_33_33_NT_DR_V      gvss33_v_4__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PVDD_09_09_NT_DR_V       gvdd09_v_1__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PVSS_09_09_NT_DR_V       gvss09_v_1__u_rram1 ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));
            PDVDDTIE_33_33_NT_DR_V   gvddtie_rr1__u      ( .RTO( rto_rr1 ), .SNS( sns_rr1 ));//## exchange pair A

// RRAM0:
            PDVDD_33_33_NT_DR_V      gvdd33_v_1__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PDVDD_33_33_NT_DR_V      gvdd33_v_2__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PDVSS_33_33_NT_DR_V      gvss33_v_1__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PDVSS_33_33_NT_DR_V      gvss33_v_2__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PDVSS_33_33_NT_DR_V      gvss33_v_3__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));//zmj 20231003
            PDVSS_33_33_NT_DR_V      gvss33_v_4__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PVDD_09_09_NT_DR_V       gvdd09_v_1__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PVSS_09_09_NT_DR_V       gvss09_v_1__u_rram0 ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));
            PDVDDTIE_33_33_NT_DR_V      gvddtie_rr0__u ( .RTO( rto_rr0 ), .SNS( sns_rr0 ));

// PMU:


            PDVDD_33_33_NT_DR_V     gvdd33_v_0__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PDVDD_33_33_NT_DR_V     gvdd33_v_1__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));//## exchange pair A

            PDVSS_33_33_NT_DR_V     gvss33_v_0__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PDVSS_33_33_NT_DR_V     gvss33_v_1__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));

            PVDD_09_09_NT_DR_V      gvdd09_v_0__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVDD_09_09_NT_DR_V      gvdd09_v_1__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVSS_09_09_NT_DR_V      gvss09_v_0__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVSS_09_09_NT_DR_V      gvss09_v_1__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));


            PDVDDTIE_33_33_NT_DR_V     gvddtie_v__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PANALOG_33_33_NT_DR_V      upll_vcca ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PANALOG_33_33_NT_DR_V      upll_vssa ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVDDI_09_09_NT_DR_V        upll_vccd ( .RTO( rto_pmu ), .SNS( sns_pmu ));

            PVDDI_09_09_NT_DR_V  gvddi_0__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVDDI_09_09_NT_DR_V  gvddi_1__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVDDI_09_09_NT_DR_V  gvddi_2__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));
            PVDDI_09_09_NT_DR_V  gvddi_3__u_pmu ( .RTO( rto_pmu ), .SNS( sns_pmu ));


wire rto_qfc_rr0, sns_qfc_rr0;
            PBRKB2B_33_33_NT_DR gbrkb2b_v_test_rr0 (.RTOBRK( rto_pe ),.SNSBRK( sns_pe ),.RTO( rto_rr0 ),.SNS( sns_rr0 ));

            PBRKB2B_33_33_NT_DR gbrkb2b_v_rr0_rr1 (.RTOBRK( rto_rr0 ),.SNSBRK( sns_rr0 ),.RTO( rto_rr1 ),.SNS( sns_rr1 ));

            PBRKB2B_33_33_NT_DR gbrkb2b_v_rr1_pd (.RTOBRK( rto_rr1 ),.SNSBRK( sns_rr1 ),.RTO( rto_pd ),.SNS(sns_pd  ));

            PBRKB2B_33_33_NT_DR gbrkb2b_h_pd_pbc (.RTOBRK( rto_pd ),.SNSBRK( sns_pd ),.RTO( rto_pbc ),.SNS( sns_pbc ));

            PBRKB2B_33_33_NT_DR gbrkb2b_h_pbc_pa (.RTOBRK( rto_pbc ),.SNSBRK( sns_pbc ),.RTO( rto_pa ),.SNS( sns_pa ));

            PBRKB2B_33_33_NT_DR gbrkb2b_v_pa_ao (.RTOBRK( rto_pa ),.SNSBRK( sns_pa ),.RTO( rto_ao ),.SNS( sns_ao ));

            PBRKB2B_33_33_NT_DR gbrkb2b_v_ao_pmu (.RTOBRK( rto_ao ),.SNSBRK( sns_ao ),.RTO( rto_pmu ),.SNS(sns_pmu  ));

            PBRKB2B_33_33_NT_DR gbrkb2b_h_pmu_qfc (.RTOBRK( rto_pmu ),.SNSBRK( sns_pmu ),.RTO( rto_qfc ),.SNS( sns_qfc ));

            PBRKB2B_33_33_NT_DR  gbrkb2b_v_qfc_test (.RTOBRK( rto_qfc ),.SNSBRK( sns_qfc ),.RTO(rto_pe  ),.SNS(sns_pe  ));

            PBRKANALOGB2B_33_33_NT_DR brkana_v_test (.RTO( rto_pe ),.SNS( sns_pe ));

            PVSENSE_33_33_NT_DR_H gvsense_0__u_qfc (.RTO(rto_qfc ),.SNS( sns_qfc ),.RETOFF(pvsense_retoff),.RETON(pvsense_reton));
            PVSENSE_33_33_NT_DR_H gvsense_1__u_pe  (.RTO(rto_pe  ),.SNS( sns_pe ),.RETOFF(pvsense_retoff),.RETON(pvsense_reton));
            PVSENSE_33_33_NT_DR_H gvsense_2__u_pbc (.RTO(rto_pbc  ),.SNS( sns_pbc ),.RETOFF(pvsense_retoff),.RETON(pvsense_reton));
            PVSENSE_33_33_NT_DR_V gvsense_3__u_pd  (.RTO(rto_pd  ),.SNS( sns_pd ),.RETOFF(pvsense_retoff),.RETON(pvsense_reton));
            PVSENSE_33_33_NT_DR_V gvsense_4__u_pa  (.RTO(rto_pa  ),.SNS( sns_pa ),.RETOFF(pvsense_retoff),.RETON(pvsense_reton));





endmodule

`ifdef SIM
module PBRKB2B_33_33_NT_DR (
                RTO,
                RTOBRK,
                SNS,
                SNSBRK
 );
   input SNS;
   input RTO;
   input SNSBRK;
   input RTOBRK;
endmodule // PBRKB2B_33_33_NT_DR

module PBRK_33_33_NT_DR (
                RTO,
                RTOBRK,
                SNS,
                SNSBRK
 );
   input SNS;
   input RTO;
   input SNSBRK;
   input RTOBRK;
endmodule // PBRKB2B_33_33_NT_DR
module PFILL10_33_33_NT_DR ( input SNS, input RTO ); endmodule

module PVDD_09_09_NT_DR_H ( input SNS, input RTO ); endmodule
module PVSS_09_09_NT_DR_H ( input SNS, input RTO ); endmodule
module PDVDD_33_33_NT_DR_H ( input SNS, input RTO ); endmodule
module PDVSS_33_33_NT_DR_H ( input SNS, input RTO ); endmodule
module PVSENSE_33_33_NT_DR_H ( output SNS, output RTO, input RETOFF, input RETON );
        assign SNS = '1;
        assign RTO = '1;
endmodule
module PDVDDTIE_33_33_NT_DR_H ( output SNS, output RTO );
        assign SNS = '1;
        assign RTO = '1;
endmodule
module PVDDI_09_09_NT_DR_H ( input SNS, input RTO ); endmodule
module PBRKANALOGB2B_33_33_NT_DR ( input SNS, input RTO ); endmodule

module PVDD_09_09_NT_DR_V ( input SNS, input RTO ); endmodule
module PVSS_09_09_NT_DR_V ( input SNS, input RTO ); endmodule
module PDVDD_33_33_NT_DR_V ( input SNS, input RTO ); endmodule
module PDVSS_33_33_NT_DR_V ( input SNS, input RTO ); endmodule
module PVSENSE_33_33_NT_DR_V ( output SNS, output RTO, input RETOFF, input RETON );
        assign SNS = '1;
        assign RTO = '1;
endmodule
module PDVDDTIE_33_33_NT_DR_V ( output SNS, output RTO );
        assign SNS = '1;
        assign RTO = '1;
endmodule
module PVDDI_09_09_NT_DR_V ( input SNS, input RTO ); endmodule

`endif
