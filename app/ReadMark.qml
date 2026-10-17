import QtQuick

Item {
    id: mark
    property string kind: "line"
    property color markColor: "#9aa0a6"
    property bool interactive: true
    signal clicked()
    width: 52
    height: 44
    opacity: interactive && iconArea.containsPress ? 0.55 : 1

    Item {
        id: chevron
        width: 14
        height: 16
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        Rectangle {
            width: 10
            height: 3
            radius: 1
            color: mark.markColor
            y: 4
            transformOrigin: Item.Left
            rotation: -42
        }
        Rectangle {
            width: 10
            height: 3
            radius: 1
            color: mark.markColor
            y: 9
            transformOrigin: Item.Left
            rotation: 42
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: chevron.right
        anchors.leftMargin: 6
        spacing: 4
        Repeater {
            model: mark.kind === "paragraph" ? 3 : 1
            Rectangle {
                width: 26
                height: 3
                radius: 1
                color: mark.markColor
            }
        }
    }

    MouseArea {
        id: iconArea
        anchors.fill: parent
        enabled: mark.interactive
        onClicked: mark.clicked()
    }
}
