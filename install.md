# Arch Install
### Ethan Jansen
### 05/16/2024

## First Setup
* [Disk Partitioning/Mounting](./drives.md)
    * Create partitions with `fdisk` and `mkfs`
    * Create btrfs subvolumes:
        * Mount btrfs disks/partitions with `mount`.
        * `cd` to mount point and create subvolumes with `sudo btrfs subvolume create <path>`.
        * Unmount btrfs disks/partitions with `umount`.
    * Make sparse directory structure before mounting. Apply NOCOW attributes with `chattr +C` before and after mounting partitions.
        * Can view these attributes later with `lsattr`.
        * Mount partitions with `mount -o subvolid=<id>,subvol=</path/from/default/subvol> <disk/part> <mount point>`.
            * Can get subvolume id and path using `sudo btrfs subvolume list -t` when the btrfs disk/parition/subvolume is mounted.
    * mount partitons in "~" after install.
* Install Base Packages
    * `pacstrap -K /mnt base linux linux-lts linux-firmware amd-ucode btrfs-progs exfatprogs sudo nano vim man-db man-pages texinfo screen git rsync openssh which fastfetch usbutils`
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
        * Mount partitions with `mount -o subvolid=<id>,subvol=</path/from/default/subvol> <disk/part> <mount point>`.
        * Alternatively, add entries to /etc/fstab and use `mount <mount point>`
            * btrfs default fstab options: 
                * SSD: `rw,relatime,ssd,discard=async,space_cache=v2,subvolid=<id>,subvol=/<volname> 0 0`
                * HDD: `rw,relatime,space_cache=v2,subvolid=<id>,subvol=/<volname> 0 0`
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
    * Add wireplumber device configurations: [~/.config/wireplumber/wireplumber.conf.d/\*](./config/wireplumber/wireplumber.conf.d)
    * Restart pipewire: `systemctl --user restart pipewire`
    * Set wireplumber settings:
        ```
        wpctl settings device.routes.default-sink-volume 1.0
        wpctl settings --save device.routes.default-sink-volume 1.0

        # Check the ID values before hand with `wpctl status` for "rnnoise_source" (default source) and "Geshelli DAC" (default sink)
        wpctl set-default {default source}
        wpctl set-default {default sink}

        wpctl set-volume {default source} 1.0
        wpctl set-volume {default sink} 1.0
        ```
* GPU Driver Configuration
    * Install Drivers: `mesa`, `vulkan-radeon`, and `libva-mesa-driver`
    * 32-bit drivers (needed for steam, requires multilib repo): `lib32-mesa`, `lib32-vulkan-radeon` 
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
        * Application Launcher: `rofi`
        * File Manager: `nnn`, `tree`, `mediainfo`, `imagemagick`
        * Editors: `vim`, `neovim`, `nano`
        * Resource monitoring: `htop`, `nvtop`, `btop`, `rocm-smi-lib`
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
            * Set font: uncomment font line under "configuration", chaging it to: `font: "JetBrainsMono Nerd Font 9";`
        * `kitty` config: [kitty.conf](./config/kitty/kitty.conf)
            * Theming:
                * Set `font_family` to "JetBrainsMono Nerd Font". Leave the rest auto (uncommented). Set `font_size` to 9.
            * Change keybinds:
                * Close window: `kitty_mod+d`
                * start_resizing_window prompt: `kitty_mod+f4`
                * Change vertical/horizonal split (New): `kitty_mod+r`
                * Resize active window:
                    * narrower: `kitty_mod+left`
                    * wider: `kitty_mod+right`
                    * taller: `kitty_mod+up`
                    * shorder: `kitty_mod+down`
            * `nnn` support:
                * `allow_remote_control yes`
                * `listen_on unix:@mykitty`
        * `nvim` theming:
            * Install `vscode-json-languageserver`, `npm`, `unzip`
            * Clone NvChad: `git clone https://github.com/NvChad/starter ~/.config/nvim` 
                * Delete the .git folder
                * Modify the configs according to [.config/nvim/lua](./config/nvim/lua)
                * For theming while using sudo also copy the configs to /root/:
                    ```
                    sudo cp -r ~/.config/nvim /root/.config/
                    sudo chown -R root:root /root/.config/nvim
                    sudo chmod -R 700 /root/.config/nvim
                    ```
            * On first run of `nvim` let plugins install and update (Use the "U" menu to update). Close/Restart `nvim`.
            * Inside `nvim` execute `:MasonInstallAll` to update/install all LSP servers automatically. Close/Restart `nvim`.
        * `nnn` config:
            * Install plugins: `sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"`
            * Configure with ".basrch" environment variables: [.bashrc](./config/bashrc)
                ```
                export NNN_OPTS="deH"
                export NNN_FIFO="/tmp/nnn.fifo"
                export NNN_PLUG="p:preview-tui"
                ```
    * GTK/QT theming:
        * For GTK settings:
            * Set font to "JetBrainsMono Nerd Font Regular" size 9
            * Set color scheme to "Prefer dark"
            * Set Icon and Mouse cursor themes to "Adwaita"
                * Note: Segmentation Fault occurs on electron apps if this is not set.
        * For QT5/QT6 settings:
            * Ensure `QT_QPA_PLATFORMTHEME` environment variable is set via hyprland.conf
            * Set "Fusion" style with custom "darker" color scheme.
            * Change font to "JetBrainsMono Nerd Font Regular 9"
    * Force apps to use wayland:
        * For electron apps use ~/.config/electron-flags.conf
            ```
            --enable-features=WebRTCPipeWireCapturer
            --ozone-platform-hint=auto
            ```
