#!/bin/bash
# Shows the state of every audio file in audio/, and copies finished TextGrids into textgrid/.
# On Torch, inside this folder:  bash status.sh
set -euo pipefail
cd "$(dirname "$0")"
source lib/env.sh

shopt -s nullglob nocaseglob
files=(audio/*.wav audio/*.flac audio/*.mp3 audio/*.m4a)
[ ${#files[@]} -gt 0 ] || { echo "No audio files in the audio folder."; exit 0; }

mkdir -p textgrid
done=0 busy=0 bad=0 new=0
for f in "${files[@]}"; do
  stem=$(basename "${f%.*}")
  tg="out/$stem/$OUT_SUBDIR/whisper_output/$stem.TextGrid"
  if [ -f "$tg" ]; then
    cp -p "$tg" textgrid/
    state="DONE"; done=$((done + 1))
  else
    st=$(squeue --me -h -n "vxh-$stem" -o %T | head -1)
    if [ "$st" = "PENDING" ]; then
      state="WAITING for a GPU"; busy=$((busy + 1))
    elif [ -n "$st" ]; then
      state="RUNNING"; busy=$((busy + 1))
    else
      last=$(sacct -n -X --starttime=now-30days --name="vxh-$stem" -o State | tail -1 | xargs)
      if [ -n "$last" ]; then
        state="FAILED ($last): see logs/vxh-${stem}_*.err"; bad=$((bad + 1))
      else
        state="NOT STARTED: run bash run.sh"; new=$((new + 1))
      fi
    fi
  fi
  printf '%-40s %s\n' "$stem" "$state"
done
echo
echo "$done done, $busy waiting/running, $bad failed, $new not started."
[ "$done" -eq 0 ] || echo "Finished TextGrids are in the textgrid folder, ready to download (README step 7)."
