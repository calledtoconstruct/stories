import QtQuick
import QtTest
import "../Draft.js" as Draft

TestCase {
    function test_draft() {
        compare(Draft.slug("Pond Day"), "pond-day")
        compare(Draft.slug("New Book"), "new-book")
        compare(Draft.validId("pond-day"), true)
        compare(Draft.validId("Pond Day"), false)
        compare(Draft.validColor("#4caf50"), true)
        compare(Draft.validColor("green"), false)
        compare(Draft.validScale("1.5"), true)
        compare(Draft.validScale("0"), false)
        compare(Draft.validScale("nope"), false)

        var block = {
            type: "text",
            rect: { x: 0.1, y: 0.1, width: 0.4, height: 0.2 },
            content: [{ lines: [
                { words: [{ id: "w1", text: "Today" }, { id: "w2", text: "I" }, { id: "w3", text: "walk." }] },
                { words: [{ id: "w4", text: "Then" }, { id: "w5", text: "home." }] }
            ] }]
        }
        compare(Draft.paragraphText(block), "Today I walk. Then home.")
        compare(Draft.sentenceCount(Draft.wordList(block)), 2)
        compare(Draft.sentenceCount([{ text: "Hello." }]), 1)
        compare(Draft.sentenceCount([{ text: "Hi!" }, { text: "Go?" }]), 2)
        compare(Draft.sentenceCount([{ text: "Hello" }]), 0)
        compare(Draft.endsSentence("pond.\""), true)
        var written = Draft.writeParagraph(block, "Today I run. Then home again.")
        compare(written.content[0].lines.length, 2)
        compare(written.content[0].lines[0].words[0].id, "w1")
        compare(written.content[0].lines[0].words[2].text, "run.")
        compare(written.content[0].lines[1].words[2].id, "w6")
        compare(written.content[0].lines[1].words[2].text, "again.")
        compare(written.rect.x, 0.1)

        var page = { blocks: [{ type: "image", src: "a.jpg", resolvedSrc: "/tmp/a.jpg" }], hotspots: [{ id: "h1" }] }
        compare(Draft.cleanPage(page).blocks[0].resolvedSrc, undefined)
        compare(Draft.cleanPage(page).hotspots[0].id, "h1")
        compare(Draft.nextPageName([{ name: "p01.json" }, { name: "p03.json" }]), "p04.json")
        compare(Draft.imageName("/home/joseph/My Photo.JPG", 2), "pic-2-MyPhoto.JPG")

        var history = Draft.begin({ title: "New Book" })
        compare(Draft.canUndo(history), false)
        history = Draft.commit(history, { title: "Pond Day" })
        compare(Draft.canUndo(history), true)
        history = Draft.commit(history, { title: "Pond Day" })
        compare(history.index, 1)
        history = Draft.undo(history)
        compare(Draft.current(history).title, "New Book")
        history = Draft.redo(history)
        compare(Draft.current(history).title, "Pond Day")
        history = Draft.undo(history)
        history = Draft.commit(history, { title: "Other" })
        compare(Draft.canRedo(history), false)
        compare(Draft.current(history).title, "Other")
    }
}
