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
        compare(findChild(reader, "pageWords").text, "Once upon a time")
        compare(reader.fontPxValue, 36)
        compare(reader.placeText, "{\"page\":0}")
        reader.speakText("a little turtle", "picture")
        compare(reader.currentWord, "a little turtle")
        compare(reader.spokenId, "picture")
        reader.readPage()
        compare(reader.currentWord, "Once")
        compare(findChild(reader, "currentWord").text, "Once")
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
        compare(reader.fitScale, 1)
        reader.width = 550
        reader.height = 700
        compare(reader.fitScale, 0.5)
        reader.width = 1100
        reader.height = 350
        compare(reader.fitScale, 0.5)
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
        compare(reader.currentWord, "A little turtle finds a pond.")
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
}
