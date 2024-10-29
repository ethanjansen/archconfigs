# Game Data Location Modification
### For when game data is not in the steam folder (for instance located in $HOME by default). The data will be moved and replaced with a symlink.

## Method:

* Move game data to /mnt/games/links/{game}/
* In original location link to moved data: `ln -s /mnt/games/links/{game}/{files} {target}`

## Games with moved data:

### Factorio

* Original location: ~/.factorio/

### SUPERHOT

* Original location: ~/.config/unity3d/SUPERHOT_Team/SUPERHOT/
* Original backup location: ~/.config/unity3d/SUPERHOT_Team/SUPERHOT_bak/

### Celeste

* ~/.local/share/Celeste/
