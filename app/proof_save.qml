import QtQuick
import Quickshell.Io
import "."

Item {
    BookStore { id: store }
    FileView {
        id: result
        blockLoading: true
    }

    ShellBuilder {
        id: shell
        booksRoot: "/tmp/stories-books-root"
        onSaved: function(folder) {
            var loaded = store.loadBook(folder)
            var code = 1
            if (loaded && loaded.book.title === "Proof Book" && loaded.pages.length === 1)
                code = 0
            var indexText = store.readAt("/tmp/stories-books-root/index.json")
            if (indexText.indexOf("new-book") < 0)
                code = 2
            result.path = "/tmp/stories-proof-save"
            result.setText(String(code))
            result.waitForJob()
        }
        Component.onCompleted: proofDraft("Proof Book", "school", "One two")
    }
}
