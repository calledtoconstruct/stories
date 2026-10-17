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

Each picture and each paragraph keeps the place and size saved in that page. Nothing speaks until you choose it. A line, a paragraph, and a page are spoken as one phrase, so the sentence has a natural melody. While that phrase plays, the speaker prints `WORD <id>` as each word is heard, and that word lights up.

The builder opens on the list of books. New book starts an empty book. Choosing a book opens its cover: title, synopsis, cover photograph, age band, voice, and theme. Back and Next move from the cover to each story page. Click a paragraph to edit its text, or a picture to choose a new photograph from the computer. Add page, Add paragraph, and Add picture grow the book. Drag a block to move it, or drag a corner to resize it. Gray line and paragraph icons sit outside each paragraph, in the place the reader will use. Undo and Redo walk the changes made during this visit. Save writes the book. The page shrinks or grows to fit the window.

The story page is the same sheet the builder uses. The title, Read page, and Repeat sit outside that sheet, and Back and Next sit beside it, so they do not cover the paragraph or its icons. The sheet keeps its shape and scales to fit the room that remains. Click a word to hear that word. The words sit in the sentence, with no button border; the spoken word is filled with the accent color. A line icon sits just to the left of each sentence, outside the paragraph rectangle, and reads that sentence. A paragraph icon sits just below the rectangle and reads the whole paragraph. It appears only when the paragraph has more than one sentence. A sentence ends with a period, a question mark, or an exclamation point. Read page hears the page. Click the picture to hear its description. That description, and the words for a named spot, appear in a bubble over the page and light up as they are spoken. The page stays the same size. Words that are already on the page light up where they sit. The named buttons under the picture speak that object. Back and Next take two clicks, and they ignore clicks for one second after a turn. Repeat hears the last word, line, or page again.

Speech is local Kokoro in `voice/`, a little slower than the model's natural pace. `STORIES_SPEED=0.85 stories/stories` slows it further, and `STORIES_SPEED=1` restores the model's own pace. No network after the voice files are downloaded. Opening a page builds that page's lines, picture, and words, then the other pages. Under the title, the page says "Getting the voice ready" while that page is being built, then "Ready", and then the line goes away. A page that is already built stays quiet. A phrase that is already built plays at once. The first time a phrase is built still waits for that one sentence. The default narrator is `af_heart`. A book can choose another voice in `book.json`:

```json
"voice": "af_bella"
```

`af_heart` and `af_bella` are American women, `am_adam` is an American man, and `bf_emma` is a British woman. The sample books use `af_heart`, `af_bella`, and `am_adam`. The first time you read aloud, `voice/speak` starts a resident process that keeps the model loaded. Later phrases start without loading it again. Install or refresh that voice with `stories/voice/setup`. If Kokoro is not installed yet, speech falls back to the bundled eSpeak voice and the word light still moves.

Save creates `books/<id>/` and adds that id to `books/index.json`. A picture chosen in the builder is copied into that book's `assets/images` folder.

Logic tests, from `/home/joseph/code`:

```
QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input stories/app/tests/tst_books.qml
```

Use the same command for `tst_theme.qml`, `tst_layout.qml`, `tst_speech.qml`, `tst_shelf.qml`, `tst_place.qml`, `tst_dwell.qml`, `tst_scroll.qml`, `tst_reader.qml`, `tst_builder.qml`, and `tst_draft.qml`. A passing run names `test_fontPx`, `test_pictureLine`, `test_pageWords`, `test_listIds`, `test_encode`, `test_roundTrip`, `test_dwell`, `test_scroll`, `test_reader`, `test_builder`, or `test_draft`.

File proofs write a result file because `Qt.exit` does not stop Quickshell. `proof_store.qml` reads the turtle book and round-trips it under `/tmp`. `proof_open.qml` checks the reader against that book. `proof_save.qml` saves a new book under `/tmp/stories-books-root`.
