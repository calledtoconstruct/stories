# Stories

Quickshell reader and builder. Each book is a folder under `books/`: `book.json`, `theme.json`, `pages/`, and `assets/images/`.

From `/home/joseph/code`:

```
qs -p stories/app/reader.qml
stories/stories
stories/stories turtle-adventure
qs -p stories/app/builder.qml
```

With no book id, the reader opens on a list of books. Each book has its own cover image on the left, separate from the pictures inside the story. When the list is taller than the window, an up target and a down target sit at the edges. A click, or a look that rests there for 600 ms, moves the list one step. The look can stay to keep moving. A target is hidden when the list cannot move that way. Selecting a book is separate from moving the list. Select a book to see and hear its synopsis, then select that book again to open it. `stories/stories turtle-adventure` opens that book directly. The same id can be passed as `STORIES_BOOK=turtle-adventure qs -p stories/app/reader.qml`. Ids are `turtle-adventure`, `family-picnic`, and `school-day`.

Each picture and each paragraph keeps the place saved in that page. Nothing speaks until you choose it.

In the builder, Add paragraph puts another paragraph on the current page. Drag a picture or a paragraph to move it, then Save.

The page keeps its shape and scales to fit the window when the window is resized or moved to another size. Click a word to hear that word. The words sit in the sentence, with no button border; the spoken word is filled with the accent color. A borderless line icon reads that line, and a borderless paragraph icon reads that paragraph. Read page hears the page. Click the picture to hear its description. The named buttons under the picture speak that object. Back and Next take two clicks, and they ignore clicks for one second after a turn. Repeat hears the last word, line, or page again.

Speech is local eSpeak NG in `voice/`. No network.

The builder edits the title, book id, age band, colors, image path, and sentence. Add page, then Save. Save creates `books/<id>/` and adds that id to `books/index.json`.

Logic tests, from `/home/joseph/code`:

```
QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input stories/app/tests/tst_books.qml
```

Use the same command for `tst_theme.qml`, `tst_layout.qml`, `tst_speech.qml`, `tst_shelf.qml`, `tst_place.qml`, `tst_dwell.qml`, `tst_scroll.qml`, `tst_reader.qml`, and `tst_builder.qml`. A passing run names `test_fontPx`, `test_pictureLine`, `test_pageWords`, `test_listIds`, `test_encode`, `test_roundTrip`, `test_dwell`, `test_scroll`, `test_reader`, or `test_builder`.

File proofs write a result file because `Qt.exit` does not stop Quickshell. `proof_store.qml` reads the turtle book and round-trips it under `/tmp`. `proof_open.qml` checks the reader against that book. `proof_save.qml` saves a new book under `/tmp/stories-books-root`.
