#!/usr/bin/env bash
# DEROX OS 2.0 - GRUB2 Theme Installer
# License: MIT

set -e

THEME_NAME="derox-2.0"
THEME_DIR="/boot/grub/themes/${THEME_NAME}"
GRUB_CFG="/etc/default/grub"

echo "========================================="
echo "  Installing DEROX OS 2.0 GRUB2 Theme... "
echo "========================================="

# التحقق من صلاحيات الجذر (Root)
if [ "$EUID" -ne 0 ]; then
  echo "[Error] Please run this script as root (use: sudo ./install.sh)"
  exit 1
fi

# إنشاء مجلد الثيم ونسخ الملفات
echo "[1/3] Copying theme files to ${THEME_DIR}..."
mkdir -p "${THEME_DIR}"
cp -r ./* "${THEME_DIR}/"
rm -f "${THEME_DIR}/install.sh"

# تحديث ملف إعدادات GRUB
echo "[2/3] Configuring ${GRUB_CFG}..."
if grep -q "^GRUB_THEME=" "${GRUB_CFG}"; then
  sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" "${GRUB_CFG}"
else
  echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >> "${GRUB_CFG}"
fi

# تحديث قائمة GRUB في النظام
echo "[3/3] Updating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
  update-grub
elif command -v grub-mkconfig >/dev/null 2>&1; then
  grub-mkconfig -o /boot/grub/grub.cfg
else
  echo "[Warning] Could not find update-grub or grub-mkconfig. Update GRUB manually."
fi

echo "========================================="
echo "  DEROX OS 2.0 Theme Installed!          "
echo "========================================="
