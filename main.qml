import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    width: 600
    height: 500
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
        spacing: 20
        anchors.fill: parent
        keyNavigationEnabled: true
        model: chatLogModel
        delegate: TextArea {
            id: delegateRoot
            padding: 0
            width: ListView.view.width
            textFormat: TextEdit.PlainText
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
                var actualStartIndex = Math.min(selectionArea.selStartIndex, selectionArea.selEndIndex);
                var actualEndIndex = Math.max(selectionArea.selStartIndex, selectionArea.selEndIndex);
                var actualStartPos = selectionArea.selStartIndex < selectionArea.selEndIndex ? selectionArea.selStartPos : selectionArea.selEndPos;
                var actualEndPos = selectionArea.selStartIndex < selectionArea.selEndIndex ? selectionArea.selEndPos : selectionArea.selStartPos;

                if (index < actualStartIndex || index > actualEndIndex)
                    delegateRoot.deselect();
                else if (index > actualStartIndex && index < actualEndIndex)
                    delegateRoot.selectAll();
                else if (index === actualStartIndex && index === actualEndIndex)
                    delegateRoot.select(actualStartPos, actualEndPos);
                else if (index === actualStartIndex)
                    delegateRoot.select(actualStartPos, delegateRoot.length);
                else if (index === actualEndIndex)
                    delegateRoot.select(0, actualEndPos);

                if (!(index < actualStartIndex || index > actualEndIndex) && actualStartPos !== actualEndPos) {
                    cursorVisible = false;
                }
            }

            function selectWordAtPos(pos) {
                cursorVisible = false;
                cursorPosition = pos;
                selectWord();
                return [selectionStart, selectionEnd];
            }

            function findLineStartAndEndPostitionAtPos(str, charPos){
                let lines = str.split('\n');
                let totalChars = 0;

                for(let i = 0; i < lines.length; i++) {
                    if(totalChars + lines[i].length >= charPos) {
                        return [totalChars, totalChars + lines[i].length];
                    }
                    totalChars += lines[i].length + 1; // +1 for the newline character
                }

                return [0, str.length];
            }

            // For this to function to support `TextEdit.RichText`, we'll need to convert the rich text
            // To plain text, or find the line's start and end positions within the rich text.
            function selectLineAtPos(pos) {
                cursorVisible = false;
                cursorPosition = pos;
                const [lineStart, lineEnd] = findLineStartAndEndPostitionAtPos(delegateRoot.text, pos);
                delegateRoot.select(lineStart, lineEnd);
                return [selectionStart, selectionEnd];
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

        property bool isWordSelected: false
        property int wordIndex
        property int wordStartPos
        property int wordEndPos

        property bool canTripleClick: false
        property bool isLineSelected: false
        property int lineIndex
        property int lineStartPos
        property int lineEndPos

        property int scrollTriggerZone: 50
        property int currentScrollDirection: 0 // 0 - no scroll, 1 - scroll up, -1 - scroll down (TODO: change to enum)

        signal selectionChanged

        anchors.fill: parent
        enabled: !scrollBar.hovered
        cursorShape: enabled ? Qt.IBeamCursor : Qt.ArrowCursor

        function indexAndPos(x, y) {
            const index = view.indexAtRelative(x, y);
            if (index === -1)
                return [-1, -1];
            const item = view.itemAtIndex(index);
            const relItemY = item.y - view.contentY;
            const pos = item.positionAt(x, y - relItemY);
            item.forceActiveFocus();
            item.cursorPosition = pos;
            return [index, pos];
        }

        onPressed: (mouse) => {
           if (canTripleClick) {
               isWordSelected = false;
               isLineSelected = true;
               canTripleClick = false;
               const [index, pos] = indexAndPos(mouse.x, mouse.y);
               if (index === -1) return;
               const item = view.itemAtIndex(index);
               [lineStartPos, lineEndPos] = item.selectLineAtPos(pos);
               lineIndex = index;
           } else {
               isWordSelected = false;
               isLineSelected = false;
               [selStartIndex, selStartPos] = indexAndPos(mouse.x, mouse.y);
               if (selStartIndex === -1) return;
               const item = view.itemAtIndex(selStartIndex);
               item.cursorVisible = true;
               [selEndIndex, selEndPos] = [selStartIndex, selStartPos]
               selectionChanged();
           }
        }

        onPositionChanged: (mouse) => {
            if (isLineSelected) {
               const [index, pos] = indexAndPos(mouse.x, mouse.y);
               if (index === -1) return;
               const item = view.itemAtIndex(index);
               const lineRange = item.selectLineAtPos(pos);
               if (index < lineIndex || (index === lineIndex && lineRange[0] < lineStartPos)) {
                   selStartIndex = index;
                   selStartPos = lineRange[0];
                   selEndIndex = lineIndex;
                   selEndPos = lineEndPos;
               } else {
                   selStartIndex = lineIndex;
                   selStartPos = lineStartPos;
                   selEndIndex = index;
                   selEndPos = lineRange[1];
               }
            } else if (isWordSelected) {
                const [index, pos] = indexAndPos(mouse.x, mouse.y);
                if (index === -1) return;
                const item = view.itemAtIndex(index);
                const wordRange = item.selectWordAtPos(pos);
                if (index < wordIndex || (index === wordIndex && wordRange[0] < wordStartPos)) {
                    selStartIndex = index;
                    selStartPos = wordRange[0];
                    selEndIndex = wordIndex;
                    selEndPos = wordEndPos;
                } else {
                    selStartIndex = wordIndex;
                    selStartPos = wordStartPos;
                    selEndIndex = index;
                    selEndPos = wordRange[1];
                }
            } else {
                [selEndIndex, selEndPos] = indexAndPos(mouse.x, mouse.y);
                if (selEndIndex === -1) return;
            }
            selectionChanged();

            if(mouse.y < selectionArea.y + scrollTriggerZone) {
                let relativePos = (selectionArea.y + scrollTriggerZone - mouse.y) / scrollTriggerZone;
                let pixelsPerSec = 200 + relativePos * 1000;
                scrollUpAnimation.duration = Math.max(calculateScrollTimeBasedOnPixelSpeed(-1, pixelsPerSec), 0);
                scrollUpAnimation.restart();
                currentScrollDirection = -1;
            } else if (mouse.y > selectionArea.y + selectionArea.height - scrollTriggerZone) {
                let relativePos = (mouse.y - (selectionArea.y + selectionArea.height - scrollTriggerZone)) / scrollTriggerZone;
                let pixelsPerSec = 200 + relativePos * 1000;
                scrollDownAnimation.duration = Math.max(calculateScrollTimeBasedOnPixelSpeed(1, pixelsPerSec), 0);
                scrollDownAnimation.restart();
                currentScrollDirection = 1;
            } else {
                currentScrollDirection = 0;
            }
        }

        onReleased: {
            currentScrollDirection = 0;
        }

        PropertyAnimation {
            id: scrollUpAnimation
            target: view
            property: "contentY"
            to: 0
            running: selectionArea.currentScrollDirection === -1
        }

        PropertyAnimation {
            id: scrollDownAnimation
            target: view
            property: "contentY"
            to: view.contentHeight - view.height
            running: selectionArea.currentScrollDirection === 1
        }

        function calculateScrollTimeBasedOnPixelSpeed(direction, pixelsPerSec, accelerationRatio) {
            var pixelsToTravel;
            if(direction === -1) {
               pixelsToTravel = view.contentY;
            } else if (direction === 1) {
               pixelsToTravel = Math.abs(view.contentHeight - view.contentY + view.height);
            }
            return pixelsToTravel / pixelsPerSec * 1000;
        }

        onDoubleClicked: (mouse) => {
            selectionArea.canTripleClick = true;
            tripleClickTimer.start();
            const [index, pos] = indexAndPos(mouse.x, mouse.y);
            if (index === -1) return;
            const item = view.itemAtIndex(index);
            [wordStartPos, wordEndPos] = item.selectWordAtPos(pos);
            isWordSelected = true;
            wordIndex = index;
        }

        Timer {
            id: tripleClickTimer
            interval: 400

            onTriggered: {
                selectionArea.canTripleClick = false;
            }
        }
    }
}
