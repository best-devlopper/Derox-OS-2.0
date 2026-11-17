#!#!/usr/bin/env bash
# DEROX OS 2.0 - Independent Root Filesystem (RootFS) Builder
# License: MIT

set -e

BUILD_DIR="$(pwd)/build/derox-2.0"
ROOTFS_DIR="${BUILD_DIR}/rootfs"

echo "================================================="
echo "  Building DEROX OS 2.0 Independent RootFS...    "
echo "================================================="

# 1. إنشاء هيكلية مجلدات نظام لينكس القياسية
echo "[1/5] Creating base Linux directory hierarchy..."
rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"/{bin,sbin,etc,proc,sys,dev,tmp,var,usr/{bin,sbin,lib},root,home,boot/grub/themes}
chmod 1777 "${ROOTFS_DIR}/tmp"

# 2. تثبيت أدوات النظام الأساسية (BusyBox Static)
echo "[2/5] Installing BusyBox static utilities into RootFS..."
if command -v busybox >/dev/null 2>&1; then
  cp "$(which busybox)" "${ROOTFS_DIR}/bin/busybox"
else
  curl -fsSLk "https://github.com" -o busybox.tar.gz
  tar -xzf busybox.tar.gz
  cd busybox-1_36_1
  make defconfig >/dev/null
  sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
  make -j"$(nproc)" >/dev/null
  make CONFIG_PREFIX="${ROOTFS_DIR}" install >/dev/null
  cd ..
fi

chmod +x "${ROOTFS_DIR}/bin/busybox"
"${ROOTFS_DIR}/bin/busybox" --install -s "${ROOTFS_DIR}/bin"

# 3. إنشاء ملفات الهوية والنظام الأساسية
echo "[3/5] Configuring DEROX OS 2.0 system identity..."
cat << 'EOF' > "${ROOTFS_DIR}/etc/os-release"
NAME="DEROX OS"
VERSION="2.0 (Independent)"
ID=derox
PRETTY_NAME="DEROX OS 2.0"
VERSION_ID="2.0"
HOME_URL="https://github.io"
EOF

echo "derox-os" > "${ROOTFS_DIR}/etc/hostname"

# 4. إنشاء أمر الطرفية المخصص (derox)
echo "[4/5] Adding built-in 'derox' system utility..."
cat << 'EOF' > "${ROOTFS_DIR}/usr/bin/derox"
#!/bin/sh
echo "========================================="
echo "  DEROX OS 2.0 — Independent Linux       "
echo "  Freedom • Performance • Innovation     "
echo "========================================="
echo "Kernel : $(uname -r)"
echo "Arch   : $(uname -m)"
echo "Uptime : $(uptime -p 2>/dev/null || uptime)"
EOF
chmod +x "${ROOTFS_DIR}/usr/bin/derox"

# 5. إنشاء سكربت الإقلاع الأولي (init)
echo "[5/5] Creating system /init script..."
cat << 'EOF' > "${ROOTFS_DIR}/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

clear
/usr/bin/derox
echo ""
exec /bin/sh
EOF
chmod +x "${ROOTFS_DIR}/init"

echo "================================================="
echo "  RootFS Build Complete: ${ROOTFS_DIR}           "
echo "================================================="
