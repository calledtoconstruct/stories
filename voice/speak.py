"""Speak one phrase and print a line as each word starts.

Stdout lines are `WORD <id>`, flushed when that word is heard.
SIGTERM stops playback.
"""

import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time

from cue import play_pcm, proportional, read_pcm, retarget, segments, wav_duration_ms
from engine import DEFAULT_SPEED, load_cached

ROOT = os.path.dirname(os.path.abspath(__file__))


def sock_path():
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return os.path.join(runtime, "stories-voice.sock")


def venv_python():
    return os.path.join(ROOT, ".venv", "bin", "python")


def spawn_daemon():
    python = venv_python()
    if not os.path.exists(python):
        raise RuntimeError("missing voice environment")
    log_path = os.path.join(ROOT, "daemon.log")
    log = open(log_path, "ab", buffering=0)
    env = os.environ.copy()
    env["HF_HOME"] = os.path.join(ROOT, "models")
    env["HF_HUB_DISABLE_TELEMETRY"] = "1"
    return subprocess.Popen(
        [python, os.path.join(ROOT, "engine.py")],
        stdout=log,
        stderr=log,
        start_new_session=True,
        env=env,
    )


def connect():
    path = sock_path()
    daemon = None
    deadline = time.monotonic() + 300
    while time.monotonic() < deadline:
        try:
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(path)
            return client
        except OSError:
            if daemon is None:
                daemon = spawn_daemon()
            elif daemon.poll() is not None:
                raise RuntimeError("voice daemon exited")
            time.sleep(0.2)
    raise RuntimeError("voice daemon did not start")


def ask(request):
    client = connect()
    try:
        client.sendall((json.dumps(request) + "\n").encode())
        data = b""
        while b"\n" not in data:
            chunk = client.recv(1 << 20)
            if not chunk:
                break
            data += chunk
    finally:
        client.close()
    if not data:
        raise RuntimeError("empty voice response")
    return json.loads(data.split(b"\n", 1)[0].decode())


def play_file(path, marks, keep=False):
    pcm, rate = read_pcm(path)
    latency = int(os.environ.get("STORIES_LATENCY_MS", "80"))
    player = subprocess.Popen(
        [
            "pw-cat", "--playback", "--raw",
            "--format", "s16",
            "--rate", str(rate),
            "--channels", "1",
            "--channel-map", "MONO",
            "--latency", "20ms",
            "-",
        ],
        stdin=subprocess.PIPE,
    )

    def stop(_signum, _frame):
        if player.poll() is None:
            player.terminate()
        if not keep:
            try:
                os.remove(path)
            except OSError:
                pass
        os._exit(0)

    signal.signal(signal.SIGTERM, stop)
    try:
        def write(chunk):
            player.stdin.write(chunk)
            player.stdin.flush()

        def emit(line):
            print(line, flush=True)

        play_pcm(pcm, rate, marks, emit, write, time.sleep, time.monotonic, latency)
    finally:
        try:
            player.stdin.close()
        except Exception:
            pass
        try:
            player.wait(timeout=5)
        except subprocess.TimeoutExpired:
            player.terminate()


def espeak_fallback(request):
    words = request.get("words") or []
    text = " ".join(word.get("text", "") for word in words).strip()
    if not text:
        return
    handle, path = tempfile.mkstemp(prefix="stories-espeak-", suffix=".wav")
    os.close(handle)
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = os.path.join(ROOT, "lib") + (
        ":" + env["LD_LIBRARY_PATH"] if env.get("LD_LIBRARY_PATH") else ""
    )
    env["ESPEAK_DATA_PATH"] = os.path.join(ROOT, "share")
    subprocess.check_call(
        [os.path.join(ROOT, "bin", "espeak-ng"), "-s", "130", "-w", path, text],
        env=env,
    )
    marks = proportional(words, wav_duration_ms(path))
    try:
        play_file(path, marks)
    finally:
        if os.path.exists(path):
            os.remove(path)


def phrase_text(words):
    return " ".join(word.get("text", "") for word in words).strip()


def lookup(voice, words, speed):
    """Play a clip that was built earlier, without waiting on the voice process."""
    text = phrase_text(words)
    if not text:
        return None
    pace = DEFAULT_SPEED if speed is None else float(speed)
    cached = load_cached(voice, pace, text)
    if not cached:
        return None
    marks = retarget(cached.get("marks"), words)
    if marks is None:
        return None
    cached["marks"] = marks
    return cached


def fetch(voice, words, speed):
    cached = lookup(voice, words, speed)
    if cached:
        return cached
    body = {"voice": voice, "words": words}
    if speed is not None:
        body["speed"] = speed
    result = ask(body)
    if not result.get("ok"):
        raise RuntimeError(result.get("error") or "voice failed")
    return result


def speak_phrases(request):
    groups = segments(request.get("words") or [])
    if not groups:
        return
    voice = request.get("voice") or "af_heart"
    speed = request.get("speed")
    pending = fetch(voice, groups[0], speed)
    for index in range(len(groups)):
        result = pending
        worker = None
        box = {}
        if index + 1 < len(groups):
            nxt = groups[index + 1]

            def run(words=nxt):
                try:
                    box["result"] = fetch(voice, words, speed)
                except Exception as exc:
                    box["error"] = exc

            worker = threading.Thread(target=run)
            worker.start()
        play_file(result.get("wav") or "", result.get("marks") or [], keep=bool(result.get("keep")))
        if worker:
            worker.join()
            if box.get("error"):
                raise box["error"]
            pending = box["result"]


def warm(request, fetch_group=None, emit=None):
    """Build the clips a page can play. Sentence pieces match what playback asks for.

    After the current page's phrases are built, emit PAGE so the reader can
    say the page is ready while later pages and single words keep building.
    """
    voice = request.get("voice") or "af_heart"
    speed = request.get("speed")
    run = fetch_group or fetch
    say = emit or (lambda line: print(line, flush=True))
    try:
        page_phrases = int(request.get("page_phrases") or 0)
    except (TypeError, ValueError):
        page_phrases = 0
    seen = set()
    phrases = request.get("phrases") or []
    for index, words in enumerate(phrases):
        for group in segments(words):
            text = phrase_text(group)
            if not text or text in seen:
                continue
            seen.add(text)
            run(voice, group, speed)
        if page_phrases and index + 1 == page_phrases:
            epoch = request.get("epoch")
            say("PAGE" if epoch is None else "PAGE " + str(epoch))


def main():
    raw = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    request = json.loads(raw)
    try:
        if not os.path.exists(venv_python()):
            raise RuntimeError("Kokoro is not installed")
        if request.get("warm"):
            warm(request)
            return
        speak_phrases(request)
    except Exception as exc:
        print(exc, file=sys.stderr)
        if not request.get("warm"):
            espeak_fallback(request)


if __name__ == "__main__":
    main()