* Virtual Machine Hypervisor:
    * Install: `qemu-desktop`, `libvirt`, `edk2-ovmf`, `virt-manager`, `dnsmasq`, `iptables-nft`, `swtpm`, and `looking-glass`
    * Create /mnt/vms/qemu, /mnt/vms/qemu/vdisks
        * Disable cow for vdisks: `chattr +C /mnt/vms/qemu/vdisks`
        * Convert old Vmware vmdk disks to qcow2: `qemu-img convert -cpf vmdk -O qcow2 {input.vmdk} {output.qcow2}`
    * Set `firewall_backend="iptables"` in /etc/libvirt/network.conf
    * Add user to libvirt and wheel groups:
        * `usermod -a -G libvirt ethan; usermod -a -G wheel ethan`
    * Enable `libvirtd.service`; also start `libvirtd.service` and `virtlogd.service`
    * Reboot.
    * Change group ownership of /mnt/vms/qemu: `chown -R ethan:libvirt-qemu /mnt/vms/qemu`
        * Also recursively set all directory permssions in /mnt/vms/qemu to 775, and all (non-executable) file permissions to 664
        * Do the same with /mnt/vms/ISOs
    * Link to libvirt VM config location:
        ```
        ln -s /etc/libvirt/qemu /mnt/vms/qemu/configs
        ln -s /etc/libvirt/storage /mnt/vms/qemu/storageConfigs
        ```
    * In virt-manager:
        * Configure /mnt/vms/qemu/vdisks storage pool:
            * Under Storage, stop the default pool and uncheck autostart on boot (this cannot be deleted as it will be recreated on boot for whatever reason).
            * Add a new pool, named "QemuPool", type "dir", with target path "/mnt/vms/qemu/vdisks". After creation have it autostart on boot. Apply.
            * Add a new pool, named "ISOs", type "dir", with target path "/mnt/vms/ISOs". After creation have it autostart on boot. Apply.
        * Configure virtual networks:
            * Delete default network
            * Configure NAT network, named "NAT", with DHCP serving 192.168.122.0/24
            * Configure Isolated network, named "Private", with IPv4 disabled
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
            * Install spice guest tools on linux: `spice-vdagent`

