# Interview audio → Whisper TextGrids on NYU Torch

This turns interview recordings into Praat TextGrids. Each TextGrid has one tier,
`utterances`: [Whisper](https://github.com/openai/whisper) writes down what is said,
and the recording is cut into short stretches at the pauses between words.

Everything happens **in your web browser**, on NYU's Torch computing cluster.
You do not need to install anything on your own computer. You will type (or paste)
a handful of short commands; each one is given below exactly as you should type it.

| Setting | Value |
|---|---|
| Model | Whisper `turbo` (`large-v3-turbo`) |
| Language | detected automatically per file; Spanish/English mixing is kept as spoken (not translated) |
| Interval boundaries | a new interval starts at every pause of 0.3 s or more; intervals longer than 15 s are split at their longest pause |

> **Privacy.** These are research-participant recordings. Keep audio and TextGrids
> on Torch and on your own computer only. Do not upload them anywhere else. When you
> have downloaded your TextGrids, delete the audio from Torch (step 8).

---

## Step 1. Things you need first

- **An NYU HPC account** with access to Torch. If you don't have one, ask your lab
  or see NYU's HPC account page.
- **NYU VPN**, if you are off campus. The Torch website does not open without it.
- A web browser (Chrome, Firefox, Safari or Edge).

## Step 2. Open Torch in your browser

1. Go to **https://ood.torch.hpc.nyu.edu** and sign in with your NYU account.
2. In the menu bar at the top, click **Clusters** → **Torch Shell Access**.
   A new tab opens with a black window. This is the **terminal**: you type a
   command, press **Enter**, and Torch runs it.

**How to paste into the terminal:** copy a command from this page as usual. Then
right-click inside the black window and choose **Paste**. If that doesn't work, try
**Ctrl+Shift+V** (Windows/Linux) or **Cmd+V** (Mac). Then press **Enter**.

## Step 3. Install (only once)

In the terminal, paste these two commands, one at a time, pressing **Enter** after each:

```bash
git clone https://github.com/craaaa/whisper-textgrid.git /scratch/$USER/whisper-textgrid
```

```bash
bash /scratch/$USER/whisper-textgrid/install.sh
```

The second command sets everything up: the speech-recognition model, Python, and
the audio tools. It takes about 5–10 minutes, sometimes longer if Torch is busy.
**Keep the tab open** until you see one of these:

- `INSTALL DONE`: go to step 4.
- `You have more than one SLURM account`: you have several billing accounts on
  Torch, and the program needs to know which one to use. See
  [Choosing an account](#choosing-an-account) below, then run the second command again.
- `INSTALL FAILED`: see [If something goes wrong](#if-something-goes-wrong).

If the tab closes by accident, the install keeps going on Torch. Open a new
terminal and run the second command again. This is always safe.

(`$USER` in these commands is filled in with your NetID automatically. Type it
exactly as shown.)

**From now on, every time you open a new terminal**, first go to the project folder:

```bash
cd /scratch/$USER/whisper-textgrid
```

## Step 4. Upload your audio

1. Go back to the **https://ood.torch.hpc.nyu.edu** tab.
2. Click **Files** → **Home Directory**.
3. Click **Change directory** (or **Go To…**, near the top), type
   `/scratch/YOUR_NETID/whisper-textgrid/audio` with your own NetID, and click **OK**.
4. Click **Upload**, and choose your audio files (`.wav`, `.flac`, `.mp3` or `.m4a`).
   Wait until every upload has finished.

Interview files are often very large (0.5–1 GB each). If the browser upload fails or
is very slow, use NYU's Globus service instead (endpoint `nyu#torch`), or ask for help.

## Step 5. Start processing

In the terminal:

```bash
cd /scratch/$USER/whisper-textgrid
```

```bash
bash run.sh
```

This starts one job for each audio file that hasn't been processed yet. You will see
`started: <file name>` for each one. It is safe to run again: files that are already
done or already started are skipped.

A 2-hour interview takes about 5 minutes once it starts. Files sometimes wait in a
queue first, from a few minutes to a few hours, depending on how busy Torch is. You
can close the browser while they run.

## Step 6. Check progress

```bash
bash status.sh
```

Each file is shown as one of:

| Status | Meaning |
|---|---|
| `WAITING for a GPU` | in the queue; check again later |
| `RUNNING` | being processed now |
| `DONE` | finished; its TextGrid has been put in the `textgrid` folder |
| `FAILED` | something went wrong; see [If something goes wrong](#if-something-goes-wrong) |
| `NOT STARTED` | run `bash run.sh` |

Run `bash status.sh` again whenever you want an update. (Remember the `cd` line
from step 2 if you opened a new terminal.)

## Step 7. Download your TextGrids

1. In the **Files** page, go to `/scratch/YOUR_NETID/whisper-textgrid/textgrid`
   (as in step 4).
2. Select the files (or tick the box to select all) and click **Download**.

Open them in Praat together with the original audio.

## Step 8. Delete the audio from Torch

Once your TextGrids are safely on your computer:

```bash
bash cleanup.sh
```

It shows what it will delete and asks you to type `YES`. It deletes the audio,
the TextGrids and the intermediate results in this folder. The installation stays,
so next time you can start straight at step 4.

**Note:** Torch automatically deletes files in `/scratch` that haven't been used
for 60 days. If the installation disappears, delete the `whisper-textgrid` folder in
the Files page and start again at step 3.

---

## Choosing an account

Torch charges computing time to a **SLURM account**, usually your lab's. If you
only have one, nothing needs doing. If you have several, the program lists them
and stops. Pick the one your lab told you to use, then:

1. In the **Files** page, go to `/scratch/YOUR_NETID/whisper-textgrid`.
2. Click the **⋮** menu next to `config.sh` → **Edit**.
3. Put the account name between the quotes, for example `ACCOUNT="my_lab_account"`.
4. Click **Save**, and go back to where you were.

## If something goes wrong

| What you see | What to do |
|---|---|
| The Torch website doesn't load | Connect to the NYU VPN; or clear the site's cookies and reload |
| `No such file or directory` after a `cd` or `bash` command | Install first (step 3), or check you typed the command exactly |
| `Not installed yet` | Run step 3 |
| `No audio files in the audio folder` | Upload into `whisper-textgrid/audio` (step 4), not somewhere else |
| `Invalid account` | The account in `config.sh` is wrong. See [Choosing an account](#choosing-an-account) |
| `WAITING for a GPU` for many hours | Torch is busy, or your lab has used up its GPU share. Waiting is fine. If it lasts a day, ask your lab |
| `FAILED` | Open the `logs` folder in the Files page. Look at the end of the `.err` file that has the recording's name in it. Then run `bash run.sh` again to retry it. If it fails again, send that `.err` file to whoever maintains this project |
| `INSTALL FAILED` | Run step 3's second command again. If it fails again, send the newest `logs/install_*.err` file to the maintainer |

Help with Torch itself: hpc@nyu.edu.

---

## For maintainers

**Layout**

| Path | Role |
|---|---|
| `install.sh`, `run.sh`, `status.sh`, `cleanup.sh` | the four user commands |
| `config.sh` | optional `ACCOUNT`; empty = automatic if the user has exactly one account |
| `lib/env.sh` | shared paths: caches, uv and ffmpeg in `/scratch/$USER`, Python env in `.venv/` |
| `lib/setup.slurm` | install job (CPU): uv, `uv sync --frozen`, ffmpeg (conda-forge), Whisper weights |
| `lib/whisper_tg.slurm` | per-file GPU job, named `vxh-<file name>`; logs in `logs/` |
| `lib/whisper_tg.py` | Whisper with word timestamps → pause-based intervals → TextGrid |
| `VoxHumana/` | git submodule: [JoeyStanley/VoxHumana](https://github.com/JoeyStanley/VoxHumana), pinned at `eb39e0e7` (v0.18.3) |

The transcription and TextGrid functions come from VoxHumana and are used
unmodified. VoxHumana's own `main.py` is not used, because it always runs MFA,
new-fave and Praat as well. `install.sh` runs `git submodule update --init`, so
users don't need `--recurse-submodules`.

Results go to `out/<name>/pauses_turbo_auto_0.3p_15.0s/whisper_output/`: the
`.TextGrid` and `<name>_words.json` (raw Whisper output with word timestamps).
`status.sh` copies finished TextGrids to `textgrid/`. `.gitignore` excludes
`audio/`, `textgrid/`, `out/`, `logs/` and `.venv/`, so participant data cannot be
committed by accident.

**Changing settings.** Other models or pause settings can be run by hand, e.g.
`MODEL=small LANG_CODE=en sbatch --account=<acct> lib/whisper_tg.slurm audio/<file> --min-pause 0.5`.
They write to a different `out/` subfolder, which `status.sh` does not track.

**Updating VoxHumana:** `git -C VoxHumana checkout <commit>`, commit the submodule
change, and have users `git pull && git submodule update` and rerun `install.sh`.

Runtime: about 1 minute of startup plus ~1.5 s per minute of audio on one GPU
(turbo). Each job has a 30-minute limit, enough for ~19 hours of audio.

**Reproducibility.** Whisper's output is not exactly reproducible. Running the same
file twice, with identical packages, can give slightly different segments and
interval boundaries, both across GPU types and on the same type. In a test on a
short file, three runs gave 21, 22 and 21 intervals. Each job log records the GPU
used (`GPU: ...`). If exact reproducibility matters, keep the TextGrids you
produced rather than regenerating them.
