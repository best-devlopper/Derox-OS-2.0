#!/usr/bin/env bash
# DEROX OS 2.0 - Kernel & Bootable ISO Builder
# License: MIT

set -e

REPO_ROOT=$(pwd)
BUILD_DIR="$REPO_ROOT/build/derox-2.0"
ROOTFS_DIR="$BUILD_DIR/rootfs"
ISO_DIR="$BUILD_DIR/iso"
ISO_OUTPUT="$REPO_ROOT/dist/derox-os-2.0-x86_64.iso"

echo "================================================="
echo "  Building DEROX OS 2.0 Kernel & Bootable ISO... "
echo "================================================="

# 1. تحميل وتجميع نواة لينكس (Linux Kernel v6.6)
echo "[1/4] Downloading and compiling Linux Kernel v6.6..."
mkdir -p "$BUILD_DIR/src"
cd "$BUILD_DIR/src"

curl -fsSLk "https://github.com" -o linux-6.6.tar.gz

rm -rf linux-6.6
tar -xzf linux-6.6.tar.gz
cd linux-6.6

make defconfig >/dev/null
make -j$(nproc) bzImage >/dev/null

# 2. ضغط نظام الملفات الجذري إلى initramfs
echo "[2/4] Packaging RootFS into initramfs.img..."
mkdir -p "$ISO_DIR/boot/grub/themes"
cp arch/x86/boot/bzImage "$ISO_DIR/boot/vmlinuz-derox"

cd "$ROOTFS_DIR"
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initramfs.img"

# 3. دمج ثيم الإقلاع وإعداد قائمة GRUB2
echo "[3/4] Configuring GRUB2 bootloader and DEROX 2.0 theme..."
if [ -d "$REPO_ROOT/grub-theme-derox2" ]; then
  cp -r "$REPO_ROOT/grub-theme-derox2" "$ISO_DIR/boot/grub/themes/derox-2.0"
fi

cat << 'EOF' > "$ISO_DIR/boot/grub/grub.cfg"
set timeout=10
set default=0

insmod all_video
insmod gfxterm
insmod png
terminal_output gfxterm

set theme=/boot/grub/themes/derox-2.0/theme.txt
export theme

menuentry "DEROX OS 2.0 — Live Session" {
    linux /boot/vmlinuz-derox quiet loglevel=3
    initrd /boot/initramfs.img
}

menuentry "DEROX OS 2.0 — Safe Mode (Debug)" {
    linux /boot/vmlinuz-derox debug
    initrd /boot/initramfs.img
}
EOF

# 4. توليد ملف الـ ISO القابل للإقلاع
echo "[4/4] Generating bootable ISO image..."
mkdir -p "$REPO_ROOT/dist"
grub-mkrescue -o "$ISO_OUTPUT" "$ISO_DIR" >/dev/null 2>&1

echo "================================================="
echo "  ISO Build Complete: $ISO_OUTPUT                "
echo "================================================="
