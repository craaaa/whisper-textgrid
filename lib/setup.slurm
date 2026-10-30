#!/bin/bash
#SBATCH --job-name=vxh-install
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
# Install job on a compute node: uv, Python env, ffmpeg, Whisper weights.
# Submitted by install.sh (sets --account and log paths).
set -euo pipefail
source "$SLURM_SUBMIT_DIR/lib/env.sh"

module purge

echo "== host: $(hostname)"
curl -sSfI https://pypi.org/simple/ >/dev/null && echo "internet: yes" || echo "internet: NO"

echo "== uv"
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$ROOT/.local/bin" sh
fi
uv --version

echo "== uv sync"
[ -f "$PKG/VoxHumana/pyproject.toml" ] || { echo "VoxHumana submodule missing; run install.sh" >&2; exit 1; }
cd "$PKG/VoxHumana"
uv sync --frozen

echo "== ffmpeg (conda-forge)"
if [ ! -x "$ROOT/envs/ffmpeg/bin/ffmpeg" ]; then
  module load anaconda3/2026.07
  conda create -y -p "$ROOT/envs/ffmpeg" -c conda-forge --override-channels ffmpeg
  module unload anaconda3/2026.07
fi
ffmpeg -version | head -1

echo "== whisper weights"
for m in ${MODELS:-turbo}; do
  uv run --frozen python -c "import whisper; whisper.load_model('$m', device='cpu'); print('ok: $m')"
done

echo "== import check"
uv run --frozen python -c "import torch, whisper, tgt, librosa; print('torch', torch.__version__, 'cuda build', torch.version.cuda)"
echo "SETUP DONE"
