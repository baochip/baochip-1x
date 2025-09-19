# Baochip 1x

This repo contains the open source elements of the Baochip 1x.

## Code Organization

- `docs` contains source for the [Baochip 1x book](https://baochip.github.io/baochip-1x/).
- `rtl` contains the open-sourced elements of the taped out RTL.
- `Vexriscv` contains the source configuration for the Vex CPU
- `scripts` contains helper scripts for repo management
- `verilate` contains the files to simulate a subsetted RTL analog of the Baochip-1x using verilator.
- `arty` contains the files to build Arty-A7 targeted SoC stubs. Useful for debugging and developing future extensions.

Auto-extracted documentation based on the RTL in this repo have been uploaded to [peripherals](https://ci.betrusted.io/bao1x/)
[core cluster](https://ci.betrusted.io/bao1x-cpu/).

## Releases, tags and branches

This repo revolves around an artifact that is fixed and unpatchable. Therefore, the typical OSS strategy of "just update to HEAD" to simplify release management does not apply.

- Each die rev will get a tag with a name of the form `tapeout-a0`. This represents the point at which the contents of the `rtl` directory exactly matches what went into the tapeout.
- A branch is also made with the same name at that time
- The assumed role of the `main` branch is to evolve the simulation tools and documentation around the `rtl` artifact. The `rtl` artifact loses its value if it functionally diverges from what is actually in a chip. Thus, future feature requests and bug fixes must go into a different branch or a fork of the repo.
- It is assumed that die revs, if any, will be limited and rare. `main` will track the latest die rev, but the previous `tapeout-*` branches will hold snapshots of the `rtl` directory as matching the older die rev, allowing users of older die revs to run simulation/docgen tools on the older revisions.

Die rev numbering takes on the form of `XY` where `X` is an alphabetic character and `Y` is a numeric character. The alphabetic character represents a full-mask set; the numeric represents a metal-mask or final-test repair stepping.
