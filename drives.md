# Arch Drive Partition Layout
### Ethan Jansen
### 09/15/2024

* **Disk 1 (2TB): Linux Install**
    * *Partition 1 (1GB):* FAT32 EFI System Partition
        * mount point: /boot
    * *Partition 2 (48GB):* SWAP
    * *Partition 3 (remainder of disk):* btrfs linuxInstall
        * *Volume 1:* root
            * mount point: /
        * *Volume 2:* home
            * mount point: /home
            * NOCOW on ~/.cache
        * *Volume 3:* tmp
            * mount point: /var/tmp
            * NOCOW
        * *Volume 4:* log
            * mount point: /var/log
            * NOCOW
        * *Volume 5:* cache
            * mount point: /var/cache
            * NOCOW
        * *Volume 6:* spool
            * mount point: /var/spool
            * NOCOW
        * *Volume 7:* games
            * mount point: /mnt/games
            * owner: ethan:ethan
* **Disk 2 (2TB): (partitionless) btrfs vms-scratch**
    * *Volume 1:* vms
        * mount point: /mnt/vms
        * NOCOW for virtual disks
        * owner: ethan:ethan
    * *Volume 2:* scratch
        * mount point: /mnt/scratch
        * owner: ethan:ethan
* **Disk 3 (6TB): (partitionless) btrfs data**
    * *Volume 1:* data
        * mount point: ~/Data
        * Make symlinks for ~/Pictures, ~/Videos, ~/Documents, ...
        * owner: ethan:ethan
    * *Volume 2:* downloads
        * mount point: ~/Downloads
        * owner: ethan:ethan
    * *Volume 3:* gameBackups
        * mount point: /mnt/gameBackups
        * owner: ethan:ethan

