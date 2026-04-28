#!/bin/bash

################################################################################
# Build script — Samsung Galaxy S23+ SM-S916B (dm2q / kalama)
################################################################################

# ─────────────────────────────────────────
# 1. RÉPERTOIRE RACINE
# ─────────────────────────────────────────
ROOT_DIR=/home/benjamin/Documents/Projets/SM-S916B/Kernel/5.15.78
cd "${ROOT_DIR}"

# ─────────────────────────────────────────
# 2. VARIABLES CIBLES
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
export ANDROID_BUILD_TOP="${ROOT_DIR}"
export TARGET_PRODUCT=gki
export TARGET_BOARD_PLATFORM=gki
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${MODEL}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${CHIPSET_NAME}-${TARGET_PRODUCT}

# ─────────────────────────────────────────
# 3. MODULES VENDOR — symboles et chemins
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

# ─────────────────────────────────────────
# 4. TOOLCHAIN DANS LE PATH
# ─────────────────────────────────────────
CLANG_DIR=kernel_platform/prebuilts/clang/host/linux-x86/clang-r450784e/bin
export PATH=${ANDROID_BUILD_TOP}/${CLANG_DIR}:$PATH
ROOT_DIR=/home/benjamin/Documents/Projets/SM-S916B/Kernel/5.15.78
cd "${ROOT_DIR}"
# ─────────────────────────────────────────
# 5. FIX GLIBC 2.39 — glibc_compat.o
# ─────────────────────────────────────────
if [ ! -f "${ANDROID_BUILD_TOP}/glibc_compat.o" ]; then
  echo "[fix] Compilation de glibc_compat.o..."
  cat > ${ANDROID_BUILD_TOP}/glibc_compat.c << 'EOFC'
#include <stdlib.h>
long __isoc23_strtol(const char *s, char **e, int b)             { return strtol(s,e,b); }
unsigned long __isoc23_strtoul(const char *s, char **e, int b)   { return strtoul(s,e,b); }
unsigned long long __isoc23_strtoull(const char *s, char **e, int b) { return strtoull(s,e,b); }
EOFC
  gcc -O2 -c ${ANDROID_BUILD_TOP}/glibc_compat.c \
      -o ${ANDROID_BUILD_TOP}/glibc_compat.o
  echo "[fix] glibc_compat.o compilé ✅"
fi

# ─────────────────────────────────────────
# 6. FIX GLIBC 2.39 — wrapper ld.lld
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
      ${ANDROID_BUILD_TOP}/glibc_compat.o "\$@"
  fi
done
exec -a "ld.lld" "\$(dirname "\$0")/ld.lld.real" "\$@"
EOF
chmod +x ${ANDROID_BUILD_TOP}/${CLANG_DIR}/ld.lld
echo "[fix] Wrapper ld.lld installé ✅"


# ─────────────────────────────────────────
# 7. NETTOYAGE resolve_btfids (cache cassé)
# ─────────────────────────────────────────
rm -rf out/msm-kernel-kalama-gki/gki_kernel/common/tools/bpf/resolve_btfids
rm -rf out/msm-kernel-kalama-gki/msm-kernel/tools/bpf/resolve_btfids

# ─────────────────────────────────────────
# 8. LANCEMENT DU BUILD
# ─────────────────────────────────────────
echo ""
echo "========================================="
echo " Démarrage build kernel SM-S916B (dm2q)"
echo "========================================="

RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor.sh sec ${TARGET_PRODUCT} 2>&1 | tee build_log.log

################################################################################
# Output files :
#   boot.img        → Odin (AP) — kernel principal
#   init_boot.img   → à patcher avec KSU Next Manager
#   vendor_boot.img → NE PAS flasher
#   dtbo.img        → NE PAS flasher
#
# Clean :
#   rm -rf out/msm-kernel-kalama-gki/
################################################################################

