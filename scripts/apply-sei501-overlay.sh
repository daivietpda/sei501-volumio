#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OVERLAY="${PROJECT_ROOT}/overlays/sei501/rootfs"
ROOTFS="${1:-${PROJECT_ROOT}/mnt/rootfs}"

if [[ ! -d "${OVERLAY}" ]]; then
  printf 'SEI501 overlay not found: %s
' "${OVERLAY}" >&2
  exit 1
fi
if [[ ! -d "${ROOTFS}" ]]; then
  printf 'Target rootfs not found: %s
' "${ROOTFS}" >&2
  exit 1
fi

if command -v rsync >/dev/null 2>&1; then
  rsync -a "${OVERLAY}/" "${ROOTFS}/"
else
  cp -a "${OVERLAY}/." "${ROOTFS}/"
fi

# Rebuild module metadata when the host has depmod. Failure is non-fatal
# because image builders commonly run depmod in their own chroot stage.
if command -v depmod >/dev/null 2>&1 && [[ -d "${ROOTFS}/lib/modules/6.12.108" ]]; then
  depmod -b "${ROOTFS}" 6.12.108 || true
fi

printf 'Applied SEI501 overlay: %s -> %s
' "${OVERLAY}" "${ROOTFS}"
