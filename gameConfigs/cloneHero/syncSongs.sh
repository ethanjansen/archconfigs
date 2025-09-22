#!/bin/bash

#### Config ####
# local folder
gameRoot="/mnt/games/cloneHero"
songFolder="$gameRoot/data/clonehero/Songs"
syncFolder="$gameRoot/sync"

# nextcloud stuff
serverUrl="https://{nextcloudURL}/remote.php/dav/files/{username}"
remotePath="/{nextcloudSongsPath}"

#### Options ####
dirsOnly=false

if [[ $# -eq 0 ]]; then
  :
elif [[ $# -eq 1 && "$1" == "--dirsOnly" ]]; then
  dirsOnly=true
else
  echo "Usage: $0 [--dirsOnly]"
  echo
  echo "Default:"
  echo "  Sync with nextcloud by comparing directories, then files, and then creating/updating/deleting directories/files if necessary."
  echo "  Does not update until after comparing directories/files to improve DAVFS latency issues."
  echo "Optional Options:"
  echo "  --dirsOnly : Only compares directories. Directories missing from nextcloud will be deleted locally (recursively)."
  echo "               Directories new on nextcloud will be created locally, with contained files."
  echo "               But files will not be updated within already existing directories (no creates/updates/deletes)"
  exit 0
fi

#### DAVFS Mount ####
# check if syncFolder exists, create if not
if [ ! -d "$syncFolder" ]; then
  mkdir "$syncFolder"
fi

# mount nextcloud share
# This will prompt for sudo password
# This will prompt for nextcloud username and password
if ! mountpoint -q -- "$syncFolder"; then
  echo "Mounting nextcloud share..."
  read -rp "Press Enter to continue..."
  sudo mount -t davfs -o ro,noexec,nodev,nosuid "$serverUrl" "$syncFolder"
  if ! mountpoint -q -- "$syncFolder"; then
    echo "Failed to Mount! Exitting..." >&2
    exit 1
  fi
fi

# rsync by itself is slow. Let's do it piece by piece...
#rsync -vtrhW --progress --del "${syncFolder}${remotePath}" "${songFolder}/../"

#### Compare directories ####
echo "Getting directory structure..."
declare -A src_set dst_set
new_dirs=()
mapfile -d "" -t src_dirs < <(cd "${syncFolder:?}${remotePath}" && find . -type d -print0 | sort -z)
mapfile -d "" -t dst_dirs < <(cd "${songFolder:?}" && find . -type d -print0 | sort -z)

for d in "${src_dirs[@]}"; do
  src_set["$d"]=1
done
for d in "${dst_dirs[@]}"; do
  dst_set["$d"]=1
done

# create missing directories
echo "Creating new directories..."
for d in "${src_dirs[@]}"; do
  [[ "$d" == "." ]] && continue
  if [[ -z "${dst_set["$d"]+_}" ]]; then
    mkdir -pv -- "${songFolder:?}/${d}"
    new_dirs+=("$d")
  fi
done

# delete directories not in source
echo "Deleting old directories..."
for (( i=${#dst_dirs[@]}-1; i>=0; i-- )); do
  d="${dst_dirs[i]}"
  [[ "$d" == "." ]] && continue
  if [[ -z "${src_set["$d"]+_}" ]]; then
    rm -rfv -- "${songFolder:?}/$d"
  fi
done


#### Compare files ####
echo "Getting file list..."
declare -A src_map dst_map

if $dirsOnly; then
  echo "Using --dirsOnly mode..."
  
  for d in "${new_dirs[@]}"; do
    while IFS= read -r -d "" line; do
      mtime=${line%% *}
      mtime=${mtime%%.*}
      path="$d/${line#* }"
      src_map["$path"]=$mtime
    done < <(cd "${syncFolder:?}${remotePath}" && find "$d" -type f ! -name "*.zip" -printf "%T@ %P\0") # ignore zips
  done
else
  while IFS= read -r -d "" line; do
    mtime=${line%% *}
    mtime=${mtime%%.*}
    path=${line#* }
    src_map["$path"]=$mtime
  done < <(cd "${syncFolder:?}${remotePath}" && find . -type f ! -name "*.zip" -printf "%T@ %P\0") # ignore zips

  while IFS= read -r -d "" line; do
    mtime=${line%% *}
    mtime=${mtime%%.*}
    path=${line#* }
    dst_map["$path"]=$mtime
  done < <(cd "${songFolder:?}" && find . -type f -printf "%T@ %P\0")
fi

# create and update files
echo "Copying new/updated files..."
for path in "${!src_map[@]}"; do
  src_mtime=${src_map["$path"]}
  dst_mtime=${dst_map["$path"]:-}
  if [[ -z "$dst_mtime" || "$src_mtime" -ne "$dst_mtime" ]]; then
    cp -vf --preserve=timestamps -- "${syncFolder:?}${remotePath}/${path}" "${songFolder:?}/${path}"
  fi
done

# delete files not in source
if ! $dirsOnly; then
  echo "Deleting old files..."
  for path in "${!dst_map[@]}"; do
    if [[ -z "${src_map["$path"]+_}" ]]; then
      rm -fv -- "${songFolder:?}/${path}"
    fi
  done
else
  echo "Skipping deleting old files in --dirsOnly mode..."
fi

# unmount nextcloud share
# This will prompt for sudo password
echo "Cleaning up..."
read -rp "Press Enter to continue..."
sudo umount "$syncFolder"
rmdir "$syncFolder"

# Done!
