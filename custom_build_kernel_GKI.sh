#!/bin/bash

################################################################################
# Build script — Samsung Galaxy S23+ SM-S916B (dm2q / kalama)
################################################################################


# ─────────────────────────────────────────
# 1. VARIABLES CIBLES
# ─────────────────────────────────────────

#1. target config

BUILD_TARGET=dm2q_eur_openx
export MODEL=$(echo ${BUILD_TARGET} | cut -d'_' -f1)
export PROJECT_NAME=${MODEL}
export REGION=$(echo ${BUILD_TARGET} | cut -d'_' -f2)
export CARRIER=$(echo ${BUILD_TARGET} | cut -d'_' -f3)
export TARGET_BUILD_VARIANT=user


#2. sm8550 common config

CHIPSET_NAME=kalama
export ANDROID_BUILD_TOP=$(pwd)
export TARGET_PRODUCT=gki
export TARGET_BOARD_PLATFORM=gki
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${MODEL}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${CHIPSET_NAME}-${TARGET_PRODUCT}
export DIST_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${CHIPSET_NAME}-${TARGET_PRODUCT}/dist
export MERGE_CONFIG="${ANDROID_BUILD_TOP}/kernel_platform/common/scripts/kconfig/merge_config.sh"

mkdir -p "${DIST_DIR}"

#3. Cleaning previous kernel compilation
rm -rf ${OUT_DIR}/gki_kernel/dist


# ─────────────────────────────────────────
# 2. MODULES VENDOR — symboles et chemins
# ─────────────────────────────────────────

# for Lcd(techpack) driver build

export KBUILD_EXTRA_SYMBOLS="\
${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mmrm-driver/Module.symvers \
${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/hw_fence/Module.symvers \
${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/sync_fence/Module.symvers \
${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/msm_ext_display/Module.symvers \
${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/securemsm-kernel/Module.symvers"


# for Audio(techpack) driver build

export MODNAME=audio_dlkm

export KBUILD_EXT_MODULES="\
../vendor/qcom/opensource/mm-drivers/msm_ext_display \
../vendor/qcom/opensource/mm-drivers/sync_fence \
../vendor/qcom/opensource/mm-drivers/hw_fence \
../vendor/qcom/opensource/mmrm-driver \
../vendor/qcom/opensource/securemsm-kernel \
../vendor/qcom/opensource/display-drivers/msm \
../vendor/qcom/opensource/audio-kernel \
../vendor/qcom/opensource/camera-kernel"


# Build Setting
export GKI_KERNEL_BUILD_OPTIONS="
    SKIP_MRPROPER=1 \
    LTO=thin \
    HERMETIC_TOOLCHAIN=0 \
    KMI_SYMBOL_LIST_STRICT_MODE=0 \
    RECOMPILE_KERNEL=1 \
    ABI_DEFINITION= \
    BUILD_BOOT_IMG=1 \
    SKIP_VENDOR_BOOT=1 \
    MKBOOTIMG_PATH=${ANDROID_BUILD_TOP}/kernel_platform/tools/mkbootimg/mkbootimg.py \
    KERNEL_BINARY=Image \
    BOOT_IMAGE_HEADER_VERSION=4 \
    AVB_SIGN_BOOT_IMG=1 \
    AVB_BOOT_PARTITION_SIZE=100663296 \
    AVB_BOOT_KEY=${ANDROID_BUILD_TOP}/kernel_platform/tools/mkbootimg/gki/testdata/testkey_rsa4096.pem \
    AVB_BOOT_ALGORITHM=SHA256_RSA4096 \
    AVB_BOOT_PARTITION_NAME=boot"

# SKIP_MRPROPER=1              → pas de clean complet, rebuild incrémental plus rapide
# LTO=thin                     → link-time optimization allégé (moins de RAM, plus rapide que full)
# HERMETIC_TOOLCHAIN=0         → autorise les outils host système (python, make…)
# KMI_SYMBOL_LIST_STRICT_MODE=0→ désactive le blocage si un symbole n'est pas dans la liste KMI officielle
# RECOMPILE_KERNEL=1           → force la recompilation du kernel même sans changement détecté
# ABI_DEFINITION=              → désactive la vérification ABI (vide = désactivé)
# BUILD_BOOT_IMG=1             → génère boot.img à la fin du build
# SKIP_VENDOR_BOOT=1           → ne génère pas vendor_boot.img pendant le build principal
# MKBOOTIMG_PATH               → chemin vers le script Python qui assemble le boot.img
# KERNEL_BINARY=Image          → binaire kernel arm64 (pas zImage)
# BOOT_IMAGE_HEADER_VERSION=4  → obligatoire pour Android 13+
# AVB_SIGN_BOOT_IMG=1          → signe le boot.img avec Android Verified Boot
# AVB_BOOT_PARTITION_SIZE      → taille de la partition boot en octets (96 Mo)
# AVB_BOOT_KEY                 → clé RSA4096 pour la signature AVB (clé de test générique)
# AVB_BOOT_ALGORITHM           → algorithme de signature AVB
# AVB_BOOT_PARTITION_NAME=boot → nom de la partition cible


