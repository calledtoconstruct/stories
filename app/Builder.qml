import QtQuick
import "Books.js" as Books
import "Layout.js" as Layout
import "Theme.js" as Theme

Item {
    id: root
    implicitWidth: 960
    implicitHeight: 640

    property string backgroundColor: "#ffffff"
    property string paperColor: "#ffffff"
    property string textColor: "#000000"
    property string accentColor: "#1565c0"
    property string ageBand: "early"
    property real fontScale: 1.0
    property string titleText: "New Book"
    property string bookId: "new-book"
    property string imageSrc: "assets/images/p01.png"
    property string sentence: "Once upon a time"
    property var pageBodies: []
    property int editPage: 0
    property var canvasBlocks: []

    signal saveRequested()

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
    }

    Column {
        id: controls
        x: 12
        y: 12
        width: 280
        spacing: 8
        Text {
            text: root.titleText
            font.pixelSize: Theme.fontPx(root.ageBand, root.fontScale)
            color: root.textColor
        }
        TextFieldLike {
            objectName: "titleField"
            text: root.titleText
            onEdited: function(value) { root.titleText = value }
        }
        TextFieldLike {
            objectName: "bookIdField"
            text: root.bookId
            onEdited: function(value) { root.bookId = value }
        }
        Text {
            text: "Age band"
            font.pixelSize: Theme.fontPx(root.ageBand, root.fontScale)
            color: root.textColor
        }
        Row {
            spacing: 8
            BandButton { label: "early"; onClicked: root.ageBand = "early" }
            BandButton { label: "growing"; onClicked: root.ageBand = "growing" }
            BandButton { label: "school"; onClicked: root.ageBand = "school" }
        }
        TextFieldLike {
            objectName: "ageBand"
            text: root.ageBand
            onEdited: function(value) { root.ageBand = value }
        }
        TextFieldLike {
            objectName: "backgroundField"
            text: root.backgroundColor
            onEdited: function(value) { root.backgroundColor = value }
        }
        TextFieldLike {
            objectName: "paperField"
            text: root.paperColor
            onEdited: function(value) { root.paperColor = value }
        }
        TextFieldLike {
            objectName: "textField"
            text: root.textColor
            onEdited: function(value) { root.textColor = value }
        }
        TextFieldLike {
            objectName: "accentField"
            text: root.accentColor
            onEdited: function(value) { root.accentColor = value }
        }
        TextFieldLike {
            objectName: "imageField"
            text: root.imageSrc
            onEdited: function(value) { root.imageSrc = value }
        }
        TextFieldLike {
            objectName: "sentenceField"
            text: root.sentence
            onEdited: function(value) { root.sentence = value }
        }
        Row {
            spacing: 8
            BandButton {
                label: "Add page"
                onClicked: root.addPictureLine(root.imageSrc, root.sentence)
            }
            BandButton {
                label: "Add paragraph"
                onClicked: root.addParagraph(root.sentence)
            }
            BandButton {
                label: "Save"
                onClicked: root.saveRequested()
            }
        }
        Text {
            objectName: "pageCount"
            text: root.pageBodies.length + " pages"
            color: root.textColor
            width: 260
            wrapMode: Text.WordWrap
        }
        Text {
            width: 260
            wrapMode: Text.WordWrap
            color: root.textColor
            font.pixelSize: 16
            text: "Drag a picture or a paragraph on the page."
        }
    }

    Rectangle {
        id: canvas
        x: 304
        y: 12
        width: parent.width - 316
        height: parent.height - 24
        color: root.paperColor
        border.color: root.accentColor
        border.width: 2

        Repeater {
            model: root.canvasBlocks
            Rectangle {
                id: piece
                x: (modelData.rect ? modelData.rect.x : 0.05) * canvas.width
                y: (modelData.rect ? modelData.rect.y : 0.05) * canvas.height
                width: Math.max(72, (modelData.rect ? modelData.rect.width : 0.3) * canvas.width)
                height: Math.max(56, (modelData.rect ? modelData.rect.height : 0.2) * canvas.height)
                color: modelData.type === "image" ? "#e3f2fd" : root.backgroundColor
                border.color: root.accentColor
                radius: 8
                Text {
                    anchors.fill: parent
                    anchors.margins: 6
                    text: modelData.type === "image" ? "Picture" : root.blockLabel(modelData)
                    wrapMode: Text.WordWrap
                    color: root.textColor
                    font.pixelSize: 16
                }
                MouseArea {
                    anchors.fill: parent
                    drag.target: piece
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: Math.max(0, canvas.width - piece.width)
                    drag.maximumY: Math.max(0, canvas.height - piece.height)
                    onReleased: root.moveBlock(index, piece.x / canvas.width, piece.y / canvas.height)
                }
            }
        }
    }

    function collectBook() {
        var draft = loadedDraft()
        return {
            title: draft.book.title,
            age_band: draft.book.age_band,
            pages: draft.book.pages,
            theme: draft.theme
        }
    }

    function loadedDraft() {
        var names = []
        var bodies = []
        var i
        for (i = 0; i < pageBodies.length; i++) {
            names.push(pageBodies[i].name)
            bodies.push(pageBodies[i].body)
        }
        return {
            book: {
                title: titleText,
                age_band: ageBand,
                pages: names
            },
            theme: {
                background: backgroundColor,
                paper: paperColor,
                text: textColor,
                accent: accentColor,
                font_scale: fontScale
            },
            pages: bodies
        }
    }

    function importImage(width, height) {
        return Layout.clampSize(width, height)
    }

    function applyTemplate(templateName, blocks) {
        if (templateName === "picture-line")
            return Layout.pictureLine(blocks)
        return blocks
    }

    function addPictureLine(imageSrc, sentence) {
        var n = pageBodies.length + 1
        var name = (n < 10 ? "p0" : "p") + n + ".json"
        var parts = sentence ? sentence.split(" ") : []
        var wordObjs = []
        var w
        for (w = 0; w < parts.length; w++) {
            if (parts[w] === "")
                continue
            wordObjs.push({ id: "w" + (w + 1), text: parts[w], highlight: false })
        }
        var blocks = applyTemplate("picture-line", [
            {
                type: "image",
                src: imageSrc,
                alt: sentence,
                rect: { x: 0.46, y: 0.08, width: 0.5, height: 0.75 }
            },
            {
                type: "text",
                rect: { x: 0.04, y: 0.12, width: 0.38, height: 0.4 },
                content: [{ lines: [{ words: wordObjs }] }]
            }
        ])
        var nextBodies = pageBodies.slice()
        nextBodies.push({
            name: name,
            body: {
                id: name.replace(".json", ""),
                blocks: blocks,
                hotspots: []
            }
        })
        pageBodies = nextBodies
        editPage = nextBodies.length - 1
        canvasBlocks = blocks
    }

    function blockLabel(block) {
        if (!block || !block.content || !block.content.length)
            return "Paragraph"
        var lines = block.content[0].lines || []
        if (!lines.length || !lines[0].words)
            return "Paragraph"
        var words = []
        var i
        for (i = 0; i < lines[0].words.length; i++)
            words.push(lines[0].words[i].text)
        return words.join(" ")
    }

    function wordsFor(sentence) {
        var parts = sentence ? sentence.split(" ") : []
        var wordObjs = []
        var w
        for (w = 0; w < parts.length; w++) {
            if (parts[w] === "")
                continue
            wordObjs.push({ id: "w" + (w + 1), text: parts[w], highlight: false })
        }
        return wordObjs
    }

    function addParagraph(sentence) {
        if (!pageBodies.length) {
            addPictureLine(imageSrc, sentence)
            return
        }
        var pages = pageBodies.slice()
        var page = pages[editPage]
        var blocks = page.body.blocks.slice()
        var textCount = 0
        var i
        for (i = 0; i < blocks.length; i++) {
            if (blocks[i].type === "text")
                textCount = textCount + 1
        }
        blocks.push({
            type: "text",
            rect: {
                x: 0.04,
                y: Math.min(0.7, 0.08 + textCount * 0.24),
                width: 0.4,
                height: 0.22
            },
            content: [{ lines: [{ words: wordsFor(sentence) }] }]
        })
        page.body.blocks = blocks
        pages[editPage] = page
        pageBodies = pages
        canvasBlocks = blocks
    }

    function moveBlock(index, x, y) {
        if (!pageBodies.length)
            return
        var pages = pageBodies.slice()
        var page = pages[editPage]
        var blocks = page.body.blocks.slice()
        var block = blocks[index]
        if (!block)
            return
        block.rect = Layout.moveRect(block.rect, x, y)
        blocks[index] = block
        page.body.blocks = blocks
        pages[editPage] = page
        pageBodies = pages
        canvasBlocks = blocks
    }

    function savePlan(loaded) {
        return Books.filesToWrite(loaded)
    }

    component BandButton: Rectangle {
        property string label: ""
        signal clicked()
        width: Math.max(88, label.length * 10)
        height: 36
        color: "#ffffff"
        border.color: "#607d8b"
        Text { anchors.centerIn: parent; text: parent.label; color: "#222222" }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component TextFieldLike: Rectangle {
        property string text: ""
        signal edited(string value)
        width: 320
        height: 36
        color: "#ffffff"
        border.color: "#607d8b"
        TextInput {
            anchors.fill: parent
            anchors.margins: 8
            text: parent.text
            color: "#222222"
            clip: true
            selectByMouse: true
            onTextEdited: parent.edited(text)
        }
    }
}
