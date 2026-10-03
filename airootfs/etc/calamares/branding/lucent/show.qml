import QtQuick 2.15
import calamares.slideshow 1.0
Presentation {
    id: presentation
    Timer {
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#101827"
            Column {
                anchors.centerIn: parent
                spacing: 24
                Image { source: "logo.svg"; width: 100; height: 100; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: qsTr("Welcome to LucentOS"); color: "#f8fafc"; font.pixelSize: 30; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: qsTr("Your Plasma desktop is taking shape."); color: "#cbd5e1"; font.pixelSize: 18; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
    Slide {
        centeredText: qsTr("Built for your next idea.\nPlasma, development tools, and everyday applications.")
    }
    Slide {
        centeredText: qsTr("Make it your own.\nChoose your workspace, connect, and start creating.")
    }
}
