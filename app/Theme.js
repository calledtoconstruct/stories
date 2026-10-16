.pragma library

function fontPx(ageBand, fontScale) {
    var base = 0
    if (ageBand === "early")
        base = 36
    else if (ageBand === "growing")
        base = 28
    else if (ageBand === "school")
        base = 22
    return base * fontScale
}
