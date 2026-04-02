import Quickshell
import QtQuick
import Quickshell.Wayland

PanelWindow {
    id: main
    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 0

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property int selectedIndex: 0
    property var options: ["static", "live"]

    function chooseCurrent() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "printf '%s' '" + options[selectedIndex] + "' > /tmp/wallpicker-mode"
        ])
        Qt.quit()
    }

    Item {
        id: root
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                main.selectedIndex = Math.max(0, main.selectedIndex - 1)
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                main.selectedIndex = Math.min(main.options.length - 1, main.selectedIndex + 1)
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                main.chooseCurrent()
            } else if (event.key === Qt.Key_Escape) {
                Qt.quit()
            } else {
                return
            }

            event.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#00000000"
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 40

            Repeater {
                model: main.options

                delegate: Rectangle {
                    required property int index
                    required property string modelData

                    width: 260
                    height: 160
                    radius: 20
                    color: "#16131ddd"
                    border.width: index === main.selectedIndex ? 3 : 1
                    border.color: index === main.selectedIndex ? "#A98881" : "#4a4458"
                    clip: true

                    Item {
                        anchors.fill: parent

                        Image {
                            visible: modelData === "static"
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: "file:///home/noah/.config/quickshell/wallmode/static-preview.jpg"
                            smooth: true
                        }

                        AnimatedImage {
                            visible: modelData === "live"
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: "file:///home/noah/.config/quickshell/wallmode/live-preview.gif"
                            playing: true
                            smooth: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: index === main.selectedIndex ? "#552a1f4d" : "#66160f2a"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 54
                            color: "#88220f35"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            text: modelData === "static" ? "Static" : "Live"
                            color: "#e8b4ff"
                            font.pixelSize: 28
                            font.bold: true
                            style: Text.Outline
                            styleColor: "#4b1d63"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            main.selectedIndex = index
                            main.chooseCurrent()
                        }
                    }
                }
            }
        }
    }
}
