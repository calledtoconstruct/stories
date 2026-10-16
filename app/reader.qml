import QtQuick
import Quickshell
import Quickshell.Io
import "Shelf.js" as Shelf
import "."

FloatingWindow {
    id: root
    title: "Stories"
    implicitWidth: 1100
    implicitHeight: 700
    minimumSize: Qt.size(480, 320)
    color: reader.backgroundColor

    property string booksRoot: "/home/joseph/code/stories/books"

    BookStore { id: store }

    property string pendingSpeech: ""
    property bool replacingSpeech: false

    Process {
        id: speaker
        onExited: {
            if (root.replacingSpeech) {
                root.replacingSpeech = false
                root.sayNow(root.pendingSpeech)
                return
            }
            reader.speechFinished()
        }
    }

    function sayNow(text) {
        speaker.exec(["/home/joseph/code/stories/voice/speak", text])
    }

    Reader {
        id: reader
        anchors.fill: parent
        voiceReady: true
        onOpenRequested: function(bookId) {
            reader.showBook(store.loadBook(root.booksRoot + "/" + bookId))
        }
        onSpeakRequested: function(text) {
            if (!text) {
                root.pendingSpeech = ""
                root.replacingSpeech = false
                if (speaker.running)
                    speaker.signal(15)
                return
            }
            root.pendingSpeech = text
            if (speaker.running) {
                root.replacingSpeech = true
                speaker.signal(15)
                return
            }
            root.sayNow(text)
        }
    }

    function requestedStory() {
        var fromEnv = Quickshell.env("STORIES_BOOK")
        if (fromEnv === null || fromEnv === undefined)
            return ""
        return String(fromEnv).trim()
    }

    function libraryEntries(indexText) {
        var ids = Shelf.listIds(indexText)
        var entries = []
        var i
        for (i = 0; i < ids.length; i++) {
            var folder = booksRoot + "/" + ids[i]
            var card = Shelf.entry(ids[i], store.readAt(folder + "/book.json"))
            if (card.cover && card.cover.indexOf("/") !== 0)
                card.cover = folder + "/" + card.cover
            entries.push(card)
        }
        return entries
    }

    Component.onCompleted: {
        var indexText = store.readAt(booksRoot + "/index.json")
        reader.showShelf(indexText)
        var story = requestedStory()
        if (story && reader.bookIds.indexOf(story) >= 0)
            reader.showBook(store.loadBook(booksRoot + "/" + story))
        else
            reader.showLibrary(libraryEntries(indexText))
    }
}
