import QtQuick
import "."
import "Books.js" as Books
import "Draft.js" as Draft
import "Layout.js" as Layout
import "Theme.js" as Theme

Item {
    id: root
    objectName: "editor"
    implicitWidth: 1100
    implicitHeight: 772

    property string backgroundColor: "#ffffff"
    property string paperColor: "#ffffff"
    property string textColor: "#000000"
    property string accentColor: "#1565c0"
    property string ageBand: "early"
    property real fontScale: 1.0
    property string titleText: "New Book"
    property string synopsisText: ""
    property string coverSrc: ""
    property string bookId: "new-book"
    property string voiceName: "af_heart"
    property string formatName: "storybook/1"
    property string imageSrc: "assets/images/p01.png"
    property string sentence: "Once upon a time"
    property string bookFolder: ""
    property string openedId: ""
    property bool idTouched: false
    property var pageBodies: []
    property int editPage: 0
    property int sheetIndex: -1
    property var canvasBlocks: []
    property var library: []
    property bool showingList: true
    property var historyState: null
    property string notice: ""
    property string openKey: ""
    property string openValue: ""
    property int editingBlock: -1
    property string editingText: ""
    property string pendingImage: ""
    property int imageSerial: 0
    property int draftRevision: 0
    readonly property var voices: ["af_heart", "af_bella", "am_adam", "bf_emma"]
    readonly property var ageBands: ["early", "growing", "school"]
    readonly property real sheetW: 1100
    readonly property real sheetH: 700
    readonly property real fitScale: Math.min(Math.max(1, width) / sheetW, Math.max(1, height - toolbar.height) / sheetH)
    readonly property bool canUndo: Draft.canUndo(historyState)
    readonly property bool canRedo: Draft.canRedo(historyState)
    readonly property string sheetLabel: {
        if (showingList)
            return "Books"
        if (sheetIndex < 0)
            return "Cover"
        return "Page " + (sheetIndex + 1) + " of " + pageBodies.length
    }

    signal saveRequested()
    signal openRequested(string bookId)
    signal imageRequested(string role)

    Rectangle {
        anchors.fill: parent
        color: "#f6f3ee"
    }

    Text {
        objectName: "ageBand"
        visible: false
        text: root.ageBand
    }

    Flow {
        id: toolbar
        width: parent.width
        spacing: 8
        padding: 8

        ToolButton { label: "Books"; visible: !root.showingList; onClicked: root.showList() }
        ToolButton { label: "Undo"; visible: !root.showingList; enabled: root.canUndo; onClicked: root.undoEdit() }
        ToolButton { label: "Redo"; visible: !root.showingList; enabled: root.canRedo; onClicked: root.redoEdit() }
        ToolButton { label: "Save"; visible: !root.showingList; onClicked: root.requestSave() }
        ToolButton { label: "Back"; visible: !root.showingList; enabled: root.sheetIndex >= 0; onClicked: root.showSheet(root.sheetIndex - 1) }
        ToolButton { label: "Next"; visible: !root.showingList; enabled: root.sheetIndex + 1 < root.pageBodies.length; onClicked: root.showSheet(root.sheetIndex + 1) }
        ToolButton { label: "Add page"; visible: !root.showingList; onClicked: root.addBlankPage() }
        ToolButton { label: "Add paragraph"; visible: root.sheetIndex >= 0; onClicked: root.addEmptyParagraph() }
        ToolButton { label: "Add picture"; visible: root.sheetIndex >= 0; onClicked: root.askImage("add") }
        Text {
            objectName: "sheetLabel"
            text: root.sheetLabel
            color: "#333333"
            font.pixelSize: 18
            height: 40
            verticalAlignment: Text.AlignVCenter
        }
    }

    Text {
        id: noticeMeasure
        visible: false
        width: parent.width - 24
        text: root.notice
        font.pixelSize: 16
        wrapMode: Text.WordWrap
    }

    Item {
        id: noticeSlot
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.notice ? noticeMeasure.implicitHeight : 0
        Text {
            objectName: "notice"
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            text: root.notice
            color: "#7a2e2e"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: stage
        anchors.top: noticeSlot.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        Flickable {
            anchors.fill: parent
            visible: root.showingList
            contentWidth: width
            contentHeight: listColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            clip: true

            Column {
                id: listColumn
                // 640 is the window height where a 64px cover already fits the card.
                // Cover and type share that scale, so they grow and shrink together.
                readonly property real listScale: Math.max(1, root.height / 640)
                readonly property real listCover: 64 * listScale
                readonly property real listTitle: 20 * listScale
                readonly property real listSynopsis: 16 * listScale
                readonly property real listHeading: 28 * listScale
                width: stage.width
                spacing: 12
                topPadding: 16
                bottomPadding: 24
                leftPadding: 24
                rightPadding: 24

                Text {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: "Stories"
                    color: "#222222"
                    font.pixelSize: listColumn.listHeading
                }

                ToolButton {
                    objectName: "newBook"
                    label: "New book"
                    onClicked: root.openNew()
                }

                Text {
                    visible: root.library.length === 0
                    text: "No books yet"
                    color: "#555555"
                    font.pixelSize: listColumn.listSynopsis
                }

                Repeater {
                    model: root.library
                    Rectangle {
                        id: bookCard
                        objectName: "bookCard"
                        readonly property real pad: 12
                        readonly property real coverSide: modelData.cover ? listColumn.listCover : 0
                        width: listColumn.width - listColumn.leftPadding - listColumn.rightPadding
                        height: Math.max(coverSide, bookWords.implicitHeight) + pad * 2
                        radius: 12
                        color: "#ffffff"
                        border.color: "#c5bfb4"

                        Image {
                            id: bookCover
                            objectName: "bookCover"
                            width: bookCard.coverSide
                            height: bookCard.coverSide
                            x: bookCard.pad
                            y: Math.round((parent.height - height) / 2)
                            fillMode: Image.PreserveAspectFit
                            source: modelData.cover ? "file://" + modelData.cover : ""
                            visible: bookCard.coverSide > 0
                        }

                        Column {
                            id: bookWords
                            x: bookCard.pad + bookCard.coverSide + (bookCard.coverSide > 0 ? bookCard.pad : 0)
                            y: Math.round((parent.height - implicitHeight) / 2)
                            width: bookCard.width - x - bookCard.pad
                            spacing: 4

                            Text {
                                id: bookTitle
                                objectName: "bookTitle"
                                width: parent.width
                                text: modelData.title
                                color: "#222222"
                                font.pixelSize: listColumn.listTitle
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                id: bookSynopsis
                                width: parent.width
                                text: modelData.synopsis
                                color: "#555555"
                                font.pixelSize: listColumn.listSynopsis
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openRequested(modelData.id)
                        }
                    }
                }
            }
        }

        Item {
            id: sheet
            visible: !root.showingList
            clip: true
            width: root.sheetW
            height: root.sheetH
            scale: root.fitScale
            transformOrigin: Item.TopLeft
            x: Math.round((stage.width - width * scale) / 2)
            y: Math.round((stage.height - height * scale) / 2)

            Rectangle {
                anchors.fill: parent
                color: root.backgroundColor
            }

            Flickable {
                objectName: "coverScroll"
                anchors.fill: parent
                visible: root.sheetIndex < 0
                contentWidth: width
                contentHeight: coverColumn.y + coverColumn.implicitHeight + 36
                clip: true
                flickableDirection: Flickable.VerticalFlick

            Column {
                id: coverColumn
                x: 36
                y: 36
                width: sheet.width - 72
                spacing: 12

                Text {
                    text: "Book"
                    color: root.textColor
                    font.pixelSize: 28
                }
                Field { key: "title"; label: "Title"; value: root.titleText }
                Field { key: "synopsis"; label: "Synopsis"; value: root.synopsisText; fieldHeight: 72 }
                Text { text: "Cover"; color: root.textColor; font.pixelSize: 18 }
                Rectangle {
                    width: 280
                    height: 180
                    radius: 12
                    color: root.paperColor
                    border.color: root.accentColor
                    border.width: 2
                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        fillMode: Image.PreserveAspectFit
                        source: root.imageSource(root.coverSrc)
                        visible: root.coverSrc
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !root.coverSrc
                        text: "Choose a cover"
                        color: root.textColor
                        font.pixelSize: 20
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.askImage("cover")
                    }
                }
                Text { text: "Age band"; color: root.textColor; font.pixelSize: 18 }
                Row {
                    spacing: 8
                    Repeater {
                        model: root.ageBands
                        ChoiceButton {
                            label: modelData
                            selected: root.ageBand === modelData
                            onClicked: root.commitChoice("age", modelData)
                        }
                    }
                }
                Text { text: "Voice"; color: root.textColor; font.pixelSize: 18 }
                Row {
                    spacing: 8
                    Repeater {
                        model: root.voices
                        ChoiceButton {
                            label: modelData
                            selected: root.voiceName === modelData
                            onClicked: root.commitChoice("voice", modelData)
                        }
                    }
                }
                Field { key: "background"; label: "Background"; value: root.backgroundColor }
                Field { key: "paper"; label: "Paper"; value: root.paperColor }
                Field { key: "text"; label: "Text"; value: root.textColor }
                Field { key: "accent"; label: "Accent"; value: root.accentColor }
                Field { key: "scale"; label: "Font scale"; value: String(root.fontScale) }
                Field { key: "id"; label: "Book id"; value: root.bookId }
            }
            }

            Item {
                id: pageCanvas
                anchors.fill: parent
                visible: root.sheetIndex >= 0

                Repeater {
                    model: root.canvasBlocks
                    Item {
                        id: piece
                        objectName: modelData.type === "text" ? "paragraphBox" : ""
                        property int blockIndex: index
                        property var blockRef: modelData
                        property var textLines: root.blockLines(modelData)
                        property var lineTops: []
                        x: ((modelData.rect && modelData.rect.x) || 0.05) * pageCanvas.width
                        y: ((modelData.rect && modelData.rect.y) || 0.05) * pageCanvas.height
                        width: Math.max(48, ((modelData.rect && modelData.rect.width) || 0.3) * pageCanvas.width)
                        height: Math.max(48, ((modelData.rect && modelData.rect.height) || 0.2) * pageCanvas.height)

                        function rememberLine(i, yPos) {
                            var tops = lineTops
                            if (tops[i] === yPos)
                                return
                            var next = tops.slice()
                            next[i] = yPos
                            lineTops = next
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: modelData.type === "image" ? "transparent" : root.paperColor
                            border.color: root.accentColor
                            border.width: 2
                        }
                        Image {
                            anchors.fill: parent
                            visible: modelData.type === "image" && modelData.src
                            source: root.imageSource(modelData.src)
                            fillMode: Image.PreserveAspectFit
                        }
                        Item {
                            anchors.fill: parent
                            clip: true
                            visible: modelData.type === "text"

                            Text {
                                anchors.fill: parent
                                anchors.margins: 8
                                visible: Draft.wordList(piece.blockRef).length === 0 && root.editingBlock !== piece.blockIndex
                                text: "Paragraph"
                                color: root.textColor
                                font.pixelSize: Theme.fontPx(root.ageBand, root.fontScale)
                            }

                            Column {
                                id: textCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 4
                                opacity: root.editingBlock === piece.blockIndex ? 0 : 1

                                Repeater {
                                    model: piece.textLines
                                    Item {
                                        id: lineSlot
                                        property var lineWords: modelData.words || []
                                        width: textCol.width
                                        height: Math.max(44, wordFlow.implicitHeight)
                                        onYChanged: piece.rememberLine(index, y)
                                        onHeightChanged: piece.rememberLine(index, y)
                                        Component.onCompleted: piece.rememberLine(index, y)

                                        Flow {
                                            id: wordFlow
                                            width: parent.width
                                            spacing: 6
                                            Repeater {
                                                model: lineSlot.lineWords
                                                Item {
                                                    width: wordText.implicitWidth + 4
                                                    height: Math.max(Theme.fontPx(root.ageBand, root.fontScale), wordText.implicitHeight)
                                                    Text {
                                                        id: wordText
                                                        anchors.centerIn: parent
                                                        text: modelData.text
                                                        color: root.textColor
                                                        font.pixelSize: Theme.fontPx(root.ageBand, root.fontScale)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: modelData.type === "image" && !modelData.src
                            text: "Choose a picture"
                            color: root.textColor
                            font.pixelSize: 22
                        }
                        TextInput {
                            id: paragraphEditor
                            anchors.fill: parent
                            anchors.margins: 8
                            visible: modelData.type === "text" && root.editingBlock === index
                            color: root.textColor
                            font.pixelSize: Theme.fontPx(root.ageBand, root.fontScale)
                            wrapMode: TextInput.Wrap
                            selectByMouse: true
                            clip: true
                            onVisibleChanged: {
                                if (visible) {
                                    text = root.editingText
                                    forceActiveFocus()
                                }
                            }
                            onTextEdited: root.noteTyping("paragraph", text)
                            onEditingFinished: root.commitParagraph(index, text)
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.editingBlock !== index
                            drag.target: piece
                            drag.minimumX: 0
                            drag.minimumY: 0
                            drag.maximumX: Math.max(0, pageCanvas.width - piece.width)
                            drag.maximumY: Math.max(0, pageCanvas.height - piece.height)
                            property real startX: 0
                            property real startY: 0
                            onPressed: {
                                startX = piece.x
                                startY = piece.y
                            }
                            onReleased: {
                                var dx = piece.x - startX
                                var dy = piece.y - startY
                                if (Math.abs(dx) < 6 && Math.abs(dy) < 6) {
                                    piece.x = startX
                                    piece.y = startY
                                    root.activateBlock(index)
                                } else {
                                    root.moveBlock(index, piece.x / pageCanvas.width, piece.y / pageCanvas.height)
                                    root.remember()
                                }
                            }
                        }
                        Repeater {
                            model: piece.textLines
                            ReadMark {
                                objectName: "readLine"
                                kind: "line"
                                interactive: false
                                markColor: "#8a9096"
                                opacity: 0.85
                                x: -width - 8
                                y: textCol.y + (piece.lineTops[index] || 0)
                            }
                        }
                        Repeater {
                            model: modelData.type === "text" ? 1 : 0
                            ReadMark {
                                objectName: "readParagraph"
                                kind: "paragraph"
                                interactive: false
                                markColor: "#8a9096"
                                opacity: 0.85
                                property bool shown: Draft.sentenceCount(Draft.wordList(piece.blockRef)) > 1
                                visible: shown
                                x: -width - 8
                                y: parent.height + 8
                            }
                        }
                        ResizeHandle { blockIndex: index; growX: -1; growY: -1 }
                        ResizeHandle { blockIndex: index; growX: 1; growY: -1 }
                        ResizeHandle { blockIndex: index; growX: -1; growY: 1 }
                        ResizeHandle { blockIndex: index; growX: 1; growY: 1 }
                    }
                }
            }
        }
    }

    function imageSource(src) {
        if (!src)
            return ""
        if (String(src).indexOf("/") === 0)
            return "file://" + src
        if (!bookFolder)
            return ""
        return "file://" + bookFolder + "/" + src
    }

    function showNotice(text) {
        notice = text || ""
    }

    function noteTyping(key, value) {
        openKey = key
        openValue = value
    }

    function requestSave() {
        commitOpenField()
        saveRequested()
    }

    function showList() {
        commitOpenField()
        editingBlock = -1
        showingList = true
    }

    function setLibrary(entries) {
        library = entries || []
    }

    function resumeBook(id) {
        if (!historyState || !id || id !== openedId)
            return false
        showingList = false
        return true
    }

    function showSheet(index) {
        commitOpenField()
        if (index < -1)
            index = -1
        if (index >= pageBodies.length)
            index = pageBodies.length - 1
        sheetIndex = index
        editingBlock = -1
        if (index >= 0) {
            editPage = index
            canvasBlocks = pageBodies[index].body.blocks || []
        }
    }

    function askImage(role) {
        commitOpenField()
        pendingImage = role
        imageRequested(role)
    }

    function nextImageName(sourcePath) {
        imageSerial += 1
        return Draft.imageName(sourcePath, Date.now() + "-" + imageSerial)
    }

    function noteFolder(id, folder) {
        if (!openedId)
            openedId = id
        bookFolder = folder || bookFolder
    }

    function confirmSaved(id, folder) {
        openedId = id
        bookFolder = folder
        idTouched = true
        notice = "Saved."
        draftRevision += 1
    }

    function fitTextBeside(blocks, imageRect) {
        var i
        for (i = 0; i < blocks.length; i++) {
            var item = blocks[i]
            if (!item || item.type !== "text" || !item.rect || !imageRect)
                continue
            var rect = item.rect
            if (!(rect.x < imageRect.x && rect.x + rect.width > imageRect.x - 0.02))
                continue
            var copy = Draft.clone(item)
            copy.rect = Draft.clone(rect)
            copy.rect.width = Math.max(0.24, imageRect.x - rect.x - 0.02)
            blocks[i] = copy
        }
    }

    function useImage(role, rel) {
        if (role === "cover") {
            coverSrc = rel
        } else if (String(role).indexOf("block:") === 0) {
            var index = parseInt(String(role).substring(6), 10)
            if (!pageBodies.length || !(index >= 0))
                return
            var pages = pageBodies.slice()
            var page = pages[editPage]
            var blocks = page.body.blocks.slice()
            if (!blocks[index])
                return
            var block = Draft.clone(blocks[index])
            block.src = rel
            delete block.resolvedSrc
            blocks[index] = block
            page.body.blocks = blocks
            pages[editPage] = page
            pageBodies = pages
            canvasBlocks = blocks
        } else if (role === "add") {
            if (sheetIndex < 0 || !pageBodies.length)
                return
            editPage = sheetIndex
            var more = pageBodies.slice()
            var current = more[editPage]
            var added = current.body.blocks.slice()
            var block = Draft.imageBlock(rel)
            var textCount = 0
            var t
            for (t = 0; t < added.length; t++) {
                if (added[t].type === "text")
                    textCount = textCount + 1
            }
            if (textCount)
                block.rect = Layout.defaultImage(textCount)
            added.push(block)
            if (textCount)
                root.fitTextBeside(added, block.rect)
            current.body.blocks = added
            more[editPage] = current
            pageBodies = more
            canvasBlocks = added
        } else {
            return
        }
        notice = ""
        remember()
    }

    function capture() {
        var draft = loadedDraft()
        return {
            folderId: bookId,
            idTouched: idTouched,
            sheet: sheetIndex,
            book: draft.book,
            theme: draft.theme,
            pages: draft.pages
        }
    }

    function restoreDraft(snapshot) {
        var draft = Draft.clone(snapshot)
        bookId = draft.folderId || bookId
        idTouched = !!draft.idTouched
        titleText = draft.book.title || ""
        synopsisText = draft.book.synopsis || ""
        coverSrc = draft.book.cover || ""
        ageBand = draft.book.age_band || "early"
        voiceName = draft.book.voice || "af_heart"
        formatName = draft.book.format || "storybook/1"
        backgroundColor = draft.theme.background || "#ffffff"
        paperColor = draft.theme.paper || "#ffffff"
        textColor = draft.theme.text || "#000000"
        accentColor = draft.theme.accent || "#1565c0"
        fontScale = draft.theme.font_scale || 1
        var names = draft.book.pages || []
        var bodies = []
        var i
        for (i = 0; i < names.length; i++)
            bodies.push({ name: names[i], body: Draft.cleanPage(draft.pages[i]) })
        pageBodies = bodies
        var sheet = draft.sheet
        if (sheet === undefined || sheet === null)
            sheet = -1
        if (sheet >= bodies.length)
            sheet = bodies.length - 1
        sheetIndex = sheet
        editingBlock = -1
        openKey = ""
        if (sheet >= 0 && bodies.length) {
            editPage = sheet
            canvasBlocks = bodies[sheet].body.blocks || []
        } else if (bodies.length) {
            editPage = 0
            canvasBlocks = bodies[0].body.blocks || []
        } else {
            editPage = 0
            canvasBlocks = []
        }
        draftRevision += 1
    }

    function remember() {
        if (!historyState)
            return
        historyState = Draft.commit(historyState, capture())
    }

    function commitOpenField() {
        if (openKey === "paragraph" && editingBlock >= 0) {
            commitParagraph(editingBlock, openValue)
            return
        }
        if (openKey)
            commitField(openKey, openValue)
    }

    function undoEdit() {
        commitOpenField()
        if (!Draft.canUndo(historyState))
            return
        historyState = Draft.undo(historyState)
        restoreDraft(Draft.current(historyState))
    }

    function redoEdit() {
        commitOpenField()
        if (!Draft.canRedo(historyState))
            return
        historyState = Draft.redo(historyState)
        restoreDraft(Draft.current(historyState))
    }

    function commitChoice(key, value) {
        commitOpenField()
        if (key === "age") {
            if (ageBand === value)
                return
            ageBand = value
        } else if (key === "voice") {
            if (voiceName === value)
                return
            voiceName = value
        } else {
            return
        }
        notice = ""
        remember()
    }

    function commitField(key, value) {
        if (openKey === key)
            openKey = ""
        if (key === "title") {
            if (value === titleText)
                return
            titleText = value
            if (!idTouched)
                bookId = Draft.slug(value)
        } else if (key === "synopsis") {
            if (value === synopsisText)
                return
            synopsisText = value
        } else if (key === "id") {
            var nextId = String(value || "").trim()
            if (!Draft.validId(nextId)) {
                notice = "Use a book id like pond-day."
                draftRevision += 1
                return
            }
            if (nextId === bookId)
                return
            bookId = nextId
            idTouched = true
        } else if (key === "background" || key === "paper" || key === "text" || key === "accent") {
            if (!Draft.validColor(value)) {
                notice = "Enter a color like #4caf50."
                draftRevision += 1
                return
            }
            if (key === "background") {
                if (value === backgroundColor)
                    return
                backgroundColor = value
            } else if (key === "paper") {
                if (value === paperColor)
                    return
                paperColor = value
            } else if (key === "text") {
                if (value === textColor)
                    return
                textColor = value
            } else if (value === accentColor) {
                return
            } else {
                accentColor = value
            }
        } else if (key === "scale") {
            if (!Draft.validScale(value)) {
                notice = "Enter a font scale from above 0 up to 4."
                draftRevision += 1
                return
            }
            var scale = Number(value)
            if (scale === fontScale)
                return
            fontScale = scale
        } else {
            return
        }
        notice = ""
        remember()
        draftRevision += 1
    }

    function commitParagraph(index, value) {
        openKey = ""
        editingBlock = -1
        if (!pageBodies.length)
            return
        var pages = pageBodies.slice()
        var page = pages[editPage]
        if (!page)
            return
        var blocks = page.body.blocks.slice()
        var block = blocks[index]
        if (!block || block.type !== "text")
            return
        if (Draft.paragraphText(block) === String(value || "").replace(/\s+/g, " ").trim())
            return
        blocks[index] = Draft.writeParagraph(block, value)
        page.body.blocks = blocks
        pages[editPage] = page
        pageBodies = pages
        canvasBlocks = blocks
        notice = ""
        remember()
    }

    function activateBlock(index) {
        var blocks = canvasBlocks || []
        var block = blocks[index]
        if (!block)
            return
        if (block.type === "image") {
            askImage("block:" + index)
            return
        }
        editingText = blockLabel(block)
        editingBlock = index
        openKey = "paragraph"
        openValue = editingText
    }

    function addBlankPage() {
        commitOpenField()
        var name = Draft.nextPageName(pageBodies)
        var pages = pageBodies.slice()
        pages.push({ name: name, body: Draft.blankPage(name) })
        pageBodies = pages
        editPage = pages.length - 1
        sheetIndex = editPage
        canvasBlocks = pages[editPage].body.blocks
        showingList = false
        notice = ""
        remember()
    }

    function addEmptyParagraph() {
        commitOpenField()
        if (sheetIndex < 0 || !pageBodies.length)
            return
        editPage = sheetIndex
        addParagraph("")
        remember()
    }

    function openNew() {
        openedId = ""
        bookFolder = ""
        idTouched = false
        titleText = "New Book"
        synopsisText = ""
        coverSrc = ""
        bookId = "new-book"
        voiceName = "af_heart"
        formatName = "storybook/1"
        ageBand = "early"
        backgroundColor = "#ffffff"
        paperColor = "#ffffff"
        textColor = "#000000"
        accentColor = "#1565c0"
        fontScale = 1
        pageBodies = []
        canvasBlocks = []
        editPage = 0
        sheetIndex = -1
        editingBlock = -1
        openKey = ""
        notice = ""
        showingList = false
        historyState = Draft.begin(capture())
        draftRevision += 1
    }

    function openLoaded(loaded, id, folder) {
        var book = loaded.book || {}
        var theme = loaded.theme || {}
        openedId = id || ""
        bookFolder = folder || ""
        idTouched = true
        titleText = book.title || ""
        synopsisText = book.synopsis || ""
        coverSrc = book.cover || ""
        bookId = id || Draft.slug(book.title)
        voiceName = book.voice || "af_heart"
        formatName = book.format || "storybook/1"
        ageBand = book.age_band || "early"
        backgroundColor = theme.background || "#ffffff"
        paperColor = theme.paper || "#ffffff"
        textColor = theme.text || "#000000"
        accentColor = theme.accent || "#1565c0"
        fontScale = theme.font_scale || 1
        var names = book.pages || []
        var bodies = []
        var i
        for (i = 0; i < names.length; i++)
            bodies.push({ name: names[i], body: Draft.cleanPage((loaded.pages || [])[i]) })
        pageBodies = bodies
        editPage = 0
        sheetIndex = -1
        canvasBlocks = bodies.length ? bodies[0].body.blocks || [] : []
        editingBlock = -1
        openKey = ""
        notice = ""
        showingList = false
        historyState = Draft.begin(capture())
        draftRevision += 1
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
            bodies.push(Draft.cleanPage(pageBodies[i].body))
        }
        return {
            book: {
                title: titleText,
                synopsis: synopsisText,
                cover: coverSrc,
                age_band: ageBand,
                voice: voiceName,
                format: formatName,
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
        sheetIndex = editPage
        canvasBlocks = blocks
    }

    function blockLines(block) {
        var lines = []
        if (!block || block.type !== "text")
            return lines
        var content = block.content || []
        var c
        var l
        for (c = 0; c < content.length; c++) {
            var group = content[c].lines || []
            for (l = 0; l < group.length; l++)
                lines.push(group[l])
        }
        if (!lines.length)
            lines.push({ words: [] })
        return lines
    }

    function blockLabel(block) {
        var text = Draft.paragraphText(block)
        return text || "Paragraph"
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

    function resizeBlock(index, x, y, width, height) {
        if (!pageBodies.length)
            return
        var pages = pageBodies.slice()
        var page = pages[editPage]
        var blocks = page.body.blocks.slice()
        var block = blocks[index]
        if (!block)
            return
        var copy = Draft.clone(block)
        copy.rect = Layout.resizeRect(block.rect, x, y, width, height)
        blocks[index] = copy
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

    component ResizeHandle: Rectangle {
        id: handle
        property int blockIndex: 0
        property int growX: 1
        property int growY: 1
        property real originX: 0
        property real originY: 0
        property real originW: 0
        property real originH: 0
        property real pressX: 0
        property real pressY: 0
        visible: root.editingBlock !== blockIndex
        z: 3
        width: 20
        height: 20
        radius: 4
        color: root.accentColor
        border.color: root.paperColor
        border.width: 2
        x: growX > 0 ? parent.width - width - 2 : 2
        y: growY > 0 ? parent.height - height - 2 : 2

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            cursorShape: handle.growX === handle.growY ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
            onPressed: function(mouse) {
                var pos = mapToItem(pageCanvas, mouse.x, mouse.y)
                handle.pressX = pos.x
                handle.pressY = pos.y
                handle.originX = handle.parent.x
                handle.originY = handle.parent.y
                handle.originW = handle.parent.width
                handle.originH = handle.parent.height
            }
            onPositionChanged: function(mouse) {
                if (!pressed)
                    return
                var pos = mapToItem(pageCanvas, mouse.x, mouse.y)
                var dx = pos.x - handle.pressX
                var dy = pos.y - handle.pressY
                var nextX = handle.originX
                var nextY = handle.originY
                var nextW = handle.originW
                var nextH = handle.originH
                if (handle.growX > 0)
                    nextW = handle.originW + dx
                else {
                    nextX = handle.originX + dx
                    nextW = handle.originW - dx
                }
                if (handle.growY > 0)
                    nextH = handle.originH + dy
                else {
                    nextY = handle.originY + dy
                    nextH = handle.originH - dy
                }
                if (nextW < 48) {
                    if (handle.growX < 0)
                        nextX = handle.originX + handle.originW - 48
                    nextW = 48
                }
                if (nextH < 48) {
                    if (handle.growY < 0)
                        nextY = handle.originY + handle.originH - 48
                    nextH = 48
                }
                if (nextX < 0) {
                    nextW = nextW + nextX
                    nextX = 0
                }
                if (nextY < 0) {
                    nextH = nextH + nextY
                    nextY = 0
                }
                if (nextX + nextW > pageCanvas.width)
                    nextW = Math.max(48, pageCanvas.width - nextX)
                if (nextY + nextH > pageCanvas.height)
                    nextH = Math.max(48, pageCanvas.height - nextY)
                handle.parent.x = nextX
                handle.parent.y = nextY
                handle.parent.width = nextW
                handle.parent.height = nextH
            }
            onReleased: {
                var moved = Math.abs(handle.parent.x - handle.originX) + Math.abs(handle.parent.y - handle.originY)
                var sized = Math.abs(handle.parent.width - handle.originW) + Math.abs(handle.parent.height - handle.originH)
                if (moved < 6 && sized < 6) {
                    handle.parent.x = handle.originX
                    handle.parent.y = handle.originY
                    handle.parent.width = handle.originW
                    handle.parent.height = handle.originH
                    return
                }
                root.resizeBlock(handle.blockIndex,
                    handle.parent.x / pageCanvas.width,
                    handle.parent.y / pageCanvas.height,
                    handle.parent.width / pageCanvas.width,
                    handle.parent.height / pageCanvas.height)
                root.remember()
            }
        }
    }

    component ToolButton: Rectangle {
        property string label: ""
        signal clicked()
        width: visible ? Math.max(72, label.length * 9 + 24) : 0
        height: visible ? 40 : 0
        radius: 8
        color: "#ffffff"
        border.color: "#607d8b"
        opacity: enabled ? 1 : 0.45
        Text {
            anchors.centerIn: parent
            text: parent.label
            color: "#222222"
            font.pixelSize: 16
        }
        MouseArea {
            anchors.fill: parent
            enabled: parent.enabled
            onClicked: parent.clicked()
        }
    }

    component ChoiceButton: Rectangle {
        property string label: ""
        property bool selected: false
        signal clicked()
        width: Math.max(96, label.length * 10 + 20)
        height: 40
        radius: 8
        color: root.paperColor
        border.width: selected ? 3 : 1
        border.color: selected ? root.accentColor : "#607d8b"
        Text {
            anchors.centerIn: parent
            text: parent.label
            color: root.textColor
            font.pixelSize: 18
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component Field: Rectangle {
        id: field
        property string key: ""
        property string label: ""
        property string value: ""
        property int fieldHeight: 44
        width: 700
        height: labelText.implicitHeight + fieldHeight + 6
        color: "transparent"
        Text {
            id: labelText
            text: field.label
            color: root.textColor
            font.pixelSize: 18
        }
        Rectangle {
            y: labelText.implicitHeight + 4
            width: parent.width
            height: field.fieldHeight
            radius: 8
            color: root.paperColor
            border.color: root.accentColor
            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                color: root.textColor
                font.pixelSize: 22
                clip: true
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter
                wrapMode: field.fieldHeight > 48 ? TextInput.WordWrap : TextInput.NoWrap
                onTextEdited: root.noteTyping(field.key, text)
                onEditingFinished: root.commitField(field.key, text)
                Component.onCompleted: text = field.value
                Connections {
                    target: root
                    function onDraftRevisionChanged() {
                        input.text = field.value
                    }
                }
            }
        }
    }
}
