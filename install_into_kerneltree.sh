#!/bin/bash


LINUX_DIR_PATH=~/Devel/unipi/rpi-kernel-6.12/linux

if ! grep -q '^source "drivers/unipi/Kconfig"' "$LINUX_DIR_PATH/drivers/Kconfig"; then
    sed 's#^endmenu#source "drivers/unipi/Kconfig"\n\nendmenu#' -i "$LINUX_DIR_PATH/drivers/Kconfig"
fi

if ! grep -q '^obj-y[[:blank:]]\++= unipi/' "$LINUX_DIR_PATH/drivers/Makefile"; then
    echo -ne '\nobj-y\t+= unipi/\n' >> "$LINUX_DIR_PATH/drivers/Makefile"
fi

mkdir -p "$LINUX_DIR_PATH/drivers/unipi"
cp modules/*/src/*.[ch] "$LINUX_DIR_PATH/drivers/unipi"
cp unipi-hardware-id/include/uniee.h "$LINUX_DIR_PATH/drivers/unipi"
cp unipi-hardware-id/include/uniee_values.h "$LINUX_DIR_PATH/drivers/unipi"

cat modules/*/src/Makefile > "$LINUX_DIR_PATH/drivers/unipi/Makefile"

(
  echo 'menu "Unipi drivers"'
  echo
  cat modules/*/src/Kconfig
  echo
  echo 'endmenu #Unipi drivers'
) > "$LINUX_DIR_PATH/drivers/unipi/Kconfig"
