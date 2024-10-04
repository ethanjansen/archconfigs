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
    * Later, after configuring `hyprland` and `hyprlock`, enable lock screen after hibernation. Create the [/etc/systemd/system/userLockHibernate@.service](./systemd/system/userLockHibernate@.service)
    * Enable `userLockHibernate@ethan.service`
* Networking, Wake-On-LAN, and Time Synchronization
    * Start and enable `systemd-resolved.service` and `systemd-networkd.service`
    * Add the network configuration [files](./systemd/network) to /etc/systemd/network/. Be sure to add the host mac address for enp6s0 in [40-br0.netdev](./systemd/network/40-br0.netdev). This configures Wake-On-LAN for enp6s0, creates the bridge br0 off of enp6s0 and enables DHCPv4 wih the static DNS address of 192.168.1.2.
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
    * Relax PAM faillock by modifying /etc/security/faillock.conf with the following:
        ```
        unlock_time = 600
        fail_interval = 600
        deny = 10
        ```
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
    * Install `pipewire`, `wireplumber`, `pipewire-jack`, `pipewire-alsa`, `pipewire-pulse`, `noise-suppression-for-voice`
    * Ensure services are started: `systemctl --user --now enable pipewire pipewire-pulse wireplumber`
    * Add Pipewire configuration for noise suppression: [~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf](./config/pipewire/pipewire.conf.d/99-input-denoising.conf)
    * Add wireplumber device configurations: [~/.config/wireplumber/wireplumber.conf.d/*](./config/wireplumber/wireplumber.conf.d)
    * Restart pipewire: `systemctl --user restart pipewire`
    * Set wireplumber settings:
        ```
        wpctl settings device.routes.default-sink-volume 1.0
        wpctl settings --save device.routes.default-sink-volume 1.0

        # could just check the ID values before hand with `wpctl status`
        wpctl set-default $(wpctl status | grep "\. rnnoise_source" | grep -Eo '[0-9]*')

        wpctl set-volume $(wpctl status | grep "\. Digital Stereo" | grep -Eo '[0-9]*') 1.0
        ```
* GPU Driver Configuration
    * Install Drivers: `mesa`, `vulkan-radeon`, and `libva-mesa-driver`
    * Install monitoring: `nvtop`
    * Install other utils: `libva-utils`
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
        * Enable `greetd.service` to start on boot
        * To enable autologin: change /etc/greetd/config.toml to execute the command `Hyprland` as user `ethan`
        * Ensure `hyprlock` is set to run-once in hyprland.conf
    * Install additional software (https://wiki.hyprland.org/Useful-Utilities/Must-have/):
        * Fonts: `nerd-fonts`
        * GTK theming: `nwg-look`
        * Qt support: `qt5-wayland`, `qt6-wayland`, `qt5ct`, `qt6ct`
        * Terminal Emulator: `kitty`, `icat`
        * Screen share: `xdg-desktop-portal-hyprland`
        * Wallpaper: `hyprpaper`
        * Idle Manager: `hypridle`
        * Status bar: `waybar`, `otf-font-awesome`
        * Notifications: `mako`
        * Application Launcher: `rofi-wayland`
        * File Manager: `nnn`
        * Editors: `vim`, `neovim`, `nano`
        * Authentication Agent: `polkit-kde-agent`
        * Clipboard Manager: `wl-clipboard`, `clipse`, `wl-clipboard-x11`
        * Screenshot: `hyprpicker`, `hyprshot`
    * Desktop configuration:
        * `hyprland` see: [hyprland.conf](./config/hypr/hyprland.conf), [hyprfont.conf](./config/fonts/hyprfont.conf), and [hyprcolor.conf](./config/colors/hyprcolor.conf)
        * `hyprpaper` see: [hyprpaper.conf](./config/hypr/hyprpaper.conf)
        * `hyprlock` see: [hyprlock.conf](./config/hypr/hyprlock.conf)
        * `rofi`:
            * Generate default `rofi` config by running `rofi -dump-config > ~/.config/rofi/config.rasi`
            * Apply theme by appending: `@theme "/usr/share/rofi/themes/Arc-Dark.rasi"`
        * `nvim` theming:
            * Install `vscode-json-languageserver`, `npm`, `unzip`, `nvchad-git`
            * Create the ~/.config/nvim/lua/configs path and copy the files:
                ```
                cp /usr/share/nvchad/lua/chadrc.lua ~/.config/nvim/lua/
                cp /usr/share/nvchad/lua/configs/lspconfig.lua ~/.config/nvim/lua/configs
                ```
                * Modify the configs according to [.config/nvim/lua](./config/nvim/lua)
            * Inside `nvim` execute `:MasonInstallAll` to update/install all LSP servers automatically
            * Close/Restart `nvim`
    * Force apps to use wayland:
        * For electron apps use ~/.config/electron-flags.conf
            ```
            --enable-features=WebRTCPipeWireCapturer
            --ozone-platform-hint=auto
            ```
* Virtual Machine Hypervisor:
    * Install: `qemu-desktop`, `libvirt`, `edk2-ovmf`, `virt-manager`, `dnsmasq`, `iptables-nft` and `looking-glass`
    * Create /mnt/vms/qemu, /mnt/vms/qemu/vdisks
        * Disable cow for vdisks: `chattr +C /mnt/vms/qemu/vdisks`
        * Convert old Vmware vmdk disks to qcow2: `qemu-img convert -cpf vmdk -O qcow2 {input.vmdk} {output.qcow2}`
    * Set `firewall_backend="iptables"` in /etc/libvirt/network.conf
    * Add user to libvirt and wheel groups:
        * `usermod -a -G libvirt ethan; usermod -a -G wheel ethan`
    * Enable libvirtd.service; also start libvirtd.service and virtlogd.service
    * Reboot.
    * Change group ownership of /mnt/vms/qemu: `chown -R ethan:libvirt-qemu /mnt/vms/qemu`
        * Also recursively set all directory permssions in /mnt/vms/qemu to 775, and all (non-executable) file permissions to 664
        * Do the same with /mnt/vms/ISOs
    * Move libvirt VM config location (leave default ownserhip/permissions)
        ```
        sudo mv /etc/libvirt/qemu /mnt/vms/qemu/configs
        sudo mv /etc/libvirt/storage /mnt/vms/qemu/storageConfigs
        sudo ln -s /mnt/vms/qemu/configs /etc/libvirt/qemu
        sudo ln -s /mnt/vms/qemu/storageConfigs /etc/libvirt/storage
        ```
    * In virt-manager:
        * Configure /mnt/vms/qemu/vdisks storage pool:
            * Under Storage, stop the default pool and uncheck autostart on boot (this cannot be deleted as it will be recreated on boot for whatever reason).
            * Add a new pool, named "QemuPool", type "dir", with target path "/mnt/vms/qemu/vdisks". After creation have it autostart on boot. Apply.
            * Add a new pool, named "ISOs", type "dir", with target path "/mnt/vms/ISOs". After creation have it autostart on boot. Apply.
        * Configure virtual networks:
            * Delete default network
            * Configure NAT network, named "NAT", with DHCP serving 192.168.122.0/24
            * Configure Bridge network, named "Bridge" connected to br0 (created manually during network configuration). Use the custom xml (uuid should be added automatically if created with virt-manager):
                ```
                <network>
                  <name>Bridge</name>
                  <forward mode="bridge"/>
                  <bridge name="br0"/>
                </network>
                ```
        * Tips:
            * To enable UEFI w/o secure boot domains, use the `UEFI x86_64: /usr/share/edk2/x64/OVMF_CODE.4m.fd` firmware.
            * To enable virtual 3D acceleration:
                * Add Video hardware with "Model" as "Virtio". Then remove any other "Video" virtual hardware (within the sidebar).
                * Go to "Display Spice" and set "Listen Type" to "None". Also tick the "OpenGL" checkbox and select the appropriate renderer.
                * Click on "Video Virtio" and tick "3D Acceleration".
            * Install virtio guest tools for windows: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/

## Additional Software
* (VS)Code: `code`, `code-marketplace`, `code-features`
    * Enable wayland rendering: `cp ~/.config/electron-flags.conf ~/.config/code-flags.conf`
* Browser: `chromium`
    * Add [~/.config/chromium-flags.conf](config/chromium-flags.conf)
    * Set custom fonts in settings
    * Enable experimental features in chrome://flags
        * Fluent Scrollbars: Enabled
        * Tab Scrolling: Enabled - tabs shrink to large size
        * Tab Scrolling Overflow Indicator: Enabled - Fade
        * Parallel downloading: Enabled
* Office: `libreoffice-fresh`, `libreoffice-extension-texmaths`, `libreoffice-extension-writer2latex`, `hunspell`, `hunspell-en_us`, `hyphen`, `hyphen-en`, `texlive-latexextra`, `texlive-fontsrecommended`, `texlive-bibtexextra`, `texlive-luatex`, `biber`, `aspell`, `aspell-en`
* Shell Check: `shellcheck`
* Discord: `webcord`
