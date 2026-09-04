# Stage 1: loaded by SEI501 vendor U-Boot at 0x01080000.
# Persist a safe SD-first boot command once, then chain to stage 2.

echo "SEI501 Volumio SD boot: chain loader"

if test "${sei501_sd_boot_saved}" != "1"; then
  setenv sei501_sd_boot_saved 1
  setenv bootcmd 'if fatload mmc 0 0x01080000 aml_autoscript; then autoscr 0x01080000; else run storeboot; fi'
  saveenv
  echo "SEI501 Volumio SD boot: persistent SD-first bootcmd saved"
fi

if fatload mmc 0 0x01020000 sei501_autoscript; then
  autoscr 0x01020000
else
  echo "SEI501 Volumio SD boot: stage 2 missing, falling back to eMMC"
  run storeboot
fi
