import unittest

from cue import align, play_pcm, proportional, retarget, segments, trim_leading


class Tok:
    def __init__(self, text, start_ts):
        self.text = text
        self.start_ts = start_ts


class CueTests(unittest.TestCase):
    def test_align_words_to_kokoro_tokens(self):
        words = [
            {"id": "w1", "text": "A"},
            {"id": "w2", "text": "little"},
            {"id": "w3", "text": "turtle."},
        ]
        tokens = [
            Tok("A", 0.0),
            Tok("little", 0.21),
            Tok("turtle", 0.48),
            Tok(".", 0.91),
        ]
        marks = align(words, tokens)
        self.assertEqual(
            marks,
            [
                {"id": "w1", "start_ms": 0},
                {"id": "w2", "start_ms": 210},
                {"id": "w3", "start_ms": 480},
            ],
        )

    def test_proportional_when_durations_are_missing(self):
        words = [
            {"id": "w1", "text": "A"},
            {"id": "w2", "text": "little"},
        ]
        marks = proportional(words, 1000)
        self.assertEqual(marks[0], {"id": "w1", "start_ms": 0})
        self.assertGreater(marks[1]["start_ms"], 0)
        self.assertLess(marks[1]["start_ms"], 1000)

    def test_word_callback_tracks_playback_cursor(self):
        pcm = b"\x00\x00" * 24000
        marks = [{"id": "w1", "start_ms": 0}, {"id": "w2", "start_ms": 500}]
        clock = {"t": 0.0}
        written = {"n": 0}
        heard = {}

        def monotonic():
            return clock["t"]

        def sleep(seconds):
            clock["t"] += seconds

        def write(chunk):
            written["n"] += len(chunk)

        def emit(line):
            heard[line] = written["n"]

        play_pcm(pcm, 24000, marks, emit, write, sleep, monotonic, latency_ms=0)
        self.assertEqual(heard["WORD w1"], 0)
        self.assertEqual(heard["WORD w2"], 24000)

    def test_trim_leading_silence_keeps_word_times(self):
        samples = [0.0] * 24000
        tokens = [Tok("A", 0.35), Tok("little", 0.5)]
        trimmed, tokens = trim_leading(samples, tokens, 24000, pad_ms=50)
        self.assertEqual(len(trimmed), 16800)
        self.assertAlmostEqual(tokens[0].start_ts, 0.05, places=3)
        self.assertAlmostEqual(tokens[1].start_ts, 0.20, places=3)

    def test_saved_clip_uses_the_ids_being_played(self):
        saved = [{"id": "w1", "start_ms": 50}, {"id": "w2", "start_ms": 180}]
        played = retarget(saved, [{"id": "w7", "text": "A"}, {"id": "w8", "text": "cat."}])
        self.assertEqual(played, [{"id": "w7", "start_ms": 50}, {"id": "w8", "start_ms": 180}])
        self.assertIsNone(retarget(saved, [{"id": "w7", "text": "A"}]))

    def test_sentences_play_separately(self):
        words = [
            {"id": "w1", "text": "Today"},
            {"id": "w2", "text": "I"},
            {"id": "w3", "text": "walk."},
            {"id": "w4", "text": "Then"},
            {"id": "w5", "text": "home."},
        ]
        parts = segments(words)
        self.assertEqual(len(parts), 2)
        self.assertEqual([word["id"] for word in parts[0]], ["w1", "w2", "w3"])
        self.assertEqual([word["id"] for word in parts[1]], ["w4", "w5"])

    def test_latency_delays_the_callback(self):
        pcm = b"\x00\x00" * 24000
        marks = [{"id": "w1", "start_ms": 0}]
        clock = {"t": 0.0}
        when = {}

        def monotonic():
            return clock["t"]

        def sleep(seconds):
            clock["t"] += seconds

        def emit(line):
            when[line] = clock["t"]

        play_pcm(pcm, 24000, marks, emit, lambda chunk: None, sleep, monotonic, latency_ms=80)
        self.assertGreaterEqual(when["WORD w1"], 0.08)


if __name__ == "__main__":
    unittest.main()
