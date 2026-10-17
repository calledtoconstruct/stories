"""Word timing for one spoken phrase.

Kokoro reports when each token starts. Playback emits "WORD <id>" at the
moment that word is heard.
"""

import wave


def norm(text):
    return "".join(ch.lower() for ch in (text or "") if ch.isalnum() or ch in "'’")


def align(words, tokens):
    usable = []
    for token in tokens:
        if norm(getattr(token, "text", "")):
            usable.append(token)
    marks = []
    index = 0
    last_start = 0
    for word in words:
        target = norm(word.get("text", ""))
        if index >= len(usable):
            marks.append({"id": word.get("id", ""), "start_ms": last_start})
            continue
        start = usable[index].start_ts
        if start is None:
            start_ms = last_start
        else:
            start_ms = int(round(float(start) * 1000))
        if not target:
            marks.append({"id": word.get("id", ""), "start_ms": start_ms})
            last_start = start_ms
            continue
        acc = ""
        while index < len(usable) and len(acc) < len(target):
            acc += norm(usable[index].text)
            index += 1
            if acc == target:
                break
        marks.append({"id": word.get("id", ""), "start_ms": start_ms})
        last_start = start_ms
    return marks


def retarget(marks, words):
    """Keep saved word times and use the ids of the phrase being played."""
    if marks is None or words is None or len(marks) != len(words):
        return None
    return [
        {"id": word.get("id", ""), "start_ms": int(mark.get("start_ms", 0))}
        for mark, word in zip(marks, words)
    ]


def segments(words):
    """Split a phrase at sentence punctuation so the first sentence can play early."""
    groups = []
    current = []
    for word in words or []:
        current.append(word)
        text = (word.get("text") or "").rstrip()
        if text.endswith((".", "!", "?")):
            groups.append(current)
            current = []
    if current:
        groups.append(current)
    return groups


def trim_leading(samples, tokens, sample_rate, pad_ms=50):
    """Drop the silence before the first word and shift the word times with it."""
    starts = []
    for token in tokens:
        start = getattr(token, "start_ts", None)
        if start is not None:
            starts.append(float(start))
    if not starts:
        return samples, tokens
    origin = max(0.0, min(starts) - pad_ms / 1000.0)
    cut = int(origin * sample_rate)
    if cut <= 0 or cut >= len(samples):
        return samples, tokens
    for token in tokens:
        start = getattr(token, "start_ts", None)
        if start is not None:
            token.start_ts = max(0.0, float(start) - origin)
    return samples[cut:], tokens


def proportional(words, duration_ms):
    weights = []
    for word in words:
        weights.append(max(1, len(norm(word.get("text", "")))))
    total = sum(weights) or 1
    cursor = 0.0
    marks = []
    span = max(0, int(duration_ms))
    for word, weight in zip(words, weights):
        marks.append({"id": word.get("id", ""), "start_ms": int(cursor)})
        cursor += span * weight / total
    return marks


def play_pcm(pcm, sample_rate, marks, emit, write, sleep, monotonic, latency_ms=80):
    """Play s16le mono pcm and emit WORD lines as each word is heard.

    write() is paced to the sample clock. latency_ms is the output buffer,
    so the callback waits until the samples should be coming out of the speaker.
    """
    if sample_rate <= 0:
        raise ValueError("sample_rate")
    total = len(pcm) // 2
    ordered = sorted(marks, key=lambda mark: int(mark["start_ms"]))
    next_mark = 0
    chunk_samples = max(1, int(sample_rate * 0.02))
    sent = 0
    origin = monotonic()

    def heard_ms():
        return (monotonic() - origin) * 1000 - latency_ms

    def emit_due():
        nonlocal next_mark
        while next_mark < len(ordered) and ordered[next_mark]["start_ms"] <= heard_ms():
            emit("WORD " + str(ordered[next_mark]["id"]))
            next_mark += 1

    while sent < total or next_mark < len(ordered):
        emit_due()
        if sent >= total:
            if next_mark >= len(ordered):
                break
            wait_s = (ordered[next_mark]["start_ms"] + latency_ms) / 1000.0 - (monotonic() - origin)
            if wait_s > 0:
                sleep(wait_s)
                continue
            emit("WORD " + str(ordered[next_mark]["id"]))
            next_mark += 1
            continue
        delay = origin + (sent / sample_rate) - monotonic()
        if delay > 0:
            sleep(delay)
        emit_due()
        take = min(chunk_samples, total - sent)
        write(pcm[sent * 2:(sent + take) * 2])
        sent += take


def write_wav(path, samples, sample_rate):
    import array
    frames = array.array("h")
    for sample in samples:
        frames.append(int(max(-1.0, min(1.0, float(sample))) * 32767))
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(sample_rate)
        handle.writeframes(frames.tobytes())


def wav_duration_ms(path):
    with wave.open(path, "rb") as handle:
        return int(handle.getnframes() / handle.getframerate() * 1000)


def read_pcm(path):
    with wave.open(path, "rb") as handle:
        if handle.getnchannels() != 1 or handle.getsampwidth() != 2:
            raise RuntimeError("voice wav must be mono s16")
        return handle.readframes(handle.getnframes()), handle.getframerate()
