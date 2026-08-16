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
  - Scopes that distinction to processor specifications exposing
    `GetPagedOffset` together with the `__tasking_c166_classic` compiler model;
    other processor and compiler models keep the stock behavior.
- [ARM5T false `BL` bug](https://siepatch.dev/docs/reverse-engineering/fixing-ghidra): disables standalone Thumb-1 `BL`/`BLX` halfwords on ARM5T so erased flash (`FF FF`) is not analyzed as calls. Complete 32-bit calls and ARM4T behavior are preserved.
- Preserves automatic hidden-return metadata for multipart pointers in the C166 TASKING Classic large model.

## Build

Requires JDK 21, Python 3, and a native C/C++ toolchain.

```bash
./build.sh
```

Sources are cached in `build/`; the host-platform ZIP is written to `dist/`.

Prebuilt archives: [Releases](https://github.com/siemens-mobile-hacks/ghidra-patched/releases).
