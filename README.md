# Volumio OS port for SEI501 (Amlogic S905X2)

This repository is the reproducible SEI501 integration layer for the Volumio
image built on WSL2. It records the board description, boot scripts, device
recipe, and the runtime overlays used while bringing up the SEI501 board.

The full upstream Volumio OS, Linux kernel, assembled rootfs, build output and
burn-package/image files remain on the build disk but are deliberately ignored
by Git. Their exact upstream revisions are recorded in [SOURCES.lock.md](SOURCES.lock.md).

## Layout

- `board/sei501/`: SEI501 DTS, stock DTS notes, RTL8822B firmware and Amlogic
  SD boot/autoscript files.
- `recipes/devices/sei501.sh`: Volumio OS device recipe.
- `overlays/sei501/rootfs/`: files installed into the target rootfs. This
  includes ALSA routing for HDMI and AV 3.5 mm, USB DAC modules, the port-80
  systemd proxy, MyVolumio/Plugin Store compatibility, and the Web UI cache-bust.
- `scripts/apply-sei501-overlay.sh`: applies the tracked overlay to an
  assembled rootfs without deleting any other target files.
- `src/rtl8822bs-aml/`: [Git Submodule](https://github.com/daivietpda/rtl8822bs-aml) - RTL8822BS SDIO Wi-Fi driver with SEI501 patches (50MHz SDIO bus, 802.11ac VHT80, TX/RX FIFO bugfix).
- `src/volumio-os/`: [Git Submodule](https://github.com/daivietpda/volumio-os) - Volumio OS build system and SEI501 recipe integration.
- `*REPORT*.md`: bring-up and live-device verification notes (local only).

## Submodules & Quick Start

### 1. Cloning with Submodules
To clone the repository and initialize all submodules in one step:
```bash
git clone --recurse-submodules https://github.com/daivietpda/volumio.git
cd volumio
```

If the repository was already cloned without the `--recurse-submodules` flag:
```bash
git submodule update --init --recursive
```

### 2. Pulling Updates
When pulling the latest changes from the main repository along with submodules:
```bash
git pull --recurse-submodules
```

### 3. Submodule Development Workflow
Submodules in Git track specific commits. When modifying code inside a submodule:

1. **Avoid Detached HEAD**: Switch to the working branch inside the submodule directory first:
   ```bash
   cd src/volumio-os        # or cd src/rtl8822bs-aml
   git checkout master
   ```
2. **Push submodule changes first**:
   ```bash
   git add -A
   git commit -m "Your descriptive commit message"
   git push origin master
   ```
3. **Commit the updated submodule reference in the main repo**:
   ```bash
   cd ../..                 # Return to main repository root
   git add src/volumio-os   # or git add src/rtl8822bs-aml
   git commit -m "chore: update volumio-os submodule reference"
   git push origin main
   ```

## Reapply the runtime changes

From the project root:

```bash
./scripts/apply-sei501-overlay.sh /path/to/assembled/rootfs
```

The argument defaults to `mnt/rootfs` when omitted. After applying to a
target rootfs, regenerate its module dependency metadata with `depmod` as
part of the normal image build. The audio service is enabled by the platform
image build and applies the SEI501 HDMI/AV routes after Volumio starts.

No MyVolumio credentials, runtime tokens or user data are included in this
repository.
