import QtQuick
import Quickshell.Io
import "Shelf.js" as Shelf
import "."

Item {
    id: root
    implicitWidth: 960
    implicitHeight: 640

    property string booksRoot: "/home/joseph/code/stories/books"
    signal saved(string folderPath)

    BookStore { id: store }

    Process {
        id: prep
        property string pending: ""
        onExited: function(exitCode) {
            if (exitCode !== 0 || !pending)
                return
            var folder = pending
            pending = ""
            root.writeBook(folder)
        }
    }

    Builder {
        id: builder
        anchors.fill: parent
        onSaveRequested: root.prepare(root.booksRoot + "/" + bookId)
    }

    function prepare(folderPath) {
        prep.pending = folderPath
        prep.exec(["mkdir", "-p", folderPath + "/pages", folderPath + "/assets/images"])
    }

    function writeBook(folderPath) {
        store.saveBook(builder.loadedDraft(), folderPath)
        var indexPath = booksRoot + "/index.json"
        var indexText = store.readAt(indexPath)
        if (!indexText || indexText.charAt(0) !== "{")
            indexText = "{\"books\":[]}"
        var bookId = folderPath.substring(folderPath.lastIndexOf("/") + 1)
        store.writeText(indexPath, Shelf.addId(indexText, bookId))
        saved(folderPath)
    }

    function proofDraft(title, band, sentence) {
        builder.titleText = title
        builder.ageBand = band
        builder.addPictureLine("assets/images/p01.png", sentence)
        prepare(booksRoot + "/" + builder.bookId)
    }

    function saveTo(folderPath) {
        writeBook(folderPath)
    }
}
