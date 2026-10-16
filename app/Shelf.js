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
    return { id: bookId, title: title, synopsis: synopsis, cover: cover }
}

function addId(indexText, bookId) {
    var index = JSON.parse(indexText)
    if (!index.books)
        index.books = []
    if (index.books.indexOf(bookId) < 0)
        index.books.push(bookId)
    return JSON.stringify(index, null, 2)
}
