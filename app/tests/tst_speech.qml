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
}
