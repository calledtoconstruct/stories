import QtQuick
import QtTest
import "../Theme.js" as Theme

TestCase {
    function test_fontPx() {
        compare(Theme.fontPx("early", 1.0), 36)
        compare(Theme.fontPx("growing", 1.0), 28)
        compare(Theme.fontPx("school", 1.0), 22)
        compare(Theme.fontPx("early", 2.0), 72)
    }
}
