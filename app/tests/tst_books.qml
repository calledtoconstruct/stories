import QtQuick
import QtTest
import "../Books.js" as Books

TestCase {
    function readUrl(url) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, false)
        xhr.send()
        return xhr.responseText
    }

    function test_roundTrip() {
        var base = Qt.resolvedUrl("../../books/turtle-adventure/")
        var bookText = readUrl(base + "book.json")
        var themeText = readUrl(base + "theme.json")
        var pages = [
            readUrl(base + "pages/p01.json"),
            readUrl(base + "pages/p02.json"),
            readUrl(base + "pages/p03.json"),
            readUrl(base + "pages/p04.json")
        ]
        var folder = "stories/books/turtle-adventure"
        var loaded = Books.loadFromText(bookText, themeText, pages, folder)
        compare(loaded.book.title, "The Little Turtle's Adventure")
        compare(loaded.pages.length, 4)
        compare(loaded.pages[0].blocks[0].resolvedSrc, folder + "/assets/images/p01.jpg")
        var files = Books.filesToWrite(loaded)
        compare(files[0].path, "book.json")
        compare(files[1].path, "theme.json")
        compare(files[2].path, "pages/p01.json")
        var againPages = [files[2].text, files[3].text, files[4].text, files[5].text]
        var again = Books.loadFromText(files[0].text, files[1].text, againPages, folder)
        compare(again.book.title, "The Little Turtle's Adventure")
        compare(again.pages.length, 4)
        compare(again.pages[0].blocks[0].resolvedSrc, folder + "/assets/images/p01.jpg")
    }
}
