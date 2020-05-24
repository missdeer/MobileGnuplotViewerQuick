import QtQuick 2.12
import QtQuick.Controls 2.5

Page {
    id: page
    //width: 600
    //height: 400
    property alias btnRun: btnRun
    property alias btnExit: btnExit
    property alias btnOpen: btnOpen
    property alias textArea: textArea
    property alias btnGraphics: btnGraphics

    title: qsTr("Gnuplot")

    TextArea {
        id: textArea
        height: 307
        anchors.bottom: btnOpen.top
        anchors.bottomMargin: 5
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.rightMargin: 5
        anchors.leftMargin: 5
        anchors.topMargin: 5
        placeholderText: qsTr("Text Area")
    }

    Button {
        id: btnOpen
        x: 5
        y: 300
        text: qsTr("Open")
        anchors.bottom: btnExit.top
        anchors.bottomMargin: 5
    }

    Button {
        id: btnExit
        x: 5
        y: 355
        text: qsTr("Exit")
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
    }

    Button {
        id: btnRun
        text: qsTr("Run")
        anchors.left: btnOpen.right
        anchors.leftMargin: 5
        anchors.top: textArea.bottom
        anchors.topMargin: 5
    }

    Button {
        id: btnGraphics
        text: qsTr("Graphics")
        anchors.left: btnExit.right
        anchors.leftMargin: 5
        anchors.top: btnRun.bottom
        anchors.topMargin: 5
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}D{i:4;anchors_x:111;anchors_y:311}D{i:5;anchors_x:110;anchors_y:436}
}
##^##*/

