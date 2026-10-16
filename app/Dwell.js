.pragma library

function fresh() {
    return {
        prevEdge: -1,
        nextEdge: -1,
        prevIgnore: 0,
        nextIgnore: 0,
        prevSpoke: false,
        nextSpoke: false
    }
}

function copyState(state) {
    if (!state)
        return fresh()
    return {
        prevEdge: state.prevEdge,
        nextEdge: state.nextEdge,
        prevIgnore: state.prevIgnore,
        nextIgnore: state.nextIgnore,
        prevSpoke: state.prevSpoke,
        nextSpoke: state.nextSpoke
    }
}

function reduce(state, event) {
    var next = copyState(state)
    var prev = event.button === "prev"
    var edge = prev ? next.prevEdge : next.nextEdge
    var ignore = prev ? next.prevIgnore : next.nextIgnore
    var spoke = prev ? next.prevSpoke : next.nextSpoke
    var action = ""

    if (event.type === "edge") {
        if (event.timestamp < ignore) {
            return next
        }
        if (edge >= 0) {
            var gap = event.timestamp - edge
            if (gap < 600 || gap >= 600) {
                action = "turn"
                ignore = event.timestamp + 1000
                spoke = false
            }
        }
        edge = event.timestamp
    } else if (event.type === "release") {
        if (edge >= 0 && (event.timestamp - edge) < 600)
            action = "speak"
    } else if (event.type === "tick") {
        if (edge >= 0 && !spoke && (event.timestamp - edge) >= 600) {
            action = "speak"
            spoke = true
        }
    }

    if (prev) {
        next.prevEdge = edge
        next.prevIgnore = ignore
        next.prevSpoke = spoke
    } else {
        next.nextEdge = edge
        next.nextIgnore = ignore
        next.nextSpoke = spoke
    }
    if (action)
        next.action = action
    return next
}
