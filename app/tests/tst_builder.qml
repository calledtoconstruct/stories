import QtQuick
import QtTest
import ".."

TestCase {
    Builder { id: builder }

    function test_builder() {
        var size = builder.importImage(10, 10)
        compare(size.width, 48)
        compare(size.height, 48)
        var blocks = [
            { type: "text", content: "line" },
            { type: "image", src: "pic.png" },
            { type: "text", content: "other" }
        ]
        var line = builder.applyTemplate("picture-line", blocks)
        compare(line.length, 2)
        compare(line[0].type, "image")
        compare(line[1].type, "text")
        var band = findChild(builder, "ageBand")
        compare(builder.collectBook().age_band, band.text)
        builder.ageBand = "school"
        compare(builder.collectBook().age_band, "school")
        compare(band.text, "school")
        var theme = builder.collectBook().theme
        compare(theme.background, builder.backgroundColor)
        compare(theme.paper, builder.paperColor)
        compare(theme.text, builder.textColor)
        compare(theme.accent, builder.accentColor)
        compare(theme.font_scale, builder.fontScale)
        var loaded = builder.loadedDraft()
        var files = builder.savePlan(loaded)
        compare(files[0].path, "book.json")
        compare(files[1].path, "theme.json")
        builder.addPictureLine("assets/images/p01.jpg", "Hello there")
        builder.addParagraph("Another paragraph")
        compare(builder.pageBodies[0].body.blocks.length, 3)
        compare(builder.pageBodies[0].body.blocks[1].type, "text")
        builder.moveBlock(1, 0.2, 0.55)
        compare(builder.canvasBlocks[1].rect.x, 0.2)
        compare(builder.canvasBlocks[1].rect.y, 0.55)
    }
}
