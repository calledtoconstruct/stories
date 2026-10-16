import QtQuick
import QtTest
import "../Place.js" as Place

TestCase {
    function test_encode() {
        var text = Place.encode({ page: 2 })
        compare(Place.parse(text).page, 2)
        compare(Place.parse("not-json"), null)
    }
}
