echo "SEI501 Volumio boot: checking boot media..."
store disprotect key

if fatload mmc 0 0x01080000 Image; then
  echo "SEI501 Volumio: booting from SD card (mmc 0)..."
  setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=%%IMG_UUID%% bootpart=UUID=%%BOOT_UUID%% datapart=UUID=%%DATA_UUID%% uuidconfig=config.ini imgfile=/volumio_current.sqsh"
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
fi

echo "SEI501 Volumio: boot failed"
