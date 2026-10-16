import QtQuick
import QtTest
import "../Dwell.js" as Dwell

TestCase {
    function ev(button, type, timestamp) {
        return { button: button, type: type, timestamp: timestamp }
    }

    function test_dwell() {
        var state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 1000))
        verify(!state.action)
        state = Dwell.reduce(state, ev("next", "release", 1400))
        compare(state.action, "speak")

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 0))
        state = Dwell.reduce(state, ev("next", "tick", 600))
        compare(state.action, "speak")
        verify(state.action !== "turn")
        state = Dwell.reduce(state, ev("next", "tick", 900))
        verify(!state.action)

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 0))
        state = Dwell.reduce(state, ev("next", "tick", 800))
        compare(state.action, "speak")

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 0))
        state = Dwell.reduce(state, ev("next", "edge", 200))
        compare(state.action, "turn")

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 0))
        state = Dwell.reduce(state, ev("next", "edge", 600))
        compare(state.action, "turn")

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("next", "edge", 0))
        state = Dwell.reduce(state, ev("next", "edge", 200))
        compare(state.action, "turn")
        state = Dwell.reduce(state, ev("next", "edge", 900))
        verify(!state.action)

        state = Dwell.fresh()
        state = Dwell.reduce(state, ev("prev", "edge", 0))
        state = Dwell.reduce(state, ev("prev", "edge", 100))
        compare(state.action, "turn")
        state = Dwell.reduce(state, ev("next", "release", 200))
        verify(!state.action)
        compare(state.nextEdge, -1)
    }
}
