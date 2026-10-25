# The Complete Linux Hibernation Master Guide: Filesystems, Hardware, and Security

Enabling true Windows-like hibernation on Linux requires bridging three key components:
1. **Storage Layout:** Providing the kernel with the swap device UUID and exact physical block offset (for swap files).
2. **Hardware Performance:** Factoring in read/write speeds and drive wear across HDDs, SATA SSDs, and NVMe drives.
3. **Security Contexts (MAC):** Ensuring Mandatory Access Control frameworks like **SELinux** and **AppArmor** do not silently block the kernel from writing raw RAM dumps to disk.

---

## Part 1: Filesystem & Partition Setup Methods

*Ensure your swap space (file or partition) is larger than your physical RAM.*

### Option A: Btrfs Filesystem (Swap File)
Btrfs requires a dedicated subvolume and physical extent mapping.
1. Create subvolume and swap file:
   ```bash
   sudo btrfs subvolume create /var/swap
   sudo touch /var/swap/swapfile
   sudo chattr +C /var/swap/swapfile
   sudo fallocate -l 42G /var/swap/swapfile
   sudo chmod 600 /var/swap/swapfile
   ```
2. Activate and mount:
   ```bash
   sudo mkswap /var/swap/swapfile
   sudo swapon /var/swap/swapfile
   ```
   Add to `/etc/fstab`: `/var/swap/swapfile none swap defaults 0 0`
3. **Required Parameters:**
   * UUID: `findmnt -no UUID -T /var/swap/swapfile`
   * Offset: `sudo btrfs inspect-internal map-swapfile -r /var/swap/swapfile`
   * *Kernel arg:* `resume=UUID=<UUID> resume_offset=<OFFSET>`

### Option B: Ext4 Filesystem (Swap File)
1. Allocate and activate:
   ```bash
   sudo fallocate -l 42G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```
   Add to `/etc/fstab`: `/swapfile none swap defaults 0 0`
2. **Required Parameters:**
   * UUID: `findmnt -no UUID -T /swapfile`
   * Offset: `sudo filefrag -v /swapfile | awk '{if($1=="0:"){print $4}}' | tr -d '.'`
   * *Kernel arg:* `resume=UUID=<UUID> resume_offset=<OFFSET>`

### Option C: XFS Filesystem (Limitation)
⚠️ **XFS does not support swap files.** If your root or home uses XFS, you **must** use a dedicated swap partition (Option D).

### Option D: Dedicated Swap Partition (Any Filesystem)
The cleanest method—bypasses filesystems and offsets completely.
1. Get partition UUID: `sudo blkid /dev/nvme0n1p2`
2. Add to `/etc/fstab`: `UUID=<UUID> none swap sw 0 0`
3. *Kernel arg:* `resume=UUID=<UUID>` *(Omit `resume_offset` entirely).*

---

## Part 2: Bootloader & Initramfs Configuration

### For Debian / Ubuntu (GRUB + initramfs-tools):
1. Add parameters to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`.
2. Update GRUB and initramfs:
   ```bash
   sudo update-grub
   echo "RESUME=UUID=<UUID>" | sudo tee /etc/initramfs-tools/conf.d/resume
   sudo update-initramfs -u -k all
   ```

### For Fedora / RHEL (GRUB + Dracut):
1. Update kernel args:
   ```bash
   sudo grubby --args="resume=UUID=<UUID> resume_offset=<OFFSET>" --update-kernel=ALL
   ```
2. Force the resume module and rebuild:
   ```bash
   echo 'force_add_dracutmodules+=" resume "' | sudo tee /etc/dracut.conf.d/99-force-resume.conf
   sudo dracut -f --regenerate-all
   ```

---

## Part 3: Mandatory Access Control (SELinux & AppArmor)

If hibernation fails silently (screen blinks and drops back to desktop), MAC frameworks are usually the culprit.

### 1. SELinux (Fedora, RHEL, AlmaLinux)
SELinux blocks systemd from writing runtime memory unless the swap file is explicitly labeled as `swapfile_t`.
* **The Fix:**
  ```bash
  sudo semanage fcontext -a -t swapfile_t "/var/swap/swapfile"
  sudo restorecon -v /var/swap/swapfile
  ```

### 2. AppArmor (Ubuntu, Debian, Mint)
AppArmor restricts path access for system utilities like `systemd-sleep`. Custom paths (like `/var/swap/swapfile` instead of standard root `/swapfile`) often trigger blocks.
* **Troubleshooting & Fix:**
  Check kernel logs for denials: `sudo dmesg | grep -i apparmor | grep -i deny`
  If blocked, configure profile exceptions or run the helper in complain mode:
  ```bash
  sudo aa-complain /usr/lib/systemd/systemd-sleep
  ```

---

## Part 4: Hardware Performance & Wear Considerations

* **Rotational HDDs:** Painfully slow (100–140 MB/s; 16GB RAM takes 2+ minutes). No wear concerns.
* **SATA SSDs:** Moderate (up to 550 MB/s; ~30 seconds for 16GB). Modern TBW ratings easily absorb daily hibernation cycles.
* **NVMe PCIe SSDs:** Blazing fast (3,500 to 14,000+ MB/s; dumps RAM in seconds). Massive sequential writes generate thermal spikes—ensure your NVMe has a proper heatsink.