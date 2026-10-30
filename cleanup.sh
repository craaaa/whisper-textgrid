#!/bin/bash
# Deletes all audio and results from this folder (keeps the install and logs).
# On Torch, inside this folder:  bash cleanup.sh
set -euo pipefail
cd "$(dirname "$0")"

if squeue --me -h -o %j | grep -q '^vxh-'; then
  echo "Jobs are still waiting or running (see bash status.sh). Wait until they finish." >&2
  exit 1
fi

shopt -s nullglob
n_audio=$(ls audio | wc -l | xargs)
n_tg=$(ls textgrid | wc -l | xargs)
echo "This permanently deletes $n_audio audio file(s), $n_tg TextGrid(s) in textgrid/, and everything in out/."
echo "Download your TextGrids first (README step 7)."
read -r -p "Type YES to delete: " answer
[ "$answer" = "YES" ] || { echo "Nothing deleted."; exit 0; }
rm -rf audio/* textgrid/* out/*
echo "Deleted."
