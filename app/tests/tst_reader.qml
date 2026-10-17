import QtQuick
import QtTest
import ".."

TestCase {
    Reader { id: reader }

    function test_reader() {
        var title = findChild(reader, "titleText")
        compare(title.text, "No book open")
        var page = {
            blocks: [{
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
            }]
        }
        reader.showBook({
            book: {
                title: "The Little Turtle's Adventure",
                age_band: "early",
                pages: ["p01.json"]
            },
            theme: {
                background: "#e8f5e9",
                paper: "#ffffff",
                text: "#2e7d32",
                accent: "#4caf50",
                font_scale: 1
            },
            pages: [page]
        })
        compare(title.text, "The Little Turtle's Adventure")
        compare(reader.voiceName, "af_heart")
        compare(findChild(reader, "pageWords").text, "Once upon a time")
        compare(reader.fontPxValue, 36)
        compare(reader.placeText, "{\"page\":0}")
        var scale = reader.fitScale
        reader.speakText("a little turtle", "picture")
        compare(reader.currentWord, "a")
        compare(reader.spokenId, "")
        compare(reader.utteranceText, "a little turtle")
        compare(reader.speechHost, "picture")
        compare(findChild(reader, "speechBubble").shown, true)
        compare(reader.fitScale, scale)
        reader.hearWord("picture:2")
        compare(reader.spokenId, "picture:2")
        compare(reader.currentWord, "little")
        reader.readPage()
        compare(reader.speechHost, "")
        compare(findChild(reader, "speechBubble").shown, false)
        compare(reader.fitScale, scale)
        compare(reader.currentWord, "Once")
        compare(reader.utteranceText, "Once upon a time")
        compare(reader.spokenId, "")
        reader.hearWord("w1")
        compare(reader.spokenId, "w1")
        compare(reader.currentWord, "Once")
        reader.hearWord("w3")
        compare(reader.spokenId, "w3")
        compare(reader.currentWord, "a")
        reader.speechFinished()
        compare(reader.spokenId, "")
        compare(reader.awaitingSpeech, false)
        compare(reader.currentWord, "a")
        compare(reader.paragraphs.length, 1)
        compare(reader.paragraphs[0].lines.length, 1)
        reader.readLine(reader.paragraphs[0].lines[0])
        compare(reader.currentWord, "Once")
        reader.readParagraph(reader.paragraphs[0])
        compare(reader.pageTokens.length, 4)
        compare(reader.canGoPrev, false)
        compare(reader.canGoNext, false)
        reader.pressNav("next")
        reader.pressNav("next")
        compare(reader.pageIndex, 0)
        compare(reader.paragraphs[0].rect.y < 0.5, true)
        reader.showBook({
            book: { title: "Tall page", age_band: "early", pages: ["p01.json"] },
            theme: { background: "#ffffff", paper: "#ffffff", text: "#000000", accent: "#1565c0", font_scale: 1 },
            pages: [{
                blocks: [{
                    type: "text",
                    rect: { x: 0.08, y: 0.12, width: 0.5, height: 0.62 },
                    content: [{ lines: [{ words: [{ text: "One" }, { text: "long" }, { text: "paragraph." }] }] }]
                }, {
                    type: "image",
                    rect: { x: 0.6, y: 0.1, width: 0.3, height: 0.7 }
                }]
            }]
        })
        compare(reader.paragraphs[0].rect.width, 0.5)
        compare(reader.paragraphs[0].rect.height, 0.62)
        compare(reader.pictures[0].rect.height, 0.7)
        var story = findChild(reader, "storyCanvas")
        compare(story.width, reader.implicitWidth)
        compare(story.height, reader.implicitHeight)
        var box = findChild(reader, "paragraphBox")
        var lineMark = findChild(reader, "readLine")
        var lineAt = lineMark.mapToItem(box, 0, 0)
        verify(lineAt.x < 0)
        verify(lineAt.x + lineMark.width <= 1)
        compare(findChild(reader, "readParagraph").shown, false)
        reader.showBook({
            book: { title: "Two sentences", age_band: "early", pages: ["p01.json"] },
            theme: { background: "#ffffff", paper: "#ffffff", text: "#000000", accent: "#1565c0", font_scale: 1 },
            pages: [{
                blocks: [{
                    type: "text",
                    rect: { x: 0.2, y: 0.2, width: 0.5, height: 0.4 },
                    content: [{ lines: [
                        { words: [{ text: "One" }, { text: "sentence." }] },
                        { words: [{ text: "Another" }, { text: "sentence." }] }
                    ] }]
                }]
            }, { blocks: [] }]
        })
        var story2 = findChild(reader, "storyCanvas")
        compare(reader.canGoNext, true)
        compare(story2.width, 1100)
        compare(story2.height, 700)
        box = findChild(reader, "paragraphBox")
        compare(box.width, 550)
        compare(box.height, 280)
        var textCol = findChild(reader, "paragraphText")
        verify(textCol.implicitHeight > 40)
        verify(textCol.implicitHeight + 16 <= box.height + 1)
        var para = findChild(reader, "readParagraph")
        compare(para.shown, true)
        var paraAt = para.mapToItem(box, 0, 0)
        verify(paraAt.y >= box.height - 1)
        verify(paraAt.x + para.width <= 1)
        var page = findChild(reader, "storySheet")
        var onPage = para.mapToItem(page, 0, 0)
        verify(onPage.x >= -1)
        verify(onPage.y + para.height <= page.height + 1)
        lineMark = findChild(reader, "readLine")
        lineAt = lineMark.mapToItem(box, 0, 0)
        verify(lineAt.x + lineMark.width <= 1)
        var fitted = reader.fitScale
        verify(fitted > 0.6)
        verify(fitted < 1)
        reader.width = 550
        reader.height = 700
        verify(reader.fitScale < fitted)
        verify(reader.fitScale > 0.3)
        reader.width = 1100
        reader.height = 350
        verify(reader.fitScale < 0.5)
        compare(findChild(reader, "storyCanvas").width, 1100)
        compare(findChild(reader, "storyCanvas").height, 700)
        var opened = ""
        reader.openRequested.connect(function(bookId) { opened = bookId })
        reader.showLibrary([
            { id: "turtle-adventure", title: "The Little Turtle's Adventure", synopsis: "A little turtle finds a pond." },
            { id: "school-day", title: "School Day", synopsis: "A child walks to school." }
        ])
        compare(reader.showingLibrary, true)
        compare(reader.titleText, "Stories")
        reader.chooseBook(reader.library[0])
        compare(reader.showingLibrary, true)
        compare(reader.selectedBookId, "turtle-adventure")
        compare(reader.currentWord, "A")
        compare(reader.utteranceText, "A little turtle finds a pond.")
        compare(reader.speechHost, "synopsis")
        compare(opened, "")
        reader.chooseBook(reader.library[1])
        compare(reader.selectedBookId, "school-day")
        compare(reader.showingLibrary, true)
        compare(opened, "")
        reader.chooseBook(reader.library[1])
        compare(reader.showingLibrary, false)
        compare(opened, "school-day")
        reader.note("next", "edge", 0)
        reader.note("next", "edge", 200)
        compare(reader.dwellAction, "turn")
    }

    function test_voice_status() {
        reader.voiceReady = true
        reader.showBook({
            book: {
                title: "The Little Turtle's Adventure",
                age_band: "early",
                pages: ["p01.json"]
            },
            theme: {
                background: "#e8f5e9",
                paper: "#ffffff",
                text: "#2e7d32",
                accent: "#4caf50",
                font_scale: 1
            },
            pages: [{
                blocks: [{
                    type: "text",
                    content: [{ lines: [{ words: [{ text: "Once" }, { text: "upon." }] }] }]
                }]
            }]
        })
        var line = findChild(reader, "voiceStatus")
        var label = findChild(reader, "voiceStatusText")
        var dot = findChild(reader, "voiceStatusDot")
        compare(reader.voiceStatus, "")
        compare(reader.voiceShown, false)
        compare(line.height, 0)
        reader.noteVoicePage(reader.prepareEpoch)
        compare(reader.voiceStatus, "")
        compare(reader.voiceShown, false)

        reader.showPage(0)
        reader.showPreparing()
        compare(reader.voiceStatus, "preparing")
        compare(reader.voiceShown, true)
        compare(line.height > 0, true)
        compare(label.text, "Getting the voice ready")
        compare(label.color, reader.textColor)
        compare(dot.width > 0, true)
        reader.noteVoicePage(reader.prepareEpoch - 1)
        compare(reader.voiceStatus, "preparing")
        reader.noteVoicePage(reader.prepareEpoch)
        compare(reader.voiceStatus, "ready")
        compare(label.text, "Ready")
        compare(label.color, reader.accentColor)
        reader.dismissReady()
        compare(reader.voiceStatus, "")
        compare(reader.voiceShown, false)
        compare(line.height, 0)

        reader.showPage(0)
        reader.showPreparing()
        reader.voicePrepareEnded()
        compare(reader.voiceStatus, "")
        reader.showLibrary([])
        compare(reader.showingLibrary, true)
        compare(reader.voiceStatus, "")
    }
}
