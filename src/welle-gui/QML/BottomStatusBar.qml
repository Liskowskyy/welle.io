import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#222222"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        spacing: 20

        // Channel ID
        Text {
            text: "CH: " + radioController.channel
            color: "#ffcc00"
            font.pixelSize: 20
            font.bold: true
        }

        Item { Layout.fillWidth: true } // Center Spacer

        // Signal Strength Bar
        RowLayout {
            spacing: 10
            Text {
                text: "Signal:"
                color: "white"
                font.pixelSize: 18
            }
            
            ProgressBar {
                value: Math.min(Math.max(radioController.snr / 30.0, 0.0), 1.0)
                Layout.preferredWidth: 200
                Layout.preferredHeight: 15
            }
        }

        // SNR in dB
        Text {
            text: "SNR: " + radioController.snr.toFixed(1) + " dB"
            color: "white"
            font.pixelSize: 18
        }
    }
}