/***************************************************************************
 *
 * MobileGnuplotViewer(Quick) - a simple frontend for gnuplot
 *
 * Copyright (C) 2020 by Michael Neuroth
 *
 * License: GPL
 *
 ***************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0

import de.mneuroth.gnuplotinvoker 1.0
//import de.mneuroth.storageaccess 1.0

ApplicationWindow {
    id: window
    objectName: "window"
    visible: true
    width: 640
    height: 480
    title: qsTr("MobileGnuplotViewerQuick")

    property string urlPrefix: "file://"

    Settings {
        id: settings
        property string currentFile: ""
    }

    Component.onDestruction: {
        settings.currentFile = homePage.currentFileUrl
    }

    Component.onCompleted: {
        homePage.currentFileUrl = settings.currentFile
        if(homePage.currentFileUrl.length>0)
        {
            readCurrentDoc(homePage.currentFileUrl)
        }
    }

    function getFontName() {
        if( Qt.platform.os === "android" )
        {
            return "Droid Sans Mono"
        }
        return "Courier"
    }

    function checkForModified() {
        if( homePage.textArea.textDocument.modified )
        {
            // auto save document if application is closing
            saveCurrentDoc()
        }
    }

    function buildValidUrl(path) {
        // ignore call, if we already have a file:// url
        if( path.startsWith(urlPrefix) )
        {
            return path;
        }
        // ignore call, if we already have a content:// url (android storage framework)
        if( path.startsWith("content://") )
        {
            return path;
        }

        var sAdd = path.startsWith("/") ? "" : "/"
        var sUrl = urlPrefix + sAdd + path
        return sUrl
    }

    function saveCurrentDoc() {
        var ok = applicationData.writeFileContent(homePage.currentFileUrl, homePage.textArea.text)
        if(!ok)
        {
// TODO --> error handling --> user output?
            var sErr = "Error writing file... "+homePage.currentFileUrl
            applicationData.logText(sErr)
            outputPage.txtOutput.text = sErr
        }
        homePage.textArea.textDocument.modified = false
    }

    function saveAsCurrentDoc(fullName) {
        homePage.currentFileUrl = fullName
        homePage.lblFileName.text = fullName
        saveCurrentDoc()
    }

    function readCurrentDoc(url) {
        var urlFileName = buildValidUrl(url)
        homePage.currentFileUrl = urlFileName
        homePage.textArea.text = applicationData.readFileContent(urlFileName)
        homePage.textArea.textDocument.modified = false
        homePage.lblFileName.text = urlFileName
    }

    function showInOutput(sContent) {
        outputPage.txtOutput.text = sContent
        stackView.pop()
        stackView.push(outputPage)
    }

    function showFileContentInOutput(sOnlyFileName) {
        var sFileName = applicationData.filesPath + sOnlyFileName
        var sContent = applicationData.readFileContent(buildValidUrl(sFileName))
        showInOutput(sContent)
    }

    function getCurrentText(currentPage) {
        var s = ""
        if(currentPage === homePage)
        {
            s = homePage.textArea.text
        }
        else if(currentPage === outputPage)
        {
            s = outputPage.txtOutput.text
        }
        else if(currentPage === helpPage)
        {
            s = helpPage.txtHelp.text
        }
        return s
    }

    onClosing: {
        // handle navigation back to home page if some other page is visible and back button is activated
        if( stackView.currentItem !== homePage )
        {
            stackView.pop()
            close.accepted = false

        }
        else
        {
            checkForModified()
            close.accepted = true
        }
    }

    header: ToolBar {
        contentHeight: toolButton.implicitHeight

        ToolButton {
            id: menuButton
            text: "\u22EE"
            font.pixelSize: Qt.application.font.pixelSize * 1.6
            anchors.right: parent.right
            anchors.leftMargin: 5
            onClicked: menu.open()

            Menu {
                id: menu
                y: menuButton.height

                MenuItem {
                    text: qsTr("Settings")
                    onTriggered: console.log("Settings...")
                }
                MenuItem {
                    text: qsTr("Print")
                    onTriggered: {
                        var s = getCurrentText(stackView.currentItem)
                        applicationData.shareTextAsPdf(s, true)
                        //applicationData.print(s)
                    }
                }
                MenuItem {
                    text: qsTr("View")
                    onTriggered: {
                        var s = getCurrentText(stackView.currentItem)
                        applicationData.shareTextAsPdf(s, false)
                    }
                }
                MenuItem {
                    text: qsTr("Delete files")
                    onTriggered: console.log("Delete...")
                }
                MenuItem {
                    text: qsTr("Send text")
                    onTriggered: {
                        var s = getCurrentText(stackView.currentItem)
                        applicationData.shareSimpleText(s);
                    }
                }
                MenuItem {
                    text: qsTr("FAQ")
                    onTriggered: {
                        showFileContentInOutput("faq.txt")
                    }
                }
                MenuItem {
                    text: qsTr("License")
                    onTriggered: {
                        showFileContentInOutput("gnuplotviewer_license.txt")
                    }
                }
                MenuItem {
                    text: qsTr("Gnuplot license")
                    onTriggered: {
                        showFileContentInOutput("gnuplot_copyright")
                    }
                }
                MenuItem {
                    text: qsTr("Gnuplot version")
                    onTriggered: {
                        var sContent = gnuplotInvoker.run("show version")
                        outputPage.txtOutput.text = sContent
                        outputPage.txtOutput.text += gnuplotInvoker.lastError
                        stackView.pop()
                        stackView.push(outputPage)
                    }
                }
                MenuItem {
                    text: qsTr("Gnuplot help")
                    onTriggered: {
                        var sContent = gnuplotInvoker.run("help")
                        outputPage.txtOutput.text = sContent
                        outputPage.txtOutput.text += gnuplotInvoker.lastError
                        stackView.pop()
                        stackView.push(outputPage)
                    }
                }
                MenuItem {
                    id: gnuplotBeta
                    text: qsTr("Gnuplot beta")
                    checkable: true
                    onTriggered: {
                        gnuplotInvoker.useBeta = gnuplotBeta.checked
                    }
                }
                MenuItem {
                    text: qsTr("About")
                    onTriggered: console.log("About...")
                }
            }
        }

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\u25C0" : "\u2261"  // original: "\u2630" for second entry, does not work on Android
            font.pixelSize: Qt.application.font.pixelSize * 1.6
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                } else {
                    drawer.open()
                }
            }
        }

        Label {
            text: stackView.currentItem.title
            anchors.centerIn: parent
        }
    }

    PageGraphicsForm {
        id: graphicsPage
        objectName: "graphicsPage"

        property string svgdata: ""

        imageMouseArea {
            // see: photosurface.qml
            onWheel: {
                if (wheel.modifiers & Qt.ControlModifier) {
                    image.rotation += wheel.angleDelta.y / 120 * 5;
                    if (Math.abs(photoFrame.rotation) < 4)
                        image.rotation = 0;
                } else {
                    image.rotation += wheel.angleDelta.x / 120;
                    if (Math.abs(image.rotation) < 0.6)
                        image.rotation = 0;
                    var scaleBefore = image.scale;
                    image.scale += image.scale * wheel.angleDelta.y / 120 / 10;
                }
            }
            onDoubleClicked: {
                // set to default with double click
                image.scale = 1.0
                image.x = 0
                image.y = 0
            }
        }

        btnShare {
            onClicked: {
/*                graphicsPage.image.grabToImage( function(result)
                {
                    console.log("GRAB img --> "+result)
                    result.saveToFile("test.png")
                } )
*/
                var ok = applicationData.shareSvgData(graphicsPage.svgdata)
                if( !ok )
                {
                    window.showInOutput(qsTr("can not share image"))
                }
            }
        }

        btnClear {
            onClicked: {
                graphicsPage.image.source = "empty.svg"
            }
        }

        btnExport {
            onClicked: {
                // TODO
                var ok = applicationData.shareViewSvgData(graphicsPage.svgdata)
                if( !ok )
                {
                    window.showInOutput(qsTr("can not view image"))
                }
            }
        }

        btnOutput {
            onClicked: {
                stackView.pop()
                stackView.push(outputPage)
            }
        }

        btnHelp {
            onClicked: {
                stackView.pop()
                stackView.push(helpPage)
            }
        }

        btnInput {
            onClicked: {
                //stackView.push(homePage)
                stackView.pop()
            }
        }
    }

    PageHelpForm {
        id: helpPage
        objectName: "helpPage"

        fontName: getFontName()

        btnShare {
            onClicked: {
                applicationData.shareText(helpPage.txtHelp.text, "help.txt")
            }
        }

        btnClear {
            onClicked: {
                helpPage.txtHelp.text = ""
            }
        }

        btnRunHelp {
            onClicked: {
                var s = gnuplotInvoker.run(helpPage.txtHelp.text)
                outputPage.txtOutput.text = s
                outputPage.txtOutput.text += gnuplotInvoker.lastError
                stackView.pop()
                stackView.push(outputPage)
            }
        }

        btnGraphics {
            onClicked: {
                stackView.pop()
                stackView.push(graphicsPage)
            }
        }

        btnOutput {
            onClicked: {
                stackView.pop()
                stackView.push(outputPage)
            }
        }

        btnInput {
            onClicked: {
                //stackView.push(homePage)
                stackView.pop()
            }
        }
    }

    PageOutputForm {
        id: outputPage
        objectName: "outputPage"

        fontName: getFontName()

        btnShare {
            onClicked: {
                applicationData.shareText(outputPage.txtOutput.text, "output.txt")
            }
        }

        btnClear {
            onClicked: {
                outputPage.txtOutput.text = ""
            }
        }

        btnSaveAs {
            onClicked: {
                // TODO
            }
        }

        btnGraphics {
            onClicked: {
                stackView.pop()
                stackView.push(graphicsPage)
            }
        }

        btnInput {
            onClicked: {
                //stackView.push(homePage)
                stackView.pop()
            }
        }

        btnHelp {
            onClicked: {
                stackView.pop()
                stackView.push(helpPage)
            }
        }
    }

    function setScriptText(script: string)
    {
        homePage.textArea.text = script
        homePage.textArea.textDocument.modified = false
    }

    function setScriptName(name: string)
    {
        homePage.currentFileUrl = name
        homePage.lblFileName.text = name
    }

    function setOutputText(txt: string)
    {
        outputPage.txtOutput.text = txt
        stackView.pop()
        stackView.push(outputPage)
    }

    HomeForm {
        id: homePage
        objectName: "homePage"

        fontName: getFontName()

        property string currentFileUrl: window.currentFile

        textArea {
            onTextChanged: {
                // set modified flag for autosave of document
                textArea.textDocument.modified = true
            }
        }

        btnOpen  {
            onClicked:  {
                //fileDialog.open()
                //mobileFileDialog.open()
                mobileFileDialog.setOpenModus()
                mobileFileDialog.btnNew.visible = true
                if( mobileFileDialog.currentDirectory == "" )
                {
                    mobileFileDialog.currentDirectory = applicationData.homePath
                }
                mobileFileDialog.setDirectory(mobileFileDialog.currentDirectory)
                stackView.pop()
                stackView.push(mobileFileDialog)
            }
        }

        btnNew {
            onClicked: {
                homePage.textArea.text = ""
                homePage.lblFileName.text = "unknown"
            }
        }

        btnRun {
            onClicked: {
                var sData = gnuplotInvoker.run(homePage.textArea.text)
                outputPage.txtOutput.text += gnuplotInvoker.lastError
                // see: https://stackoverflow.com/questions/51059963/qml-how-to-load-svg-dom-into-an-image
                if( sData.length > 0 )
                {
                    graphicsPage.image.source = "data:image/svg+xml;utf8," + sData
                    graphicsPage.svgdata = sData
                    stackView.pop()
                    stackView.push(graphicsPage)
                }
                else
                {
// TODO --> graphics page mit error Image fuellen
                    graphicsPage.image.source = ":/empty.svg"
                    stackView.pop()
                    stackView.push(outputPage)
                }
            }
        }

        btnShare {
            onClicked: {
                applicationData.shareText(homePage.textArea.text, "gnuplot.gpt")
            }
        }

        btnSave {
            onClicked: {
                saveCurrentDoc()
            }
        }

        btnSaveAs {
            onClicked: {
                mobileFileDialog.setSaveAsModus()
                mobileFileDialog.setDirectory(mobileFileDialog.currentDirectory)
                stackView.pop()
                stackView.push(mobileFileDialog)
            }
        }

        btnGraphics {
            onClicked: {
                stackView.pop()
                stackView.push(graphicsPage)
            }
        }

        btnOutput {
            onClicked: {
                stackView.pop()
                stackView.push(outputPage)
            }
        }

        btnHelp {
            onClicked: {
                stackView.pop()
                stackView.push(helpPage)
            }
        }
/*
        btnExit {
            onClicked: {
                //onClicked: window.close() //Qt.quit()
                applicationData.test()
            }
        }
*/
    }

    MobileFileDialog {
        id: mobileFileDialog

        property bool isSaveAsModus: false

        listView {
            // https://stackoverflow.com/questions/9400002/qml-listview-selected-item-highlight-on-click
            currentIndex: -1
            focus: true
            onCurrentIndexChanged: {
                if( listView.currentItem ) {
// TODO --> nur bei files nicht bei directories !
                    mobileFileDialog.setCurrentName(listView.currentItem.currentFileName)
                }
            }
        }

        function setSaveAsModus() {
            mobileFileDialog.lblMFDInput.text = qsTr("new file name:")
            mobileFileDialog.txtMFDInput.text = "unknown.gpt"
            mobileFileDialog.txtMFDInput.readOnly = false
            mobileFileDialog.btnOpen.text = qsTr("Save as")
            mobileFileDialog.isSaveAsModus = true
        }

        function setOpenModus() {
            mobileFileDialog.lblMFDInput.text = qsTr("open name:")
            mobileFileDialog.txtMFDInput.readOnly = true
            mobileFileDialog.btnOpen.text = qsTr("Open")
            mobileFileDialog.isSaveAsModus = false
        }

        function setDirectory(newPath) {
            newPath = applicationData.normalizePath(newPath)
            listView.model.folder = buildValidUrl(newPath)
            listView.currentIndex = -1
            listView.focus = true
            lblDirectoryName.text = newPath
            currentDirectory = newPath
        }

        function setCurrentName(name) {
            txtMFDInput.text = name
            currentFileName = name
        }

        function openCurrentFileNow() {
            var fullPath = currentDirectory + "/" + currentFileName
            window.readCurrentDoc(buildValidUrl(fullPath))
            stackView.pop()
        }

        function saveAsCurrentFileNow() {
            var fullPath = currentDirectory + "/" + txtMFDInput.text
            window.saveAsCurrentDoc(buildValidUrl(fullPath))
            stackView.pop()
        }

        Component {
            id: fileDelegate
            Rectangle {
                property string currentFileName: fileName
                height: 40
                color: "transparent"
                anchors.left: parent.left
                anchors.right: parent.right
                Keys.onPressed: {
                     if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
                        if( fileIsDir )
                        {
                            mobileFileDialog.setDirectory(filePath)
                            mobileFileDialog.setCurrentName(fileName)
                            event.accepted = true
                        }
                        else
                        {
                            mobileFileDialog.openCurrentFileNow()
                            event.accepted = true
                        }
                     }
                }
                Label {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: (fileIsDir ? "DIR_" : "FILE") + /*filePath +*/ " | " + fileName
                }
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        mobileFileDialog.listView.currentIndex = index
                        if( fileIsDir )
                        {
                            mobileFileDialog.setDirectory(filePath)
                            mobileFileDialog.setCurrentName(fileName)
                        }
                    }
                    onDoubleClicked: {
                        mobileFileDialog.listView.currentIndex = index
                        if( !fileIsDir )
                        {
                            mobileFileDialog.openCurrentFileNow()
                        }
                    }
                }
            }
        }

        btnOpen  {
            onClicked: {
                if( mobileFileDialog.isSaveAsModus )
                {
                    mobileFileDialog.saveAsCurrentFileNow()
                }
                else
                {
                    mobileFileDialog.openCurrentFileNow()
                }
            }
        }

        btnCancel {
            onClicked: stackView.pop()
        }

        btnUp {
            onClicked: {
                mobileFileDialog.setDirectory(currentDirectory + "/..")
                mobileFileDialog.setCurrentName("")
            }
        }

        btnHome {
            onClicked: {
                mobileFileDialog.setDirectory(applicationData.homePath)
                mobileFileDialog.setCurrentName("")
            }
        }

        btnSDCard {
            onClicked: {
                if( !applicationData.hasAccessToSDCardPath() )
                {
                    applicationData.grantAccessToSDCardPath(window)
                }

                if( applicationData.hasAccessToSDCardPath() )
                {
                    mobileFileDialog.setDirectory(applicationData.sdCardPath)
                    mobileFileDialog.setCurrentName("")
                }
            }
        }

        btnStorage {
            onClicked: {
                //fileDialog.open()
                storageAccess.openFile()
            }
        }
    }

    FileDialog {
        id: fileDialog
        visible: false
        modality: Qt.WindowModal
        title: qsTr("Choose a file")
        folder: "." //StandardPaths.writableLocation(StandardPaths.DocumentsLocation) //"c:\sr"
        selectExisting: true
        selectMultiple: false
        selectFolder: false
        //nameFilters: ["Image files (*.png *.jpg)", "All files (*)"]
        //selectedNameFilter: "All files (*)"
        sidebarVisible: false
        onAccepted: {
              console.log("Accepted: " + fileUrls)
              //homePage.textArea.text = "# Hello World !\nplot sin(x)"

// TODO: https://www.volkerkrause.eu/2019/02/16/qt-open-files-on-android.html
// https://stackoverflow.com/questions/58715547/how-to-open-a-file-in-android-with-qt-having-the-content-uri

              window.readCurrentDoc(fileUrls[0])
              stackView.pop()

              //if (fileDialogOpenFiles.checked)
              //    for (var i = 0; i < fileUrls.length; ++i)
              //        Qt.openUrlExternally(fileUrls[i])
        }
        onRejected: { console.log("Rejected") }
    }

    Drawer {
        id: drawer
        width: window.width * 0.66
        height: window.height

        Column {
            anchors.fill: parent

            ItemDelegate {
                text: qsTr("Graphics")
                width: parent.width
                onClicked: {
                    stackView.pop()
                    stackView.push(graphicsPage)
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("Output")
                width: parent.width
                onClicked: {
                    stackView.pop()
                    stackView.push(outputPage)
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("Help")
                width: parent.width
                onClicked: {
                    stackView.pop()
                    stackView.push(helpPage)
                    drawer.close()
                }
            }
        }
    }

    GnuplotInvoker {
        id: gnuplotInvoker
    }

//    StorageAccess {
//        id: storageAccess
//    }

    Connections {
        target: applicationData

        onSendDummyData: {
            console.log("========> Dummy Data !!! "+txt+" "+value)
        }
    }

    Connections {
        target: storageAccess

        onOpenFileContentReceived: {
            applicationData.logText("==> onOpenFileContentReceived "+fileUri+" "+decodedFileUri)
// TODO does not work (improve!):            window.readCurrentDoc(fileUri) --> stackView.pop() not working
            homePage.currentFileUrl = fileUri
            homePage.textArea.text = content // window.readCurrentDoc(fileUri)  //content
            homePage.textArea.textDocument.modified = false
            homePage.lblFileName.text = fileUri
            stackView.pop()
        }
        onOpenFileCanceled: {
//            applicationData.logText("==> onOpenFileCanceled")
            stackView.pop()
        }
        onOpenFileError: {
//            applicationData.logText("==> onOpenFileError "+message)
// TODO
            homePage.textArea.text = message
            stackView.pop()
        }
        onCreateFileReceived: {
//            applicationData.logText("==> onCreateFileReceived "+fileUri)
// TODO
            homePage.textArea.text += "\ncreated: "+fileUri+"\n"
            homePage.lblFileName.text = fileUri
            stackView.pop()
        }
    }

    StackView {
        id: stackView
        initialItem: homePage
        anchors.fill: parent
        width: parent.width
        height: parent.height
    }
}
