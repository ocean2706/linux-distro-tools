Copy sparse
`pv -s $(du -b /var/lib/incus/storage-pools/default/virtual-machines/win-vm/root.img | awk '{print $1}') /var/lib/incus/storage-pools/default/virtual-machines/win-vm/root.img | cp --sparse=always /dev/stdin /mnt/date/vdisks/win11.v0.img
or simpler
`pv  /var/lib/incus/storage-pools/default/virtual-machines/win-vm/root.img | cp --sparse=always /dev/stdin /mnt/date/vdisks/win11.v0.img
