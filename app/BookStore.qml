import QtQuick
import Quickshell.Io
import "Books.js" as Books

Item {
    id: root

    FileView {
        id: file
        preload: true
        blockLoading: true
    }

    function readAt(path) {
        file.path = path
        file.waitForJob()
        return file.text()
    }

    function writeText(path, text) {
        file.path = path
        file.setText(text)
        file.waitForJob()
    }

    function loadBook(folderPath) {
        var bookText = readAt(folderPath + "/book.json")
        var themeText = readAt(folderPath + "/theme.json")
        var book = JSON.parse(bookText)
        var pageTexts = []
        var names = book.pages || []
        var i
        for (i = 0; i < names.length; i++)
            pageTexts.push(readAt(folderPath + "/pages/" + names[i]))
        return Books.loadFromText(bookText, themeText, pageTexts, folderPath)
    }

    function saveBook(loaded, folderPath) {
        var files = Books.filesToWrite(loaded)
        var i
        for (i = 0; i < files.length; i++)
            writeText(folderPath + "/" + files[i].path, files[i].text)
    }
}
