# Arch Install
### Ethan Jansen
### 09/15/2024

## First Setup
* [Disk Partitioning/Mounting](./drives.md)
    * Make sparse directory structure before mounting. Apply NOCOW attributes with `chattr +C` before and after mounting partitions.
        * Can view these attributes later with `lsattr`.
    * mount partitons in "~" after install.
* Install Base Packages
    * `pacstrap -K /mnt base linux linux-lts linux-firmware amd-ucode btrfs-progs exfatprogs sudo nano vim man-db man-pages texinfo screen htop git rsync openssh which`
* Initial Config
    * `genfstab -U /mnt >> /mnt/etc/fstab`
    * `arch-chroot /mnt`
    * `ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime`
    * `hwclock --systohc`
    * Uncomment `en_US.UTF-8 UTF-8` from /etc/locale.gen and generate locales: `locale-gen`
    * `echo "LANG=en_US.UTF-8" > /etc/locale.conf`
    * `echo ethandesktop > /etc/hostname`
    * Set root password: `passwd`
    * To enable hibernation, add the `resume` hook to /etc/mkinitcpio.conf.
    * `mkinitcpio -P`
* Install Boot Loader
    * `pacman -S grub efibootmgr`
    * `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`
    * Edit /etc/default/grub by removing `quiet` and adding `rootflags=subvol=root ipv6.disable_ipv6=1` to `GRUB_CMDLINE_LINUX_DEFAULT`. Also uncomment `GRUB_DISABLE_SUBMENU=y` and add `GRUB_TOP_LEVEL="/boot/vmlinuz-linux"`.
    * Add the following to /etc/grub.d/40_custom:
     ```
    menuentry "System Shutdown" {
	    echo "System shutting down..."
	    halt
    }
    menuentry "System Restart" {
	    echo "System rebooting..."
	    reboot
    }
     ```
    * (Re)generate grub config: `grub-mkconfig -o /boot/grub/grub.cfg`
* Unmount and Reboot!
    * Exit the chroot environment: `exit`
    * Unmount the install: `umount -R /mnt`
    * `shutdown -r now`

## Post-Installation
* Configure hibernation
    * Set `AllowSuspend=no` and `HibernateMode=shutdown` under `[Sleep]` in /etc/systemd/sleep.conf.d/hibernate.conf. The directory needs to be created first.
* Networking, Wake-On-LAN, and Time Synchronization
    * Start and enable `systemd-resolved.service` and `systemd-networkd.service`
    * Create /etc/systemd/network/20-wired.network with contents:
    ```
    [Match]
    Name=enp6s0

    [Network]
    DHCP=ipv4
    DNS=192.168.1.2

    [DHCPv4]
    UseDNS=false
    ```
    * For Wake-On-LAN, create /etc/systemd/network/50-wired.link with contents:
    ```
    [Match]
    MACAddress=aa:bb:cc:dd:ee:ff

    [Link]
    NamePolicy=kernel database onboard slot path
    MACAddressPolicy=persistent
    WakeOnLan=magic
    ```
    * `ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`
    * Start time sync daemon: `timedatectl set-ntp true`
    * Reboot
* User Setup
    * Normal user
        * `useradd -m ethan`
        * `passwd ethan`
        * In /etc/sudoers add `ethan ALL=(ALL:ALL) ALL`
    * Power service user: no sudo password required for shutdown/reboot/hibernate commands
        * `useradd -m -d /home/.power-service power-service`
        * `passwd power-service`
        * In /etc/sudoers add the following:
        ```
        Cmnd_Alias  POWER = /usr/bin/shutdown -h, /usr/bin/shutdown -r, /usr/bin/shutdown -c, /usr/bin/systemctl hibernate
        power-service ALL=(ALL:ALL) !ALL
        power-service ALL=(ALL:ALL) NOPASSWD: POWER
        ```
    * Configure OpenSSH
        * Create /etc/ssh/sshd_config.d/50-desktop.conf:
            ```
            Port ####
            PermitRootLogin no
            PasswordAuthentication no
            AuthenticationMethods publickey
            ```
        * Start/enable `sshd.service`
    * Create ssh keypair for `ethan`. Install IoT server public key for `power-service`.
    * Mount additional "~" drives, fixing user:group ownership to `ethan:ethan` and adding `chattr +C` where applicable