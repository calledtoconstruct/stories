import QtQuick
import "."
import "Theme.js" as Theme
import "Speech.js" as Speech
import "Draft.js" as Draft
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
    property string voiceName: "af_heart"
    property string utteranceText: ""
    property string speechHost: ""
    property string lastHost: ""
    property bool awaitingSpeech: false
    property bool voiceReady: false
    property string voiceStatus: ""
    property double prepareMark: 0
    property int prepareEpoch: 0
    property int prepareWaitMs: 300
    property int readyHoldMs: 1600
    readonly property bool voiceShown: voiceStatus !== "" && !showingLibrary
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
    signal warmRequested(string payload)
    readonly property real fitScale: sheet.fit

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
                            Flow {
                                id: synopsisFlow
                                property string synopsis: modelData.synopsis || ""
                                visible: root.selectedBookId === modelData.id
                                width: bookWords.width
                                spacing: 6
                                Repeater {
                                    model: Speech.phraseWords(synopsisFlow.synopsis, "synopsis")
                                    Item {
                                        width: synopsisText.implicitWidth + 4
                                        height: Math.max(22, synopsisText.implicitHeight)
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 4
                                            color: root.spokenId === modelData.id ? root.accentColor : "transparent"
                                        }
                                        Text {
                                            id: synopsisText
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            color: root.spokenId === modelData.id ? root.paperColor : root.textColor
                                            font.pixelSize: Math.max(22, viewport.frameHeight * 0.04)
                                        }
                                    }
                                }
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
            id: reading
            visible: !root.showingLibrary
            anchors.fill: parent
            readonly property real navW: 104
            readonly property real leftNav: root.canGoPrev ? navW : 0
            readonly property real rightNav: root.canGoNext ? navW : 0

            Column {
                id: topBar
                x: 12
                y: 12
                width: Math.max(0, viewport.frameWidth - 24)
                spacing: 8

                Text {
                    objectName: "titleText"
                    width: parent.width
                    text: root.titleText
                    color: root.textColor
                    font.pixelSize: Math.max(22, root.fontPxValue - 6)
                    wrapMode: Text.WordWrap
                }

                Row {
                    id: voiceLine
                    objectName: "voiceStatus"
                    width: parent.width
                    spacing: 8
                    visible: root.voiceShown
                    height: root.voiceShown ? implicitHeight : 0

                    Rectangle {
                        id: voiceStatusDot
                        objectName: "voiceStatusDot"
                        visible: root.voiceStatus === "preparing"
                        width: Math.max(10, root.fontPxValue * 0.28)
                        height: width
                        radius: width / 2
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: root.voiceStatus === "preparing"
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.35; duration: 700 }
                            NumberAnimation { from: 0.35; to: 1; duration: 700 }
                        }
                    }

                    Text {
                        objectName: "voiceStatusText"
                        width: Math.max(0, voiceLine.width - (voiceStatusDot.visible ? voiceStatusDot.width + voiceLine.spacing : 0))
                        text: root.voiceStatus === "ready" ? "Ready" : "Getting the voice ready"
                        color: root.voiceStatus === "ready" ? root.accentColor : root.textColor
                        font.pixelSize: Math.max(18, root.fontPxValue - 10)
                        wrapMode: Text.WordWrap
                    }
                }

                Text {
                    objectName: "pageWords"
                    visible: false
                    text: root.pageWords
                }
            }

            Column {
                id: bottomBar
                x: 12
                width: Math.max(0, viewport.frameWidth - 24)
                y: Math.max(0, viewport.frameHeight - height - 12)
                spacing: 8

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
                            color: root.spokenId === modelData.id || root.speechHost === modelData.id ? root.accentColor : root.paperColor
                            border.width: 3
                            border.color: root.accentColor
                            Text {
                                id: labelText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.spokenId === modelData.id || root.speechHost === modelData.id ? root.paperColor : root.textColor
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

            NavZone {
                side: "prev"
                visible: root.canGoPrev
                x: 0
                y: pageFrame.y
                width: reading.leftNav
                height: pageFrame.height
            }

            NavZone {
                side: "next"
                visible: root.canGoNext
                x: Math.max(0, viewport.frameWidth - reading.rightNav)
                y: pageFrame.y
                width: reading.rightNav
                height: pageFrame.height
            }

            Item {
                id: pageFrame
                x: reading.leftNav
                y: topBar.y + topBar.height + 8
                width: Math.max(1, viewport.frameWidth - reading.leftNav - reading.rightNav)
                height: Math.max(1, bottomBar.y - y - 8)

                Item {
                    id: sheet
                    objectName: "storySheet"
                    width: 1100
                    height: 700
                    clip: true
                    transformOrigin: Item.TopLeft
                    readonly property real fit: Math.min(pageFrame.width / width, pageFrame.height / height)
                    scale: fit
                    x: Math.round((pageFrame.width - width * scale) / 2)
                    y: Math.round((pageFrame.height - height * scale) / 2)

                    Rectangle {
                        anchors.fill: parent
                        color: root.backgroundColor
                    }

                    Item {
                        id: canvas
                        objectName: "storyCanvas"
                        anchors.fill: parent

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
                        id: paragraphItem
                        objectName: "paragraphBox"
                        x: modelData.rect.x * canvas.width
                        y: modelData.rect.y * canvas.height
                        width: modelData.rect.width * canvas.width
                        height: modelData.rect.height * canvas.height
                        property var lineTops: []

                        function rememberLine(i, yPos) {
                            var tops = lineTops
                            if (tops[i] === yPos)
                                return
                            var next = tops.slice()
                            next[i] = yPos
                            lineTops = next
                        }

                        Item {
                            anchors.fill: parent
                            clip: true

                            Column {
                                id: textCol
                                objectName: "paragraphText"
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 4

                                Repeater {
                                    model: modelData.lines
                                    Item {
                                        id: lineSlot
                                        property var lineWords: modelData.words || []
                                        width: textCol.width
                                        height: Math.max(44, wordFlow.implicitHeight)
                                        onYChanged: paragraphItem.rememberLine(index, y)
                                        onHeightChanged: paragraphItem.rememberLine(index, y)
                                        Component.onCompleted: paragraphItem.rememberLine(index, y)

                                        Flow {
                                            id: wordFlow
                                            width: parent.width
                                            spacing: 6
                                            Repeater {
                                                model: lineSlot.lineWords
                                                Item {
                                                    width: wordText.implicitWidth + 4
                                                    height: Math.max(root.fontPxValue, wordText.implicitHeight)
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
                            }
                        }

                        Repeater {
                            model: modelData.lines
                            ReadMark {
                                objectName: "readLine"
                                kind: "line"
                                markColor: root.accentColor
                                x: -width - 8
                                y: textCol.y + (paragraphItem.lineTops[index] || 0)
                                onClicked: root.readLine(modelData)
                            }
                        }

                        ReadMark {
                            objectName: "readParagraph"
                            kind: "paragraph"
                            markColor: root.accentColor
                            property bool shown: Draft.sentenceCount(modelData.words) > 1
                            visible: shown
                            x: -width - 8
                            y: parent.height + 8
                            onClicked: root.readParagraph(modelData)
                        }
                    }
                }
            }

                }
            }
        }

        Rectangle {
            id: speechBubble
            objectName: "speechBubble"
            property bool shown: root.awaitingSpeech && !root.showingLibrary && root.speechHost !== ""
            visible: shown
            z: 6
            radius: 16
            color: root.paperColor
            border.color: root.accentColor
            border.width: 3
            width: Math.max(160, pageFrame.width * 0.72)
            height: bubbleFlow.implicitHeight + 20
            x: pageFrame.x + Math.max(0, (pageFrame.width - width) / 2)
            y: pageFrame.y + pageFrame.height - height - 12

            Flow {
                id: bubbleFlow
                x: 14
                y: 10
                width: parent.width - 28
                spacing: 6
                Repeater {
                    model: speechBubble.shown ? root.lastTokens : []
                    Item {
                        width: bubbleWord.implicitWidth + 4
                        height: Math.max(28, bubbleWord.implicitHeight)
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: root.spokenId === modelData.id ? root.accentColor : "transparent"
                        }
                        Text {
                            id: bubbleWord
                            anchors.centerIn: parent
                            text: modelData.text
                            color: root.spokenId === modelData.id ? root.paperColor : root.textColor
                            font.pixelSize: 28
                        }
                    }
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
        if (voiceReady && loadedBook) {
            var epoch = beginPrepare()
            var body = JSON.parse(Speech.warmBook(voiceName, loadedBook.pages, index))
            body.epoch = epoch
            warmRequested(JSON.stringify(body))
        } else {
            clearVoice()
        }
    }

    function beginPrepare() {
        prepareEpoch += 1
        prepareMark = Date.now()
        voiceStatus = ""
        readyHold.stop()
        prepareDelay.interval = prepareWaitMs
        prepareDelay.restart()
        return prepareEpoch
    }

    function clearVoice() {
        prepareEpoch += 1
        prepareMark = 0
        voiceStatus = ""
        prepareDelay.stop()
        readyHold.stop()
    }

    function showPreparing() {
        if (!prepareMark)
            return
        voiceStatus = "preparing"
    }

    function noteVoicePage(epoch) {
        if (epoch && epoch !== prepareEpoch)
            return
        if (!prepareMark && voiceStatus !== "preparing")
            return
        var fast = prepareMark && (Date.now() - prepareMark < prepareWaitMs)
        prepareDelay.stop()
        prepareMark = 0
        if (fast && voiceStatus !== "preparing") {
            voiceStatus = ""
            return
        }
        voiceStatus = "ready"
        readyHold.interval = readyHoldMs
        readyHold.restart()
    }

    function voicePrepareEnded() {
        prepareDelay.stop()
        if (voiceStatus === "preparing")
            voiceStatus = ""
    }

    function dismissReady() {
        if (voiceStatus === "ready")
            voiceStatus = ""
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
        clearVoice()
        if (voiceReady)
            warmRequested("")
    }

    Timer {
        id: prepareDelay
        interval: 300
        onTriggered: root.showPreparing()
    }

    Timer {
        id: readyHold
        interval: 1600
        onTriggered: root.dismissReady()
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
            voiceName = book.voice || "af_heart"
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
        voiceName = loaded.book.voice || "af_heart"
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

    function wordIsOnPage(id) {
        if (!id)
            return false
        var list = paragraphs || []
        var p
        var l
        var w
        for (p = 0; p < list.length; p++) {
            var lines = list[p].lines || []
            for (l = 0; l < lines.length; l++) {
                var words = lines[l].words || []
                for (w = 0; w < words.length; w++) {
                    if (words[w].id === id)
                        return true
                }
            }
        }
        return false
    }

    function beginSpeak(tokens) {
        lastTokens = tokens ? tokens.slice() : []
        speakQueue = []
        spokenId = ""
        lastHost = speechHost
        if (!lastTokens.length) {
            awaitingSpeech = false
            utteranceText = ""
            speechHost = ""
            speakRequested("")
            return
        }
        utteranceText = Speech.phrase(lastTokens)
        currentWord = lastTokens[0].text
        lastSpoken = utteranceText
        awaitingSpeech = true
        speakRequested(Speech.speechPayload(voiceName, lastTokens))
    }

    function hearWord(id) {
        if (!awaitingSpeech || !id)
            return
        var token = Speech.wordById(lastTokens, id)
        spokenId = id
        if (token && token.text)
            currentWord = token.text
    }

    function speechFinished() {
        if (!awaitingSpeech)
            return
        awaitingSpeech = false
        spokenId = ""
        speechHost = ""
    }

    function stopSpeaking() {
        speakQueue = []
        awaitingSpeech = false
        spokenId = ""
        speechHost = ""
    }

    function speakText(text, id) {
        if (wordIsOnPage(id)) {
            speechHost = ""
            beginSpeak([{ id: id, text: text }])
            return
        }
        speechHost = id || "spoken"
        beginSpeak(Speech.phraseWords(text, speechHost))
    }

    function readLine(line) {
        speechHost = ""
        beginSpeak(line.words || [])
    }

    function readParagraph(paragraph) {
        speechHost = ""
        beginSpeak(paragraph.words || [])
    }

    function readPage() {
        speechHost = ""
        beginSpeak(pageTokens)
    }

    function repeatLast() {
        if (!lastTokens.length)
            return
        speechHost = lastHost
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
