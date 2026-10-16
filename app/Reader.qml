import QtQuick
import "Theme.js" as Theme
import "Speech.js" as Speech
import "Dwell.js" as Dwell
import "Place.js" as Place
import "Shelf.js" as Shelf
import "Scroll.js" as Scroll

Item {
    id: root
    implicitWidth: 1100
    implicitHeight: 700

    property string titleText: "No book open"
    property string pageWords: ""
    property string currentWord: ""
    property int fontPxValue: 22
    property string dwellAction: ""
    property int pageIndex: 0
    property int wordIndex: 0
    property var loadedBook: null
    property var dwellState: null
    property string placeText: ""
    property var bookIds: []
    property var library: []
    property bool showingLibrary: false
    property string selectedBookId: ""
    property var paragraphs: []
    property var pictures: []
    property var hotspots: []
    property var pageTokens: []
    property var speakQueue: []
    property var lastTokens: []
    property string spokenId: ""
    property string lastSpoken: ""
    property bool awaitingSpeech: false
    property bool voiceReady: false
    property string armedButton: ""
    property double navIgnore: 0
    property color accentColor: "#4caf50"
    property color textColor: "#222222"
    property color paperColor: "#ffffff"
    property color backgroundColor: "#f5f5f5"
    readonly property bool canGoPrev: loadedBook && pageIndex > 0
    readonly property bool canGoNext: loadedBook && loadedBook.pages && pageIndex + 1 < loadedBook.pages.length
    readonly property bool canScrollUp: Scroll.canScroll(libraryView.contentY, libraryView.height, libraryView.contentHeight, "up")
    readonly property bool canScrollDown: Scroll.canScroll(libraryView.contentY, libraryView.height, libraryView.contentHeight, "down")

    signal openRequested(string bookId)
    signal speakRequested(string text)
    readonly property real fitScale: sheet.fit

    Timer {
        id: advanceTimer
        onTriggered: root.speechFinished()
    }

    Item {
        id: viewport
        anchors.fill: parent
        readonly property real frameWidth: root.width > 1 ? root.width : root.implicitWidth
        readonly property real frameHeight: root.height > 1 ? root.height : root.implicitHeight

        Rectangle {
            anchors.fill: parent
            color: root.backgroundColor
        }

        Item {
            id: libraryFrame
            visible: root.showingLibrary
            anchors.fill: parent

            ScrollEdge {
                id: scrollUp
                direction: "up"
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
            }

        Flickable {
            id: libraryView
            objectName: "shelf"
            anchors.top: scrollUp.bottom
            anchors.bottom: scrollDown.top
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            contentWidth: width
            contentHeight: libraryColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: libraryColumn
                width: libraryView.width
                spacing: 20
                topPadding: 28
                bottomPadding: 28
                leftPadding: 36
                rightPadding: 36

                Text {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: root.library.length ? "Stories" : "No books"
                    color: root.textColor
                    font.pixelSize: Math.max(32, viewport.frameHeight * 0.07)
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.library
                    Item {
                        readonly property real iconSize: Math.max(72, viewport.frameHeight * 0.12)
                        width: libraryColumn.width - libraryColumn.leftPadding - libraryColumn.rightPadding
                        height: Math.max(iconSize, bookWords.implicitHeight) + 8

                        Image {
                            id: bookIcon
                            width: iconSize
                            height: iconSize
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectCrop
                            source: root.imageSource(modelData.cover)
                            asynchronous: true
                        }

                        Column {
                            id: bookWords
                            width: parent.width - bookIcon.width - 18
                            anchors.left: bookIcon.right
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                id: bookTitle
                                width: bookWords.width
                                text: modelData.title
                                color: root.selectedBookId === modelData.id ? root.accentColor : root.textColor
                                font.pixelSize: Math.max(28, viewport.frameHeight * 0.055)
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                id: bookSynopsis
                                visible: root.selectedBookId === modelData.id
                                width: bookWords.width
                                text: modelData.synopsis
                                color: root.textColor
                                font.pixelSize: Math.max(22, viewport.frameHeight * 0.04)
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.chooseBook(modelData)
                        }
                    }
                }
            }
            }

            ScrollEdge {
                id: scrollDown
                direction: "down"
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }

            Rectangle {
                visible: libraryView.contentHeight > libraryView.height + 1
                anchors.right: parent.right
                anchors.rightMargin: 10
                width: 8
                radius: 4
                color: root.accentColor
                opacity: 0.75
                y: libraryView.y + libraryView.visibleArea.yPosition * libraryView.height
                height: Math.max(28, libraryView.visibleArea.heightRatio * libraryView.height)
            }
        }

        Item {
            id: sheet
            visible: !root.showingLibrary
            width: root.implicitWidth
            height: root.implicitHeight
            transformOrigin: Item.TopLeft
            readonly property real fit: Math.min(viewport.frameWidth / width, viewport.frameHeight / height)
            scale: fit
            x: Math.round((viewport.frameWidth - width * fit) / 2)
            y: Math.round((viewport.frameHeight - height * fit) / 2)

    Row {
        anchors.fill: parent

        NavZone {
            side: "prev"
            visible: root.canGoPrev
            width: root.canGoPrev ? sheet.width * 0.12 : 0
            height: sheet.height
        }

        Item {
            id: stage
            width: sheet.width - (root.canGoPrev ? sheet.width * 0.12 : 0) - (root.canGoNext ? sheet.width * 0.12 : 0)
            height: sheet.height

            Column {
                id: pageColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    objectName: "titleText"
                    width: parent.width
                    text: root.titleText
                    color: root.textColor
                    font.pixelSize: Math.max(22, root.fontPxValue - 6)
                    wrapMode: Text.WordWrap
                }

                Text {
                    objectName: "pageWords"
                    visible: false
                    text: root.pageWords
                }

                Text {
                    objectName: "currentWord"
                    width: parent.width
                    text: root.currentWord
                    color: root.accentColor
                    font.pixelSize: root.fontPxValue
                    wrapMode: Text.WordWrap
                }

                Item {
                    id: canvas
                    width: pageColumn.width
                    height: Math.max(240, pageColumn.height - 210)

                    Repeater {
                        model: root.pictures
                        Item {
                            x: modelData.rect.x * canvas.width
                            y: modelData.rect.y * canvas.height
                            width: modelData.rect.width * canvas.width
                            height: modelData.rect.height * canvas.height
                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: root.imageSource(modelData.src)
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.speakText(modelData.speak, "picture")
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.paragraphs
                        Item {
                            x: modelData.rect.x * canvas.width
                            y: modelData.rect.y * canvas.height
                            width: modelData.rect.width * canvas.width
                            height: modelData.rect.height * canvas.height
                            clip: true

                            Column {
                                anchors.fill: parent
                                spacing: 4
                                Repeater {
                                    model: modelData.lines
                                    Row {
                                        spacing: 6
                                        width: parent.width
                                        ReadIcon {
                                            id: lineIcon
                                            kind: "line"
                                            onClicked: root.readLine(modelData)
                                        }
                                        Flow {
                                            width: Math.max(0, parent.width - lineIcon.width - 6)
                                            spacing: 6
                                            Repeater {
                                                model: modelData.words
                                                Item {
                                                    width: wordText.implicitWidth + 10
                                                    height: Math.max(root.fontPxValue + 6, wordText.implicitHeight + 6)
                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: 4
                                                        color: root.spokenId === modelData.id ? root.accentColor : "transparent"
                                                        border.width: 0
                                                    }
                                                    Text {
                                                        id: wordText
                                                        anchors.centerIn: parent
                                                        text: modelData.text
                                                        color: root.spokenId === modelData.id ? root.paperColor : root.textColor
                                                        font.pixelSize: root.fontPxValue
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: root.speakText(modelData.text, modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                ReadIcon {
                                    kind: "paragraph"
                                    onClicked: root.readParagraph(modelData)
                                }
                            }
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 8
                    visible: root.hotspots.length > 0
                    Repeater {
                        model: root.hotspots
                        Rectangle {
                            width: Math.max(120, labelText.implicitWidth + 28)
                            height: 52
                            radius: 12
                            color: root.spokenId === modelData.id ? root.accentColor : root.paperColor
                            border.width: 3
                            border.color: root.accentColor
                            Text {
                                id: labelText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.spokenId === modelData.id ? root.paperColor : root.textColor
                                font.pixelSize: 20
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.speakText(modelData.speak, modelData.id)
                            }
                        }
                    }
                }

                Row {
                    spacing: 12
                    PlayButton {
                        objectName: "readPage"
                        label: "Read page"
                        onClicked: root.readPage()
                    }
                    PlayButton {
                        objectName: "repeat"
                        label: "Repeat"
                        onClicked: root.repeatLast()
                    }
                }

            }
        }

        NavZone {
            side: "next"
            visible: root.canGoNext
            width: root.canGoNext ? sheet.width * 0.12 : 0
            height: sheet.height
        }
    }
        }
    }

    function imageSource(path) {
        if (!path)
            return ""
        if (path.indexOf("/") === 0)
            return "file://" + path
        return path
    }

    function pageImagePath() {
        if (!pictures.length)
            return ""
        return pictures[0].src || ""
    }

    function showPage(index) {
        stopSpeaking()
        armedButton = ""
        var page = loadedBook.pages[index]
        var model = Speech.reading(page)
        pageIndex = index
        wordIndex = 0
        paragraphs = model.paragraphs
        pictures = model.pictures
        hotspots = model.hotspots
        pageTokens = model.words
        pageWords = Speech.pageWords(page).join(" ")
        currentWord = pageTokens.length ? pageTokens[0].text : ""
        placeText = Place.encode({ page: index })
    }

    function showLibrary(entries) {
        stopSpeaking()
        if (voiceReady)
            speakRequested("")
        library = entries || []
        selectedBookId = ""
        showingLibrary = true
        loadedBook = null
        titleText = "Stories"
        pageWords = ""
        currentWord = ""
        paragraphs = []
        pictures = []
        hotspots = []
        pageTokens = []
    }

    function scrollLibrary(direction) {
        var amount = Math.max(88, viewport.frameHeight * 0.16)
        libraryView.contentY = Scroll.step(libraryView.contentY, libraryView.height, libraryView.contentHeight, direction, amount)
    }

    function chooseBook(book) {
        if (!book || !book.id)
            return
        if (selectedBookId !== book.id) {
            selectedBookId = book.id
            speakText(book.synopsis || book.title || book.id, "synopsis")
            return
        }
        showingLibrary = false
        openRequested(book.id)
    }

    function showBook(loaded) {
        stopSpeaking()
        if (voiceReady)
            speakRequested("")
        showingLibrary = false
        loadedBook = loaded
        titleText = loaded.book.title
        fontPxValue = Theme.fontPx(loaded.book.age_band, loaded.theme.font_scale)
        backgroundColor = loaded.theme.background || "#f5f5f5"
        paperColor = loaded.theme.paper || "#ffffff"
        textColor = loaded.theme.text || "#222222"
        accentColor = loaded.theme.accent || "#1565c0"
        var saved = Place.parse(placeText)
        var index = saved && saved.page >= 0 ? saved.page : 0
        if (index >= loaded.pages.length)
            index = 0
        showPage(index)
    }

    function beginSpeak(tokens) {
        lastTokens = tokens ? tokens.slice() : []
        speakQueue = lastTokens.slice()
        pump()
    }

    function pump() {
        advanceTimer.stop()
        if (!speakQueue.length) {
            awaitingSpeech = false
            spokenId = ""
            return
        }
        var item = speakQueue[0]
        speakQueue = speakQueue.slice(1)
        spokenId = item.id
        currentWord = item.text
        lastSpoken = item.text
        awaitingSpeech = true
        speakRequested(item.text)
        advanceTimer.interval = voiceReady ? 8000 : 30
        advanceTimer.restart()
    }

    function speechFinished() {
        if (!awaitingSpeech)
            return
        awaitingSpeech = false
        pump()
    }

    function stopSpeaking() {
        speakQueue = []
        awaitingSpeech = false
        advanceTimer.stop()
        spokenId = ""
    }

    function speakText(text, id) {
        beginSpeak([{ id: id, text: text }])
    }

    function readLine(line) {
        beginSpeak(line.words || [])
    }

    function readParagraph(paragraph) {
        beginSpeak(paragraph.words || [])
    }

    function readPage() {
        beginSpeak(pageTokens)
    }

    function repeatLast() {
        if (lastTokens.length)
            beginSpeak(lastTokens.slice())
    }

    function pressNav(button) {
        if (button === "next" && !canGoNext)
            return
        if (button === "prev" && !canGoPrev)
            return
        var now = Date.now()
        if (now < navIgnore)
            return
        if (armedButton !== button) {
            armedButton = button
            return
        }
        armedButton = ""
        navIgnore = now + 1000
        if (!loadedBook)
            return
        var count = loadedBook.pages.length
        if (button === "next" && pageIndex + 1 < count)
            showPage(pageIndex + 1)
        if (button === "prev" && pageIndex > 0)
            showPage(pageIndex - 1)
    }

    function note(button, type, timestamp) {
        dwellState = Dwell.reduce(dwellState, {
            button: button,
            type: type,
            timestamp: timestamp
        })
        dwellAction = dwellState.action || ""
    }

    function turn(button) {
        note(button, "edge", 0)
        var second = note(button, "edge", 200)
        if (dwellAction !== "turn" || !loadedBook)
            return
        var count = loadedBook.pages.length
        if (button === "next" && canGoNext)
            showPage(pageIndex + 1)
        if (button === "prev" && canGoPrev)
            showPage(pageIndex - 1)
        return second
    }

    function showShelf(indexText) {
        bookIds = Shelf.listIds(indexText)
    }

    function hotspotSpeak(hotspot) {
        return Speech.hotspotText(hotspot)
    }

    component ScrollEdge: Item {
        property string direction: "down"
        property real held: 0
        property real progress: 0
        readonly property bool shown: direction === "down" ? root.canScrollDown : root.canScrollUp
        height: shown ? Math.max(72, viewport.frameHeight * 0.12) : 0
        visible: shown

        Rectangle {
            anchors.fill: parent
            color: edgeArea.containsMouse ? root.accentColor : root.paperColor
        }

        Item {
            width: 22
            height: 22
            anchors.centerIn: parent
            rotation: direction === "up" ? -90 : 90
            Rectangle {
                width: 14
                height: 4
                radius: 2
                y: 4
                color: edgeArea.containsMouse ? root.paperColor : root.accentColor
                transformOrigin: Item.Left
                rotation: -42
            }
            Rectangle {
                width: 14
                height: 4
                radius: 2
                y: 12
                color: edgeArea.containsMouse ? root.paperColor : root.accentColor
                transformOrigin: Item.Left
                rotation: 42
            }
        }

        Rectangle {
            visible: direction === "down"
            anchors.left: parent.left
            anchors.top: parent.top
            height: 8
            width: parent.width * progress
            color: root.accentColor
        }
        Rectangle {
            visible: direction === "up"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 8
            width: parent.width * progress
            color: root.accentColor
        }

        Timer {
            interval: 50
            repeat: true
            running: edgeArea.containsMouse && shown && root.showingLibrary
            onTriggered: {
                parent.held += 50
                parent.progress = Math.min(1, parent.held / Scroll.holdMs())
                if (parent.held >= Scroll.holdMs()) {
                    root.scrollLibrary(parent.direction)
                    parent.held = 0
                    parent.progress = 0
                }
            }
        }

        MouseArea {
            id: edgeArea
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (!containsMouse) {
                    parent.held = 0
                    parent.progress = 0
                }
            }
            onClicked: {
                root.scrollLibrary(parent.direction)
                parent.held = 0
                parent.progress = 0
            }
        }
    }

    component ReadIcon: Item {
        property string kind: "line"
        signal clicked()
        width: 52
        height: 44
        opacity: iconArea.containsPress ? 0.55 : 1

        Item {
            id: chevron
            width: 14
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            Rectangle {
                width: 10
                height: 3
                radius: 1
                color: root.accentColor
                y: 4
                transformOrigin: Item.Left
                rotation: -42
            }
            Rectangle {
                width: 10
                height: 3
                radius: 1
                color: root.accentColor
                y: 9
                transformOrigin: Item.Left
                rotation: 42
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: chevron.right
            anchors.leftMargin: 6
            spacing: 4
            Repeater {
                model: kind === "paragraph" ? 3 : 1
                Rectangle {
                    width: 26
                    height: 3
                    radius: 1
                    color: root.accentColor
                }
            }
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    component PlayButton: Rectangle {
        property string label: ""
        signal clicked()
        width: Math.max(88, label.length * 12 + 24)
        height: 56
        radius: 12
        color: root.paperColor
        border.color: root.accentColor
        border.width: 3
        Text {
            anchors.centerIn: parent
            text: parent.label
            color: root.textColor
            font.pixelSize: 20
        }
        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    component NavZone: Rectangle {
        property string side: "next"
        color: root.armedButton === side ? root.accentColor : root.backgroundColor
        border.color: root.accentColor
        border.width: 4
        Text {
            anchors.centerIn: parent
            width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: root.armedButton === side ? root.paperColor : root.textColor
            font.pixelSize: 28
            text: root.armedButton === side
                  ? (side === "next" ? "Next\nagain" : "Back\nagain")
                  : (side === "next" ? "Next" : "Back")
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.pressNav(side)
        }
    }
}
