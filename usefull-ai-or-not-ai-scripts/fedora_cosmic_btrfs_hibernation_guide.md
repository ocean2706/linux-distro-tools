# Enabling Hibernation with a Swap File on Btrfs in Fedora COSMIC

By default, Fedora does not enable hibernation out of the box, and setting it up on a **Btrfs filesystem** with the **COSMIC Desktop Environment** requires a few specific steps—particularly because swap files on Btrfs require physical disk offset mapping and explicit initramfs configuration.

This guide walks through how to successfully set up, configure, and test true Windows-like hibernation on Fedora COSMIC.

---

## Step 1: Create and Activate a Btrfs Swap File

Because Btrfs handles file layout and extents differently than ext4, a swap file requires a dedicated subvolume and an explicit physical offset. Ensure your swap file is larger than your physical RAM.

1. Create a dedicated subvolume for the swap file:
   ```bash
   sudo btrfs subvolume create /var/swap
   ```

2. Create the swap file (adjust the size to match your RAM + headroom, e.g., `42g` for 32GB RAM):
   ```bash
   sudo btrfs filesystem mkswapfile --size 42g --uuid clear /var/swap/swapfile
   ```

3. Activate the swap file:
   ```bash
   sudo swapon /var/swap/swapfile
   ```

4. Add it to `/etc/fstab` to ensure it mounts automatically on boot. Open `/etc/fstab` and append:
   ```text
   /var/swap/swapfile none swap defaults,pri=0 0 0
   ```

---

## Step 2: Gather UUID and Physical Offset

The Linux kernel needs to know the exact disk partition and the physical block offset of the swap file to write RAM contents during sleep and retrieve them during boot.

1. Find the UUID of your swap file:
   ```bash
   sudo findmnt -no UUID -T /var/swap/swapfile
   ```
   *(Example output: `fda1b27b-5096-4711-83ef-964c19c817b6`)*

2. Find the physical disk offset of the swap file:
   ```bash
   sudo btrfs inspect-internal map-swapfile -r /var/swap/swapfile
   ```
   *(Example output: `36220938`)*

---

## Step 3: Configure Kernel Parameters & Initramfs

1. Update your kernel boot parameters using `grubby` (replace with your specific UUID and offset):
   ```bash
   sudo grubby --args="resume=UUID=YOUR-SWAP-UUID resume_offset=YOUR-OFFSET" --update-kernel=ALL
   ```

2. Force Dracut to include the `resume` module in your initramfs images (crucial for Btrfs swap files):
   ```bash
   echo 'force_add_dracutmodules+=" resume "' | sudo tee /etc/dracut.conf.d/99-force-resume.conf
   ```

3. Regenerate all initramfs images:
   ```bash
   sudo dracut -f --regenerate-all
   ```

---

## Step 4: Configure Systemd & SELinux Security Policies

1. Allow hibernation globally in systemd by editing or creating `/etc/systemd/sleep.conf`:
   ```text
   [Sleep]
   AllowHibernation=yes
   HibernateMode=shutdown
   ```

2. Fedora's strict SELinux policies will block the kernel from writing to a swap file unless properly labeled. Apply the correct SELinux file context:
   ```bash
   sudo semanage fcontext -a -t swapfile_t "/var/swap/swapfile"
   sudo restorecon -v /var/swap/swapfile
   ```

3. Verify the context is correct (`swapfile_t`):
   ```bash
   ls -Z /var/swap/swapfile
   ```

---

## Step 5: Reboot and Test

1. **Reboot your system** to make sure the kernel boot parameters and SELinux policies take full effect.

2. Test manual hibernation from the terminal:
   ```bash
   sudo systemctl hibernate
   ```
   Your computer should write the RAM data to disk and completely power down. When powered back on, it will seamlessly restore your previous desktop session.

---

## Step 6: Integrating with COSMIC Desktop

Because the COSMIC desktop environment is under active development, its native dropdown system panel menu does not yet feature a graphical "Hibernate" button out of the box. 

To make it easily accessible:
1. Open **COSMIC Settings**.
2. Navigate to **Input Devices** -> **Keyboard** -> **Keyboard Shortcuts** -> **Custom**.
3. Create a custom shortcut (e.g., `Super + Alt + H`) mapped to the command:
   ```bash
   systemctl hibernate