import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    width: 200
    height: 400
    visible: true
    title: qsTr("Text is ez")

    menuBar: MenuBar {
        Menu {
            title: qsTr("Load")

            MenuItem {
                text: qsTr("Chat History")
                onTriggered: textArea.text = chatLog
            }
        }
    }

    // 1. TextArea
//    ScrollView {
//        id: view
//        anchors.fill: parent

//        TextArea {
//            id: textArea
//            textFormat: TextEdit.RichText
//            wrapMode: Text.Wrap
//            selectByKeyboard: true
//            selectByMouse: true
//        }
//    }

    // 2. ListView
    ListView {
        anchors.fill: parent
        model: chatLogModel
        delegate: TextArea {
            padding: 0
            width: ListView.view.width
            textFormat: TextEdit.RichText
            wrapMode: Text.Wrap
            selectByKeyboard: true
            selectByMouse: true

            text: display
        }
    }
}
