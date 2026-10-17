.pragma library

function listIds(indexText) {
    var index = JSON.parse(indexText)
    return index.books || []
}

function entry(bookId, bookText) {
    var book = JSON.parse(bookText)
    var title = book.title || bookId
    var synopsis = book.synopsis || title
    var cover = book.cover || ""
    var voice = book.voice || "af_heart"
    return { id: bookId, title: title, synopsis: synopsis, cover: cover, voice: voice }
}

function addId(indexText, bookId) {
    var index = JSON.parse(indexText)
    if (!index.books)
        index.books = []
    if (index.books.indexOf(bookId) < 0)
        index.books.push(bookId)
    return JSON.stringify(index, null, 2)
}

function replaceId(indexText, oldId, newId) {
    if (!oldId || oldId === newId)
        return addId(indexText, newId)
    var index = JSON.parse(indexText)
    var books = index.books || []
    var next = []
    var i
    for (i = 0; i < books.length; i++) {
        if (books[i] === oldId || books[i] === newId)
            continue
        next.push(books[i])
    }
    next.push(newId)
    index.books = next
    return JSON.stringify(index, null, 2)
}
