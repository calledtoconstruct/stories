"""Resident Kokoro voice. One process keeps the model loaded.

Each request is one JSON line:
{"voice":"af_heart","words":[{"id":"w1","text":"Once"}]}

The response is one JSON line with a wav path and word start times.
Word callbacks are printed by voice/speak.py while that wav plays.
"""

import hashlib
import json
import os
import socket
import sys

from cue import align, proportional, retarget, trim_leading, write_wav

ROOT = os.path.dirname(os.path.abspath(__file__))
MODEL = "hexgrad/Kokoro-82M"
SAMPLE_RATE = 24000
CACHE = os.path.join(ROOT, "cache")
# A little slower than Kokoro's natural pace. STORIES_SPEED overrides it.
DEFAULT_SPEED = float(os.environ.get("STORIES_SPEED", "0.9"))


def sock_path():
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return os.path.join(runtime, "stories-voice.sock")


def lang_of(voice):
    if voice.startswith("b"):
        return "b"
    return "a"


class Speaker:
    def __init__(self):
        import torch
        from kokoro import KModel, KPipeline

        torch.set_num_threads(2)
        self.model = KModel(repo_id=MODEL).to("cpu").eval()
        self.pipelines = {}
        self.KPipeline = KPipeline

    def pipeline(self, voice):
        lang = lang_of(voice)
        if lang not in self.pipelines:
            self.pipelines[lang] = self.KPipeline(lang_code=lang, model=self.model, repo_id=MODEL)
        return self.pipelines[lang]

    def synthesize(self, voice, text, speed):
        pieces = []
        tokens = []
        offset = 0.0
        for result in self.pipeline(voice)(text, voice=voice, speed=speed):
            audio = result.audio
            if audio is None:
                continue
            samples = audio.detach().cpu().numpy().astype("float32").reshape(-1)
            pieces.append(samples)
            for token in result.tokens or []:
                start = getattr(token, "start_ts", None)
                if start is None:
                    continue
                tokens.append(type("Tok", (), {
                    "text": getattr(token, "text", "") or "",
                    "start_ts": float(start) + offset,
                })())
            offset += len(samples) / SAMPLE_RATE
        if not pieces:
            raise RuntimeError("Kokoro returned no audio")
        import numpy as np
        return np.concatenate(pieces), tokens


def speed_of(request):
    if request.get("speed") is not None:
        return float(request["speed"])
    return DEFAULT_SPEED


def cache_paths(voice, speed, text):
    key = f"v1\n{voice}\n{speed:.2f}\n{text}"
    digest = hashlib.sha256(key.encode()).hexdigest()[:24]
    base = os.path.join(CACHE, digest)
    return base + ".wav", base + ".json"


def load_cached(voice, speed, text):
    wav_path, meta_path = cache_paths(voice, speed, text)
    if not os.path.exists(wav_path) or not os.path.exists(meta_path):
        return None
    with open(meta_path, encoding="utf-8") as handle:
        marks = json.load(handle)
    return {"ok": True, "wav": wav_path, "sample_rate": SAMPLE_RATE, "marks": marks, "keep": True}


def store_cached(voice, speed, text, samples, marks):
    os.makedirs(CACHE, exist_ok=True)
    wav_path, meta_path = cache_paths(voice, speed, text)
    write_wav(wav_path, samples, SAMPLE_RATE)
    with open(meta_path, "w", encoding="utf-8") as handle:
        json.dump(marks, handle)
    return wav_path


def answer(speaker, request):
    voice = request.get("voice") or "af_heart"
    words = request.get("words") or []
    text = " ".join(word.get("text", "") for word in words).strip()
    if not text:
        raise RuntimeError("nothing to say")
    speed = speed_of(request)
    cached = load_cached(voice, speed, text)
    if cached:
        marks = retarget(cached["marks"], words)
        if marks is not None:
            cached["marks"] = marks
            if os.environ.get("STORIES_VOICE_DEBUG"):
                print("cache", text, file=sys.stderr)
            return cached
    samples, tokens = speaker.synthesize(voice, text, speed)
    samples, tokens = trim_leading(samples, tokens, SAMPLE_RATE)
    duration_ms = int(len(samples) / SAMPLE_RATE * 1000)
    marks = align(words, tokens) if tokens else proportional(words, duration_ms)
    path = store_cached(voice, speed, text, samples, marks)
    if os.environ.get("STORIES_VOICE_DEBUG"):
        print("tokens", [(token.text, token.start_ts) for token in tokens], file=sys.stderr)
        print("marks", marks, file=sys.stderr)
    return {"ok": True, "wav": path, "sample_rate": SAMPLE_RATE, "marks": marks, "keep": True}


def handle(speaker, conn):
    data = b""
    while b"\n" not in data:
        chunk = conn.recv(65536)
        if not chunk:
            return
        data += chunk
        if len(data) > 2000000:
            return
    request = json.loads(data.split(b"\n", 1)[0].decode())
    try:
        payload = answer(speaker, request)
    except Exception as exc:
        payload = {"ok": False, "error": str(exc)}
    try:
        conn.sendall((json.dumps(payload) + "\n").encode())
    except OSError:
        return


def serve(speaker):
    path = sock_path()
    if os.path.exists(path):
        os.remove(path)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    os.chmod(path, 0o600)
    server.listen(4)
    print("ready", path, file=sys.stderr, flush=True)
    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            continue
        try:
            handle(speaker, conn)
        except Exception as exc:
            print("client", exc, file=sys.stderr, flush=True)
        finally:
            try:
                conn.close()
            except OSError:
                pass


def main():
    os.environ.setdefault("HF_HOME", os.path.join(ROOT, "models"))
    os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")
    speaker = Speaker()
    serve(speaker)


if __name__ == "__main__":
    main()
