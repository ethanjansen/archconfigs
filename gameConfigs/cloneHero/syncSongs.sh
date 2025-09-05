#!/bin/bash

# local folder
gameRoot="/mnt/games/cloneHero"
songFolder="$gameRoot/data/clonehero/Songs"
syncFolder="$gameRoot/sync"

# nextcloud stuff
serverUrl="https://{nextcloudURL}/remote.php/dav/files/{username}"
remotePath="/{nextcloudSongsPath}"

# check if syncFolder exists, create if not
if [ ! -d "$syncFolder" ]; then
  mkdir "$syncFolder"
fi

# mount nextcloud share
# This will prompt for sudo password
# This will prompt for nextcloud username and password
if ! mountpoint -q -- "$syncFolder"; then
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
mapfile -d "" -t src_dirs < <(cd "${syncFolder:?}${remotePath}" && find . -type d -print0 | sort -z)
mapfile -d "" -t dst_dirs < <(cd "${songFolder:?}" && find . -type d -print0 | sort -z)

declare -A src_set dst_set
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
echo "Deleting old files..."
for path in "${!dst_map[@]}"; do
  if [[ -z "${src_map["$path"]+_}" ]]; then
    rm -fv -- "${songFolder:?}/${path}"
  fi
done


# unmount nextcloud share
# This will prompt for sudo password
sudo umount "$syncFolder"
rmdir "$syncFolder"

# Done!
