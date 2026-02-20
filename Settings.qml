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
    property int editBarWidth:
        pluginApi?.pluginSettings?.barWidth ??
        pluginApi?.manifest?.metadata?.defaultSettings?.barWidth ??
        6
    property int editBarRadius:
        pluginApi?.pluginSettings?.barRadius ??
        pluginApi?.manifest?.metadata?.defaultSettings?.barRadius ??
        0
    property string editBarVerticalAlign:
        pluginApi?.pluginSettings?.barVerticalAlign ??
        pluginApi?.manifest?.metadata?.defaultSettings?.barVerticalAlign ??
        "center"
    

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: (pluginApi?.tr("settings.frame-rate.label") || "帧率") + ": " + root.editFrameRate
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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: (pluginApi?.tr("settings.bar-radius.label") || "圆角") + ": " + root.editBarRadius
        }

        NSlider {
            Layout.fillWidth: true
            from: 0
            to: 12
            stepSize: 1
            value: root.editBarRadius
            onValueChanged: root.editBarRadius = Math.round(value)
        }
    }


    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: (pluginApi?.tr("settings.bar-count.label") || "频谱条数量") + ": " + root.editBarCount
        }

        NSlider {
            Layout.fillWidth: true
            from: 2
            to: 64
            stepSize: 2
            value: root.editBarCount
            onValueChanged: root.editBarCount = Math.round(value / 2) * 2
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: (pluginApi?.tr("settings.bar-width.label") || "频谱条宽度") + ": " + root.editBarWidth
        }

        NSlider {
            Layout.fillWidth: true
            from: 1
            to: 30
            stepSize: 1
            value: root.editBarWidth
            onValueChanged: root.editBarWidth = Math.round(value)
        }
    }
    

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.align.label") || "对齐方式"
        }

        NComboBox {
            Layout.fillWidth: true
            model: [
                {
                    "key": "bottom",
                    "name": pluginApi?.tr("settings.align.bottom") || "底部对齐"
                },
                {
                    "key": "center",
                    "name": pluginApi?.tr("settings.align.center") || "垂直居中"
                }
            ]
            currentKey: root.editBarVerticalAlign
            onSelected: key => root.editBarVerticalAlign = key
        }
    }


    function saveSettings() {
        if (!pluginApi) {
            Logger.e("CavaVisualizer", "Cannot save settings: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.framerate = root.editFrameRate
        pluginApi.pluginSettings.bars = root.editBarCount
        pluginApi.pluginSettings.barWidth = root.editBarWidth
        pluginApi.pluginSettings.barRadius = root.editBarRadius
        pluginApi.pluginSettings.barVerticalAlign = root.editBarVerticalAlign
        pluginApi.saveSettings()
        Logger.i("CavaVisualizer", "Settings saved: framerate=" + root.editFrameRate + ", bars=" + root.editBarCount)
    }
}