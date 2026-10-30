#!/bin/bash
# Starts one GPU job for every audio file in audio/ that has no TextGrid yet.
# On Torch, inside this folder:  bash run.sh
set -euo pipefail
cd "$(dirname "$0")"
source lib/env.sh
[ -d .venv ] || { echo "Not installed yet. Run: bash install.sh" >&2; exit 1; }
pick_account

shopt -s nullglob nocaseglob
files=(audio/*.wav audio/*.flac audio/*.mp3 audio/*.m4a)
[ ${#files[@]} -gt 0 ] || { echo "No audio files in the audio folder. Upload them first (README step 4)." >&2; exit 1; }

mkdir -p out logs
queued=$(squeue --me -h -o %j)
n=0
for f in "${files[@]}"; do
  stem=$(basename "${f%.*}")
  if [ -f "out/$stem/$OUT_SUBDIR/whisper_output/$stem.TextGrid" ]; then
    echo "already done:   $stem"
  elif grep -qxF "vxh-$stem" <<<"$queued"; then
    echo "already queued: $stem"
  else
    sbatch --account="$ACCOUNT" --job-name="vxh-$stem" \
      --output="logs/%x_%j.out" --error="logs/%x_%j.err" lib/whisper_tg.slurm "$f" >/dev/null
    echo "started:        $stem"
    n=$((n + 1))
  fi
done
echo
echo "$n new job(s) started (account $ACCOUNT). Check progress with: bash status.sh"
