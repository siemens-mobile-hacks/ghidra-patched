# Ghidra Patched

A Ghidra fork with fixes for reverse engineering Siemens phones.

## Differences from stock Ghidra

- Converts typed `PAGE:OFFSET` joins into segmented far pointers.
- Preserves physical addresses through p-code folding instead of decoding them twice.
- Resolves far-pointer strings and symbols and makes their decompiler tokens navigate to the physical address.
- Hides representation-only pointer casts and width conversions.
- Activates these changes only for processor specifications with `farpointer="yes"`.

## Build

Requires JDK 21, Python 3, and a native C/C++ toolchain.

```bash
./build.sh
```

Sources are cached in `build/`; the host-platform ZIP is written to `dist/`.

Prebuilt archives: [Releases](https://github.com/siemens-mobile-hacks/ghidra-patched/releases).
