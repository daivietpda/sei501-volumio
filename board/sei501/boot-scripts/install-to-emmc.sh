#!/bin/bash
set -e

echo "========================================================"
echo " SEI501 Volumio - Công cụ Cài đặt Trực tiếp lên eMMC"
echo "========================================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "[LỖI] Vui lòng chạy script này với quyền root (sudo)!"
    exit 1
fi

EMMC_DEV="/dev/mmcblk1"
if [ ! -b "$EMMC_DEV" ]; then
    echo "[LỖI] Không tìm thấy thiết bị eMMC $EMMC_DEV!"
    exit 1
fi

CURRENT_ROOT=$(findmnt -n -o SOURCE /imgpart || true)
if [[ "$CURRENT_ROOT" == *"$EMMC_DEV"* ]]; then
    echo "[CẢNH BÁO] Hệ điều hành hiện tại đang chạy từ chính eMMC ($CURRENT_ROOT)!"
    echo "Không thể ghi đè lên eMMC khi đang boot từ eMMC."
    echo "Vui lòng cắm thẻ nhớ SD và khởi động lại để chạy cài đặt từ thẻ nhớ."
    exit 1
fi

echo "[1/7] Hủy mount các phân vùng cũ trên eMMC nếu có..."
umount ${EMMC_DEV}p* 2>/dev/null || true

echo "[2/7] Phân vùng lại eMMC theo chuẩn MBR tương thích cao..."
parted -s $EMMC_DEV mklabel msdos
parted -s $EMMC_DEV mkpart primary fat32 64MiB 192MiB
parted -s $EMMC_DEV set 1 boot on
parted -s $EMMC_DEV mkpart primary ext4 192MiB 4288MiB
parted -s $EMMC_DEV mkpart primary ext4 4288MiB 100%

partprobe $EMMC_DEV || true
sleep 2

echo "[3/7] Ghi Bootloader (DDR.USB) và Device Tree (DTB)..."
if [ -f "/boot/DDR.USB" ]; then
    dd if=/boot/DDR.USB of=$EMMC_DEV bs=512 seek=1 conv=fsync 2>/dev/null
fi

if [ -f "/boot/_aml_dtb.from_dev_dtb" ]; then
    dd if=/boot/_aml_dtb.from_dev_dtb of=$EMMC_DEV bs=512 seek=8192 conv=fsync 2>/dev/null
fi

echo "[4/7] Định dạng phân vùng boot và sao chép kernel..."
mkfs.fat -F 32 -n "boot" -i D433ACED ${EMMC_DEV}p1
mkdir -p /mnt/emmc_boot
mount ${EMMC_DEV}p1 /mnt/emmc_boot
cp -r /boot/* /mnt/emmc_boot/
sync
umount /mnt/emmc_boot

echo "[5/7] Định dạng phân vùng hệ thống và sao chép rootfs squashfs..."
mkfs.ext4 -F -U e7b69da6-0dd2-4ae8-aa7d-be4a4977405e -L volumio ${EMMC_DEV}p2
mkdir -p /mnt/emmc_img
mount ${EMMC_DEV}p2 /mnt/emmc_img
cp /imgpart/volumio_current.sqsh /mnt/emmc_img/
cp /imgpart/kernel_current.tar /mnt/emmc_img/
sync
umount /mnt/emmc_img

echo "[6/7] Định dạng phân vùng dữ liệu người dùng (datapart)..."
mkfs.ext4 -F -U 39baee08-4807-45ed-bc7f-e78acb180e13 -L volumio_data ${EMMC_DEV}p3

echo "[7/7] Cấu hình môi trường U-Boot autoboot vào eMMC..."
if [ -f "/boot/env.PARTITION" ]; then
    dd if=/boot/env.PARTITION of=$EMMC_DEV bs=512 seek=1482752 conv=fsync 2>/dev/null
fi

echo "========================================================"
echo " [THÀNH CÔNG] Volumio đã được cài đặt hoàn tất lên eMMC!"
echo " Bạn có thể rút thẻ nhớ SD và khởi động lại thiết bị:"
echo " sudo reboot"
echo "========================================================"
