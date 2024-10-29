# Custom Save Backups
### For when game data (saves/configurations) are not saved to the cloud.

## Method:

* Move games save/configuration data to /mnt/gameBackups/saves/{game}/
* In game location, create symbolic link to moved data: `ln -s /mnt/gameBackups/saves/{game}/{files} {target}`

## Inidividual Game Data Location:

### Five Nights at Freddy's 

* Save game: /mnt/games/SteamLibrary/steamapps/compatdata/319510/pfx/drive_c/users/steamuser/AppData/Roaming/MMFApplications/freddy

### Five Nights at Freddy's 2

* Save game: /mnt/games/SteamLibrary/steamapps/compatdata/332800/pfx/drive_c/users/steamuser/AppData/Roaming/MMFApplications/freddy2

### Five Nights at Freddy's 3

* Save game: /mnt/games/SteamLibrary/steamapps/compatdata/354140/pfx/drive_c/users/steamuser/AppData/Roaming/MMFApplications/freddy3

### Getting Over It 

* Save game/configuration: /mnt/games/SteamLibrary/steamapps/compatdata/240720/pfx/user.reg
    * [Using Steam Compatibility - Proton](./steamLaunchParams.md)
