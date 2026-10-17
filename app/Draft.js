.pragma library

function clone(value) {
    return JSON.parse(JSON.stringify(value))
}

function slug(title) {
    var text = String(title || "").toLowerCase()
    var out = ""
    var dash = false
    var i
    var ch
    for (i = 0; i < text.length; i++) {
        ch = text.charAt(i)
        if ((ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9")) {
            out += ch
            dash = false
        } else if (!dash && out.length) {
            out += "-"
            dash = true
        }
    }
    if (out.charAt(out.length - 1) === "-")
        out = out.substring(0, out.length - 1)
    return out || "new-book"
}

function validId(value) {
    var text = String(value || "")
    var i
    var ch
    var dash = false
    if (!text.length)
        return false
    for (i = 0; i < text.length; i++) {
        ch = text.charAt(i)
        if ((ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9")) {
            dash = false
            continue
        }
        if (ch === "-" && i > 0 && i < text.length - 1 && !dash)
            dash = true
        else
            return false
    }
    return true
}

function validColor(value) {
    var text = String(value || "")
    var i
    var ch
    if (text.charAt(0) !== "#")
        return false
    if (text.length !== 4 && text.length !== 7)
        return false
    for (i = 1; i < text.length; i++) {
        ch = text.charAt(i).toLowerCase()
        if (!((ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f")))
            return false
    }
    return true
}

function validScale(value) {
    var n = Number(value)
    return isFinite(n) && n > 0 && n <= 4
}

function cleanPage(page) {
    var copy = clone(page || {})
    var blocks = copy.blocks || []
    var i
    for (i = 0; i < blocks.length; i++)
        delete blocks[i].resolvedSrc
    return copy
}

function wordList(block) {
    var words = []
    var content = (block && block.content) || []
    var c
    var l
    var w
    for (c = 0; c < content.length; c++) {
        var lines = content[c].lines || []
        for (l = 0; l < lines.length; l++) {
            var lineWords = lines[l].words || []
            for (w = 0; w < lineWords.length; w++) {
                if (lineWords[w] && lineWords[w].text)
                    words.push(lineWords[w])
            }
        }
    }
    return words
}

function endsSentence(text) {
    var s = String(text || "")
    var i = s.length - 1
    var ch
    while (i >= 0) {
        ch = s.charAt(i)
        if (ch === "\"" || ch === "'" || ch === ")" || ch === "]" || ch === "”" || ch === "’")
            i = i - 1
        else
            break
    }
    if (i < 0)
        return false
    ch = s.charAt(i)
    return ch === "." || ch === "!" || ch === "?"
}

function sentenceCount(words) {
    var list = words || []
    var n = 0
    var i
    for (i = 0; i < list.length; i++) {
        var word = list[i]
        var text = word && word.text ? word.text : ""
        if (endsSentence(text))
            n = n + 1
    }
    return n
}

function paragraphText(block) {
    var words = wordList(block)
    var parts = []
    var i
    for (i = 0; i < words.length; i++)
        parts.push(words[i].text)
    return parts.join(" ")
}

function writeParagraph(block, text) {
    var oldWords = wordList(block)
    var maxId = 0
    var i
    for (i = 0; i < oldWords.length; i++) {
        var digits = String(oldWords[i].id || "").replace(/[^0-9]/g, "")
        var n = parseInt(digits, 10)
        if (n > maxId)
            maxId = n
    }
    var raw = String(text || "").split(/\s+/)
    var parts = []
    for (i = 0; i < raw.length; i++) {
        if (raw[i])
            parts.push(raw[i])
    }
    var lines = []
    var current = []
    for (i = 0; i < parts.length; i++) {
        var word
        if (i < oldWords.length) {
            word = clone(oldWords[i])
            word.text = parts[i]
        } else {
            maxId += 1
            word = { id: "w" + maxId, text: parts[i], highlight: false }
        }
        current.push(word)
        var last = parts[i].charAt(parts[i].length - 1)
        if (last === "." || last === "!" || last === "?") {
            lines.push({ words: current })
            current = []
        }
    }
    if (current.length || !lines.length)
        lines.push({ words: current })
    var copy = clone(block || { type: "text" })
    copy.type = "text"
    delete copy.resolvedSrc
    copy.content = [{ lines: lines }]
    return copy
}

function blankPage(name) {
    var id = String(name || "p01.json").replace(".json", "")
    return {
        id: id,
        blocks: [{
            type: "text",
            rect: { x: 0.08, y: 0.12, width: 0.84, height: 0.28 },
            content: [{ lines: [{ words: [] }] }]
        }],
        hotspots: []
    }
}

function nextPageName(pageBodies) {
    var max = 0
    var list = pageBodies || []
    var i
    for (i = 0; i < list.length; i++) {
        var digits = String(list[i].name || "").replace(/[^0-9]/g, "")
        var n = parseInt(digits, 10)
        if (n > max)
            max = n
    }
    var next = max + 1
    return (next < 10 ? "p0" : "p") + next + ".json"
}

function imageBlock(src) {
    return {
        type: "image",
        src: src || "",
        alt: "",
        speak_text: "",
        rect: { x: 0.08, y: 0.08, width: 0.84, height: 0.7 }
    }
}

function imageName(sourcePath, serial) {
    var base = String(sourcePath || "").split("/").pop().split("\\").pop()
    base = base.replace(/[^A-Za-z0-9._-]/g, "")
    if (!base || base.charAt(0) === ".")
        base = "image.jpg"
    return "pic-" + serial + "-" + base
}

function begin(snapshot) {
    return { drafts: [clone(snapshot)], index: 0 }
}

function current(history) {
    return clone(history.drafts[history.index])
}

function same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b)
}

function commit(history, snapshot) {
    var drafts = history.drafts.slice(0, history.index + 1)
    if (same(drafts[drafts.length - 1], snapshot))
        return history
    drafts.push(clone(snapshot))
    return { drafts: drafts, index: drafts.length - 1 }
}

function canUndo(history) {
    return !!(history && history.index > 0)
}

function canRedo(history) {
    return !!(history && history.index + 1 < history.drafts.length)
}

function undo(history) {
    if (!canUndo(history))
        return history
    return { drafts: history.drafts, index: history.index - 1 }
}

function redo(history) {
    if (!canRedo(history))
        return history
    return { drafts: history.drafts, index: history.index + 1 }
}
