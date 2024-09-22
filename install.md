# Arch Install
### Ethan Jansen
### 09/15/2024

## First Setup
* [Disk Partitioning/Mounting](./drives.md)
    * Make sparse directory structure before mounting. Apply NOCOW attributes with `chattr +C` before and after mounting partitions.
        * Can view these attributes later with `lsattr`.
    * mount partitons in "~" after install.
* Install Base Packages
    * `pacstrap -K /mnt base linux linux-lts linux-firmware amd-ucode btrfs-progs exfatprogs sudo nano vim man-db man-pages texinfo screen htop git rsync openssh which fastfetch`
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
    * To allow `power-service` to login during a scheduled shutdown, comment out `auth requisite pam_nologin.so` and `account required pam_nologin.so` from /etc/pam.d/system-login
    * Create ssh keypair for `ethan`. Install IoT server public key for `power-service`.
    * Mount additional "~" drives, fixing user:group ownership to `ethan:ethan` and adding `chattr +C` where applicable
* Configure git: `git config --global {setting} {value}`
    * Set name and email: `user.name` and `user.email`
    * Default editor: `core.editor`
    * Default branch name: `init.defaultBranch`

## System Setup
* Automate /etc/pacman.d/mirrorlist with `reflector`
    * Install `reflector`
    * Add to the Systemd configuration in /etc/xdg/reflector/reflector.conf:
        ```
        --country 'United States,'
        ```
    * Start/enable the timer:
        ```
        sudo systemctl enable reflector.timer
        sudo systemctl start reflector.timer
        ```
    * Valid by running immediately: `systemctl start reflector.service`
* `pikaur` pacman Wrapper Install - (This will install python if not done already)
    * Install `base-devel` and `devtools` (and optionally `bat`)
    * Create ~/builds directory for manual AUR builds.
    * Clone `pikaur` into builds: https://aur.archlinux.org/pikaur.git
    * Read the PKGBUILD
    * Make install with `makepkg -si`
    * Check `pikaur` with `sudo pikaur -Syu`
    * Clean builds directory
    * At this point ~/.cache should be created, ensure `chattr +C` is set
* Numlock setup
    * Install `mkinitcpio-numlock` from AUR
    * Add the `numlock` hook to /etc/mkinitcpio.conf before `block`
    * Regenerate initramfs: `sudo mkinitcpio -P`
    * Reboot to test
* BTRFS Snapshots
    * Install `snapper`
    * Create configs (located in /etc/snapper/configs/) for each subvolume that should have regular snapshots:
        ```
        sudo snapper -c root create-config /
        sudo snapper -c home create-config /home
        sudo snapper -c games create-config /mnt/games
        sudo snapper -c vms create-config /mnt/vms
        sudo snapper -c data create-config /home/ethan/Data
        sudo snapper -c gameBackups create-config /mnt/gameBackups
        ```
        * For the above subvolumes, use the config (leave the rest default):
            ```
            # run daily number cleanup - for pre-post snapshots (currently unused)
            NUMBER_CLEANUP="yes"

            # limit for number cleanup
            NUMBER_MIN_AGE="604800" # 7 days
            NUMBER_LIMIT="10"
            NUMBER_LIMIT_IMPORTANT="10"

            # create hourly snapshots
            TIMELINE_CREATE="yes"

            # cleanup hourly snapshots after some time
            TIMELINE_CLEANUP="yes"

            # limits for timeline cleanup
            TIMELINE_MIN_AGE="604800" # 7 days
            TIMELINE_LIMIT_HOURLY="168" # 7 days
            TIMELINE_LIMIT_DAILY="30" # 1 month
            TIMELINE_LIMIT_WEEKLY="0"
            TIMELINE_LIMIT_MONTHLY="0"
            TIMELINE_LIMIT_QUARTERLY="0"
            TIMELINE_LIMIT_YEARLY="0"
            ```
        ```
        sudo snapper -c scratch create-config /mnt/scratch
        ```
        * For the scratch subvolume, use the config (leave the rest default):
            ```
            # run daily number cleanup - for pre-post snapshots (currently unused)
            NUMBER_CLEANUP="yes"

            # limit for number cleanup
            NUMBER_MIN_AGE="10800" # 3 hours
            NUMBER_LIMIT="0"
            NUMBER_LIMIT_IMPORTANT="0"

            # create hourly snapshots
            TIMELINE_CREATE="yes"

            # cleanup hourly snapshots after some time
            TIMELINE_CLEANUP="yes"

            # limits for timeline cleanup
            TIMELINE_MIN_AGE="10800" # 3 hours
            TIMELINE_LIMIT_HOURLY="3"
            TIMELINE_LIMIT_DAILY="0"
            TIMELINE_LIMIT_WEEKLY="0"
            TIMELINE_LIMIT_MONTHLY="0"
            TIMELINE_LIMIT_QUARTERLY="0"
            TIMELINE_LIMIT_YEARLY="0"
            ```
    * Check configurations with `sudo snapper list-configs`
    * Enable/Start snapper-timeline.timer and snapper-cleanup.timer
    * Check snapshot creation/retention with `sudo snapper -c {config} list` after some time
