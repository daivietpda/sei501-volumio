# Stage 1: loaded by SEI501 vendor U-Boot at 0x01080000 via Upgrade/Recovery button.
# Multiboot: persist SD-first bootcmd to U-Boot environment, then chain to stage 2.

echo "SEI501 Volumio SD boot: configuring persistent multiboot environment"

setenv start_autoscript "if fatload mmc 0 0x01020000 sei501_autoscript; then autoscr 0x01020000; elif fatload mmc 1:1 0x01020000 sei501_autoscript; then autoscr 0x01020000; fi"
setenv bootcmd "run start_autoscript; run storeboot"
saveenv

echo "SEI501 Volumio SD boot: starting stage 2"

if fatload mmc 0 0x01020000 sei501_autoscript; then
  autoscr 0x01020000
else
  echo "SEI501 Volumio SD boot: sei501_autoscript missing, falling back to eMMC"
  run storeboot
fi
