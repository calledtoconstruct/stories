.pragma library
.import "Layout.js" as Layout

function pageWords(page) {
    var words = []
    var blocks = page && page.blocks ? page.blocks : []
    var b, c, l, w
    for (b = 0; b < blocks.length; b++) {
        if (blocks[b].type !== "text" || !blocks[b].content)
            continue
        for (c = 0; c < blocks[b].content.length; c++) {
            var lines = blocks[b].content[c].lines || []
            for (l = 0; l < lines.length; l++) {
                var lineWords = lines[l].words || []
                for (w = 0; w < lineWords.length; w++)
                    words.push(lineWords[w].text)
            }
        }
    }
    return words
}

function hotspotText(hotspot) {
    if (!hotspot)
        return ""
    if (hotspot.speak_text)
        return hotspot.speak_text
    if (hotspot.label)
        return hotspot.label
    return ""
}

function joinText(tokens) {
    var parts = []
    var i
    for (i = 0; i < tokens.length; i++) {
        if (tokens[i].text)
            parts.push(tokens[i].text)
    }
    return parts.join(" ")
}

function hotspotBox(polygon) {
    var minX = 1
    var minY = 1
    var maxX = 0
    var maxY = 0
    var i
    var points = polygon || []
    for (i = 0; i < points.length; i++) {
        minX = Math.min(minX, points[i][0])
        minY = Math.min(minY, points[i][1])
        maxX = Math.max(maxX, points[i][0])
        maxY = Math.max(maxY, points[i][1])
    }
    if (!points.length)
        return { x: 0, y: 0, width: 1, height: 1 }
    return { x: minX, y: minY, width: Math.max(0.08, maxX - minX), height: Math.max(0.08, maxY - minY) }
}

function reading(page) {
    var paragraphs = []
    var pictures = []
    var words = []
    var placed = Layout.layoutBlocks(page && page.blocks ? page.blocks : [])
    var b, c, l, w, n
    n = 0
    for (b = 0; b < placed.length; b++) {
        var block = placed[b].block
        var blockRect = placed[b].rect
        if (block.type === "image") {
            pictures.push({
                src: block.resolvedSrc || block.src || "",
                alt: block.alt || "picture",
                speak: block.speak_text || block.alt || "picture",
                rect: blockRect
            })
            continue
        }
        if (block.type !== "text" || !block.content)
            continue
        for (c = 0; c < block.content.length; c++) {
            var linesIn = block.content[c].lines || []
            var lines = []
            var paragraphWords = []
            for (l = 0; l < linesIn.length; l++) {
                var lineWords = linesIn[l].words || []
                var tokens = []
                for (w = 0; w < lineWords.length; w++) {
                    n = n + 1
                    var token = {
                        id: "w" + n,
                        text: lineWords[w].text || ""
                    }
                    tokens.push(token)
                    paragraphWords.push(token)
                    words.push(token)
                }
                lines.push({
                    id: "p" + paragraphs.length + "l" + l,
                    words: tokens,
                    text: joinText(tokens)
                })
            }
            var paragraphRect = blockRect
            if (block.content.length > 1) {
                var slice = blockRect.height / block.content.length
                paragraphRect = {
                    x: blockRect.x,
                    y: blockRect.y + c * slice,
                    width: blockRect.width,
                    height: slice * 0.92
                }
            }
            if (block.content[c].rect)
                paragraphRect = Layout.rectOf(block.content[c]) || paragraphRect
            paragraphs.push({
                id: "p" + paragraphs.length,
                lines: lines,
                words: paragraphWords,
                text: joinText(paragraphWords),
                rect: paragraphRect
            })
        }
    }
    var hotspots = []
    var spots = page && page.hotspots ? page.hotspots : []
    var h
    for (h = 0; h < spots.length; h++) {
        hotspots.push({
            id: spots[h].id || ("h" + h),
            label: spots[h].label || "picture",
            speak: hotspotText(spots[h]),
            box: hotspotBox(spots[h].polygon)
        })
    }
    return { paragraphs: paragraphs, pictures: pictures, hotspots: hotspots, words: words }
}
