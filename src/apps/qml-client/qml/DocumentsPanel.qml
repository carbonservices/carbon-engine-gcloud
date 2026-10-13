import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CarbonEngineClient
import "BrsrMetadata.js" as BrsrMeta

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 260
    color: Theme.bgSidebar
    radius: 4
    border.color: Theme.borderCol
    border.width: 1
    clip: true

    property int tabIndex: 0
    property var activeModel: (typeof activeDocumentsModel !== "undefined") ? activeDocumentsModel : null
    property var queueModel: (typeof documentQueueModel !== "undefined") ? documentQueueModel : null
    property int currentJobId: (typeof appWindow !== "undefined") ? appWindow.currentJobId : -1
    property bool batchConfirmed: (typeof appWindow !== "undefined") ? appWindow.batchConfirmed : false
    property bool daemonConnected: (typeof appWindow !== "undefined" && appWindow.systemPoller) ? appWindow.systemPoller.isConnected : true

    signal addDocumentRequested()
    signal startProcessingRequested()
    signal cancelActiveJobRequested()

    function showQueueTab() { tabIndex = 1 }
    function showAttachedTab() { tabIndex = 0 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: "DOCUMENTS"
                font.bold: true
                font.pixelSize: 11
                color: Theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Label {
                visible: root.currentJobId >= 0
                text: "Report #" + root.currentJobId
                font.pixelSize: 10
                font.bold: true
                color: Theme.brandAccent
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                id: attachedTabRect
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 3
                color: root.tabIndex === 0 ? Theme.bgActive : Theme.bgSubtle
                border.color: root.tabIndex === 0 ? Theme.brandAccent : Theme.borderSubtle
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: "Attached (" + (root.activeModel ? root.activeModel.count : 0) + ")"
                    font.pixelSize: 11
                    font.bold: root.tabIndex === 0
                    color: root.tabIndex === 0 ? Theme.textBright : Theme.textMuted
                }

                ToolTip.visible: attachedMouse.containsMouse
                ToolTip.delay: 350
                ToolTip.text: "Attached: Ingested documents already linked to the active report that are indexed in vector memory."

                MouseArea {
                    id: attachedMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabIndex = 0
                }
            }

            Rectangle {
                id: stagingTabRect
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 3
                color: root.tabIndex === 1 ? Theme.bgActive : Theme.bgSubtle
                border.color: root.tabIndex === 1 ? Theme.brandAccent : Theme.borderSubtle
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: (root.queueModel && root.queueModel.count > 0) ? ("Queue (" + root.queueModel.count + ")") : "Staging"
                    font.pixelSize: 11
                    font.bold: root.tabIndex === 1
                    color: (root.queueModel && root.queueModel.count > 0) ? Theme.brandAccent : (root.tabIndex === 1 ? Theme.textBright : Theme.textMuted)
                }

                ToolTip.visible: stagingMouse.containsMouse
                ToolTip.delay: 350
                ToolTip.text: "Staging: Upload queue of selected files waiting to be ingested and vectorized into the knowledge base."

                MouseArea {
                    id: stagingMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabIndex = 1
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderCol }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Item {
                anchors.fill: parent
                visible: root.tabIndex === 0

                ListView {
                    id: attachedList
                    anchors.fill: parent
                    visible: root.activeModel && root.activeModel.count > 0
                    model: root.activeModel
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: attachedList.width
                        height: 36
                        color: Theme.bgSubtle
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Text {
                                text: "📄"
                                font.pixelSize: 14
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Label {
                                    Layout.fillWidth: true
                                    text: model.fileName
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    color: Theme.textBright
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: {
                                        if (model.chunkCount > 0) {
                                            return model.chunkCount + " chunks" + (model.pageCount > 0 ? (" • " + model.pageCount + " pgs") : "")
                                        }
                                        if (model.status === BrsrMeta.DocumentStatus.Processing) return "Processing document..."
                                        if (model.status === BrsrMeta.DocumentStatus.Queued) return "Queued for ingestion"
                                        return "Ingested"
                                    }
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: badgeText.implicitWidth + 8
                                radius: 3
                                color: {
                                    if (model.status === BrsrMeta.DocumentStatus.Ingested || model.status === "COMPLETED") return Qt.rgba(0.06, 0.73, 0.51, 0.15)
                                    if (model.status === BrsrMeta.DocumentStatus.Processing) return Qt.rgba(0.23, 0.51, 0.96, 0.15)
                                    if (model.status === BrsrMeta.DocumentStatus.Failed) return Qt.rgba(0.94, 0.27, 0.27, 0.15)
                                    return Qt.rgba(0.92, 0.70, 0.03, 0.15)
                                }

                                Label {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: model.status || "INGESTED"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: {
                                        if (model.status === BrsrMeta.DocumentStatus.Ingested || model.status === "COMPLETED") return Theme.successColor
                                        if (model.status === BrsrMeta.DocumentStatus.Processing) return Theme.brandAccent
                                        if (model.status === BrsrMeta.DocumentStatus.Failed) return Theme.dangerColor
                                        return Theme.warningColor
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !root.activeModel || root.activeModel.count === 0
                    spacing: 4

                    Label {
                        text: "No documents attached to report"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Select a report or ingest files from Staging"
                        font.pixelSize: 10
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.tabIndex === 1

                ListView {
                    id: queueList
                    anchors.fill: parent
                    visible: root.queueModel && root.queueModel.count > 0
                    model: root.queueModel
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: queueList.width
                        height: 30
                        color: Theme.bgSubtle
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Text {
                                text: "📄"
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.fillWidth: true
                                text: model.fileName
                                elide: Text.ElideMiddle
                                font.pixelSize: 11
                                color: Theme.textMain
                            }

                            Rectangle {
                                visible: !root.batchConfirmed
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                radius: 3
                                color: removeMouse.containsMouse ? Theme.bgHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: removeMouse.containsMouse ? Theme.dangerColor : Theme.textMuted
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: removeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.queueModel) root.queueModel.remove(index)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !root.queueModel || root.queueModel.count === 0
                    spacing: 4

                    Label {
                        text: "Staging queue is empty"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Click '+ Add Document' to stage PDF files"
                        font.pixelSize: 10
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderCol }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: "+ Add Document"
                enabled: !root.batchConfirmed
                Layout.preferredHeight: 28
                background: Rectangle {
                    color: !parent.enabled ? "transparent"
                        : (parent.down ? Theme.bgActive
                        : (parent.hovered ? Theme.bgHover : Theme.bgSubtle))
                    border.color: Theme.borderSubtle
                    border.width: 1
                    radius: 3
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.enabled ? Theme.textMain : Theme.textMuted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.addDocumentRequested()
            }

            Item { Layout.fillWidth: true }

            Button {
                id: ingestBtn
                text: root.batchConfirmed ? "Cancel Ingestion" : "Start Ingestion"
                enabled: root.batchConfirmed || (root.daemonConnected && root.queueModel && root.queueModel.count > 0)
                Layout.preferredHeight: 28
                background: Rectangle {
                    color: !ingestBtn.enabled ? Theme.bgSubtle
                        : (root.batchConfirmed ? (ingestBtn.hovered ? "#dc2626" : Theme.dangerColor)
                        : (ingestBtn.down ? Theme.brandAccentPressed
                        : (ingestBtn.hovered ? Theme.brandAccentHover : Theme.brandAccent)))
                    radius: 3
                }
                contentItem: Text {
                    text: ingestBtn.text
                    color: ingestBtn.enabled ? (root.batchConfirmed ? "#ffffff" : Theme.textBright) : Theme.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (root.batchConfirmed) {
                        root.cancelActiveJobRequested()
                    } else {
                        root.startProcessingRequested()
                    }
                }
            }
        }
    }
}
