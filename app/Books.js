.pragma library

function loadFromText(bookText, themeText, pageTexts, bookFolder) {
    var book = JSON.parse(bookText)
    var theme = JSON.parse(themeText)
    var pages = []
    var i, b
    for (i = 0; i < pageTexts.length; i++) {
        var page = JSON.parse(pageTexts[i])
        if (bookFolder && page.blocks) {
            for (b = 0; b < page.blocks.length; b++) {
                var block = page.blocks[b]
                if (block.type === "image" && block.src)
                    block.resolvedSrc = bookFolder + "/" + block.src
            }
        }
        pages.push(page)
    }
    return { book: book, theme: theme, pages: pages }
}

function filesToWrite(loaded) {
    var files = []
    files.push({ path: "book.json", text: JSON.stringify(loaded.book, null, 2) })
    files.push({ path: "theme.json", text: JSON.stringify(loaded.theme, null, 2) })
    var names = loaded.book.pages || []
    var i
    for (i = 0; i < names.length; i++) {
        files.push({
            path: "pages/" + names[i],
            text: JSON.stringify(loaded.pages[i], null, 2)
        })
    }
    return files
}
