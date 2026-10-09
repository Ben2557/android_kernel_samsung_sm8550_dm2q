# ROOT-LKM — Custom GKI Kernel for Samsung Galaxy S23+ (SM-S916B)

![Kernel](https://img.shields.io/badge/Kernel-5.15.78-blue)
![Android](https://img.shields.io/badge/Android-13-green)
![Device](https://img.shields.io/badge/Device-dm2q-orange)
![Root](https://img.shields.io/badge/Root-not_included-lightgrey)

Custom **GKI 2.0 (Linux 5.15.78)** kernel and build scripts for the **Samsung Galaxy S23+ (SM-S916B/DS, dm2q, Qualcomm SM8550 / Kalama)**, based on Samsung firmware **S916BXXS3AWIF** (Android 13 / One UI 5.1).

The `ROOT-LKM` branch provides a **root-manager-independent kernel base**. **KernelSU Next is not built into the kernel**, and no root manager is shipped with it. Compatible loadable-kernel-module (LKM) root solutions can be installed separately, subject to compatibility with the specific kernel and firmware.

> **Compatibility:** Intended for the stated firmware base. Other Android versions, bootloader revisions and vendor module combinations are not guaranteed to work. An unlocked bootloader is required to flash custom boot images.

## Features

- **No built-in KernelSU Next:** the previous `CONFIG_KSU=y` integration and its source wiring have been removed.
- **Loadable kernel module support:** `CONFIG_MODULES=y` in the custom configuration, subject to verification in the generated `.config`.
- **Adjusted Samsung kernel security configuration:** UH, RKP, KDP, DEFEX, PROCA and FIVE disabled where these options exist and the build accepts the overrides.
- **Thin LTO** build setting.
- **Custom defconfig merge**, optional interactive `menuconfig` and Odin TAR generation.
- **GLIBC 2.39 compatibility workarounds** for the bundled toolchain on newer Linux hosts.

**Security note:** Disabling Samsung kernel security protections reduces device security. It does **not** bypass every device-level security mechanism or guarantee compatibility with every root manager.

## Branches and releases

| Branch | Description |
|---|---|
| [`ROOT-LKM`](https://github.com/Ben2557/android_kernel_samsung_sm8550_dm2q/tree/ROOT-LKM) | Root-independent kernel; prepared for compatible LKM solutions |
| [`KernelSU-Next`](https://github.com/Ben2557/android_kernel_samsung_sm8550_dm2q/tree/KernelSU-Next) | Legacy builds with KernelSU Next integrated into the kernel |
| [`stock`](https://github.com/Ben2557/android_kernel_samsung_sm8550_dm2q/tree/stock) | Samsung stock-based sources |

**Downloads:** [All releases](https://github.com/Ben2557/android_kernel_samsung_sm8550_dm2q/releases) · [Stock-LKM release](https://github.com/Ben2557/android_kernel_samsung_sm8550_dm2q/releases/tag/Stock-LKM)

## Requirements

- Ubuntu 22.04+ (or compatible Linux distribution)
- GCC, Make, Python 3 and standard Android kernel build dependencies
- `libncurses-dev` and `ncurses-bin` for optional `menuconfig`
- Sufficient RAM and disk space for the Samsung/Qualcomm kernel build

```bash
sudo apt update
sudo apt install gcc make python3 libncurses-dev ncurses-bin
```

The build script downloads the project toolchain when `kernel_platform/prebuilts` is missing.

## Source tree

```text
5.15.78/
├── kernel_platform/
│   ├── common/                  # GKI kernel (without built-in KSUN)
│   ├── msm-kernel/              # Samsung / Qualcomm kernel sources
│   ├── prebuilts/               # Toolchain (downloaded as needed)
│   └── build/
├── vendor/qcom/opensource/      # Qualcomm external kernel modules
├── custom_defconfigs/
│   └── custom_defconfig        # Custom kernel configuration overrides
├── fix/                         # Generated host compatibility files
├── out/                         # Generated build artifacts
└── custom_build_kernel_GKI.sh   # Main build script
```

## Build instructions

From the repository root:

```bash
chmod +x custom_build_kernel_GKI.sh
./custom_build_kernel_GKI.sh
```

The script asks:

```text
Customise kernel compilation with the GUI menuconfig ? [y/N] :
```

- Press **Enter** or `n` to use the project configuration.
- Press `y` to open interactive `menuconfig`.

To rebuild, rerun the same script. After a major branch or configuration change, you can clean the generated build directory:

```bash
rm -rf out/msm-kernel-kalama-gki/
```

Run that command only from the correct repository root, after confirming the directory holds disposable build output.

### Output files

After a successful build:

```text
out/built_kernel/
├── boot.img          # Boot image for the target firmware
├── Image / Image.gz  # Kernel image(s), depending on build output
└── dm2q_Odin.tar     # Odin AP-flashable archive
```

Release downloads may also contain an **AnyKernel3 ZIP**, which is packaged separately from the main build script.

## Flashing the kernel

| File | Installation method |
|---|---|
| `Odin_*.tar` or generated `dm2q_Odin.tar` | Download Mode → Odin → **AP** |
| `AK3_*.zip` | Compatible custom recovery |
| `AK3_*.zip` | `adb sideload <zip_file_path>` in a compatible recovery |
| `boot.img` | Flash to **boot** using a recovery or imaging tool that supports raw images |

**Notes:**

- A raw `.img` cannot be installed directly with `adb sideload`.
- Samsung stock recovery generally rejects unsigned custom ZIP packages.
- Back up the working boot image and confirm firmware compatibility before flashing.
- Do not replace `vendor_boot.img` or `dtbo.img` unless matching images are explicitly required.
- Do not relock the bootloader while custom boot images are installed.

## Installing root separately (LKM)

**The ROOT-LKM kernel does not provide root access by itself.** To use a supported LKM-based root solution:

1. Flash and successfully boot the custom kernel.
2. Confirm that the chosen root implementation supports your kernel's ABI/KMI, exported symbols and module-loading configuration.
3. Use the root manager's supported installation method to patch the **appropriate boot ramdisk image**. On devices with `init_boot`, this may be `init_boot.img`, rather than `boot.img`.
4. Flash the patched image with a Samsung-compatible method.
5. Reboot and verify that the root module loads correctly.

KernelSU Next releases: https://github.com/KernelSU-Next/KernelSU-Next/releases

`CONFIG_MODULES=y` **does not guarantee universal LKM compatibility**. Module signing, `vermagic`, symbol versioning and Samsung-specific restrictions still apply. Not every root manager is LKM-based.

## Custom defconfig

The main build script merges `custom_defconfigs/custom_defconfig` with Samsung's base configuration. Current intended overrides include:

```ini
# Samsung kernel security options (where supported)
CONFIG_UH=n
CONFIG_RKP=n
CONFIG_KDP=n
CONFIG_SECURITY_DEFEX=n
CONFIG_PROCA=n
CONFIG_FIVE=n

# Build options
CONFIG_WERROR=n
CONFIG_LOCALVERSION="-ROOT-LKM-S916BXXS3AWIF"
CONFIG_LOCALVERSION_AUTO=n

# Module support; no built-in root manager
CONFIG_MODULES=y
# CONFIG_KSU is not set
```

Check the **generated** `.config` after merging. Once KSUN's Kconfig has been removed, `CONFIG_KSU` may no longer exist as a recognized symbol.

**Module compatibility:** Changing `CONFIG_LOCALVERSION` changes the kernel release shown by `uname -r`, which can affect prebuilt Samsung/Qualcomm modules. Check `vermagic`, symbol versions and compatibility with the target firmware.

## Toolchain and GLIBC 2.39 compatibility

The build uses the project's Samsung/Android Clang 14-series toolchain. The main script prepares host compatibility code and an `ld.lld` wrapper to address selected GLIBC 2.39-related linker issues on newer Linux distributions.

## Credits

Special thanks to [@GoRhanHee](https://github.com/GoRhanHee) for help merging custom defconfigs and adjusting Samsung kernel security options.

Thanks to the [KernelSU Next developers](https://github.com/KernelSU-Next/KernelSU-Next) for their work on kernel-level root solutions.

---

**Disclaimer:** Flashing custom kernels and disabling security protections can cause boot failures, reduced device security or loss of functionality. Proceed only if you understand the risks and have a recovery plan.

