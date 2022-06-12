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
        id: view
        anchors.fill: parent
        model: chatLogModel
        delegate: TextArea {
            id: delegateRoot
            padding: 0
            width: ListView.view.width
            textFormat: TextEdit.RichText
            wrapMode: Text.Wrap

            text: display

            Connections {
                target: selectionArea
                function onSelectionChanged() {
                    updateSelection();
                }
            }

            Component.onCompleted: updateSelection()

            function updateSelection() {
                if (index < selectionArea.selStartIndex || index > selectionArea.selEndIndex)
                    delegateRoot.select(0, 0);
                else if (index > selectionArea.selStartIndex && index < selectionArea.selEndIndex)
                    delegateRoot.selectAll();
                else if (index === selectionArea.selStartIndex && index === selectionArea.selEndIndex)
                    delegateRoot.select(selectionArea.selStartPos, selectionArea.selEndPos);
                else if (index === selectionArea.selStartIndex)
                    delegateRoot.select(selectionArea.selStartPos, delegateRoot.length);
                else if (index === selectionArea.selEndIndex)
                    delegateRoot.select(0, selectionArea.selEndPos);
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AlwaysOn
            minimumSize: 0.1
        }

        function indexAtRelative(x, y) {
            return indexAt(x + contentX, y + contentY)
        }
    }

    MouseArea {
        id: selectionArea
        property int selStartIndex
        property int selEndIndex
        property int selStartPos
        property int selEndPos

        signal selectionChanged

        anchors.fill: parent
        enabled: !scrollBar.hovered
        cursorShape: enabled ? Qt.IBeamCursor : Qt.ArrowCursor

        function indexAndPos(x, y) {
            const index = view.indexAtRelative(x, y);
            if (index === -1)
                return;
            const item = view.itemAtIndex(index);
            const relItemY = item.y - view.contentY;
            const pos = item.positionAt(x, y - relItemY);

            return [index, pos];
        }

        onPressed: {
            [selStartIndex, selStartPos] = indexAndPos(mouse.x, mouse.y);
            selectionChanged();
        }

        onPositionChanged: {
            [selEndIndex, selEndPos] = indexAndPos(mouse.x, mouse.y);
            selectionChanged();
        }
    }
}
