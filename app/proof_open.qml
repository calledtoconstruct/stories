import QtQuick
import Quickshell.Io
import "."

Item {
    BookStore { id: store }
    Reader { id: reader }
    Builder { id: builder }
    FileView {
        id: result
        blockLoading: true
    }

    function finish(code) {
        result.path = "/tmp/stories-proof-open"
        result.setText(String(code))
        result.waitForJob()
    }

    Component.onCompleted: {
        var books = "/home/joseph/code/stories/books"
        var loaded = store.loadBook(books + "/turtle-adventure")
        reader.showBook(loaded)
        if (reader.titleText !== "The Little Turtle's Adventure") {
            finish(1)
            return
        }
        if (reader.pageWords !== "A little turtle.") {
            finish(2)
            return
        }
        if (reader.fontPxValue !== 36) {
            finish(3)
            return
        }
        if (reader.imageSource(reader.pageImagePath()) !== "file:///home/joseph/code/stories/books/turtle-adventure/assets/images/p01.jpg") {
            finish(10)
            return
        }
        if (!reader.hotspots.length || reader.hotspots[0].speak.indexOf("turtle") < 0) {
            finish(11)
            return
        }
        reader.readPage()
        if (reader.currentWord !== "A") {
            finish(4)
            return
        }
        if (reader.paragraphs.length < 1 || reader.paragraphs[0].lines.length < 1) {
            finish(12)
            return
        }
        reader.showShelf(store.readAt(books + "/index.json"))
        if (reader.bookIds.length < 3) {
            finish(5)
            return
        }
        reader.showBook(store.loadBook(books + "/family-picnic"))
        if (reader.fontPxValue !== 28) {
            finish(6)
            return
        }
        if (reader.paragraphs.length < 2) {
            finish(13)
            return
        }
        if (reader.canGoPrev) {
            finish(14)
            return
        }
        reader.pressNav("prev")
        reader.pressNav("prev")
        if (reader.pageIndex !== 0) {
            finish(15)
            return
        }
        builder.ageBand = "growing"
        builder.titleText = "Built Story"
        builder.backgroundColor = "#eeeeee"
        builder.addPictureLine("assets/images/p01.png", "Hello there friend")
        var draft = builder.loadedDraft()
        if (draft.book.pages.length !== 1 || draft.pages[0].blocks.length !== 2) {
            finish(7)
            return
        }
        var temp = "/tmp/stories-built-book"
        store.saveBook(draft, temp)
        var again = store.loadBook(temp)
        reader.showBook(again)
        if (reader.titleText !== "Built Story" || reader.pageWords !== "Hello there friend") {
            finish(8)
            return
        }
        if (reader.fontPxValue !== 28) {
            finish(9)
            return
        }
        finish(0)
    }
}
