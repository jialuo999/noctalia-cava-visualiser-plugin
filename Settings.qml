import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null
    property int editFrameRate:
        pluginApi?.pluginSettings?.framerate ??
        pluginApi?.manifest?.metadata?.defaultSettings?.framerate ??
        30
    property int editBarCount:
        pluginApi?.pluginSettings?.bars ??
        pluginApi?.manifest?.metadata?.defaultSettings?.bars ??
        12
    
    NText {
        text: "Hello World"
        font.pointSize: Style.fontSizeL
        color: Color.mOnSurface
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: "Frame Rate"
            description: "Refresh rate of the visualizer: " + root.editFrameRate
        }

        NSlider {
            Layout.fillWidth: true
            from: 5
            to: 120
            stepSize: 1
            value: root.editFrameRate
            onValueChanged: root.editFrameRate = value
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Bar Count"
        description: "Number of bars in the visualizer"
        placeholderText: "12"
        text: String(root.editBarCount)
        onTextChanged: root.editBarCount = parseInt(text)
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("CavaVisualizer", "Cannot save settings: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.framerate = root.editFrameRate
        pluginApi.pluginSettings.bars = root.editBarCount
        pluginApi.saveSettings()
        Logger.i("CavaVisualizer", "Settings saved: framerate=" + root.editFrameRate + ", bars=" + root.editBarCount)
    }
}
