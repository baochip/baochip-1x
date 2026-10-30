#!/usr/bin/env bash
#
# Equivalence regression: oss_* AHB bridges vs the closed cmsdk_* models.
#
# Builds one Verilator binary per configuration (open-source re-implementation
# next to the original ARM CMSDK source, ~/bunnie/to-oss) and sweeps the test
# bench parameters (geometry / burst / clock-enable modes) with several random
# seeds per configuration. Every compared cycle checks all DUT outputs of both
# models for equality; $fatal on the first divergence.
#
# usage:  tb/oss_equiv/run_equiv.sh [CYCLES] [SEEDS]
#           CYCLES  compared cycles per run          (default 100000)
#           SEEDS   comma list of seeds per config   (default 1,2,3)
#
set -u
cd "$(dirname "$0")/../.." || exit 1
TOOSS=${TOOSS:-$HOME/bunnie/to-oss}
CYCLES=${1:-100000}
SEEDS=${2:-1,2,3}
BUILD=${BUILD:-/tmp/ossbuild/c$CYCLES}
mkdir -p "$BUILD"

SRC=rtl/modules/amba/rtl
SRC_SYNC="$SRC/oss_ahb_to_ahb_sync.sv $SRC/oss_ahb_to_ahb_sync_err_canc.sv"
REF_SYNC="$TOOSS/ahb_to_ahb_sync/cmsdk_ahb_to_ahb_sync.v $TOOSS/ahb_to_ahb_sync_down/cmsdk_ahb_to_ahb_sync_error_canc.v"
SRC_EC="$SRC/oss_ahb_to_ahb_sync_err_canc.sv"
REF_EC="$TOOSS/ahb_to_ahb_sync_down/cmsdk_ahb_to_ahb_sync_error_canc.v"
SRC_APB="$SRC/oss_ahb_to_apb.sv"
REF_APB="$TOOSS/ahb_to_apb/cmsdk_ahb_to_apb.v"
SRC_SRAM="$SRC/oss_ahb_to_sram.sv"
REF_SRAM="$TOOSS/cmsdk_ahb_to_sram.v"
SRC_MUX="$SRC/oss_ahb_master_mux.sv"
REF_MUX="$TOOSS/cmsdk_ahb_master_mux.v"

fails=0; runs=0

build() { # name top params... sources...
    local name=$1 top=$2; shift 2
    [ -x "$BUILD/$name/tb" ] && return 0
    echo "build $name ..."
    verilator --binary --timing -Wno-fatal --top-module "$top" \
        "$@" "tb/oss_equiv/${top}.sv" --Mdir "$BUILD/$name" -o tb \
        >"$BUILD/$name.log" 2>&1 || { echo "BUILD FAIL $name (see $BUILD/$name.log)"; return 1; }
}

run_one() { # name  (runs $SEEDS against an already-built binary)
    local name=$1
    for s in ${SEEDS//,/ }; do
        runs=$((runs+1))
        out=$("$BUILD/$name/tb" +verilator+seed+$s 2>&1 | grep -E "PASS|FAIL" | head -1)
        printf '%-36s %s\n' "$name seed=$s" "${out:-NO RESULT}"
        case "$out" in PASS*) ;; *) fails=$((fails+1));; esac
    done
}

# ---- sync bridge: burst x geometry sweep -----------------------------------
for burst in 1 0; do
for geom in "32 32 4" "32 16 4" "32 64 1" "16 32 8"; do
    set -- $geom
    n=sync_b${burst}_a$1_d$2_m$3
    build $n tb_ahb_to_ahb_sync_equiv \
        -GBURST=$burst -GAW=$1 -GDW=$2 -GMW=$3 -GCYCLES=$CYCLES \
        $SRC_SYNC $REF_SYNC || fails=$((fails+1))
    [ -x "$BUILD/$n/tb" ] && run_one $n
done; done

# ---- error-cancel bridge: hclken on/off ------------------------------------
for hem in 0 1; do
    n=ec_hem$hem
    build $n tb_ahb_to_ahb_sync_err_canc_equiv \
        -GHCLKEN_MODE=$hem -GCYCLES=$CYCLES \
        $SRC_EC $REF_EC || fails=$((fails+1))
    [ -x "$BUILD/$n/tb" ] && run_one $n
done

# ---- apb bridge: rdata/wdata variants, ADDRWIDTH sweep, PCLKEN on/off ------
for conf in "1 0 15 0" "1 1 12 0" "0 0 16 0" "1 1 15 1" "0 0 13 1"; do
    set -- $conf
    n=apb_r$1w$2_a$3_p$4
    build $n tb_ahb_to_apb_equiv \
        -GRDATA=$1 -GWDATA=$2 -GADDRWIDTH=$3 -GPCLKEN_MODE=$4 -GCYCLES=$CYCLES \
        $SRC_APB $REF_APB || fails=$((fails+1))
    [ -x "$BUILD/$n/tb" ] && run_one $n
done

# ---- sram bridge: address-width sweep --------------------------------------
for aw in 13 16 17; do
    n=sram_a$aw
    build $n tb_ahb_to_sram_equiv -GAW=$aw -GCYCLES=$CYCLES \
        $SRC_SRAM $REF_SRAM || fails=$((fails+1))
    [ -x "$BUILD/$n/tb" ] && run_one $n
done

# ---- master mux: port-enable and DW sweep ----------------------------------
for conf in "1 1 1 32 15" "1 1 1 64 15" "1 1 0 32 15" "1 0 1 32 15" "1 1 1 128 15" "1 1 1 32 45" "1 1 1 64 45"; do
    set -- $conf
    n=mux_p$1$2$3_d$4_e$5
    build $n tb_ahb_master_mux_equiv \
        -GP0=$1 -GP1=$2 -GP2=$3 -GDW=$4 -GERRPCT=$5 -GCYCLES=$CYCLES \
        $SRC_MUX $REF_MUX || fails=$((fails+1))
    [ -x "$BUILD/$n/tb" ] && run_one $n
done

echo "=============================================="
if [ $fails -eq 0 ]; then echo "ALL PASS ($runs runs)"; else echo "FAILURES: $fails/$runs"; exit 1; fi
