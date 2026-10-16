import QtQuick
import Quickshell.Io
import "."

Item {
    BookStore { id: store }
    FileView {
        id: result
        blockLoading: true
    }

    function finish(code) {
        result.path = "/tmp/stories-proof-store"
        result.setText(String(code))
        result.waitForJob()
    }

    Component.onCompleted: {
        var turtle = "/home/joseph/code/stories/books/turtle-adventure"
        var loaded = store.loadBook(turtle)
        if (!loaded || loaded.book.title !== "The Little Turtle's Adventure") {
            finish(1)
            return
        }
        if (loaded.pages.length !== 4) {
            finish(2)
            return
        }
        if (loaded.pages[0].blocks[0].resolvedSrc !== turtle + "/assets/images/p01.jpg") {
            finish(3)
            return
        }
        if (loaded.theme.background !== "#e8f5e9") {
            finish(4)
            return
        }
        var family = store.loadBook("/home/joseph/code/stories/books/family-picnic")
        var school = store.loadBook("/home/joseph/code/stories/books/school-day")
        if (family.theme.background === loaded.theme.background) {
            finish(5)
            return
        }
        if (school.theme.background === family.theme.background) {
            finish(6)
            return
        }
        var temp = "/tmp/stories-store-roundtrip"
        store.saveBook(loaded, temp)
        var again = store.loadBook(temp)
        if (again.book.title !== "The Little Turtle's Adventure" || again.pages.length !== 4) {
            finish(7)
            return
        }
        if (again.pages[0].blocks[0].resolvedSrc !== temp + "/assets/images/p01.jpg") {
            finish(8)
            return
        }
        finish(0)
    }
}
