import QtQuick
import QtTest
import "../Shelf.js" as Shelf

TestCase {
    function test_listIds() {
        var text = "{\"books\":[\"turtle-adventure\",\"family-picnic\"]}"
        var ids = Shelf.listIds(text)
        compare(ids.length, 2)
        compare(ids[0], "turtle-adventure")
        var next = Shelf.addId(text, "school-day")
        var added = Shelf.listIds(next)
        compare(added.length, 3)
        compare(added[2], "school-day")
        compare(Shelf.listIds(Shelf.addId(next, "school-day")).length, 3)
        var card = Shelf.entry("turtle-adventure", "{\"title\":\"The Little Turtle's Adventure\",\"synopsis\":\"A little turtle finds a pond.\",\"cover\":\"assets/images/cover.jpg\"}")
        compare(card.id, "turtle-adventure")
        compare(card.title, "The Little Turtle's Adventure")
        compare(card.synopsis, "A little turtle finds a pond.")
        compare(card.cover, "assets/images/cover.jpg")
        compare(card.voice, "af_heart")
        var voiced = Shelf.entry("family-picnic", "{\"title\":\"Family Picnic\",\"voice\":\"af_bella\"}")
        compare(voiced.voice, "af_bella")
        var titled = Shelf.entry("school-day", "{\"title\":\"School Day\"}")
        compare(titled.synopsis, "School Day")
        compare(titled.cover, "")
        var renamed = Shelf.replaceId(text, "family-picnic", "pond-day")
        var ids = Shelf.listIds(renamed)
        compare(ids.length, 2)
        compare(ids[0], "turtle-adventure")
        compare(ids[1], "pond-day")
        compare(Shelf.listIds(Shelf.replaceId(renamed, "pond-day", "pond-day")).length, 2)
    }
}
