# Stage 1: loaded by SEI501 vendor U-Boot at 0x01080000.
# Move execution to a separate buffer before loading the Linux Image.

echo "SEI501 Volumio SD boot: chain loader"

if fatload mmc 0 0x01020000 sei501_autoscript; then
  autoscr 0x01020000
fi

echo "SEI501 Volumio SD boot: unable to run sei501_autoscript"
