#!/usr/bin/env python3
import argparse

KERNEL_OFFSET=0x6_0000
TARGET_PATH="../deps/xous-core/target/riscv32imac-unknown-xous-elf/release/"
def main():
    parser = argparse.ArgumentParser(description="Build a Cramium FPGA dev image")
    parser.add_argument(
        "--loader", required=False, help="Loader path", type=str, default=TARGET_PATH+"loader.bin"
    )
    parser.add_argument(
        "--kernel", required=False, help="Kernel path", type=str, default=TARGET_PATH+"xous.img"
    )
    parser.add_argument(
        "--image", required=False, help="Image output path", type=str, default="simspi.init"
    )
    args = parser.parse_args()

    with open(args.loader, 'rb') as loader_file:
        loader = loader_file.read()

    with open(args.kernel, 'rb') as kernel_file:
        kernel = kernel_file.read()

    with open(args.image, 'wb') as image_file:
        written = len(loader)
        image_file.write(loader)
        if written > KERNEL_OFFSET:
            print("Loader is larger than the allocated space, aborting")
            exit(1)
        image_file.write(bytes(KERNEL_OFFSET - written))
        written += (KERNEL_OFFSET - written)
        if written != KERNEL_OFFSET:
            print("Code bug!")
            exit(1)
        image_file.write(kernel)
        written += len(kernel)
        print("Final image size: 0x{:x}({}) bytes".format(written, written))

if __name__ == "__main__":
    main()
    exit(0)
