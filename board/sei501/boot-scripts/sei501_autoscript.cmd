# Stage 2: direct, non-persistent Volumio SD boot.

echo "SEI501 Volumio SD boot: loading Linux 6.12.108"

setenv kernel_addr_r 0x01080000
setenv fdt_addr_r 0x10000000
setenv ramdisk_addr_r 0x13000000
setenv fdt_high 0xffffffff
setenv initrd_high 0xffffffff

setenv bootargs "console=ttyAML0,115200n8 earlycon no_console_suspend loglevel=8 nosplash use_kmsg=yes rootwait net.ifnames=0 elevator=noop maxcpus=4 consoleblank=0 hwdevice=sei501 imgpart=UUID=fe054e16-9b88-4651-bdfc-2501ddb4da0d bootpart=UUID=75B0-A957 datapart=UUID=d03bfabb-f44d-4e95-968e-6a65a749668c uuidconfig=config.ini imgfile=/volumio_current.sqsh"

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
