import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#2a2a2a"

    ListView {
        id: stationCarousel
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 15
        leftMargin: 20
        rightMargin: 20
        clip: true

        model: stationList

        delegate: Item {
            width: 100
            height: parent.height

            Column {
                anchors.centerIn: parent
                spacing: 8

                Image {
                    source: typeof logo !== "undefined" && logo !== "" ? logo : ""
                    width: 72
                    height: 72
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: "#444"
                        border.width: 1
                        radius: 8
                    }
                }

                Text {
                    text: typeof stationName !== "undefined" ? stationName.trim() : "Unknown"
                    color: "white"
                    font.pixelSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    elide: Text.ElideRight
                    width: 90
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    radioController.play(channelName, stationName, stationSId)
                }
            }
        }
    }
}