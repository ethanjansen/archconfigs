#!/bin/bash
# On remote handheld
# Config set from remote call

#### Config ####
# DST is folder that will be created from tarball (use dirname elsewhere)
TARBALL="$1"
DST="$2"
CLONEHEROPATH="/mnt/c/{path}"

#### Check Inputs ####
if [[ $# -ne 2 ]]; then
  echo "Error: Missing inputs" >&2
  exit 1
fi

for path in "$TARBALL" "$DST"; do
  case "$path" in
    "$CLONEHEROPATH"/*)
      # good
      ;;
    *)
      echo "Error: $path not in $CLONEHEROPATH" >&2
      exit 1
      ;;
  esac
done

echo "TARBALL=$TARBALL"
echo "DST=$DST"

#### Finish Sync ####
# Delete DST
echo "Deleting destination"
rm -rvf "$DST"

# Extract tarball
echo "Extracting tarball"
tar -xvf "$TARBALL" -C "$(dirname "$DST")"

# Delete tarball
echo "Cleaning up"
rm -vf "$TARBALL"

# Done!
