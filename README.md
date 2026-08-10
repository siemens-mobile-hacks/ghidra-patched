# Ghidra Patched

A Ghidra fork with fixes for reverse engineering Siemens phones.

## Differences from stock Ghidra

- Segmented far pointers for processor specifications with `farpointer="yes"`:
  - Converts typed `PAGE:OFFSET` joins into far pointers.
  - Preserves physical addresses through p-code folding.
  - Resolves strings and symbols and makes decompiler tokens navigate to physical addresses.
  - Hides representation-only pointer casts and width conversions.
- [ARM5T false `BL` bug](https://siepatch.dev/docs/reverse-engineering/fixing-ghidra): disables standalone Thumb-1 `BL`/`BLX` halfwords on ARM5T so erased flash (`FF FF`) is not analyzed as calls. Complete 32-bit calls and ARM4T behavior are preserved.

## Build

Requires JDK 21, Python 3, and a native C/C++ toolchain.

```bash
./build.sh
```

Sources are cached in `build/`; the host-platform ZIP is written to `dist/`.

Prebuilt archives: [Releases](https://github.com/siemens-mobile-hacks/ghidra-patched/releases).
