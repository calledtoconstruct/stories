.pragma library

function encode(index) {
    return JSON.stringify(index)
}

function parse(text) {
    try {
        return JSON.parse(text)
    } catch (e) {
        return null
    }
}
