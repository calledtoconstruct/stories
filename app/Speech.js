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

function phrase(tokens) {
    return joinText(tokens || [])
}

function phraseWords(text, host) {
    var parts = String(text || "").split(/\s+/)
    var words = []
    var i
    var n = 0
    for (i = 0; i < parts.length; i++) {
        if (!parts[i])
            continue
        n = n + 1
        words.push({ id: (host || "spoken") + ":" + n, text: parts[i] })
    }
    return words
}

function voiceName(book) {
    if (book && book.voice)
        return book.voice
    return "af_heart"
}

function wordById(tokens, id) {
    var i
    var list = tokens || []
    for (i = 0; i < list.length; i++) {
        if (list[i].id === id)
            return list[i]
    }
    return null
}

function speechPayload(voice, tokens) {
    var words = []
    var list = tokens || []
    var i
    for (i = 0; i < list.length; i++) {
        words.push({
            id: list[i].id || "",
            text: list[i].text || ""
        })
    }
    return JSON.stringify({
        voice: voice || "af_heart",
        words: words
    })
}

function addPhrase(phrases, seen, words) {
    if (!words || !words.length)
        return
    var key = phrase(words)
    if (!key || seen[key])
        return
    seen[key] = true
    var copy = []
    var i
    for (i = 0; i < words.length; i++)
        copy.push({ id: words[i].id || "", text: words[i].text || "" })
    phrases.push(copy)
}

function addPagePhrases(phrases, seen, model) {
    var page = model || {}
    addPhrase(phrases, seen, page.words)
    var paragraphs = page.paragraphs || []
    var p, l
    for (p = 0; p < paragraphs.length; p++) {
        addPhrase(phrases, seen, paragraphs[p].words)
        var lines = paragraphs[p].lines || []
        for (l = 0; l < lines.length; l++)
            addPhrase(phrases, seen, lines[l].words)
    }
    var pictures = page.pictures || []
    for (p = 0; p < pictures.length; p++)
        addPhrase(phrases, seen, phraseWords(pictures[p].speak || "", "picture"))
    var hotspots = page.hotspots || []
    for (p = 0; p < hotspots.length; p++)
        addPhrase(phrases, seen, phraseWords(hotspots[p].speak || "", hotspots[p].id || "spot"))
}

function addPageWords(phrases, seen, model) {
    var paragraphs = (model || {}).paragraphs || []
    var p, l, w
    for (p = 0; p < paragraphs.length; p++) {
        var lines = paragraphs[p].lines || []
        for (l = 0; l < lines.length; l++) {
            var lineWords = lines[l].words || []
            for (w = 0; w < lineWords.length; w++)
                addPhrase(phrases, seen, [lineWords[w]])
        }
    }
}

function warmPayload(voice, reading) {
    var phrases = []
    var seen = {}
    var model = reading || {}
    var paragraphs = model.paragraphs || []
    var p, l
    for (p = 0; p < paragraphs.length; p++) {
        var lines = paragraphs[p].lines || []
        for (l = 0; l < lines.length; l++)
            addPhrase(phrases, seen, lines[l].words)
    }
    var pictures = model.pictures || []
    for (p = 0; p < pictures.length; p++)
        addPhrase(phrases, seen, phraseWords(pictures[p].speak || "", "picture"))
    var hotspots = model.hotspots || []
    for (p = 0; p < hotspots.length; p++)
        addPhrase(phrases, seen, phraseWords(hotspots[p].speak || "", hotspots[p].id || "spot"))
    addPageWords(phrases, seen, model)
    return JSON.stringify({
        warm: true,
        voice: voice || "af_heart",
        phrases: phrases
    })
}

function warmBook(voice, pages, index) {
    var list = pages || []
    var start = index || 0
    if (start < 0 || start >= list.length)
        start = 0
    var order = []
    var i
    if (list.length)
        order.push(start)
    for (i = start + 1; i < list.length; i++)
        order.push(i)
    for (i = start - 1; i >= 0; i--)
        order.push(i)
    var models = []
    for (i = 0; i < order.length; i++)
        models.push(reading(list[order[i]]))
    var phrases = []
    var seen = {}
    var pagePhrases = 0
    if (models.length) {
        addPagePhrases(phrases, seen, models[0])
        pagePhrases = phrases.length
    }
    for (i = 1; i < models.length; i++)
        addPagePhrases(phrases, seen, models[i])
    for (i = 0; i < models.length; i++)
        addPageWords(phrases, seen, models[i])
    return JSON.stringify({
        warm: true,
        voice: voice || "af_heart",
        page_phrases: pagePhrases,
        phrases: phrases
    })
}
