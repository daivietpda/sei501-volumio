#!/bin/bash
set -e

echo "========================================================"
echo " SEI501 Volumio - Cong cu Cai dat Truc tiep len eMMC"
echo "========================================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "[LOI] Vui long chay script nay voi quyen root (sudo)!"
    exit 1
fi

EMMC_DEV="/dev/mmcblk1"
if [ ! -b "$EMMC_DEV" ]; then
    echo "[LOI] Khong tim thay thiet bi eMMC $EMMC_DEV!"
    exit 1
fi

CURRENT_ROOT=$(findmnt -n -o SOURCE /imgpart || true)
if [[ "$CURRENT_ROOT" == *"$EMMC_DEV"* ]]; then
    echo "[CANH BAO] He dieu hanh hien tai dang chay tu chinh eMMC ($CURRENT_ROOT)!"
    echo "Khong the ghi de len eMMC khi dang boot tu eMMC."
    echo "Vui long cam the nho SD va khoi dong lai de chay cai dat tu the nho."
    exit 1
fi

echo "[1/7] Huy mount cac phan vung cu tren eMMC neu co..."
umount ${EMMC_DEV}p* 2>/dev/null || true

echo "[2/7] Phan vung lai eMMC theo chuan MBR (bat dau tu 800 MiB de tranh offset uboot/env)..."
# Sector 0 - 800 MiB (1,638,400 sectors) danh rieng cho:
# - Sector 1 (512B): DDR.USB bootloader
# - Sector 8192 (4MiB): _aml_dtb
# - Sector 1286144 (628MiB): U-Boot primary env
# - Sector 1482752 (724MiB): U-Boot backup env
parted -s $EMMC_DEV mklabel msdos
parted -s $EMMC_DEV mkpart primary fat32 800MiB 1056MiB
parted -s $EMMC_DEV set 1 boot on
parted -s $EMMC_DEV mkpart primary ext4 1056MiB 2256MiB
parted -s $EMMC_DEV mkpart primary ext4 2256MiB 100%

partprobe $EMMC_DEV || true
sleep 2

echo "[3/7] Ghi Bootloader goc (DDR.USB) va Device Tree (DTB)..."
if [ -f "/boot/DDR.USB" ]; then
    dd if=/boot/DDR.USB of=$EMMC_DEV bs=512 seek=1 conv=fsync 2>/dev/null
fi

if [ -f "/boot/_aml_dtb.from_dev_dtb" ]; then
    dd if=/boot/_aml_dtb.from_dev_dtb of=$EMMC_DEV bs=512 seek=8192 conv=fsync 2>/dev/null
fi

echo "[4/7] Dinh dang phan vung boot va sao chep kernel/script..."
mkfs.fat -F 32 -n "boot" -i D433ACED ${EMMC_DEV}p1
mkdir -p /mnt/emmc_boot
mount ${EMMC_DEV}p1 /mnt/emmc_boot
cp -r /boot/* /mnt/emmc_boot/

# Cap nhat config.ini tren eMMC voi UUID phan vung eMMC
if [ -f "/mnt/emmc_boot/config.ini" ]; then
    sed -i 's/imgpart=UUID=[^ ]*/imgpart=UUID=e7b69da6-0dd2-4ae8-aa7d-be4a4977405e/g' /mnt/emmc_boot/config.ini
    sed -i 's/bootpart=UUID=[^ ]*/bootpart=UUID=D433-ACED/g' /mnt/emmc_boot/config.ini
    sed -i 's/datapart=UUID=[^ ]*/datapart=UUID=39baee08-4807-45ed-bc7f-e78acb180e13/g' /mnt/emmc_boot/config.ini
fi

# Dam bao bat SSH
touch /mnt/emmc_boot/ssh
sync
umount /mnt/emmc_boot

echo "[5/7] Dinh dang phan vung he thong va sao chep rootfs squashfs..."
mkfs.ext4 -F -U e7b69da6-0dd2-4ae8-aa7d-be4a4977405e -L volumio ${EMMC_DEV}p2
mkdir -p /mnt/emmc_img
mount ${EMMC_DEV}p2 /mnt/emmc_img
cp /imgpart/volumio_current.sqsh /mnt/emmc_img/
cp /imgpart/kernel_current.tar /mnt/emmc_img/
sync
umount /mnt/emmc_img

echo "[6/7] Dinh dang phan vung du lieu nguoi dung (datapart)..."
mkfs.ext4 -F -U 39baee08-4807-45ed-bc7f-e78acb180e13 -L volumio_data ${EMMC_DEV}p3

echo "[7/7] Cau hinh U-Boot environment de autoboot truc tiep tu eMMC..."
python3 - << 'PYEOF'
import zlib, struct

emmc_path = '/dev/mmcblk1'
try:
    with open(emmc_path, 'rb') as f:
        f.seek(0x27400000)
        raw = f.read(65536)

    payload = raw[4:]
    end = payload.find(b'\x00\x00')
    items = payload[:end].split(b'\x00') if end != -1 else [x for x in payload.split(b'\x00') if x]
    env = {}
    for item in items:
        if b'=' in item:
            k, v = item.split(b'=', 1)
            env[k.decode('latin1', errors='replace')] = v.decode('latin1', errors='replace')
except Exception as e:
    print(f"Warning: Could not read existing env ({e}), creating default env")
    env = {}

env['start_autoscript'] = (
    'store disprotect key; if fatload mmc 0 0x01020000 sei501_autoscript; then autoscr 0x01020000;'
    ' elif fatload mmc 1:1 0x01020000 sei501_autoscript; then autoscr 0x01020000; fi'
)
env['bootcmd'] = 'run start_autoscript; run storeboot'

payload = b'\x00'.join(f'{k}={v}'.encode('latin1') for k, v in sorted(env.items())) + b'\x00\x00'
payload = payload.ljust(65532, b'\x00')
crc = zlib.crc32(payload) & 0xFFFFFFFF
env_data = struct.pack('<I', crc) + payload

with open(emmc_path, 'r+b') as f:
    f.seek(0x27400000) # sector 1286144
    f.write(env_data)
    f.seek(0x2d400000) # sector 1482752
    f.write(env_data)
    f.flush()
print("Da ghi U-Boot environment thanh cong vao eMMC (0x27400000 va 0x2d400000).")
PYEOF

echo "========================================================"
echo " [THANH CONG] Volumio da duoc cai dat hoan tat len eMMC!"
echo " Ban co the rut the nho SD va khoi dong lai thiet bi:"
echo " sudo reboot"
echo "========================================================"
