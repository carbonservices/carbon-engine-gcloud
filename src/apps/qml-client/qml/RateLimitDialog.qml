import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CarbonEngineClient

Popup {
    id: rateLimitDialog
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.NoAutoClose

    width: Math.min(580, parent.width - 40)
    height: Math.min(540, parent.height - 40)
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    padding: 0

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.warningColor
        border.width: 1
        radius: 8
    }

    property string errorText: ""
    property string modelName: ""
    property string sectionName: ""
    property string limitType: "INFERENCE"
    property int jobId: -1

    signal resolved(string action, string newModel)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: Theme.isDarkMode ? "#2d1a10" : "#fff1e6"
            radius: 8

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                color: parent.color
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.warningColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    text: "⚠️"
                    font.pixelSize: 16
                }

                Label {
                    text: "Google Cloud API Rate Limit Exceeded (HTTP 429)"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.warningColor
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Body
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 32
                x: 16
                y: 14
                spacing: 12

                Label {
                    text: "The Google AI Studio API has throttled requests for model '" + (rateLimitDialog.modelName !== "" ? rateLimitDialog.modelName : globalModeClient.cloudModel) + "'."
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textBright
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    visible: rateLimitDialog.sectionName !== ""
                    text: "Current Stage: " + rateLimitDialog.sectionName
                    font.pixelSize: 11
                    color: Theme.brandAccent
                    Layout.fillWidth: true
                }

                // Error detail box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: errorDetailText.implicitHeight + 16
                    color: Theme.isDarkMode ? "#1f1814" : "#fbf2eb"
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 4

                    Text {
                        id: errorDetailText
                        anchors.fill: parent
                        anchors.margins: 8
                        text: rateLimitDialog.errorText !== ""
                            ? rateLimitDialog.errorText
                            : "API rate limit reached. Please choose an option below to proceed."
                        font.pixelSize: 10
                        font.family: "Consolas, monospace"
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                    }
                }

                Label {
                    text: "To avoid unintended delays or charges, choose an explicit resolution below:"
                    font.pixelSize: 11
                    color: Theme.textMuted
                    Layout.fillWidth: true
                }

                // Option 1: Switch Cloud Model
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: opt1Col.implicitHeight + 16
                    color: Theme.bgSubtle
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        id: opt1Col
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Label {
                            text: rateLimitDialog.limitType === "EMBEDDING"
                                ? "Option 1: Switch to Another Embedding Model"
                                : "Option 1: Switch to Another Cloud Model"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textBright
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ComboBox {
                                id: fallbackModelCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                model: rateLimitDialog.limitType === "EMBEDDING"
                                    ? globalModeClient.availableEmbeddingModels
                                    : globalModeClient.availableModels

                                background: Rectangle {
                                    color: Theme.bgInput
                                    border.color: Theme.borderCol
                                    border.width: 1
                                    radius: 4
                                }
                                contentItem: Text {
                                    leftPadding: 8
                                    text: fallbackModelCombo.displayText
                                    color: Theme.textBright
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Button {
                                text: "Switch & Continue"
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 140
                                background: Rectangle {
                                    color: parent.hovered ? Theme.brandAccentHover : Theme.brandAccent
                                    radius: 4
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    var chosen = fallbackModelCombo.currentText
                                    rateLimitDialog.resolved("switch_model", chosen)
                                    rateLimitDialog.close()
                                }
                            }
                        }
                    }
                }

                // Option 2: Switch to Local LLM
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: opt2Col.implicitHeight + 16
                    color: Theme.bgSubtle
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        id: opt2Col
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: "Option 2: Switch to Local On-Device Engine"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textBright
                                }
                                Label {
                                    text: "Executes strictly offline via Google Gemma 2 2B Instruct / BGE. Air-gapped and zero API quota."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            Button {
                                text: "Switch to Local"
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 140
                                background: Rectangle {
                                    color: parent.hovered ? Theme.bgHover : Theme.bgActive
                                    border.color: Theme.borderCol
                                    border.width: 1
                                    radius: 4
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Theme.textBright
                                    font.bold: true
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    rateLimitDialog.resolved("switch_local", "")
                                    rateLimitDialog.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.bgHeader
            radius: 8

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                color: parent.color
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.borderCol
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    text: "Wait & Retry"
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 100
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"
                        border.color: Theme.borderCol
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textMain
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        rateLimitDialog.resolved("retry", "")
                        rateLimitDialog.close()
                    }
                }

                Button {
                    text: "Cancel Job"
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 90
                    background: Rectangle {
                        color: parent.hovered ? Theme.badgeDangerBg : "transparent"
                        border.color: Theme.badgeDangerBorder
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.badgeDangerText
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        rateLimitDialog.resolved("cancel", "")
                        rateLimitDialog.close()
                    }
                }
            }
        }
    }
}

