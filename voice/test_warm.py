import unittest

import speak


class WarmTests(unittest.TestCase):
    def test_page_is_ready_before_later_phrases(self):
        log = []

        def fetch_group(voice, group, speed):
            log.append(speak.phrase_text(group))

        speak.warm({
            "voice": "af_heart",
            "epoch": 4,
            "page_phrases": 1,
            "phrases": [
                [
                    {"id": "w1", "text": "Today"},
                    {"id": "w2", "text": "I"},
                    {"id": "w3", "text": "walk."},
                    {"id": "w4", "text": "Then"},
                    {"id": "w5", "text": "home."},
                ],
                [{"id": "w6", "text": "Later."}],
            ],
        }, fetch_group=fetch_group, emit=lambda line: log.append(line))
        self.assertEqual(log, [
            "Today I walk.",
            "Then home.",
            "PAGE 4",
            "Later.",
        ])


if __name__ == "__main__":
    unittest.main()
