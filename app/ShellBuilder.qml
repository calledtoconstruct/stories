import QtQuick
import QtQuick.Dialogs
import Quickshell.Io
import "Draft.js" as Draft
import "Shelf.js" as Shelf
import "."

Item {
    id: root
    implicitWidth: 1100
    implicitHeight: 772

    property string booksRoot: "/home/joseph/code/stories/books"
    property string imageRole: ""
    property string imageSource: ""
    property string imageRel: ""
    property string imageFolder: ""
    property color backgroundColor: builder.showingList ? "#f6f3ee" : builder.backgroundColor
    signal saved(string folderPath)

    BookStore { id: store }

    Process {
        id: prep
        property string pending: ""
        onExited: function(exitCode) {
            if (exitCode !== 0 || !pending) {
                if (exitCode !== 0)
                    builder.showNotice("The book folder could not be created.")
                pending = ""
                return
            }
            var folder = pending
            pending = ""
            root.writeBook(folder)
        }
    }

    Process {
        id: imageDir
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                builder.showNotice("The picture could not be copied.")
                return
            }
            imageCopy.exec(["cp", root.imageSource, root.imageFolder + "/" + root.imageRel])
        }
    }

    Process {
        id: imageCopy
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                builder.showNotice("The picture could not be copied.")
                return
            }
            builder.noteFolder(root.folderId(), root.imageFolder)
            builder.useImage(root.imageRole, root.imageRel)
        }
    }

    Process {
        id: mover
        property string folder: ""
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                builder.showNotice("The book could not be renamed.")
                return
            }
            root.writeBook(folder)
        }
    }

    FileDialog {
        id: picker
        title: "Choose a picture"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp *.gif)"]
        onAccepted: root.copyChosen(selectedFile)
    }

    Builder {
        id: builder
        anchors.fill: parent
        onSaveRequested: root.saveCurrent()
        onOpenRequested: function(bookId) { root.openBook(bookId) }
        onImageRequested: function(role) {
            root.imageRole = role
            picker.open()
        }
    }

    function folderId() {
        return builder.openedId || builder.bookId
    }

    function localPath(fileUrl) {
        var text = String(fileUrl)
        if (text.indexOf("file://") === 0)
            text = decodeURIComponent(text.substring(7))
        return text
    }

    function copyChosen(fileUrl) {
        var source = localPath(fileUrl)
        if (!source) {
            builder.showNotice("The picture could not be copied.")
            return
        }
        var id = folderId()
        if (!Draft.validId(id)) {
            builder.showNotice("Use a book id like pond-day before choosing a picture.")
            return
        }
        var ids = Shelf.listIds(indexText())
        if (id !== builder.openedId && ids.indexOf(id) >= 0) {
            builder.showNotice("A book with that id already exists.")
            return
        }
        if (imageRole === "add" && builder.sheetIndex < 0) {
            builder.showNotice("Add a page before choosing a picture.")
            return
        }
        imageSource = source
        imageFolder = booksRoot + "/" + id
        imageRel = "assets/images/" + builder.nextImageName(source)
        imageDir.exec(["mkdir", "-p", imageFolder + "/assets/images"])
    }

    function indexText() {
        var indexPath = booksRoot + "/index.json"
        var text = store.readAt(indexPath)
        if (!text || text.charAt(0) !== "{")
            return "{\"books\":[]}"
        return text
    }

    function saveCurrent() {
        var id = String(builder.bookId || "").trim()
        if (!Draft.validId(id)) {
            builder.showNotice("Use a book id like pond-day.")
            return
        }
        var ids = Shelf.listIds(indexText())
        var fromId = builder.openedId
        if (id !== fromId && ids.indexOf(id) >= 0) {
            builder.showNotice("A book with that id already exists.")
            return
        }
        var folder = booksRoot + "/" + id
        if (fromId && fromId !== id) {
            mover.folder = folder
            mover.exec(["mv", booksRoot + "/" + fromId, folder])
            return
        }
        prepare(folder)
    }

    function prepare(folderPath) {
        prep.pending = folderPath
        prep.exec(["mkdir", "-p", folderPath + "/pages", folderPath + "/assets/images"])
    }

    function writeBook(folderPath) {
        store.saveBook(builder.loadedDraft(), folderPath)
        var indexPath = booksRoot + "/index.json"
        var id = folderPath.substring(folderPath.lastIndexOf("/") + 1)
        store.writeText(indexPath, Shelf.replaceId(indexText(), builder.openedId, id))
        builder.confirmSaved(id, folderPath)
        reloadLibrary()
        saved(folderPath)
    }

    function openBook(bookId) {
        if (builder.resumeBook(bookId))
            return
        var folder = booksRoot + "/" + bookId
        builder.openLoaded(store.loadBook(folder), bookId, folder)
    }

    function reloadLibrary() {
        var text = indexText()
        var ids = Shelf.listIds(text)
        var entries = []
        var i
        for (i = 0; i < ids.length; i++) {
            var folder = booksRoot + "/" + ids[i]
            var card = Shelf.entry(ids[i], store.readAt(folder + "/book.json"))
            if (card.cover && String(card.cover).indexOf("/") !== 0)
                card.cover = folder + "/" + card.cover
            entries.push(card)
        }
        builder.setLibrary(entries)
    }

    function proofDraft(title, band, sentence) {
        builder.titleText = title
        builder.ageBand = band
        builder.bookId = "new-book"
        builder.addPictureLine("assets/images/p01.png", sentence)
        prepare(booksRoot + "/" + builder.bookId)
    }

    function saveTo(folderPath) {
        writeBook(folderPath)
    }

    Component.onCompleted: reloadLibrary()
}
