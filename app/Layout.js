.pragma library

function pictureLine(blocks) {
    var result = []
    var imageBlock = null
    var textBlock = null
    var i
    for (i = 0; i < blocks.length; i++) {
        if (!imageBlock && blocks[i].type === "image")
            imageBlock = blocks[i]
        if (!textBlock && blocks[i].type === "text")
            textBlock = blocks[i]
    }
    if (imageBlock)
        result.push(imageBlock)
    if (textBlock)
        result.push(textBlock)
    return result
}

function clampSize(width, height) {
    return {
        width: Math.max(width, 48),
        height: Math.max(height, 48)
    }
}

function clamp01(value) {
    if (value < 0)
        return 0
    if (value > 1)
        return 1
    return value
}

function rectOf(block) {
    var rect = block && block.rect
    if (!rect || !(rect.width > 0) || !(rect.height > 0))
        return null
    return {
        x: clamp01(rect.x || 0),
        y: clamp01(rect.y || 0),
        width: clamp01(rect.width),
        height: clamp01(rect.height)
    }
}

function defaultImage(textCount) {
    if (!textCount)
        return { x: 0.08, y: 0.08, width: 0.84, height: 0.84 }
    return { x: 0.48, y: 0.06, width: 0.48, height: 0.88 }
}

function defaultText(index, textCount, imageCount) {
    var height = Math.min(0.34, 0.8 / Math.max(textCount, 1))
    return {
        x: 0.04,
        y: 0.06 + index * (height + 0.04),
        width: imageCount ? 0.4 : 0.92,
        height: height
    }
}

function layoutBlocks(blocks) {
    var list = blocks || []
    var imageCount = 0
    var textCount = 0
    var i
    for (i = 0; i < list.length; i++) {
        if (list[i].type === "image")
            imageCount = imageCount + 1
        else if (list[i].type === "text")
            textCount = textCount + 1
    }
    var seenImage = 0
    var seenText = 0
    var placed = []
    for (i = 0; i < list.length; i++) {
        var block = list[i]
        var rect = rectOf(block)
        if (!rect) {
            if (block.type === "image")
                rect = defaultImage(textCount)
            else
                rect = defaultText(seenText, textCount, imageCount)
        }
        if (block.type === "image")
            seenImage = seenImage + 1
        else if (block.type === "text")
            seenText = seenText + 1
        placed.push({ block: block, rect: rect })
    }
    return placed
}

function moveRect(rect, x, y) {
    var width = rect && rect.width ? rect.width : 0.3
    var height = rect && rect.height ? rect.height : 0.2
    return {
        x: clamp01(Math.min(x, 1 - width)),
        y: clamp01(Math.min(y, 1 - height)),
        width: width,
        height: height
    }
}

function resizeRect(rect, x, y, width, height) {
    var minW = 0.05
    var minH = 0.07
    var nx = clamp01(x)
    var ny = clamp01(y)
    var w = width > minW ? width : minW
    var h = height > minH ? height : minH
    if (nx + w > 1) {
        if (nx > 1 - minW)
            nx = 1 - minW
        w = 1 - nx
    }
    if (ny + h > 1) {
        if (ny > 1 - minH)
            ny = 1 - minH
        h = 1 - ny
    }
    return { x: nx, y: ny, width: w, height: h }
}