* Printers:
    * Install: `cups-pdf`, `hplip`, and `foomatic-db-ppds`
    * Enable/Start `cups.service`
    * Access config at [https://localhost:631/admin](https://localhost:631/admin)
        * Add printers:
            * CUPS-PDF:
                * Name: PDF-Printer
                * Description: CUPS PDF Printer
                * Driver: Generic CUPS-PDF (w/ options)
                * Default options:
                    * Log Level: error and status messages
                    * output resolution: 2400dpi
            * Lexmark E360d:
                * Name: Ethan-Printer
                * Description: Lexmark E360d
                * Driver: Lexmark E360d
                * Default options:
                    * Finishing->Duplex: Duplex - Long Edge
                    * Resolution: 600dpi
            * HP OfficeJet Pro 8710:
                * Name: Office-Printer
                * Description: HP OfficeJet Pro 8710
                * Driver: HP Officejet Pro 8710,hpcups,3.24.4 (en,en)
                * Default options:
                    * Double-sided printing: Long Edge
        * Set Ethan-Printer as the server default printer *(can be found under manage printers->administration dropdown)*
    * Set PDF-Printer output location:
        * Uncomment the line starting with "#Out" and modify it to `Out ${HOME}/Downloads` in /etc/cups/cups-pdf.conf
    * Restart `cups.service`
    * Tips:
        * Can print file from command line using: `lp [-d {printer}] {filename}`
            * Can also pipe into `lp`
            * If printer is not specified, default is used

## Additional Software
* Browser: `chromium`
    * Add [~/.config/chromium-flags.conf](config/chromium-flags.conf)
    * Set custom fonts in settings
    * Enable "Use System title bar and borders" to fix flashing and launch issues
    * Enable experimental features in chrome://flags
        * Fluent Scrollbars: Enabled
        * Tab Scrolling: Enabled - tabs shrink to large size
        * Tab Scrolling Overflow Indicator: Enabled - Fade
        * Parallel downloading: Enabled
* Office: `libreoffice-fresh`, `libreoffice-extension-texmaths`, `libreoffice-extension-writer2latex`, `hunspell`, `hunspell-en_us`, `hyphen`, `hyphen-en`, `texlive-latexextra`, `texlive-fontsrecommended`, `texlive-bibtexextra`, `texlive-luatex`, `biber`, `aspell`, `aspell-en`
* Shell Check: `shellcheck`
* 7zip: `p7zip`
* Discord: `discord`
    * Config: [~/.config/discord/settings.json](./config/discord/settings.json)
        * Use `"SKIP_HOST_UPDATE": true` to prevent update messages on startup
* Spotify:
    * Import spotify GPG key:
        * Check [aur package](https://aur.archlinux.org/packages/spotify) for latest GPG to import
        * Remove old GPG keys with `gpg --delete-key {KEY}`
            * Get the key to delete with `gpg -k`
    * Install from AUR: `spotify`, `spicetify-cli`
    
    * Force Wayland support: in ~/.config/spotify-flags.conf append:
        ```
        --enable-features=UseOzonePlatform
        --ozone-platform=wayland
        ```
        * Wayland actually breaks settings dropdowns in spotify. Disable to apply settings, and reapply later.
    * Start spotify to create ~/.config/spotify
    * Limit storage size: append `storage.size=5120` to ~/.config/spotify/prefs
    * Theme with spicetify:
        * Allow spicetify access to spotify install:
            ```
            sudo chmod a+wr /opt/spotify
            sudo chmod a+wr /opt/spotify/Apps -R
            ```
        * Install Spicetify-Lucid theme:
            * Create ~/.config/spicetify/Themes/Lucid
            * Copy theme from github:
                ```
                curl --silent -L -o ~/.config/spicetify/Themes/Lucid/color.ini "https://raw.githubusercontent.com/sanoojes/Spicetify-Lucid/main/src/color.ini"
                curl --silent -L -o ~/.config/spicetify/Themes/Lucid/user.css "https://raw.githubusercontent.com/sanoojes/Spicetify-Lucid/main/src/user.css"
                curl --silent -L -o ~/.config/spicetify/Themes/Lucid/theme.js "https://raw.githubusercontent.com/sanoojes/Spicetify-Lucid/main/src/theme.js"
                ```
            * Apply spicetify: 
                ```
                spicetify config current_theme Lucid color_scheme dark
                spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
                spicetify config extensions "bookmark.js|fullAppDisplay.js|keyboardShortcut.js"
                spicetify backup apply
                ```
            * Lucid settings (in spotify):
                * blur: 15
                * dynamic colors
                * set grains: default
                * playlist set background iamge: now-playing
                * set player mode: default
                * playbar set backdrop blur: 15
                * playlist view mode: compact
            * Full App Display settings (in spotify, full app display, right click):
                * Enable progress bar
                * Enable controls
                * Trim title
                * Show album
                * Show icons
                * Enable song change animation
* **UNUSED** Razer Peripherals: `openrazer-daemon`, `razergenie` 
    * Installation:
        * Add user to plugdev group: `sudo gpasswd -a $USER plugdev`; sign out after this.
        * openrazer-daemon uses a dkms driver; linux headers are required to build this. Install `linux-headers` and `linux-lts-headers`.
            * This should automatically build the dkms driver. Reboot.
    * Keyboard: Nothing
* Vial Peripherals:
    * Configuration:
        * Add udev rules to /etc/udev/rules.d/99-vial.rules, replacing Vendor and Product id's for specific keyboard using `lsusb`:
            ```
            # Name of your keyboard
            KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="XXXX", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
            ```
        * Reload udev: `sudo udevadm control --reload-rules && sudo udevadm trigger`
        * Ensure user is added to plugdev group: `sudo gpasswd -a $USER plugdev`; sign out after this.
        * Configure devices using [vial.rocks](https://vial.rocks) using chromium browser
            * Make sure to backup configuration!
            * Refer to [keyboard scan codes](https://www.usb.org/sites/default/files/hut1_6.pdf#chapter.10), [media scan codes](https://www.usb.org/sites/default/files/hut1_6.pdf#chapter.15), and [xkb keysyms](https://github.com/xkbcommon/libxkbcommon/blob/master/include/xkbcommon/xkbcommon-keysyms.h)
        * Use `wev` to get keyboard codes for programming Hyprland
    * Keyboard:
        * Modern Model F F122:
            * [Layout](./config/modelF122Layout.vial)
            * Diagnostics: `leyden-jar-diagnostic-tool-git`
                * *Note: Run with `leyden-jar-diagnostic-tool` from shell. Cannot quit window because keyboard will not work*
* Logitech Peripherals: `solaar`
    * Installation:
        * Ensure user is added to plugdev group: `sudo gpasswd -a $USER plugdev`; sign out after this.
        * Reload udev rules: `sudo udevadm contorl --reload-rules`
        * Add startup to hyprland config: `exec-once = solaar -w hide --restart-on-wake-up`
    * Mouse:
        * Unlock and set the following settings:
            * Onboard profiles: Disabled
            * Report rate: 1ms *(Note: higher refresh rate does not work in some games)*
            * Sensitivity: X/Y/LOD: 800
* RGB: `openrgb`
    * Installation: Enable the `i2c_dev` module by adding `i2c_dev` to /etc/modules-load.x/i2c-dev.conf and reboot.
    * Set Asus Addressable RGB 1 to size 0 and Asus Addressable RGB 2 to size 30.
    * Create a static green profile applied to all devices.
    * Apply on boot by adding `exec-once = openrgb -p Green.org` to hyprland config
    * Apply after hibernation by adding [userRGBAfterHibernate systemd service](./systemd/system/userRGBAfterHibernate@.service) and enabling for user.
* Java: `jdk-openjdk` (latest), `jdk17-openjdk`, and `jdk8-openjdk` (for minecraft)
    * Ensure the latest java is set as the default environment using `archlinux-java status` and `archlinux-java set {java environment name}`
* Gaming:
    * Steam:
        * Install: 
            * Enable multilib support (dumb 32bit): uncomment the `[multilib]` section in /etc/pacman.conf. Update system.
            * Add user to disk group: `sudo gpasswd -a $USER disk`; sign out after this.
            * Install Windows fonts (yuck): `ttf-ms-win11-auto`
            * Install 32-bit dependencies: `lib32-systemd`
            * Increase `vm.max_map_count`: Create /etc/sysctl.d/80-vmmaxmap.conf with contents `vm.max_map_count = 2147483642`. Reboot.
            * Install steam: `steam`, `steam-screensaver-fix`
        * Settings:
            * In Steam Settings -> Storage, add /mnt/games as drive and make default.
            * In Steam Settings -> Compatibility, enable steam play for all other titles
            * In Steam settings -> Downloads, disable shader pre-caching
        * Run:
            * Using Rofi, run "Steam (Screensaver fix) (Runtime)" to prevent Steam from inhibiting lockscreen (even after being closed) -- known bug
        * [Check anti-cheat support](https://areweanticheatyet.com/)
        * [Check Proton support](https://www.protondb.com/)
        * [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Home) - for custom save locations
        * [Custom Game Launch Configs](./gameConfigs/steamLaunchParams.md)
        * [Non-standard Game Data Relocation](./gameConfigs/dataLocationMoves.md)
        * [Save Backups](./gameConfigs/saveBackups.md) (non-cloud saves)
        * [Special Linux Game Settings](./gameConfigs/specialLinuxSettings.md)
    * Minecraft:
        * Install: `prismlauncher`
        * Create folders: /mnt/games/prismLauncher/instances/ /mnt/games/prismLauncher/mods/ /mnt/games/prismLauncher/icons/ /mnt/games/prismLauncher/java/ /mnt/games/prismLauncher/skins/
        * Settings:
            * Set folders to match those above (leave downloads as default)
            * In Minecraft -> Tweaks, use discrete GPU
            * In Java, set min allocation to 1024 and max to 10240. Set JVM arguments: `-XX:+UseG1GC -Dsun.rmi.dgc.server.gcInterval=2147483646 -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M`. Set java path to "/usr/lib/jvm/java-8-openjdk/bin/java" (use "Auto-detect...").
                * For newer minecraft versions: set java path accordingly per instance
            * For instances crashing due to libopenal: set environment variable: `ALSOPT_DRIVERS=pulse`
        * For each modpack instance create and symlink to /mnt/gameBackups/backups/minecraft/{instance}/ from /mnt/games/prismLauncher/instances/{instance}/minecraft/backups then ensure the ftbbackups location is set to nothing (`S:folder=`) in {instance folder}/minecraft/config/ftbutilities.cfg and {instance folder}/minecraft/config/ftbbackups.cfg
            * When creating a final backup of an instance, delete the /mnt/games/prismLauncher/instances/{instance}/minecraft/backups symlink, delete the automatic backups, and store an entire xz backup of /mnt/games/prismLauncher/instances/{instance} 
    * CloneHero:
        * Install:
            * Create folders: /mnt/games/cloneHero/ /mnt/games/cloneHero/data/clonehero/ /mnt/games/cloneHero/data/Clone\ Hero/
            * Download tarball from [CloneHero Website](https://clonehero.net)
            * Extract: `tar -xvf {path/to}/CloneHero-linux.tar.xz -C /mnt/games/cloneHero`
            * Move files: `mv /mnt/games/cloneHero/clonehero-linux/* /mnt/games/cloneHero/ && rmdir /mnt/games/cloneHero/clonehero-linux`
            * Create symlinks according to [dataLocationMoves](./gameConfigs/dataLocationMoves.md)
            * Make executable: `chmod +x /mnt/games/cloneHero/clonehero`
            * Copy start script: `cp ./gameConfigs/cloneHero/startCloneHero.sh /mnt/games/cloneHero/`
        * Run:
            * Use [start script](./gameConfigs/cloneHero/startCloneHero.sh) to prevent black screen glitch after 3 songs
        * [Settings](./gameConfigs/specialLinuxSettings.md)
        * Custom Songs:
            * Sync with NextCloud using [script](./gameConfigs/cloneHero/syncSongs.sh)
                * Requires `davfs2`
                    * Config: [/etc/davfs2/davfs2.conf](./config/davfs2/davfs2.conf)
                        * *Bug Note: Settings `buf_size 64` or more is required to read from webDAV on linux 6.16*
                * *Note: This is slow*
            * Scan for new songs in CloneHero settings.
            * Sync with Windows PC with [script](./gameConfigs/cloneHero/syncHandheld.sh)
                * First create song directory structure and upload [remote script](./gameConfigs/cloneHero/finishHandheldSync.sh)
                * Requires wsl on Windows
        * *Bug Note: Calibration tool has muted audio*
* Docker: `docker`, `docker-compose`
    * Enable docker socket: `sudo systemctl enable docker.socket`
    * Ensure the docker btrfs subvolume is mounted (and in fstab) at /var/lib/docker
    * Reboot
    * Verify docker install: `sudo docker info`
    * Use the btrfs docker storage driver:
        * Ensure `docker.service` is not running
        * Remove everything from /var/lib/docker
        * Create /etc/docker/daemon.json and add:
            ```
            {
              "storage-driver": "btrfs"
            }
            ```
        * Start docker and verify with `sudo docker info`
    * Test docker install: `sudo docker run -it --rm archlinux bash -c "echo Hello World!"`
        * To clean up test get image id with `sudo docker images` and delete image with `sudo docker rmi <image id>`
    * *Do not add user to `docker` group as it is equivalent to root*
* CAD:
    * Kicad: `kicad`, `kicad-library`, `kicad-library-3d`
        * Disable automatic update checking
* 3D Printer Slicer: `orca-slicer-bin`
    * Setup: Generic Marlin 0.4mm printer, generic filaments, stealth mode
    * Preferences: check for stable updates only, do not show tip of day
* Partition management: `gparted`, `udftools`, `xfsprogs`, `gpart`, `xorg-xhost`, `mtools`
    * Launch with `sudo -E gpated`
* Media Content:
    * Player: `mpv`
    * MKV Tools: `makemkv`, `mkvtoolnix-gui`, `qt6-multimedia-ffmpeg`
        * MakeMKV settings:
            * Custom file destination: /mnt/scratch/Movies/MakeMKV
            * Minimum file length: 40 seconds
            * Expert mode, show AV synchronization messages, and enable internet access
            * Interface/Preferred language: eng
            * Custom java executable location: /usr/lib/jvm/java-23-openjdk/bin/java
        * MKVToolNix GUI settings:
            * GUI: Uncheck "Check online for available updates"
            * Multiplexer:
                * Process priority: Normal
                * Adding files: always add files to the current multiplex settings
                * Adding directories: handle all files from all directories as a single list of files
                * Predefined values:
                    * Audio: Surround 7.1, Surround 5.1, Stereo, Commentary
                    * Subtitles: English, Forced, Commentary
                * Default values:
                    * Set default track languages to eng
                    * Disable "default track" flag for subtitle tracks
                    * Added underscores to the "derive... from file names" regular expressions
                * Destination file:
                    * Check "Only use the first source file that contains a video track"
                    * Fixed destination directory: /mnt/scratch/Movies/MKVTools
                * Playlists and Blu-rays:
                    * Minimum playlist duration: 40 seconds
            * Jobs and job queue:
                * Always use a default description when adding a job to the queue
                * Remove the output file when a job ends with errors or when it is aborted
                * Remove job from queue after completion: Only if the job ocmpleted successfully
    * Transcoding: `handbrake`, `ffmpeg`
        * Handbrake settings:
            * Set destination "To" to: /mnt/scratch/Movies/Handbrake 
            * Import presets from "~/Documents/Handbrake Presets"
                * Set 1080p preset as default
    * Subtitles: `subtitleedit`, `tesseract`, `tesseract-data-eng`
        * SubtitleEdit settings:
            * General: Uncheck "Check for updates"
            * Toolbar: New, Open, Save, Find, Replace, Fix common errors, Spell check, settings
            * Appearance:
                * Subtitle font: JetBrainsMono Nerd Font
                * Use dark theme with list view grid lines
                * List view: subtitle font size: 11
                * Text box: subtitle font size: 11 bold
            * Layout (not under settings): 12
            * Batch convert settings:
                * Save in output folder: /mnt/scratch/Movies/SubtitleEdit
                * Format: srt
                * Encoding: UTF-8 with BOM
            * Spell check (set by running spell check): Set dictionary language to "English - English/British" and download
            * Fix common errors default: Remove empty lines/unused line breaks, Fix overlapping display times, Fix invalid italic tags, Remove unneeded spaces, Remove unneeded periods, Fix commas, Fix double apostrophe characters to a single quote, Add missing quotes, Remove '> >', Fix missing \[ or \( in line, Fix ocmmon OCR errors, Fix uppercase 'i' inside lowercase words, remove space between numbers, Fix alone lowercase 'i' to 'I'
        * *Note: SubtitleEdit batch convert does not work when input files do not have an extension.*
    * Audio: `audacity`
    * Video Recording: `obs-studio`
        * Optimize for recording
* File/Photo/Video Comparison Tool: `czkawka`
* Android File Transfer: `android-file-transfer`
    * Usage: `aft-mtp-cli`
        * Use `?` to get help
        * Alternatively use `aft-mtp-mount <dir>` to mount android device to "<dir>" with FUSE
