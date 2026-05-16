/*
 *    Copyright (C) 2017 - 2021
 *    Albrecht Lohofener (albrechtloh@gmx.de)
 *
 *    This file is part of the welle.io.
 *    Many of the ideas as implemented in welle.io are derived from
 *    other work, made available through the GNU general Public License.
 *    All copyrights of the original authors are recognized.
 *
 *    welle.io is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    welle.io is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with welle.io; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtCore

import "texts"
import "settingpages"
import "components"

ApplicationWindow {
    id: mainWindow

    property bool isExpertView: false
    property bool isFullScreen: false
    property bool isLoaded: false
    property bool isStationNameInWindowTitle: false
    property string knownEnsembleNamesSerialized

    StationListModel { id: stationList ; type: "all"}
    StationListModel { id: favoritsList ; type: "favorites"}

    readonly property bool inPortrait: mainWindow.width < mainWindow.height

    function getWidth() {
        if(Screen.desktopAvailableWidth < Units.dp(700)
                || Screen.desktopAvailableHeight < Units.dp(500)
                || Qt.platform.os == "android") // Always full screen on Android
            return Screen.desktopAvailableWidth
        else
            return Units.dp(700)
    }

    function getHeight() {
        if(Screen.desktopAvailableHeight < Units.dp(500)
                || Screen.desktopAvailableWidth < Units.dp(700)
                || Qt.platform.os == "android")  // Always full screen on Android
            return Screen.desktopAvailableHeight
        else
            return Units.dp(500)
    }

    width: getWidth()
    height: getHeight()

    // Dynamic Window Title
    title: isStationNameInWindowTitle ? radioController.title.trim() + " - welle.io" : "welle.io"

    visible: true 
    visibility: isFullScreen ? Window.FullScreen : Window.Windowed

    Component.onCompleted: {
        if(Qt.platform.os == "android") {
            mainWindow.width = getWidth()
            mainWindow.height = getHeight()
        }

        if(errorMessagePopup.text != "")
            errorMessagePopup.open();
            
        updateTheme()

        // Updated MPRIS integration to use stationList directly since the visual view is gone
        guiHelper.updateMprisStationList(stationList.serialized, stationList.type, 0)

        isLoaded = true
    }

    Settings {
        property alias width : mainWindow.width
        property alias height : mainWindow.height
        property alias stationListSerialize: stationList.serialized
        property alias favoritsListSerialize: favoritsList.serialized
        property alias volume: volumeSlider.value
        property alias knownEnsembleNamesSerialized: mainWindow.knownEnsembleNamesSerialized
    }

    // ==========================================
    // TOP BUTTONS (Floating in Top Right)
    // ==========================================
    header: ToolBar {
        id: overlayHeader

        // Make the toolbar background completely transparent
        background: Rectangle { color: "transparent" }

        RowLayout {
            anchors.fill: parent

            // This invisible, expanding spacer pushes everything else to the far right
            Item { Layout.fillWidth: true }

            ToolButton {
                id: startStopIcon
                implicitWidth: icon.width + Units.dp(20)
                icon.name: "stop"

                onClicked: {
                    if (radioController.isPlaying || radioController.isChannelScan) {
                        startStopIcon.stop()
                    } else {
                        startStopIcon.play()
                    }
                }

                Component.onCompleted: { startStopIcon.setStartPlayIcon() }

                Connections {
                    target: radioController
                    function onIsPlayingChanged() { startStopIcon.setStartPlayIcon() }
                    function onIsChannelScanChanged() { startStopIcon.setStartPlayIcon() }
                }

                function setStartPlayIcon() {
                    if (radioController.isPlaying || radioController.isChannelScan) {
                        startStopIcon.icon.name = "stop"
                    } else {
                        startStopIcon.icon.name = "play"
                    }
                }

                function play() {
                    var channel = radioController.lastChannel[1]
                    var sidHex = radioController.lastChannel[0]
                    stationList.play(channel, sidHex)
                }

                function stop() {
                    if (radioController.isPlaying)
                        radioController.stop();
                    else if (radioController.isChannelScan)
                        radioController.stopScan()
                }
            }

            ToolButton {
                id: speakerIconContainer
                implicitWidth: icon.width + Units.dp(24)
                icon.name: "speaker"

                onPressAndHold: volumePopup.open()
                onClicked: {
                    if(radioController.volume !== 0) {
                        volumeSlider.valueBeforeMute = volumeSlider.value
                        volumeSlider.value = 0
                    } else {
                        volumeSlider.value = volumeSlider.valueBeforeMute
                    }
                }

                Popup {
                    id: volumePopup
                    y: speakerIconContainer.y + speakerIconContainer.height
                    x: Math.round(speakerIconContainer.x + (speakerIconContainer.width / 2) - volumePopup.width/2 )
                    parent: Overlay.overlay
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    ColumnLayout{
                        Slider {
                            id: volumeSlider
                            property real valueBeforeMute: 1
                            Layout.alignment: Qt.AlignCenter
                            height: 100
                            orientation: Qt.Vertical
                            snapMode: Slider.SnapAlways
                            wheelEnabled: true
                            from: 0
                            to: 1
                            stepSize: 0.01
                            value: radioController.volume

                            onValueChanged: setVolume(value)

                            Connections {
                                target: radioController
                                function onVolumeChanged(volume) { volumeSlider.value = volume }
                            }

                            function setVolume(value) {
                                if (volumeSlider.value != radioController.volume) {
                                    if (value === 0) {
                                        radioController.setVolume(value)
                                        speakerIconContainer.icon.color = "red"
                                    } else {
                                        radioController.setVolume(value)
                                        speakerIconContainer.icon.color = undefined
                                    }
                                }
                            }
                        }

                        TextStandart {
                            id: volumeLabel
                            Layout.alignment: Qt.AlignCenter
                            font.pixelSize: Units.em(0.8)
                            text: Math.round(volumeSlider.value*100) + "%"
                        }
                    }
                }
            }

            ToolButton {
                icon.name: "menu"
                implicitWidth: icon.width + Units.dp(20)
                onClicked: optionsMenu.open()

                WMenu {
                    id: optionsMenu
                    sizeToContents: true
                    x: parent.width - width
                    transformOrigin: Menu.TopRight
                    
                    MenuItem {
                        id: startStationScanItem
                        text: qsTr("Start station scan")
                        font.pixelSize: TextStyle.textStandartSize
                        onTriggered:  { radioController.startScan() }
                    }

                    MenuItem {
                        id: stopStationScanItem
                        text: qsTr("Stop station scan")
                        font.pixelSize: TextStyle.textStandartSize
                        enabled: false
                        onTriggered:  { radioController.stopScan() }
                    }
                    
                    MenuSeparator {}

                    MenuItem {
                        text: qsTr("Settings")
                        font.pixelSize: TextStyle.textStandartSize
                        onTriggered: {
                            globalSettingsDialog.title = "Settings"
                            globalSettingsDialog.open()
                        }
                    }
                    MenuItem {
                        text: qsTr("Expert Settings")
                        font.pixelSize: TextStyle.textStandartSize
                        onTriggered: {
                            expertSettingsDialog.title = "Expert Settings"
                            expertSettingsDialog.open()
                        }
                    }
                    MenuItem {
                        text: qsTr("About")
                        font.pixelSize: TextStyle.textStandartSize
                        onTriggered: {
                            aboutDialog.title = "About"
                            aboutDialog.open()
                        }
                    }
                    MenuItem {
                        text: qsTr("Exit")
                        font.pixelSize: TextStyle.textStandartSize
                        onTriggered: guiHelper.close()
                    }
                }
            }
        }
    }

    // ==========================================
    // TABLET MAIN VIEW (Carousel + Info + Bottom Bar)
    // ==========================================
    Rectangle {
        id: mainContentArea
        anchors.fill: parent
        
        // Match the background to the current Light/Dark theme
        color: (mainWindow.Universal.theme === Universal.Dark ) ? "#1e1e1e" : "#e6e6e6"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TopCarousel {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
            }

            CenterInfo {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            BottomStatusBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
            }
        }
    }

    // ==========================================
    // DIALOGS & POPUPS 
    // ==========================================
    WDialog {
        id: aboutDialog
        contentItem: InfoPage{ id: infoPage }
    }

    WDialog {
        id: stationSettingsDialog
        content: Loader {
            id: stationSettingsLoader
            anchors.right: parent.right
            anchors.left: parent.left
            height: progress < 1 ? undefined : item.implicitHeight
            source:  "qrc:/QML/settingpages/ChannelSettings.qml"
            onLoaded: isStationNameInWindowTitle = stationSettingsLoader.item.addStationNameToWindowTitleState
        }
        Connections {
            target: stationSettingsLoader.item
            function onAddStationNameToWindowTitleStateChanged() {isStationNameInWindowTitle = stationSettingsLoader.item.addStationNameToWindowTitleState}
        }
    }

    WDialog {
        id: globalSettingsDialog
        content: Loader {
            id: globalSettingsLoader
            anchors.right: parent.right
            anchors.left: parent.left
            height: progress < 1 ? undefined : item.implicitHeight
            source:  "qrc:/QML/settingpages/GlobalSettings.qml"
            onLoaded : isFullScreen = globalSettingsLoader.item.enableFullScreenState
        }
        Connections {
            target: globalSettingsLoader.item
            function onEnableFullScreenStateChanged() {isFullScreen = globalSettingsLoader.item.enableFullScreenState}
            function onQQStyleThemeChanged() {updateTheme()}
        }
    }

    WDialog {
        id: expertSettingsDialog
        content: Loader {
            id: expertSettingsLoader
            anchors.right: parent.right
            anchors.left: parent.left
            height: progress < 1 ? undefined : item.implicitHeight
            source:  "qrc:/QML/settingpages/ExpertSettings.qml"
            onLoaded: isExpertView = expertSettingsLoader.item.enableExpertModeState
        }
        Connections {
            target: expertSettingsLoader.item
            function onEnableExpertModeStateChanged() {isExpertView = expertSettingsLoader.item.enableExpertModeState}
        }
    }

    MessagePopup {
        id: errorMessagePopup
        x: mainWindow.width/2 - width/2
        y: mainWindow.height  - overlayHeader.height - height
        revealedY: mainWindow.height - overlayHeader.height - height
        hiddenY: mainWindow.height
        color: "#8b0000"
    }

    MessagePopup {
        id: infoMessagePopup
        x: mainWindow.width/2 - width/2
        y: mainWindow.height  - overlayHeader.height - height
        revealedY: mainWindow.height - overlayHeader.height - height
        hiddenY: mainWindow.height
        color:  "#468bb7"
        onOpened: closeTimer.running = true;
        Timer {
            id: closeTimer
            interval: 1 * 5000 // 5 s
            repeat: false
            onTriggered: { infoMessagePopup.close() }
        }
    }

    Connections{
        target: radioController

        function onShowErrorMessage(Text) {
            errorMessagePopup.text = Text;
            if(mainWindow.isLoaded)
                errorMessagePopup.open();
        }

        function onShowInfoMessage(Text) {
            infoMessagePopup.text = Text;
            infoMessagePopup.open();
        }

        function onScanStopped() {
            startStationScanItem.enabled = true
            stopStationScanItem.enabled = false
        }

        function onScanProgress() {
            startStationScanItem.enabled = false
            stopStationScanItem.enabled = true
        }

        function onNewStationNameReceived(station, sId, channel) {stationList.addStation(station, sId, channel, false)}

        function onEnsembleChanged() {
            var ensemble = radioController.ensemble.trim()
            var channel = radioController.channel
            if(ensemble != "") {
                var knownEnsembleNames = {}
                if(knownEnsembleNamesSerialized != "")
                    knownEnsembleNames = JSON.parse(knownEnsembleNamesSerialized)

                if (!(channel in knownEnsembleNames) || knownEnsembleNames[channel] !== ensemble) {
                    knownEnsembleNames[channel] = ensemble;
                    knownEnsembleNamesSerialized = JSON.stringify(knownEnsembleNames)
                }
            }
        }
    }

    Connections {
        target: guiHelper
        function onMinimizeWindow() {hide()}
        function onMaximizeWindow() {showMaximized()}
        function onRestoreWindow() {
            if (Qt.platform.os === "linux" && !active) 
                hide()
            showNormal()
            raise() 
            if (Qt.platform.os === "linux" && !active) 
                requestActivate()
        }
    }

    onVisibilityChanged: function(visibility) {
        if(visibility === Window.Minimized)
            guiHelper.tryHideWindow()
    }

    function updateTheme() {
        switch(globalSettingsLoader.item.qQStyleTheme) {
            case 0: mainWindow.Universal.theme = Universal.Light; break;
            case 1: mainWindow.Universal.theme = Universal.Dark; break;
            case 2: mainWindow.Universal.theme = Universal.System; break;
        }
    }
}