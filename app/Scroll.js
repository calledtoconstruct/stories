.pragma library

function holdMs() {
    return 600
}

function maxOffset(viewHeight, contentHeight) {
    return Math.max(0, contentHeight - viewHeight)
}

function step(contentY, viewHeight, contentHeight, direction, amount) {
    var limit = maxOffset(viewHeight, contentHeight)
    var next = contentY + (direction === "down" ? amount : -amount)
    if (next < 0)
        next = 0
    if (next > limit)
        next = limit
    return next
}

function canScroll(contentY, viewHeight, contentHeight, direction) {
    var limit = maxOffset(viewHeight, contentHeight)
    if (limit <= 0)
        return false
    if (direction === "up")
        return contentY > 0.5
    return contentY < limit - 0.5
}
