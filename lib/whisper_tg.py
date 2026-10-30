"""Whisper -> utterance TextGrid using VoxHumana's pipeline functions (repo unmodified).

Default: VoxHumana's transcribe() -> one interval per Whisper segment.
With --pauses: rerun Whisper with word timestamps, cut intervals at pauses between
words (>= --min-pause s), then split any interval still longer than --max-sec at
its largest internal gap. A code-switching prompt (--prompt) is carried into every
30 s window so Spanish/English stay in the language spoken.
"""
import argparse
import json
import statistics
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent / "VoxHumana"  # git submodule
sys.path.insert(0, str(REPO))

import torch  # noqa: E402
import whisper  # noqa: E402
from pipeline.transcribe_with_whisper import transcribe  # noqa: E402
from pipeline.convert_whisper_to_textgrid import convert_whisper_to_textgrid  # noqa: E402

# Generic English/Spanish code-switched example; biases Whisper toward
# transcribing each language as spoken instead of translating.
DEFAULT_PROMPT = (
    "Bueno, so we were at my abuela's house, y ella me dijo, you know, que no se puede. "
    "And I was like, ¿en serio? Pero anyway, I went back home."
)


def split_longest_gap(words, max_sec):
    """Recursively split a word list at its largest gap until each part <= max_sec."""
    if len(words) < 2 or words[-1]["end"] - words[0]["start"] <= max_sec:
        return [words]
    # Largest gap (to 10 ms); ties go to the gap nearest the middle, avoiding tiny fragments.
    mid = (len(words) - 2) / 2
    i = max(range(len(words) - 1),
            key=lambda j: (round(words[j + 1]["start"] - words[j]["end"], 2), -abs(j - mid))) + 1
    return split_longest_gap(words[:i], max_sec) + split_longest_gap(words[i:], max_sec)


def chunk_at_pauses(result, min_pause, max_sec):
    """Group all words into intervals at pauses; returns a result-like dict."""
    words = [w for seg in result["segments"] for w in seg.get("words", [])]
    groups, cur = [], []
    for w in words:
        if cur and w["start"] - cur[-1]["end"] >= min_pause:
            groups.append(cur)
            cur = []
        cur.append(w)
    if cur:
        groups.append(cur)
    chunks = [part for g in groups for part in split_longest_gap(g, max_sec)]

    segments = []
    prev_end = 0.0
    for c in chunks:
        # Word times can overlap slightly across chunks; tgt rejects overlapping intervals.
        start = max(c[0]["start"], prev_end)
        end = c[-1]["end"]
        if end <= start:
            continue
        segments.append({"start": start, "end": end, "text": "".join(w["word"] for w in c).strip()})
        prev_end = end
    return {"segments": segments}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("audio_path")
    p.add_argument("out_dir")
    p.add_argument("--model", default="small")
    p.add_argument("--language", default="en", help="Whisper language code, or 'auto'")
    p.add_argument("--pauses", action="store_true", help="cut intervals at pauses (see module doc)")
    p.add_argument("--min-pause", type=float, default=0.3)
    p.add_argument("--max-sec", type=float, default=15.0)
    p.add_argument("--prompt", default=DEFAULT_PROMPT, help="initial prompt ('' to disable)")
    args = p.parse_args()
    language = None if args.language == "auto" else args.language

    print(f"torch {torch.__version__}, cuda available: {torch.cuda.is_available()}", flush=True)
    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}", flush=True)

    stem = Path(args.audio_path).stem
    job_dir = Path(args.out_dir) / stem

    if not args.pauses:
        result = transcribe(args.audio_path, job_dir, {"model": args.model, "language": language})
    else:
        job_dir = job_dir / f"pauses_{args.model}_{args.language}_{args.min_pause}p_{args.max_sec}s"
        model = whisper.load_model(args.model)
        full = model.transcribe(
            whisper.load_audio(args.audio_path),
            language=language,
            word_timestamps=True,
            initial_prompt=args.prompt or None,
            carry_initial_prompt=bool(args.prompt),
        )
        print(f"language used: {full['language']}", flush=True)
        (job_dir / "whisper_output").mkdir(parents=True, exist_ok=True)
        with open(job_dir / "whisper_output" / f"{stem}_words.json", "w") as f:
            json.dump(full, f, indent=2)
        result = chunk_at_pauses(full, args.min_pause, args.max_sec)
        durs = [s["end"] - s["start"] for s in result["segments"]]
        print(f"{len(full['segments'])} whisper segments -> {len(durs)} intervals; "
              f"median {statistics.median(durs):.2f}s, max {max(durs):.2f}s, "
              f"{sum(d > args.max_sec for d in durs)} over {args.max_sec}s (single long words)",
              flush=True)

    tg = convert_whisper_to_textgrid(result, args.audio_path, job_dir)
    print(f"{len(result['segments'])} intervals -> {tg}", flush=True)


if __name__ == "__main__":
    main()
