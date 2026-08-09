# Ghidra Patched

A Ghidra fork with fixes for reverse engineering Siemens phones.

## Differences from stock Ghidra

- Supports multiple `segmentop` definitions for one address space with different pointer sizes.
- Preserves resolved segmented pointers instead of translating them twice, fixing far-pointer and string constants in decompiled code.

## Build

Requires JDK 21, Python 3, and a native C/C++ toolchain.

```bash
./build.sh
```

Sources are cached in `build/`; the host-platform ZIP is written to `dist/`.

Prebuilt archives: [Releases](https://github.com/siemens-mobile-hacks/ghidra-patched/releases).
