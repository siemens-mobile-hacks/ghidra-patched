# Ghidra Patched

A Ghidra fork with fixes for reverse engineering Siemens phones.

## Differences from stock Ghidra

- Segmented far pointers for processor specifications with `farpointer="yes"`:
  - Converts typed `PAGE:OFFSET` joins into far pointers.
  - Preserves physical addresses through p-code folding.
  - Resolves strings and symbols and makes decompiler tokens navigate to physical addresses.
  - Hides representation-only pointer casts and width conversions.
  - Distinguishes TASKING Classic C166 function pointers from data pointers:
    pointers to a Function Definition retain their raw 24-bit
    `SEGMENT:OFFSET` value, while ordinary pointers continue to use the C166
    `PAGE:OFFSET` calculation.
  - Scopes all C166-specific far-pointer behavior to processor specifications
    declaring the exact `c166.abi=tasking-classic-large` property; other
    processor and compiler models keep the stock behavior.
  - Hides representation-only masks and casts when a TASKING far pointer is
    formed from an R0-relative user-stack address.
  - Reconstructs page-local `EXTP` accesses from proven far-data pointer
    halves as ordinary constant or scalar-indexed pointer arithmetic, including
    nested fields, adjacent post-increment loads, lock-step control flow, and
    reverse PAGE/OFFSET stack spills.
  - Rejects function-pointer and scalar call results before folding physical
    `R5:R4` halves into a far-data pointer.
  - Raises the type-recovery pass budget from 7 to 20 only for the exact
    `c166.abi=tasking-classic-large` profile; all other architectures retain
    the upstream limit.
- Extends Auto Structure for TASKING Classic Large far-data pointers, including
  split PAGE:OFFSET globals and indexed array elements, and retypes the actual
  four-byte global pointer instead of a selected 16-bit index variable.
- [ARM5T false `BL` bug](https://siepatch.dev/docs/reverse-engineering/fixing-ghidra): disables standalone Thumb-1 `BL`/`BLX` halfwords on ARM5T so erased flash (`FF FF`) is not analyzed as calls. Complete 32-bit calls and ARM4T behavior are preserved.
- Preserves automatic hidden-return metadata for multipart pointers in the C166 TASKING Classic large model.
- Preserves TASKING C166 Classic Large indirect R4 returns as logical `double`
  or aggregate values without adding a hidden return parameter; the protocol
  change is gated by the exact processor-spec ABI property.

## Build

Requires JDK 21, Python 3, and a native C/C++ toolchain.

```bash
./build.sh
```

Sources are cached in `build/`; the host-platform ZIP is written to `dist/`.

Prebuilt archives: [Releases](https://github.com/siemens-mobile-hacks/ghidra-patched/releases).
