# Shared settings, sourced by every script. Nothing to edit here.

PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # this repo's folder
ROOT="/scratch/$USER"                                      # caches, uv, ffmpeg (outside $HOME: inode limit)

export UV_CACHE_DIR=$ROOT/.cache/uv
export UV_PYTHON_INSTALL_DIR=$ROOT/.local/share/uv/python
export UV_PROJECT_ENVIRONMENT=$PKG/.venv    # keep the env out of the VoxHumana submodule
export XDG_CACHE_HOME=$ROOT/.cache          # whisper weights -> $XDG_CACHE_HOME/whisper
export TORCH_HOME=$ROOT/.cache/torch
export PYTHONNOUSERSITE=True
export PATH=$ROOT/envs/ffmpeg/bin:$ROOT/.local/bin:$PATH

OUT_SUBDIR=pauses_turbo_auto_0.3p_15.0s     # whisper_tg.py's output folder for the locked-in settings

# Sets ACCOUNT from config.sh, or picks the user's only SLURM account (ignoring the generic "users").
pick_account() {
  source "$PKG/config.sh"
  [ -n "$ACCOUNT" ] && return 0
  local accts
  accts=$(sacctmgr -nP list assoc where user="$USER" format=account | sort -u | grep -vx users || true)
  if [ -z "$accts" ]; then
    echo "No SLURM account found for $USER. Ask your lab or hpc@nyu.edu for one." >&2
    exit 1
  elif [ "$(wc -l <<<"$accts")" -gt 1 ]; then
    echo "You have more than one SLURM account:" >&2
    sed 's/^/    /' <<<"$accts" >&2
    echo "Open config.sh, put one of them between the quotes (ACCOUNT=\"...\"), save, and run this again." >&2
    exit 1
  fi
  ACCOUNT=$accts
}
