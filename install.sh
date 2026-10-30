#!/bin/bash
# One-time install. On Torch, inside this folder:  bash install.sh
# Safe to run again: finished steps are skipped.
set -euo pipefail
cd "$(dirname "$0")"
source lib/env.sh
pick_account
echo "SLURM account: $ACCOUNT"

echo "Fetching VoxHumana (pinned version)..."
git submodule update --init

mkdir -p audio out logs textgrid

echo "Starting the install job. This usually takes 5-10 minutes, plus time waiting in the queue."
echo "Please keep this window open until it says INSTALL DONE or INSTALL FAILED."
if out=$(sbatch --parsable --wait --account="$ACCOUNT" \
           --output=logs/install_%j.out --error=logs/install_%j.err lib/setup.slurm); then
  echo "INSTALL DONE. Next: upload audio into the audio folder (README step 4)."
else
  jobid=${out%%;*}
  echo "INSTALL FAILED. The error is at the end of logs/install_${jobid}.err:" >&2
  tail -5 "logs/install_${jobid}.err" >&2 || true
  exit 1
fi