* Audio
    * Install `pipewire`, `wireplumber`, `pipewire-jack`
* GPU Driver Configuration
    * Install Drivers: `mesa`, `vulkan-radeon`, and `libva-mesa-driver`
    * Install monitoring: `nvtop`
    * Disable passthrough GPU on host with VFIO driver:
        * Determine IOMMU groups/PCI IDs, and GPU IDs (ensure passthrough and host GPUs are in separate IOMMU groups). Use the script:
            ```
            #!/bin/bash
            shopt -s nullglob
            for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
                echo "IOMMU Group ${g##*/}:"
                for d in $g/devices/*; do
                    echo -e "\t$(lspci -nns ${d##*/})"
                done;
            done;
            ```
        * In /etc/modprobe.d/vfio.conf add (where `{x}` is the list of ids, {vendor}:{device}, associated with the passthrough GPU IOMMU):
            ```
            softdep drm pre: vfio-pci

            options vfio-pci ids={x}
            ```
        * In /etc/modprobe.d/amdgpu.conf add: `blacklist radeon`
        * In /etc/mkinitcpio.conf, ensure `modconf` is included as a HOOK and that `vfio_pci vfio vfio_iommu_type1 amdgpu` (ensure `vfio` modules precede `amdgpu` and that `radeon` is not included) are included as MODULE
        * Regenerate initramfs and reboot: `sudo mkinitcpio -P`
        * Ensure drivers are configured correctly with `lspci -nnk -d {xx:xx}`
            * Where `{xx:xx}` corresponds to the GPU {vendor}:{device}
            * Check that the passthrough GPU is using `vfio-pci` and the host GPU is using `amdgpu`
    * Overclocking:
        * Install `amdgpu-clocks-git`
        * Run `printf 'amdgpu.ppfeaturemask=0x%x\n' "$(($(cat /sys/module/amdgpu/parameters/ppfeaturemask) | 0x4000))"` to determine the `amdgpu.ppfeature` kernel parameter setting required to enable overclocking
            * In /etc/modprobe.d/amdgpu.conf add (where `{x}` is the hex value determined above): `options amdgpu ppfeaturemask={x}`
            * Regenerate initramfs and reboot: `sudo mkinitcpio -P`
            * Enable `amdgpu-clocks` on boot: `sudo systemctl enable --now amdgpu-clocks`
            * When overclocking, manually create the configuration file: /etc/default/amdgpu-custom-state.pci:xxxx:xx:xx.x
                * "xxxx:xx:xx.x" refers to the cards PCI {domain}:{bus}:{dev}.{function} numbers which can be determined from `lspci -n`
                * See https://github.com/sibradzic/amdgpu-clocks for overclocking reference
* GUI: Hyprland
    * Install Dependencies: `polkit`
    * Install hyprland: `hyprland`
    * Install Display Manager/Lockscreen: `greetd`, `hyprlock`
        * Configure `greetd` for autologin and then auto run-once `hyprlock` at start
    * Install additional software (https://wiki.hyprland.org/Useful-Utilities/Must-have/):
        * GTK theming: `nwg-look`
        * Qt support: `qt5-wayland`, `qt6-wayland`, `qt5ct`, `qt6ct`
        * Terminal Emulator: `wezterm`
        * Screen share: `xdg-desktop-portal-hyprland`
        * Wallpaper: `hyprpaper`
        * Idle Manager: `hypridle`
        * Status bar: `waybar`
        * Notifications: `mako`
        * Application Launcher: `rofi-wayland`
        * File Manager: `nnn`
        * Editors: `vim`, `neovim`, `nano`
        * Authentication Agent: `polkit-kde-agent`
        * Clipboard Manager: `wl-clipboard`, `clipse`
        * Screenshot: `hyprpicker`, `hyprshot`
    * Force apps to use wayland. Add `--enable-features=UseOzonePlatform --ozone-platform=wayland` to the applications .conf file
        * For electron apps use ~/.config/electron-flags.conf

## Additional Software
* (VS)Code: `code`, `code-marketplace`, `code-features`
    * Enable wayland rendering in config
* Browser: `chromium`
    * Enable wayland rendering in config
    * Enable Google synchrnozation via Oauth
    * Enable scrolling tabs
* Office: `libreoffice-fresh`, `libreoffice-extension-texmaths`, `libreoffice-extension-writer2latex`, `hunspell`, `hunspell-en_us`, `hyphen`, `hyphen-en`, `texlive-latexextra`, `texlive-fontsrecommended`, `texlive-bibtexextra`, `texlive-luatex`, `biber`, `aspell`, `aspell-en`
* Shell Check: `shellcheck`
* Discord: `webcord`
