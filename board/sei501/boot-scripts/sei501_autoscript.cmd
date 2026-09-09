# Stage 2: smart dual-boot Volumio autoscript for SEI501.
# Automatically detects if SD card (mmc 0) is inserted; if not, falls back to eMMC (mmc 1:1).
echo "SEI501 Volumio boot: checking boot media..."
store disprotect key

if fatload mmc 0 0x01080000 Image; then
  echo "SEI501 Volumio: booting from SD card (mmc 0)..."
  setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=c84cb092-2dc7-47e2-b4c4-2c1a758344d0 bootpart=UUID=B2D9-740D datapart=UUID=f0d43802-0abb-417f-ac84-3f81f6bb427c uuidconfig=config.ini imgfile=/volumio_current.sqsh"
  if fatload mmc 0 0x13000000 uInitrd; then
    if fatload mmc 0 0x10000000 amlogic/meson-g12a-sei501.dtb; then
      fdt addr 0x10000000
      booti 0x01080000 0x13000000 0x10000000
    fi
  fi
elif fatload mmc 1:1 0x01080000 Image; then
  echo "SEI501 Volumio: booting from eMMC (mmc 1:1)..."
  setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=e7b69da6-0dd2-4ae8-aa7d-be4a4977405e bootpart=UUID=D433-ACED datapart=UUID=39baee08-4807-45ed-bc7f-e78acb180e13 uuidconfig=config.ini imgfile=/volumio_current.sqsh"
  if fatload mmc 1:1 0x13000000 uInitrd; then
    if fatload mmc 1:1 0x10000000 amlogic/meson-g12a-sei501.dtb; then
      fdt addr 0x10000000
      booti 0x01080000 0x13000000 0x10000000
    fi
  fi
elif fatload mmc 1:a 0x01080000 Image; then
  echo "SEI501 Volumio: booting from eMMC (mmc 1:a)..."
  if fatload mmc 1:a 0x02000000 mbr.bin; then
    echo "SEI501 Volumio: initializing MBR partition table..."
    mmc dev 1
    mmc write 0x02000000 0 1
  fi
  setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=e7b69da6-0dd2-4ae8-aa7d-be4a4977405e bootpart=UUID=D433-ACED datapart=UUID=39baee08-4807-45ed-bc7f-e78acb180e13 uuidconfig=config.ini imgfile=/volumio_current.sqsh"
  if fatload mmc 1:a 0x13000000 uInitrd; then
    if fatload mmc 1:a 0x10000000 amlogic/meson-g12a-sei501.dtb; then
      fdt addr 0x10000000
      booti 0x01080000 0x13000000 0x10000000
    fi
  fi
fi

echo "SEI501 Volumio: boot failed"
