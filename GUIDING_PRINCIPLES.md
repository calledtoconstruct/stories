# Guiding principles: calledtoconstruct/stories

## Purpose and scope
Stories: a local Quickshell picture-book reader and builder with local Kokoro speech.

## Stack and layout
QML app in `app/` (`reader.qml`, `builder.qml`, tests in `app/tests/tst_*.qml`), books in `books/<id>/` (book.json, theme.json, pages/, assets/images/), speech in `voice/` (Python, with `test_cue.py` and `test_warm.py`), launcher script `stories`.

## Commands
| Check | Command | Evidence |
|---|---|---|
| Run | From the parent folder of the checkout: `qs -p stories/app/reader.qml`, `stories/stories [book-id]`, `qs -p stories/app/builder.qml` | README.md |
| Changed-feature tests | `QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input stories/app/tests/tst_<area>.qml` for the area you changed | README.md |
| Build / type-check | None (QML is interpreted) | - |
| CI | None | repository tree |

Commands marked as not written down come from the build files, not from project docs; confirm them before relying on them.

## Before every push
Before every push: run the build and type-check/lint that exist here, plus only the tests for the files or feature you changed (team rule, ideas #14 note 6797). Do not run the full suite locally as a routine gate; this repository has no CI that runs the full suite, so run the full suite only when the change is broad, and say in the PR that CI coverage is missing. Merge needs a positive review. Explain any new failure your change caused. Never weaken a valid test to make it pass, and never invent a command this file does not list.

## Project rules
- Nothing speaks until the reader chooses it.
- Saving a book writes `books/<id>/` and updates `books/index.json`; keep that file in step.
- Speech stays local; no network after the voice files are downloaded.

## What to avoid
- Committing to the default branch; work on a branch and open a pull request.
- Deleting files, branches or history, or changing repository settings.
- Adding tooling, CI or dependencies that the change does not need.
- Rules copied from other projects (file-size limits, clocks, quotas) that this repository never adopted.

## Delivery and safety
- Nothing is published.

## Open questions
- How to run the `voice/` Python tests is not written down.

## Sources
Read from the `main` branch on 2026-11-08 ET: `README.md`, stories, repository tree.

## Instruction updates
Check `guiding-principles.version` at the start of each turn and when you enter this project; reload this file when the version changes. Change this file, its version and date, and `PRINCIPLES_HISTORY.md` in the same commit. Team-wide role instructions are versioned separately in the team-process repository.
