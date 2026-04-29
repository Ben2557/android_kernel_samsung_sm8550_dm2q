# Stock GKI Kernel for Samsung Galaxy S23+ (SM-S916B)

![Kernel Version](https://img.shields.io/badge/Kernel-5.15.78-blue.svg)
![Architecture](https://img.shields.io/badge/Arch-arm64--v8a-orange.svg)
![Android](https://img.shields.io/badge/Android-13-green.svg)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)

This repository contains the source code and build scripts for the **Samsung Galaxy S23+ (Kalama)** kernel. It is based on official Samsung open-source releases, unmodified, and compiled as-is for GKI (Generic Kernel Image) compliance.

## 🚀 Key Features

* **Downstream Base:** GKI v5.15.78.
* **Stock:** No modifications — strictly based on official Samsung open-source releases.
* **Smart Build System:**
    * Automatic merging of `custom_defconfig` during the build process.
    * Conditional `menuconfig` execution (targeted specifically at the GKI/Common tree).
    * Automated Odin-ready `.tar` package generation.
* **Toolchain:** Compiled using official Android Clang 14.0.7 for maximum stability.

---

## Features

- ✅ **Stock Samsung kernel** — unmodified official source
- ✅ **LTO thin** — link-time optimization
- ✅ **Custom defconfig** — merged on top of Samsung base config
- ✅ **Interactive menuconfig** — optional GUI configuration at build time
- ✅ **GLIBC 2.39 compatibility fixes** — for modern Linux hosts

---

## Requirements

### Host system
- Ubuntu 22.04+ (or equivalent)
- GCC, Python 3
- `libncurses-dev` (for menuconfig)

```bash
sudo apt install gcc python3 libncurses-dev ncurses-bin
```

### Source tree structure

```
5.15.78/
├── kernel_platform/
│   ├── common/              ← GKI kernel (stock)
│   ├── msm-kernel/          ← Samsung Qualcomm kernel
│   ├── prebuilts/           ← Clang toolchain
│   └── build/
├── vendor/qcom/opensource/  ← Qualcomm open-source modules
├── custom_defconfigs/
│   └── custom_defconfig     ← Your custom kernel config
├── fix/                     ← GLIBC 2.39 compatibility files (auto-generated)
├── out/                     ← Build output (auto-generated)
└── custom_build_kernel_GKI.sh  ← Main build script
```

---

## Build

### First build

```bash
chmod +x custom_build_kernel_GKI.sh
./custom_build_kernel_GKI.sh
```

The script will ask if you want to open **menuconfig** before compiling:
```
Customise kernel compilation with the GUI menuconfig ? [y/N] :
```

- Press **Enter** or type `n` → build with default config
- Type `y` → opens interactive menuconfig before compiling

---

### Incremental rebuild

Simply re-run the script — only modified files will be recompiled.
The build script automatically cleans the previous GKI kernel output (`gki_kernel/dist`)
before each compilation to ensure a fresh kernel image is always produced.

```bash
./custom_build_kernel_GKI.sh
```

---

### Deep clean

Required after switching branches or modifying defconfig significantly:

```bash
rm -rf out/msm-kernel-kalama-gki/
```

---

## Output files

After a successful build, files are located in:

```
out/built_kernel/
├── boot.img          → Flash via Odin (AP slot)
├── Image.gz          → Raw kernel binary (AnyKernel3)
└── dm2q_Odin.tar     → Ready-to-flash Odin archive
```

### Flashing

| File | Tool | Slot |
|---|---|---|
| `dm2q_Odin.tar` | Odin | AP slot |
| `boot.img` | Custom Recovery | Flash image > boot |

> ⚠️ Do **not** flash `vendor_boot.img` or `dtbo.img`

---

## Custom defconfig

Add your kernel config options in:

```
custom_defconfigs/custom_defconfig
```

This file is merged on top of the Samsung base defconfig at each build. Example:

```
CONFIG_LOCALVERSION="-Stock_Kernel_SM8550"
CONFIG_LOCALVERSION_AUTO=n
```

---

## GLIBC 2.39 Compatibility

The Samsung prebuilt `ld.lld` linker requires symbols absent from GLIBC 2.39+. The build script automatically applies two fixes:

1. Compiles `fix/glibc_compat.o` with the missing symbols
2. Wraps `ld.lld` to inject the compatibility object when needed

These fixes are **idempotent** — applied only once, then reused on subsequent builds.

---

## Branches

| Branch | Description |
|---|---|
| `KernelSU-Next` | KSU-Next integrated branch |
| `stock` | **Current branch** — Stock Samsung kernel, no modifications |
