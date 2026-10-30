#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
# Locked-in setup: turbo, auto language + code-switch prompt, pause-based intervals (0.3 s, 15 s cap).
# Submitted by run.sh (sets --account, --job-name and log paths), one job per audio file.
# Overrides (output goes to a different out/ subfolder, which status.sh does not track):
#   MODEL=small LANG_CODE=en sbatch ... lib/whisper_tg.slurm audio/<file> --min-pause 0.5
source "$SLURM_SUBMIT_DIR/lib/env.sh"

module purge

cd "$PKG"
uv run --frozen --project VoxHumana python lib/whisper_tg.py "$1" out \
  --model "${MODEL:-turbo}" --language "${LANG_CODE:-auto}" --pauses "${@:2}"
