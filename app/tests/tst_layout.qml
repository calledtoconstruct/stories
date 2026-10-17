import QtQuick
import QtTest
import "../Layout.js" as Layout

TestCase {
    function test_pictureLine() {
        var blocks = [
            { type: "text", content: "second" },
            { type: "image", src: "a.png" },
            { type: "text", content: "first" },
            { type: "image", src: "b.png" }
        ]
        var line = Layout.pictureLine(blocks)
        compare(line.length, 2)
        compare(line[0].type, "image")
        compare(line[0].src, "a.png")
        compare(line[1].type, "text")
        compare(line[1].content, "second")
        var size = Layout.clampSize(10, 80)
        compare(size.width, 48)
        compare(size.height, 80)
        var authored = Layout.layoutBlocks([
            { type: "text", rect: { x: 0.7, y: 0.05, width: 0.25, height: 0.2 } },
            { type: "image", rect: { x: 0.02, y: 0.4, width: 0.4, height: 0.5 } }
        ])
        compare(authored[0].rect.y, 0.05)
        compare(authored[1].rect.x, 0.02)
        var moved = Layout.moveRect(authored[0].rect, 0.1, 0.6)
        compare(moved.x, 0.1)
        compare(moved.y, 0.6)
        compare(moved.width, 0.25)
        var sized = Layout.resizeRect(authored[0].rect, 0.1, 0.2, 0.5, 0.6)
        compare(sized.x, 0.1)
        compare(sized.y, 0.2)
        compare(sized.width, 0.5)
        compare(sized.height, 0.6)
        var limited = Layout.resizeRect(authored[0].rect, 0.9, 0.95, 0.8, 0.8)
        verify(limited.x + limited.width <= 1)
        verify(limited.y + limited.height <= 1)
        verify(limited.width >= 0.05)
        verify(limited.height >= 0.07)
    }
}
