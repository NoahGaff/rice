import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main
    implicitWidth: Screen.width
    implicitHeight: 500
    color: "transparent"

    property int speed: 5000
    property int sidePad: 90

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 0

    anchors {
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
        }
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + configs.wallpaper_path
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.mov", "*.avi"]
        sortField: FolderListModel.Name
    }

    ListView {
        id: list
        anchors.fill: parent
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: 4
        clip: true
        leftMargin: main.sidePad
        rightMargin: main.sidePad
        cacheBuffer: width

        property int selectedIndex: 0
        property real tileWidth: (width - (main.sidePad * 2)) / configs.number_of_pictures - 10

        function clampIndex(i) {
            return Math.max(0, Math.min(i, count - 1))
        }

        function activateCurrent() {
            const path = folderModel.get(selectedIndex, "filePath")
            Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), path])
            Qt.quit()
        }

        function clampX(x) {
            return Math.max(0, Math.min(x, contentWidth - width))
        }

        function ensureVisibleAnimated(i) {
            const step = tileWidth + spacing
            const itemStart = i * step
            const itemEnd = itemStart + tileWidth + 20

            if (itemStart < contentX)
                contentX = clampX(itemStart)
            else if (itemEnd > contentX + width)
                contentX = clampX(itemStart - (width - step))
        }

        Behavior on contentX {
            SmoothedAnimation {
                id: anim
                property int v: 10
                duration: 100
            }
        }

        Component.onCompleted: {
            anim.v = main.speed
        }

        delegate: Item {
            property bool active: index === list.selectedIndex
            width: list.tileWidth
            height: main.height

            Behavior on width {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                id: alt
                visible: false
                text: ""
                color: configs.border_color
                anchors.centerIn: parent
                font.pixelSize: 16
                transform: Shear { xFactor: -0.25 }
            }

            Image {
                id: img
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop

                asynchronous: true
                cache: true
                smooth: true

                source: "file://" + configs.cache_path + fileName + ".jpg"
                sourceSize.width: width
                sourceSize.height: height

                transform: Shear { xFactor: -0.25 }

                onStatusChanged: {
                    if (status === Image.Ready) {
                        alt.visible = false
                        alt.text = ""
                    } else if (status === Image.Loading) {
                        alt.visible = false
                        alt.text = ""
                    } else if (status === Image.Error) {
                        alt.visible = true
                        alt.text = "No preview"
                    }
                }
            }

            Rectangle {
                id: border
                z: 10
                visible: parent.active
                width: list.tileWidth
                height: main.height
                color: "transparent"

                border.width: 4
                border.color: configs.border_color

                transform: Shear { xFactor: -0.25 }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    list.selectedIndex = index
                    list.activateCurrent()
                }

                onWheel: function(wheel) {
                    list.contentX = list.clampX(
                        list.contentX - wheel.angleDelta.y * 2
                    )
                    wheel.accepted = false
                }
            }
        }

        Keys.onPressed: function(event) {
            const step = 1
            const big = configs.number_of_pictures

            if (event.key === Qt.Key_Right || event.key === Qt.Key_J) {
                anim.v = main.speed
                selectedIndex = clampIndex(selectedIndex + step)
                ensureVisibleAnimated(selectedIndex)
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_K) {
                anim.v = main.speed
                selectedIndex = clampIndex(selectedIndex - step)
                ensureVisibleAnimated(selectedIndex)
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_D) {
                anim.v = main.speed * big
                selectedIndex = clampIndex(selectedIndex + big)
                ensureVisibleAnimated(selectedIndex)
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_U) {
                anim.v = main.speed * big
                selectedIndex = clampIndex(selectedIndex - big)
                ensureVisibleAnimated(selectedIndex)
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                activateCurrent()
            } else if (event.key === Qt.Key_Escape) {
                Qt.quit()
            } else {
                return
            }

            event.accepted = true
        }
    }
}
