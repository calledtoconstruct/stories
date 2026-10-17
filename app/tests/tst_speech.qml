import QtQuick
import QtTest
import "../Speech.js" as Speech

TestCase {
    function test_pageWords() {
        var page = {
            blocks: [
                { type: "image", src: "a.png", alt: "A little turtle in a garden" },
                {
                    type: "text",
                    content: [{
                        lines: [{
                            words: [
                                { text: "Once" },
                                { text: "upon" },
                                { text: "a" },
                                { text: "time" }
                            ]
                        }]
                    }]
                }
            ]
        }
        compare(Speech.pageWords(page).join(" "), "Once upon a time")
        compare(Speech.hotspotText({ speak_text: "turtle" }), "turtle")
        compare(Speech.hotspotText({}), "")
        var model = Speech.reading(page)
        compare(model.words.length, 4)
        compare(model.paragraphs.length, 1)
        compare(model.paragraphs[0].lines[0].text, "Once upon a time")
        compare(model.pictures.length, 1)
        compare(model.pictures[0].speak, "A little turtle in a garden")
        var repeated = {
            blocks: [
                { type: "text", content: [{ lines: [{ words: [{ id: "w1", text: "One" }, { id: "w2", text: "two" }] }] }] },
                { type: "text", content: [{ lines: [{ words: [{ id: "w1", text: "Three" }, { id: "w2", text: "four" }] }] }] }
            ]
        }
        var read = Speech.reading(repeated)
        compare(read.words.length, 4)
        compare(read.words[0].id === read.words[2].id, false)
        compare(read.paragraphs[0].lines[0].words[0].id, read.words[0].id)
        compare(read.paragraphs[1].lines[0].words[0].id, read.words[2].id)
    }

    function test_phrase() {
        var tokens = [
            { id: "w1", text: "Once" },
            { id: "w2", text: "upon" },
            { id: "w3", text: "a" },
            { id: "w4", text: "time" }
        ]
        compare(Speech.phrase(tokens), "Once upon a time")
        compare(Speech.voiceName({ voice: "bf_emma" }), "bf_emma")
        compare(Speech.voiceName({}), "af_heart")
        compare(Speech.voiceName(null), "af_heart")
        var payload = JSON.parse(Speech.speechPayload("bf_emma", tokens))
        compare(payload.voice, "bf_emma")
        compare(payload.words.length, 4)
        compare(payload.words[0].id, "w1")
        compare(payload.words[3].text, "time")
        var found = Speech.wordById(tokens, "w3")
        compare(found.text, "a")
        compare(Speech.wordById(tokens, "missing"), null)
    }

    function test_warm() {
        var reading = {
            paragraphs: [{
                lines: [{
                    words: [
                        { id: "w1", text: "Once" },
                        { id: "w2", text: "upon." }
                    ]
                }]
            }],
            pictures: [{ speak: "A little turtle." }],
            hotspots: [{ id: "h1", speak: "A pond." }]
        }
        var payload = JSON.parse(Speech.warmPayload("af_heart", reading))
        compare(payload.warm, true)
        compare(payload.voice, "af_heart")
        compare(payload.phrases.length, 5)
        compare(payload.phrases[0].length, 2)
        compare(payload.phrases[0][1].text, "upon.")
        compare(payload.phrases[1].length, 3)
        compare(payload.phrases[1][0].id, "picture:1")
        compare(payload.phrases[1][2].text, "turtle.")
        compare(payload.phrases[2][0].id, "h1:1")
        compare(payload.phrases[2][1].text, "pond.")
        var pictured = Speech.phraseWords("A little turtle.", "picture")
        compare(pictured.length, 3)
        compare(pictured[1].text, "little")
        compare(payload.phrases[3][0].text, "Once")
        compare(payload.phrases[4][0].text, "upon.")
    }

    function test_warm_book() {
        var earlier = {
            blocks: [{
                type: "text",
                content: [{ lines: [{ words: [{ text: "One" }, { text: "dog." }] }] }]
            }]
        }
        var current = {
            blocks: [
                {
                    type: "text",
                    content: [{ lines: [{ words: [{ text: "Two" }, { text: "cats." }] }] }]
                },
                { type: "image", src: "pic.jpg", speak_text: "Two cats sit." }
            ]
        }
        var payload = JSON.parse(Speech.warmBook("af_bella", [earlier, current], 1))
        compare(payload.warm, true)
        compare(payload.voice, "af_bella")
        compare(payload.page_phrases, 2)
        compare(payload.phrases.length, 7)
        compare(payload.phrases[0][0].text, "Two")
        compare(payload.phrases[0][1].text, "cats.")
        compare(payload.phrases[1].length, 3)
        compare(payload.phrases[1][0].text, "Two")
        compare(payload.phrases[1][2].text, "sit.")
        compare(payload.phrases[2][0].text, "One")
        compare(payload.phrases[2][1].text, "dog.")
        compare(payload.phrases[3][0].text, "Two")
        compare(payload.phrases[4][0].text, "cats.")
        compare(payload.phrases[5][0].text, "One")
        compare(payload.phrases[6][0].text, "dog.")
    }
}
