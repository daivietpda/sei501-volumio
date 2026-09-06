# Stage 2: direct, non-persistent Volumio SD boot.
# UUID tokens are replaced by the image builder after it creates the
# boot/root/data filesystems.  They must not be hard-coded across builds.
echo "SEI501 Volumio SD boot: loading Linux 6.12.108"

setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=%%IMG_UUID%% bootpart=UUID=%%BOOT_UUID%% datapart=UUID=%%DATA_UUID%% uuidconfig=config.ini imgfile=/volumio_current.sqsh"

if fatload mmc 0 0x01080000 Image; then
  if fatload mmc 0 0x13000000 uInitrd; then
    if fatload mmc 0 0x10000000 amlogic/meson-g12a-sei501.dtb; then
      echo "SEI501 Volumio SD boot: starting kernel"
      fdt addr 0x10000000
      booti 0x01080000 0x13000000 0x10000000
    fi
  fi
fi

echo "SEI501 Volumio SD boot: load or boot failed"
