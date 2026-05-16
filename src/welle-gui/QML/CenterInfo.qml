import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 15
        width: parent.width * 0.8

        // MUX Name
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: radioController.ensemble ? "" + radioController.ensemble.trim() : ""
            color: "#aaaaaa"
            font.pixelSize: 22
            font.letterSpacing: 1.5
        }

        // MOT Slideshow Image
        Image {
            id: motImage
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 320
            fillMode: Image.PreserveAspectFit
            
            // Start completely empty to avoid provider errors on boot
            source: "" 

            Connections {
                target: guiHelper
                function onMotChanged(pictureName, categoryTitle, categoryId, slideId) {
                    // Only call the provider when a real image arrives
                    motImage.source = "image://SLS/" + pictureName
                }
                function onMotReseted() {
                    // Clear the image safely
                    motImage.source = ""
                }
            }

            Rectangle {
                anchors.fill: parent
                z: -1
                color: "black"
                radius: 10
            }
        }

        // Station Name (Service)
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: radioController.title ? radioController.title.trim() : "No Station" 
            color: "white"
            font.pixelSize: 42
            font.bold: true
        }

        // Radio Text (DLS)
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: radioController.text ? radioController.text.trim() : ""
            color: "#dddddd"
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }
}