# MKBOOTIMG Setting
export MKBOOTIMG_EXTRA_ARGS="
    --os_version 13.0.0 \
    --os_patch_level 2023-10 \
    --pagesize 4096"


# ─────────────────────────────────────────
# 3. TOOLCHAIN DANS LE PATH
# ─────────────────────────────────────────
CLANG_DIR=kernel_platform/prebuilts/clang/host/linux-x86/clang-r450784e/bin
export PATH=${ANDROID_BUILD_TOP}/${CLANG_DIR}:$PATH


# ─────────────────────────────────────────
# 4. FIX GLIBC 2.39 — glibc_compat.o
# ─────────────────────────────────────────
FIX_DIR=${ANDROID_BUILD_TOP}/fix
mkdir -p "${FIX_DIR}"

if [ ! -f "${FIX_DIR}/glibc_compat.o" ]; then
  echo "[fix] Compilation de glibc_compat.o..."
  cat > ${FIX_DIR}/glibc_compat.c << 'EOFC'
#include <stdlib.h>
long __isoc23_strtol(const char *s, char **e, int b)             { return strtol(s,e,b); }
unsigned long __isoc23_strtoul(const char *s, char **e, int b)   { return strtoul(s,e,b); }
unsigned long long __isoc23_strtoull(const char *s, char **e, int b) { return strtoull(s,e,b); }
EOFC
  gcc -O2 -c ${FIX_DIR}/glibc_compat.c \
      -o ${FIX_DIR}/glibc_compat.o
  echo "[fix] glibc_compat.o compilé ✅"
fi

# ─────────────────────────────────────────
# 5. FIX GLIBC 2.39 — wrapper ld.lld
# ─────────────────────────────────────────
if [ ! -f "${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld.real" ]; then
  echo "[fix] Installation wrapper ld.lld..."
  cp ${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld \
     ${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld.real
fi

cat > ${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld << EOF
#!/bin/bash
for arg in "\$@"; do
  if [[ "\$arg" == *libsubcmd* ]]; then
    exec -a "ld.lld" "\$(dirname "\$0")/ld.lld.real" \\
      --allow-multiple-definition \\
      ${FIX_DIR}/glibc_compat.o "\$@"
  fi
done
exec -a "ld.lld" "\$(dirname "\$0")/ld.lld.real" "\$@"
EOF
chmod +x ${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld
echo "[fix] Wrapper ld.lld installé ✅"


# ─────────────────────────────────────────
# 6. NETTOYAGE resolve_btfids (cache cassé)
# ─────────────────────────────────────────
rm -rf ${OUT_DIR}/gki_kernel/common/tools/bpf/resolve_btfids
rm -rf ${OUT_DIR}/msm-kernel/tools/bpf/resolve_btfids

# ─────────────────────────────────────────
# 7. LANCEMENT DU BUILD
# ─────────────────────────────────────────
echo ""
echo "========================================="
echo " Démarrage build kernel SM-S916B (dm2q)"
echo "========================================="

( env ${GKI_KERNEL_BUILD_OPTIONS} ${ANDROID_BUILD_TOP}/kernel_platform/build/android/prepare_vendor.sh sec ${TARGET_PRODUCT} || exit 1) 2>&1 | tee build_log.log

# Affiche le nom du kernel compilé
printf "\n\n\n"
strings ${DIST_DIR}/Image | grep -i "linux version" | head -1


# Déplace le kernel fraîchement compilé
mkdir ${ANDROID_BUILD_TOP}/out/built_kernel
mv ${DIST_DIR}/boot.img ${ANDROID_BUILD_TOP}/out/built_kernel/boot.img
mv ${DIST_DIR}/Image* ${ANDROID_BUILD_TOP}/out/built_kernel/

# Compresse en format Odin (AP)
cd ${ANDROID_BUILD_TOP}/out/built_kernel/
tar -cvf ${MODEL}_Odin.tar boot.img
cd ${ANDROID_BUILD_TOP}

################################################################################
# Output files :
#   boot.img        → Odin (AP) — kernel principal
#   Image.gz        → AnyKernel3 — kernel principal
#
# Deep Clean :
#   rm -rf ${OUT_DIR}/
################################################################################

