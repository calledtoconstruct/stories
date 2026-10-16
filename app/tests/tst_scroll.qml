import QtQuick
import QtTest
import "../Scroll.js" as Scroll

TestCase {
    function test_scroll() {
        compare(Scroll.holdMs(), 600)
        compare(Scroll.step(0, 100, 250, "down", 40), 40)
        compare(Scroll.step(0, 100, 250, "up", 40), 0)
        compare(Scroll.step(140, 100, 250, "down", 40), 150)
        compare(Scroll.step(20, 100, 250, "up", 40), 0)
        compare(Scroll.canScroll(0, 100, 250, "down"), true)
        compare(Scroll.canScroll(0, 100, 250, "up"), false)
        compare(Scroll.canScroll(150, 100, 250, "down"), false)
        compare(Scroll.canScroll(40, 100, 250, "up"), true)
        compare(Scroll.canScroll(0, 100, 80, "down"), false)
        compare(Scroll.canScroll(0, 100, 80, "up"), false)
    }
}
