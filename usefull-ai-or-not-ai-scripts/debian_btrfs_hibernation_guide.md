# Enabling Hibernation with a Swap File on Btrfs in Debian and Ubuntu

By default, Debian-based distributions (including Ubuntu and Linux Mint) do not enable hibernation out of the box. Setting it up on a **Btrfs filesystem** requires creating a swap file, finding its physical disk offset, updating GRUB parameters, and reconfiguring the initramfs (`initramfs-tools`) so the kernel knows how to resume from disk.

This guide walks through how to successfully set up, configure, and test true Windows-like hibernation on Debian and its derivatives.

---

## Step 1: Create and Activate a Btrfs Swap File

Because Btrfs handles file layout and extents differently than ext4, a swap file requires a dedicated subvolume and an explicit physical offset. Ensure your swap file is larger than your physical RAM.

1. Create a dedicated subvolume for the swap file:
   ```bash
   sudo btrfs subvolume create /var/swap
   ```

2. Turn off COW (Copy-on-Write) and fallocate a swap file (adjust the size to match your RAM + headroom, e.g., `42G` for 32GB RAM):
   ```bash
   sudo touch /var/swap/swapfile
   sudo chattr +C /var/swap/swapfile
   sudo fallocate -l 42G /var/swap/swapfile
   sudo chmod 600 /var/swap/swapfile
   ```

3. Format and activate the swap file:
   ```bash
   sudo mkswap /var/swap/swapfile
   sudo swapon /var/swap/swapfile
   ```

4. Add it to `/etc/fstab` to ensure it mounts automatically on boot. Open `/etc/fstab` and append:
   ```text
   /var/swap/swapfile none swap defaults 0 0
   ```

---

## Step 2: Gather UUID and Physical Offset

The Linux kernel needs to know the exact disk partition and the physical block offset of the swap file to write RAM contents during sleep and retrieve them during boot.

1. Find the UUID of your root/btrfs filesystem:
   ```bash
   findmnt -no UUID -T /var/swap/swapfile
   ```
   *(Example output: `a1b2c3d4-e5f6-...`)*

2. Find the physical disk offset of the swap file:
   ```bash
   sudo btrfs inspect-internal map-swapfile -r /var/swap/swapfile
   ```
   *(Example output: `36220938`)*

---

## Step 3: Configure Kernel Parameters & Initramfs

1. Open your GRUB configuration file:
   ```bash
   sudo nano /etc/default/grub
   ```

2. Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` and append `resume=UUID=YOUR-SWAP-UUID resume_offset=YOUR-OFFSET`. For example:
   ```text
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash resume=UUID=a1b2c3d4-e5f6-... resume_offset=36220938"
   ```

3. Update GRUB to apply the changes:
   * **On Debian/Ubuntu:**
     ```bash
     sudo update-grub
     ```

4. Configure `initramfs-tools` to recognize the resume partition:
   ```bash
   echo "RESUME=UUID=YOUR-SWAP-UUID" | sudo tee /etc/initramfs-tools/conf.d/resume
   ```

5. Regenerate your initramfs images:
   ```bash
   sudo update-initramfs -u -k all
   ```

---

## Step 4: Configure Systemd Sleep Settings

1. Open or create `/etc/systemd/sleep.conf`:
   ```bash
   sudo nano /etc/systemd/sleep.conf
   ```

2. Ensure the `[Sleep]` block contains the following settings to allow full shutdown hibernation:
   ```text
   [Sleep]
   AllowHibernation=yes
   HibernateMode=shutdown
   ```

---

## Step 5: Reboot and Test

1. **Reboot your system** to make sure the kernel boot parameters and initramfs updates take full effect:
   ```bash
   sudo reboot
   ```

2. Once back in your desktop, test manual hibernation from the terminal:
   ```bash
   sudo systemctl hibernate
   ```

Your computer should write the RAM data to disk and completely power down. When powered back on, it will read the offset and seamlessly restore your previous desktop session!