#!/bin/bash

# WSL seems to struggle with lots of small files
# rsync -rltvP --no-perms --del --rsync-path='wsl rsync' /mnt/games/cloneHero/data/clonehero/Songs ethan@ethanlegiongo.pihole:/mnt/c/Users/ethan/Music/clonehero/

#### Configuration ####
# Only doing Custom songs (others shouldn't change frequently)
GAMEPATH="/mnt/games/cloneHero"
SRC="$GAMEPATH/data/clonehero/Songs/Custom"
DST="/mnt/c/{path}"
REMOTEHOST="{username}@{remoteIP/DN}"
TARBALL="songsHandheldSync.tar"
REMOTESCRIPT="$DST/finishHandheldSync.sh"

#### Sync ####
# Create tarball locally
echo "Creating tarball"
tar -cvf "$GAMEPATH/$TARBALL" -C "$(dirname "$SRC")" "$(basename "$SRC")"

# Copy tarball to remote host -- will prompt for key password
echo "Copying tarball to remote host"
read -rp "Press Enter to continue..."
rsync -tvP --no-perms --rsync-path='wsl rsync' "$GAMEPATH/$TARBALL" "$REMOTEHOST":"$DST/"

# Extract on remote and clean up -- will prompt for key password
#   rm -rvf $DST/Songs/Custom
#   tar -xvf $DST/$TARBALL -C $DST/Songs
#   rm -vf $DST/$TARBALL
echo "Finishing on remote host"
read -rp "Press Enter to continue..."
# shellcheck disable=SC2029
ssh "$REMOTEHOST" "wsl \"$REMOTESCRIPT\" \"$DST/$TARBALL\" \"$DST/Songs/Custom\""

# Clean up locally
echo "Cleaning up locally"
rm -vf "$GAMEPATH/$TARBALL"

# Done!
