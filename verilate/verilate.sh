#!/bin/bash

# Set default values for the options
TARGET="iron"
SPEED="normal"
CPU="vexi"
XOUS_PATH="../deps/xous-core"
NTO_TESTS="../deps/nto-tests"

# not in github checkout but needed for listing outputs
mkdir -p ../listings

# Function to display the script usage
function display_usage {
    echo "Usage: $0 [-t xous] [-s fast] [-c vexii]"
    echo "-t: Select target [xous, iron]"
    echo "-s: Run fast (but don't save waveforms) [normal, fast]"
    echo "-c: Select cpu [vexi, vexii]"
}

# Parse command line options
while getopts ":s:t:c:" opt; do
    case $opt in
        t)
            TARGET=$OPTARG
            ;;
        s)
            SPEED=$OPTARG
            ;;
        c)
            CPU=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            display_usage
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            display_usage
            exit 1
            ;;
    esac
done

mkdir -p ../listings

# Shift the parsed options, so the remaining arguments are at the end of the argument list
shift $((OPTIND - 1))

# Check if any non-option arguments are passed (if required)
if [ $# -ne 0 ]; then
    echo "Invalid arguments: $@"
    display_usage
    exit 1
fi

# Use the parsed options in your script logic
echo "Target: $TARGET"
echo "Speed: $SPEED"
echo "CPU: $CPU"

set -e

echo "--------------------- BUILD CORE --------------------"
if [ $CPU == "vexii" ]
then
    python3 ./bao_core_vexii.py
else
    python3 ./bao_core.py
fi

echo "******************** BUILD SOC DEFS ***********************"
python3 ./bao_soc.py --svd-only --vextype $CPU
echo "Core+SoC build finished."

echo "******************** BUILD KERNEL ***********************"
if [ $TARGET == "xous" ]
then
  echo "Simulating Xous target"
  # svd's now come from cram-nto
  cp build/software/soc.svd ../deps/xous-core/utralib/bao1x/
  # cp build/software/core.svd ../deps/xous-core/utralib/bao1x/
  cd $XOUS_PATH
    if [ $CPU == "vexii" ]
    then
        cargo xtask bao1x-sim --loader-feature verilator-only \
            --loader-feature simulation-only \
            --kernel-feature verilator-only \
            --feature hwsim \
            --feature message-test \
            --loader-feature vexii-test \
            --kernel-feature vexii-test \
            --feature vexii-test \
            --no-timestamp
            # --feature aestests \
    else
        cargo xtask bao1x-sim --loader-feature verilator-only \
            --loader-feature simulation-only \
            --kernel-feature verilator-only \
            --feature hwsim \
            --feature message-test \
            --no-timestamp
            # --feature aestests \
    fi

  riscv-none-elf-objdump -S -d target/riscv32imac-unknown-none-elf/release/xous-kernel | rustfilt > ../../listings/xous-kernel.lst
  # change as needed for codezoom usage
  riscv-none-elf-objdump -S -d target/riscv32imac-unknown-xous-elf/release/bao1x-mbox1 | rustfilt > ../../listings/bao1x-mbox1.lst

  cd ../../verilate
  python3 ./mkimage.py
  BIOS="./simspi.init"
else
  echo "Simulating raw iron target"
  # build the binary
  cd $NTO_TESTS
  cp tests/link.x.straight tests/link.x
  # change --boot-offset in the cramy_soc.py commandline to match what is in link.x!!
  cargo xtask boot-image --no-default-features --feature fast-fclk --feature quirks-pll --feature aes-zkn --feature bio-mul --feature reset-value-tests --feature bio-tests
  python3 ./merge_cm7.py --rv32=rv32.bin --cm7=cm7/mbox.bin --out-file=boot.bin

  riscv-none-elf-objdump -h target/riscv32imac-unknown-none-elf/release/tests > ../../listings/boot.lst
  riscv-none-elf-nm -r --size-sort --print-size target/riscv32imac-unknown-none-elf/release/tests | rustfilt >> ../../listings/boot.lst
  riscv-none-elf-objdump target/riscv32imac-unknown-none-elf/release/tests -S -d | rustfilt >> ../../listings/boot.lst

  cd ../../verilate
  BIOS="../deps/nto-tests/boot.bin"
fi
echo "******************** RUN SIM ***********************"

# This seems to be about the right amount of concurrency for this model. More threads don't speed things
# up, and in some cases even slow things down because there just isn't enough work and you're spending
# most of your time locking.
THREADS=5

# remember - trace-start is not 0!

echo "Don't forget: finisher.v needs to have the XOUS variable defined according to the target config."
echo -e "\n\nRun with $THREADS threads" >> stats.txt
date >> stats.txt
# --udma for udma simulations...
/usr/bin/time -a --output stats.txt python3 ./bao_soc.py --vextype $CPU --speed $SPEED --bios $BIOS  --boot-offset 0x000000 --gtkwave-savefile --threads $THREADS --jobs 20 --trace --trace-start 0 --trace-end 200000000000 --trace-fst # --sim-debug
echo "Core+SoC build finished."
