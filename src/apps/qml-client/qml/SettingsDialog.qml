import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CarbonEngineClient

Popup {
    id: settingsDialog
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: Math.min(620, parent.width - 40)
    height: Math.min(720, parent.height - 40)
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    padding: 0

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.borderDialog
        border.width: 1
        radius: 8
    }

    property var modeClient: (typeof appWindow !== "undefined" && appWindow.globalModeClient) ? appWindow.globalModeClient : null
    property bool isBackendConnected: (typeof appWindow !== "undefined" && appWindow.systemPoller) ? appWindow.systemPoller.isConnected : false

    onOpened: {
        if (settingsDialog.parent) {
            settingsDialog.x = Math.round((settingsDialog.parent.width - width) / 2)
            settingsDialog.y = Math.round((settingsDialog.parent.height - height) / 2)
        }
        if (!modeClient) return
        modeClient.fetchMode()
        cloudToggle.checked = modeClient.cloudEnabled
        apiKeyInput.text = modeClient.apiKey
        if (apiKeyInput.text.trim().length > 10) {
            modeClient.fetchAvailableModels(apiKeyInput.text.trim())
        }
        var idx = modeClient.availableModels.indexOf(modeClient.cloudModel)
        if (idx >= 0) {
            modelCombo.currentIndex = idx
        }
        var embIdx = modeClient.availableEmbeddingModels.indexOf(modeClient.embeddingModel)
        if (embIdx >= 0) {
            embeddingModelCombo.currentIndex = embIdx
        }
    }

    Connections {
        target: modeClient
        function onSettingsSaved() {
            settingsDialog.close()
        }
        function onCloudModelChanged() {
            var idx = modeClient.availableModels.indexOf(modeClient.cloudModel)
            if (idx >= 0) modelCombo.currentIndex = idx
        }
        function onEmbeddingModelChanged() {
            var idx = modeClient.availableEmbeddingModels.indexOf(modeClient.embeddingModel)
            if (idx >= 0) embeddingModelCombo.currentIndex = idx
        }
        function onAvailableModelsChanged() {
            var idx = modeClient.availableModels.indexOf(modeClient.cloudModel)
            if (idx >= 0) modelCombo.currentIndex = idx
        }
        function onAvailableEmbeddingModelsChanged() {
            var idx = modeClient.availableEmbeddingModels.indexOf(modeClient.embeddingModel)
            if (idx >= 0) embeddingModelCombo.currentIndex = idx
        }
        function onApiKeyChanged() {
            if (apiKeyInput.text !== modeClient.apiKey) {
                apiKeyInput.text = modeClient.apiKey
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Title Bar (Draggable)
        Rectangle {
            id: titleBarRect
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: Theme.bgHeader
            radius: 8

            // Flatten bottom corners of the header
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                color: Theme.bgHeader
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.borderCol
            }

            // Drag handler to allow moving the dialog around the application window
            MouseArea {
                id: titleBarDragArea
                anchors.fill: parent
                anchors.rightMargin: 46
                cursorShape: Qt.SizeAllCursor
                property point dragStart: Qt.point(0, 0)
                property point popupStart: Qt.point(0, 0)

                onPressed: (mouse) => {
                    dragStart = mapToItem(null, mouse.x, mouse.y)
                    popupStart = Qt.point(settingsDialog.x, settingsDialog.y)
                }
                onPositionChanged: (mouse) => {
                    if (pressed && settingsDialog.parent) {
                        var curScene = mapToItem(null, mouse.x, mouse.y)
                        var nx = popupStart.x + (curScene.x - dragStart.x)
                        var ny = popupStart.y + (curScene.y - dragStart.y)
                        var maxX = Math.max(0, settingsDialog.parent.width - settingsDialog.width)
                        var maxY = Math.max(0, settingsDialog.parent.height - settingsDialog.height)
                        settingsDialog.x = Math.max(0, Math.min(maxX, nx))
                        settingsDialog.y = Math.max(0, Math.min(maxY, ny))
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Label {
                    text: "Processing & Cloud Settings"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textBright
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 4
                    color: closeMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsDialog.close()
                    }
                }
            }
        }

        // Scrollable Body
        ScrollView {
            id: bodyScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            contentHeight: contentCol.implicitHeight + 36

            ColumnLayout {
                id: contentCol
                width: bodyScrollView.availableWidth - 36
                x: 18
                y: 18
                spacing: 16

                // Backend Disconnected Notice Banner
                Rectangle {
                    visible: !settingsDialog.isBackendConnected
                    Layout.fillWidth: true
                    color: Theme.isDarkMode ? "#2e1e1a" : "#fff1f0"
                    border.color: Theme.dangerColor
                    border.width: 1
                    radius: 6
                    implicitHeight: discLayout.implicitHeight + 20

                    RowLayout {
                        id: discLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "⚠️"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignTop
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Label {
                                text: "Backend Daemon Disconnected"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.dangerColor
                            }

                            Label {
                                text: "The carbon-engine daemon is not currently reachable on localhost:8080. Operating strictly in local offline mode with on-device Gemma 2 2B and BGE Small embedding models."
                                font.pixelSize: 10
                                color: Theme.isDarkMode ? "#fca5a5" : "#991b1b"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Section 1: Mode Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: Theme.bgSubtle
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Label {
                                text: "Google Cloud Processing"
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textBright
                            }
                            Label {
                                text: {
                                    if (!settingsDialog.isBackendConnected) {
                                        return "Backend offline • Using Local On-Device Gemma 2 2B & BGE Small Embeddings"
                                    }
                                    return cloudToggle.checked
                                        ? "Using Google Cloud Gemini API & Embeddings (Configure models below)"
                                        : "Using Local On-Device Gemma 2 2B & BGE Small Embeddings (Air-gapped offline)"
                                }
                                font.pixelSize: 11
                                color: (!settingsDialog.isBackendConnected) ? Theme.warningColor : Theme.textMuted
                            }
                        }

                        Switch {
                            id: cloudToggle
                            checked: modeClient.cloudEnabled && settingsDialog.isBackendConnected
                            enabled: settingsDialog.isBackendConnected
                            padding: 0

                            indicator: Rectangle {
                                implicitWidth: 40
                                implicitHeight: 22
                                radius: 11
                                color: cloudToggle.checked
                                    ? (cloudToggle.hovered ? Theme.brandAccentHover : Theme.brandAccent)
                                    : (cloudToggle.hovered ? (Theme.isDarkMode ? "#484848" : "#c4c4c4") : (Theme.isDarkMode ? "#3c3c3c" : "#d0d0d0"))
                                border.color: cloudToggle.checked ? Theme.brandAccent : Theme.borderSubtle
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                Rectangle {
                                    x: cloudToggle.checked ? (parent.width - width - 3) : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#ffffff"

                                    Behavior on x {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }

                // Section 2: Disclaimer (Prominently displayed when Cloud is enabled)
                Rectangle {
                    id: disclaimerBox
                    visible: cloudToggle.checked
                    Layout.fillWidth: true
                    color: Theme.isDarkMode ? "#2a2415" : "#fffbeb"
                    border.color: Theme.warningColor
                    border.width: 1
                    radius: 6
                    implicitHeight: disclaimerLayout.implicitHeight + 20

                    RowLayout {
                        id: disclaimerLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "⚠️"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignTop
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "Google AI Studio Free Tier Data Processing Notice"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.warningColor
                            }

                            Label {
                                id: disclaimerTextLabel
                                text: modeClient.disclaimer
                                font.pixelSize: 10
                                color: Theme.isDarkMode ? "#dfd5c0" : "#92400e"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Section 3: Cloud Parameters Form Card (Visible when Cloud is enabled)
                Rectangle {
                    visible: cloudToggle.checked
                    Layout.fillWidth: true
                    implicitHeight: formLayout.implicitHeight + 28
                    color: Theme.bgSubtle
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        id: formLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 16

                        Label {
                            text: "Cloud Service Configuration"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textBright
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderCol
                        }

                        // Row 1: API Key
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Label {
                                text: "API Key"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textBright
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 8
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    TextField {
                                        id: apiKeyInput
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        text: modeClient.apiKey
                                        placeholderText: "Enter AI Studio API Key (AIzaSy...)"
                                        echoMode: showKeyBtn.checked ? TextInput.Normal : TextInput.Password
                                        color: Theme.textBright
                                        font.pixelSize: 12
                                        background: Rectangle {
                                            color: Theme.bgInput
                                            border.color: apiKeyInput.activeFocus ? Theme.brandAccent : Theme.borderCol
                                            border.width: 1
                                            radius: 4
                                        }
                                        onEditingFinished: {
                                            if (text.trim().length > 10) {
                                                modeClient.apiKey = text.trim()
                                                modeClient.fetchAvailableModels(text.trim())
                                            }
                                        }
                                    }

                                    Button {
                                        id: showKeyBtn
                                        checkable: true
                                        text: checked ? "Hide" : "Show"
                                        Layout.preferredHeight: 34
                                        Layout.preferredWidth: 65
                                        background: Rectangle {
                                            color: showKeyBtn.hovered ? Theme.bgHover : Theme.bgSubtle
                                            border.color: Theme.borderCol
                                            border.width: 1
                                            radius: 4
                                        }
                                        contentItem: Text {
                                            text: showKeyBtn.text
                                            color: Theme.textMain
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                Label {
                                    text: "Key is saved securely in local application settings."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }

                        // Row 2: Inference Model
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Label {
                                text: "Inference Model"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textBright
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 8
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                ComboBox {
                                    id: modelCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    model: modeClient ? modeClient.availableModels : []
                                    currentIndex: (modeClient && modeClient.availableModels && modeClient.availableModels.length > 0)
                                        ? Math.max(0, modeClient.availableModels.indexOf(modeClient.cloudModel))
                                        : -1
                                    onActivated: function(index) {
                                        if (modeClient) modeClient.cloudModel = modelCombo.textAt(index)
                                    }

                                    background: Rectangle {
                                        color: Theme.bgInput
                                        border.color: Theme.borderCol
                                        border.width: 1
                                        radius: 4
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        text: modelCombo.displayText
                                        color: Theme.textBright
                                        font.pixelSize: 12
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Label {
                                    text: "Inference model for statutory BRSR extraction and narrative reasoning."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }

                        // Row 3: Embedding Model
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Label {
                                text: "Embedding Model"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textBright
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 8
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                ComboBox {
                                    id: embeddingModelCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    model: modeClient ? modeClient.availableEmbeddingModels : []
                                    currentIndex: (modeClient && modeClient.availableEmbeddingModels && modeClient.availableEmbeddingModels.length > 0)
                                        ? Math.max(0, modeClient.availableEmbeddingModels.indexOf(modeClient.embeddingModel))
                                        : -1
                                    onActivated: function(index) {
                                        if (modeClient) modeClient.embeddingModel = embeddingModelCombo.textAt(index)
                                    }

                                    background: Rectangle {
                                        color: Theme.bgInput
                                        border.color: Theme.borderCol
                                        border.width: 1
                                        radius: 4
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        text: embeddingModelCombo.displayText
                                        color: Theme.textBright
                                        font.pixelSize: 12
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Label {
                                    text: "Gemini embedding models (e.g. text-embedding-004) for ESG document retrieval."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }

                        // Row 4: Connection Test & Status
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Label {
                                text: "Connection"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textBright
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 7
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Button {
                                        id: testBtn
                                        text: modeClient.isTesting ? "Testing..." : "Test Cloud Connection"
                                        enabled: !modeClient.isTesting && apiKeyInput.text.trim().length > 0 && settingsDialog.isBackendConnected
                                        Layout.preferredHeight: 32
                                        Layout.preferredWidth: 160
                                        background: Rectangle {
                                            color: testBtn.hovered ? Theme.bgHover : Theme.bgSubtle
                                            border.color: Theme.borderCol
                                            border.width: 1
                                            radius: 4
                                        }
                                        contentItem: Text {
                                            text: testBtn.text
                                            color: testBtn.enabled ? Theme.textBright : Theme.textMuted
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            modeClient.apiKey = apiKeyInput.text.trim()
                                            modeClient.cloudModel = modelCombo.currentText
                                            modeClient.embeddingModel = embeddingModelCombo.currentText
                                            modeClient.testConnection()
                                        }
                                    }

                                    Label {
                                        visible: modeClient.isTesting
                                        text: "Contacting Google AI Studio..."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Test Result Display
                                Rectangle {
                                    id: testResultBox
                                    visible: modeClient.testSuccess || modeClient.testError !== "" || modeClient.inferenceTestError !== "" || modeClient.embeddingTestError !== ""
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(48, testResultLayout.implicitHeight + 16)
                                    color: modeClient.testSuccess
                                        ? (Theme.isDarkMode ? "#17331e" : "#dcfce7")
                                        : (modeClient.inferenceTestSuccess || modeClient.embeddingTestSuccess
                                            ? (Theme.isDarkMode ? "#332a17" : "#fef3c7")
                                            : Theme.badgeDangerBg)
                                    border.color: modeClient.testSuccess
                                        ? Theme.successColor
                                        : (modeClient.inferenceTestSuccess || modeClient.embeddingTestSuccess
                                            ? Theme.warningColor
                                            : Theme.badgeDangerBorder)
                                    border.width: 1
                                    radius: 4

                                    RowLayout {
                                        id: testResultLayout
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Text {
                                            text: modeClient.testSuccess ? "✓" : (modeClient.inferenceTestSuccess || modeClient.embeddingTestSuccess ? "⚠" : "✕")
                                            font.pixelSize: 13
                                            color: modeClient.testSuccess
                                                ? Theme.successColor
                                                : (modeClient.inferenceTestSuccess || modeClient.embeddingTestSuccess
                                                    ? Theme.warningColor
                                                    : Theme.badgeDangerText)
                                            Layout.alignment: Qt.AlignTop
                                            Layout.topMargin: 1
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            // Inference Model Status
                                            Label {
                                                Layout.fillWidth: true
                                                text: modeClient.inferenceTestSuccess
                                                    ? ("Inference (" + modelCombo.currentText + "): Connected (" + modeClient.testLatencyMs + " ms)")
                                                    : ("Inference (" + modelCombo.currentText + ") Failed: " + (modeClient.inferenceTestError !== "" ? modeClient.inferenceTestError : (modeClient.testError || "Connection error")))
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: modeClient.inferenceTestSuccess ? Theme.successColor : Theme.badgeDangerText
                                                wrapMode: Text.WordWrap
                                            }

                                            // Embedding Model Status
                                            Label {
                                                Layout.fillWidth: true
                                                text: modeClient.embeddingTestSuccess
                                                    ? ("Embedding (" + embeddingModelCombo.currentText + "): Connected (" + modeClient.embeddingDim + " dims, " + modeClient.embeddingTestLatencyMs + " ms)")
                                                    : ("Embedding (" + embeddingModelCombo.currentText + ") Failed: " + (modeClient.embeddingTestError !== "" ? modeClient.embeddingTestError : (modeClient.testError || "Connection error")))
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: modeClient.embeddingTestSuccess ? Theme.successColor : Theme.badgeDangerText
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Section 4: Offline Mode Details (Visible when Local is selected or Backend is disconnected)
                Rectangle {
                    visible: !cloudToggle.checked || !settingsDialog.isBackendConnected
                    Layout.fillWidth: true
                    implicitHeight: offlineLayout.implicitHeight + 24
                    color: Theme.bgSubtle
                    border.color: Theme.borderCol
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        id: offlineLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 12

                        Label {
                            text: "Local On-Device Models (Offline Engine)"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textBright
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderCol
                        }

                        // Local Inference Model
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                text: "🧠"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignTop
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: "Inference Model (LLM): Google Gemma 2 2B Instruct"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textBright
                                }

                                Label {
                                    text: "Model file: models/gemma-2-2b-it-q4_k_m.gguf (Q4_K_M quantized GGUF)\nRuntime: llama.cpp engine with GPU acceleration (CUDA) fallback to AVX2 CPU."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Local Embedding Model
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                text: "🔍"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignTop
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: "Embedding Model: BAAI BGE Small EN v1.5"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textBright
                                }

                                Label {
                                    text: "Model file: models/bge-small-en-v1.5-f16.gguf (384 dimensions)\nRuntime: Local embedding processor with FAISS HNSW vector indexing."
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderSubtle
                        }

                        Label {
                            text: "🔒 Complete Data Privacy: All statutory BRSR extractions and vector similarity searches execute 100% on-device with zero network traffic."
                            font.pixelSize: 10
                            color: Theme.isDarkMode ? "#a3e635" : "#4d7c0f"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // Footer Actions
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: Theme.bgHeader
            radius: 8

            // Flatten top corners of the footer
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                color: Theme.bgHeader
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

                Label {
                    text: (!settingsDialog.isBackendConnected) ? "Backend disconnected" : modeClient.statusMessage
                    font.pixelSize: 11
                    color: (!settingsDialog.isBackendConnected) ? Theme.dangerColor : Theme.successColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Button {
                    text: "Cancel"
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 80
                    background: Rectangle {
                        color: parent.down ? Theme.bgActive
                             : (parent.hovered ? Theme.bgHover : "transparent")
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
                    onClicked: settingsDialog.close()
                }

                Button {
                    id: saveBtn
                    text: "Save"
                    enabled: settingsDialog.isBackendConnected
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 80
                    background: Rectangle {
                        color: !saveBtn.enabled ? Theme.bgSubtle
                             : (saveBtn.down ? Theme.brandAccentPressed
                             : (saveBtn.hovered ? Theme.brandAccentHover : Theme.brandAccent))
                        radius: 4
                    }
                    contentItem: Text {
                        text: saveBtn.text
                        color: saveBtn.enabled ? "#ffffff" : Theme.textMuted
                        font.bold: true
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        modeClient.saveSettings(
                            cloudToggle.checked,
                            apiKeyInput.text.trim(),
                            modelCombo.currentText,
                            embeddingModelCombo.currentText
                        )
                    }
                }
            }
        }
    }

    // Modal dialog border overlay ensures crisp, unclipped perimeter
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Theme.borderDialog
        border.width: 1
        radius: 8
        z: 999
        enabled: false
    }
}

