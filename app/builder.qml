import QtQuick
import Quickshell
import "."

FloatingWindow {
    id: window
    title: "Stories Builder"
    implicitWidth: 1100
    implicitHeight: 772
    minimumSize: Qt.size(480, 320)
    color: shell.backgroundColor

    ShellBuilder {
        id: shell
        anchors.fill: parent
    }
}
