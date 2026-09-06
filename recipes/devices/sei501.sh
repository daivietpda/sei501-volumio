#!/usr/bin/env bash
# Volumio community port for SEI Robotics SEI501 (Amlogic S905X2/G12A).
# The first image is intended for removable-media bring-up and keeps the
# factory eMMC bootloader/DDR untouched.

DEVICE_SUPPORT_TYPE="C"
DEVICE_STATUS="P"

BASE="Debian"
ARCH="armhf"
BUILD="armv7"
UINITRD_ARCH="arm64"

DEVICEFAMILY="sei501"
DEVICENAME="SEI501 S905X2"
DEVICEREPO=""

VOLVARIANT=no
MYVOLUMIO=no
VOLINITUPDATER=yes
KIOSKMODE=no
DEBUG_IMAGE="yes"
PLYMOUTH_THEME=""

BOOT_START=1
BOOT_END=128
IMAGE_END=4416
BOOT_TYPE=msdos
BOOT_USE_UUID=yes
INIT_TYPE="initv3"

MODULES=(overlay squashfs nls_cp437 nls_utf8 rfkill cfg80211 8822bs)
PACKAGES=("iw" "wireless-regdb" "wpasupplicant" "alsa-utils")

write_device_files() {
  log "Installing SEI501 boot files, modules and firmware" "ext"
  # FAT boot mounts do not support chown; preserve modes but not ownership.
  cp -a --no-preserve=ownership "${PLTDIR}/${DEVICE}/boot/." "${ROOTFSMNT}/boot/"
  cp -a --no-preserve=ownership "${PLTDIR}/${DEVICE}/lib/modules" "${ROOTFSMNT}/lib/"
  cp -a --no-preserve=ownership "${PLTDIR}/${DEVICE}/lib/firmware" "${ROOTFSMNT}/lib/"
}

write_device_bootloader() {
  log "SEI501: preserving stock bootloader/DDR (removable-media bring-up)" "info"
  :
}

device_image_tweaks() {
  :
}

device_chroot_tweaks_pre() {
  log "Configuring SEI501 kernel command line" "cfg"
  if [[ -f /boot/config.ini ]]; then
    sed -i "s/%%VOLUMIO-UUIDPARAMS%%/imgpart=UUID=${UUID_IMG} bootpart=UUID=${UUID_BOOT} datapart=UUID=${UUID_DATA}/" /boot/config.ini
    if [[ "${DEBUG_IMAGE}" == "yes" ]]; then
      sed -i "s/%%VERBOSITY%%/verbosity=loglevel=8 nosplash use_kmsg=yes/" /boot/config.ini
    else
      sed -i "s/%%VERBOSITY%%/verbosity=quiet loglevel=0/" /boot/config.ini
    fi
  fi
  cat <<-EOF >>/etc/sysctl.conf
abi.cp15_barrier=2
EOF
  sed -i "s/^MODULES=.*/MODULES=list/" /etc/initramfs-tools/initramfs.conf
}

device_chroot_tweaks_post() {
  :
}

device_image_tweaks_post() {
  log "Wrapping volumio.initrd as uInitrd" "info"
  if [[ -f "${ROOTFSMNT}/boot/volumio.initrd" ]]; then
    mkimage -A "${UINITRD_ARCH}" -O linux -T ramdisk -C none -a 0 -e 0 -n uInitrd -d "${ROOTFSMNT}/boot/volumio.initrd" "${ROOTFSMNT}/boot/uInitrd"
    rm -f "${ROOTFSMNT}/boot/volumio.initrd"
  fi
}
