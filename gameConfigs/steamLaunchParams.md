# Steam Launch Parameters / Settings
### For when games require changes from the default Steam install to work (better)

## Games:

### Getting Over It

* Force to use Steam Play compatibilty with Proton Experimental
    * Without this, wins are not tracked, achievements don't work, and cannot use end-game chatroom.
    * Also removes 60fps lock and improves stuttering.
    * Notes: change to full screen to hide waybar; and screen goes black when not focused

### Grand Theft Auto V

* Selected launch option: "Play Grand Theft Auto V"
* Advanced launch options: `WINEDLLOVERRIDES="dinput8=n,b" %command% -nobattleye`
    * Cannot play online on linux due to anticheat
* Modding:
    * ScriptHook, asiloader, GTAV.UncapFPS, and V.Rainbomizer mods all saved in /mnt/games/mods/gtaV/ and linked to /mnt/games/SteamLibrary/steamapps/common/Grand\ Theft\ Auto\ V/
    * (Un)Install mods with scripts in /mnt/games/mods/gtaV/
        * install.sh: `ln -s /mnt/games/mods/gtaV/* /mnt/games/SteamLibrary/steamapps/common/Grand\ Theft\ Auto\ V/`
        * uninstall.sh `find /mnt/games/SteamLibrary/steamapps/common/Grand\ Theft\ Auto\ V/ -maxdepth 1 -type l -lname "/mnt/games/mods/gtaV/*" -delete` 
* Special saves backed up to /mnt/gameBackups/backups/gtaV/
