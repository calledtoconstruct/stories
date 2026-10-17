import QtQuick
import QtTest
import ".."

TestCase {
    Builder { id: builder }

    function test_builder() {
        var size = builder.importImage(10, 10)
        compare(size.width, 48)
        compare(size.height, 48)
        var blocks = [
            { type: "text", content: "line" },
            { type: "image", src: "pic.png" },
            { type: "text", content: "other" }
        ]
        var line = builder.applyTemplate("picture-line", blocks)
        compare(line.length, 2)
        compare(line[0].type, "image")
        compare(line[1].type, "text")
        var band = findChild(builder, "ageBand")
        compare(builder.collectBook().age_band, band.text)
        builder.ageBand = "school"
        compare(builder.collectBook().age_band, "school")
        compare(band.text, "school")
        var theme = builder.collectBook().theme
        compare(theme.background, builder.backgroundColor)
        compare(theme.paper, builder.paperColor)
        compare(theme.text, builder.textColor)
        compare(theme.accent, builder.accentColor)
        compare(theme.font_scale, builder.fontScale)
        var loaded = builder.loadedDraft()
        compare(loaded.book.voice, "af_heart")
        var files = builder.savePlan(loaded)
        compare(files[0].path, "book.json")
        compare(files[1].path, "theme.json")
        builder.addPictureLine("assets/images/p01.jpg", "Hello there")
        builder.addParagraph("Another paragraph")
        compare(builder.pageBodies[0].body.blocks.length, 3)
        compare(builder.pageBodies[0].body.blocks[1].type, "text")
        builder.moveBlock(1, 0.2, 0.55)
        compare(builder.canvasBlocks[1].rect.x, 0.2)
        compare(builder.canvasBlocks[1].rect.y, 0.55)
    }

    function test_editor() {
        compare(builder.showingList, true)
        compare(builder.sheetLabel, "Books")
        builder.width = 1100
        builder.height = 772
        verify(builder.fitScale > 0.9)
        builder.width = 550
        builder.height = 772
        verify(builder.fitScale < 0.6)

        builder.openNew()
        compare(builder.showingList, false)
        compare(builder.sheetLabel, "Cover")
        var coverScroll = findChild(builder, "coverScroll")
        verify(coverScroll.contentHeight > coverScroll.height + 40)
        compare(builder.canUndo, false)
        builder.commitField("title", "Pond Day")
        compare(builder.titleText, "Pond Day")
        compare(builder.bookId, "pond-day")
        compare(builder.canUndo, true)
        builder.undoEdit()
        compare(builder.titleText, "New Book")
        compare(builder.bookId, "new-book")
        compare(builder.sheetLabel, "Cover")
        builder.redoEdit()
        compare(builder.titleText, "Pond Day")

        builder.commitField("background", "green")
        compare(builder.backgroundColor, "#ffffff")
        compare(builder.notice, "Enter a color like #4caf50.")
        builder.commitField("background", "#e8f5e9")
        compare(builder.backgroundColor, "#e8f5e9")
        builder.commitField("scale", "9")
        compare(builder.fontScale, 1)
        compare(builder.notice, "Enter a font scale from above 0 up to 4.")
        builder.commitField("scale", "1.5")
        compare(builder.fontScale, 1.5)

        builder.addBlankPage()
        compare(builder.sheetLabel, "Page 1 of 1")
        compare(builder.pageBodies.length, 1)
        builder.resizeBlock(0, 0.08, 0.1, 0.5, 0.62)
        builder.remember()
        compare(builder.canvasBlocks[0].rect.width, 0.5)
        compare(builder.canvasBlocks[0].rect.height, 0.62)
        builder.undoEdit()
        compare(builder.canvasBlocks[0].rect.height, 0.28)
        builder.commitParagraph(0, "A little turtle walks.")
        compare(builder.canvasBlocks[0].content[0].lines[0].words[0].text, "A")
        compare(builder.canvasBlocks[0].content[0].lines[0].words[3].text, "walks.")
        var box = findChild(builder, "paragraphBox")
        var lineMark = findChild(builder, "readLine")
        var lineAt = lineMark.mapToItem(box, 0, 0)
        verify(lineAt.x < 0)
        verify(lineAt.x + lineMark.width <= 1)
        compare(findChild(builder, "readParagraph").shown, false)
        builder.commitParagraph(0, "A little turtle walks. She finds a pond.")
        var para = findChild(builder, "readParagraph")
        compare(para.shown, true)
        var paraAt = para.mapToItem(findChild(builder, "paragraphBox"), 0, 0)
        verify(paraAt.y >= findChild(builder, "paragraphBox").height - 1)
        verify(paraAt.x + para.width <= 1)
        builder.undoEdit()
        compare(builder.canvasBlocks[0].content[0].lines.length, 1)
        builder.useImage("add", "assets/images/pic-1-turtle.jpg")
        compare(builder.canvasBlocks[1].type, "image")
        compare(builder.canvasBlocks[1].src, "assets/images/pic-1-turtle.jpg")
        compare(builder.canvasBlocks[1].rect.x, 0.48)
        verify(builder.canvasBlocks[0].rect.width < 0.45)
        builder.undoEdit()
        compare(builder.canvasBlocks.length, 1)
        builder.undoEdit()
        compare(builder.canvasBlocks[0].content[0].lines[0].words.length, 0)

        builder.openLoaded({
            book: {
                title: "The Little Turtle's Adventure",
                synopsis: "A little turtle finds a pond.",
                cover: "assets/images/cover.jpg",
                age_band: "early",
                voice: "af_bella",
                format: "storybook/1",
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
                id: "p01",
                blocks: [{
                    type: "image",
                    src: "assets/images/p01.jpg",
                    resolvedSrc: "/tmp/p01.jpg",
                    alt: "A turtle",
                    speak_text: "A turtle."
                }, {
                    type: "text",
                    content: [{ lines: [{ words: [{ id: "w1", text: "Hello." }] }] }]
                }],
                hotspots: [{ id: "h1", label: "Turtle" }]
            }]
        }, "turtle-adventure", "/home/joseph/code/stories/books/turtle-adventure")
        compare(builder.bookId, "turtle-adventure")
        compare(builder.voiceName, "af_bella")
        compare(builder.synopsisText, "A little turtle finds a pond.")
        compare(builder.loadedDraft().pages[0].hotspots[0].id, "h1")
        compare(builder.loadedDraft().pages[0].blocks[0].resolvedSrc, undefined)
        compare(builder.loadedDraft().pages[0].blocks[0].speak_text, "A turtle.")
        builder.commitField("title", "Turtle")
        compare(builder.bookId, "turtle-adventure")
        builder.showSheet(0)
        compare(builder.sheetLabel, "Page 1 of 1")
        builder.showList()
        compare(builder.showingList, true)
        compare(builder.resumeBook("turtle-adventure"), true)
        compare(builder.showingList, false)
        compare(builder.canUndo, true)
        builder.confirmSaved("turtle-adventure", "/home/joseph/code/stories/books/turtle-adventure")
        compare(builder.canUndo, true)
        compare(builder.openedId, "turtle-adventure")
    }

    function test_listFit() {
        builder.showList()
        builder.width = 1100
        builder.library = [{
            id: "pond",
            title: "Pond Day",
            synopsis: "A little turtle finds a quiet pond.",
            cover: "/home/joseph/code/stories/books/turtle-adventure/assets/images/cover.jpg"
        }]
        var card = findChild(builder, "bookCard")
        var cover = findChild(builder, "bookCover")
        var title = findChild(builder, "bookTitle")
        verify(card !== null)
        verify(cover !== null)
        builder.height = 640
        compare(cover.width, 64)
        compare(cover.height, 64)
        verify(card.height >= cover.height + 24)
        compare(title.font.pixelSize, 20)
        verify(cover.y >= 12)
        verify(cover.y + cover.height <= card.height - 12)
        builder.height = 1280
        compare(cover.width, 128)
        compare(cover.height, 128)
        verify(card.height >= cover.height + 24)
        compare(title.font.pixelSize, 40)
        verify(cover.y >= 12)
        verify(cover.y + cover.height <= card.height - 12)
        builder.library = [{
            id: "pond",
            title: "Pond Day",
            synopsis: "One two three four five six seven eight nine ten. One two three four five six seven eight nine ten. One two three four five six seven eight nine ten.",
            cover: "/home/joseph/code/stories/books/turtle-adventure/assets/images/cover.jpg"
        }]
        builder.height = 900
        verify(card.height >= cover.height + 24)
        verify(cover.y + cover.height <= card.height - 12)
        builder.width = builder.implicitWidth
        builder.height = builder.implicitHeight
    }
}
