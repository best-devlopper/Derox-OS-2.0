#!/usr/bin/env bash
# DEROX OS 2.0 - Independent Root Filesystem (RootFS) Builder with Fastfetch
# License: MIT

set -e

BUILD_DIR=$(pwd)/build/derox-2.0
ROOTFS_DIR="$BUILD_DIR/rootfs"

echo "================================================="
echo "  Building DEROX OS 2.0 Independent RootFS...    "
echo "================================================="

# 1. إنشاء هيكلية مجلدات نظام لينكس القياسية
echo "[1/5] Creating base Linux directory hierarchy..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,var,usr/{bin,sbin,lib},root,home,boot/grub/themes}
chmod 1777 "$ROOTFS_DIR/tmp"

# 2. تثبيت أدوات النظام الأساسية (BusyBox Static)
echo "[2/5] Installing BusyBox static utilities into RootFS..."
cp "$(which busybox)" "$ROOTFS_DIR/bin/busybox"
chmod +x "$ROOTFS_DIR/bin/busybox"
"$ROOTFS_DIR/bin/busybox" --install -s "$ROOTFS_DIR/bin"

# 3. إنشاء ملفات الهوية والنظام الأساسية
echo "[3/5] Configuring DEROX OS 2.0 system identity..."
cat << 'EOF' > "$ROOTFS_DIR/etc/os-release"
NAME="DEROX OS"
VERSION="2.0 (Independent)"
ID=derox
PRETTY_NAME="DEROX OS 2.0"
VERSION_ID="2.0"
HOME_URL="https://github.io"
EOF

echo "derox-os" > "$ROOTFS_DIR/etc/hostname"

# 4. إنشاء أداة fastfetch و deroxfetch المدمجة بشعار ASCII البنفسجي
echo "[4/5] Adding built-in 'fastfetch' & 'derox' utilities..."
cat << 'EOF' > "$ROOTFS_DIR/usr/bin/fastfetch"
#!/bin/sh
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

OS_NAME="DEROX OS 2.0 (x86_64)"
KERNEL=$(uname -r)
UPTIME=$(uptime | awk -F'( |,|:)+' '{print $6"h "$7"m"}' 2>/dev/null || echo "Just booted")
SHELL_NAME="/bin/sh (BusyBox)"
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^ //')
[ -z "$CPU_MODEL" ] && CPU_MODEL=$(uname -m)
MEM_TOTAL=$(awk '/MemTotal/ {printf "%.0f MiB", $2/1024}' /proc/meminfo 2>/dev/null || echo "N/A")
MEM_FREE=$(awk '/MemAvailable/ {printf "%.0f MiB", $2/1024}' /proc/meminfo 2>/dev/null || echo "N/A")

echo ""
printf "${PURPLE}   ██████╗ ███████╗██████╗  ██████╗ ██╗  ██╗${RESET}   ${WHITE}root@derox-os${RESET}\n"
printf "${PURPLE}   ██╔══██╗██╔════╝██╔══██╗██╔═══██╗╚██╗██╔╝${RESET}   ${GRAY}-------------${RESET}\n"
printf "${PURPLE}   ██║  ██║█████╗  ██████╔╝██║   ██║ ╚███╔╝ ${RESET}   ${PURPLE}OS:${RESET} ${WHITE}${OS_NAME}${RESET}\n"
printf "${PURPLE}   ██║  ██║██╔══╝  ██╔══██╗██║   ██║ ██╔██╗ ${RESET}   ${PURPLE}Kernel:${RESET} ${WHITE}${KERNEL}${RESET}\n"
printf "${PURPLE}   ██████╔╝███████╗██║  ██║╚██████╔╝██╔╝ ██╗${RESET}   ${PURPLE}Uptime:${RESET} ${WHITE}${UPTIME}${RESET}\n"
printf "${PURPLE}   ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝${RESET}   ${PURPLE}Shell:${RESET} ${WHITE}${SHELL_NAME}${RESET}\n"
printf "${CYAN}        FREEDOM • PERFORMANCE • INNOVATION  ${RESET}   ${PURPLE}CPU:${RESET} ${WHITE}${CPU_MODEL}${RESET}\n"
printf "                                               ${PURPLE}Memory:${RESET} ${WHITE}${MEM_FREE} / ${MEM_TOTAL}${RESET}\n"
echo ""
EOF

chmod +x "$ROOTFS_DIR/usr/bin/fastfetch"
ln -sf /usr/bin/fastfetch "$ROOTFS_DIR/usr/bin/derox"
ln -sf /usr/bin/fastfetch "$ROOTFS_DIR/usr/bin/neofetch"

# 5. إنشاء سكربت الإقلاع الأولي (init)
echo "[5/5] Creating system /init script..."
cat << 'EOF' > "$ROOTFS_DIR/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

clear
/usr/bin/fastfetch
echo "Type 'fastfetch' anytime to view system info."
echo ""
exec /bin/sh
EOF
chmod +x "$ROOTFS_DIR/init"

echo "================================================="
echo "  RootFS Build Complete: $ROOTFS_DIR             "
echo "================================================="
