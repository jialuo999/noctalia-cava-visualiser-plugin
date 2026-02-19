import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

// ─────────────────────────────────────────────
//  Cava Visualizer — Noctalia Bar Widget
//  依赖：cava, pactl (pipewire-pulse 或 pulseaudio)
// ─────────────────────────────────────────────
Item {
    id: root

    // ── 必须由 PluginService 注入的属性 ──────
    property var    pluginApi: null
    property var    screen
    property string widgetId: ""
    property string section:  ""

    // ── 每屏 bar 属性（多显示器支持）──────────
    readonly property string screenName:    screen?.name ?? ""
    readonly property string barPosition:   Settings.getBarPositionForScreen(screenName)
    readonly property bool   isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real   capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real   barFontSize:   Style.getBarFontSizeForScreen(screenName)

    // ── 插件设置 ─────────────────────────────
    readonly property int  barCount:   pluginApi?.pluginSettings?.bars   ?? 12
    readonly property bool useThemeColor: (pluginApi?.pluginSettings?.colorMode ?? "theme") === "theme"

    // ── 状态 ─────────────────────────────────
    property bool  audioActive: false
    property var   barValues:   []   // 长度 = barCount，值 0-7

    // ── 布局尺寸 ──────────────────────────────
    readonly property real barWidth:   6
    readonly property real barSpacing: 2
    readonly property real totalW:     barCount * barWidth + (barCount - 1) * barSpacing + Style.marginM * 2

    // 控制整个胶囊显隐
    readonly property real contentWidth:  audioActive ? totalW : 0
    readonly property real contentHeight: capsuleHeight

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    visible: audioActive

    // ── 胶囊背景 ─────────────────────────────
    Rectangle {
        id: capsule
        x:      Style.pixelAlignCenter(parent.width,  width)
        y:      Style.pixelAlignCenter(parent.height, height)
        width:  root.contentWidth
        height: root.contentHeight
        color:  Style.capsuleColor
        radius: Style.radiusM

        clip: true

        // ── 频谱条 ───────────────────────────
        Row {
            anchors.centerIn: parent
            spacing: root.barSpacing

            Repeater {
                model: root.barCount
                delegate: Rectangle {
                    id: bar
                    width:  root.barWidth
                    // barValues[index] 范围 0-7，映射到 capsuleHeight 的 10%~100%
                    property real normalized: (root.barValues.length > index)
                                              ? root.barValues[index] / 7.0
                                              : 0.0
                    height: Math.max(2, normalized * (capsule.height - Style.marginS * 2))
                    anchors.verticalCenter: parent.verticalCenter
                    radius: root.barWidth / 2

                    color: root.useThemeColor ? Color.mPrimary : "#A8AEFF"

                    Behavior on height {
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }
    }

    // ── 淡入淡出动画 ─────────────────────────
    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    // ── Process：运行后台桥接脚本 ─────────────
    Process {
        id: bridge
        // 使用插件目录内的脚本；Quickshell 把 Qt.resolvedUrl 作为文件路径
        command: ["bash", Qt.resolvedUrl("cava-bridge.sh").toString().replace("file://", ""),
                  root.barCount.toString()]
        running: true

        stdout: SplitParser {
            onRead: function(line) {
                line = line.trim()
                if (line.startsWith("ACTIVE:")) {
                    root.audioActive = true
                    var data = line.substring(7)  // 去掉 "ACTIVE:"
                    // data 形如 "▁▃▆▂▇▄▁▂▅▆▂▄"，每个字符对应一个频谱条
                    var chars = "▁▂▃▄▅▆▇█"
                    var vals = []
                    for (var i = 0; i < data.length && i < root.barCount; i++) {
                        var idx = chars.indexOf(data[i])
                        vals.push(idx >= 0 ? idx : 0)
                    }
                    // 补齐
                    while (vals.length < root.barCount) vals.push(0)
                    root.barValues = vals
                } else if (line === "IDLE") {
                    root.audioActive = false
                    // 重置所有条到 0
                    var zeros = []
                    for (var j = 0; j < root.barCount; j++) zeros.push(0)
                    root.barValues = zeros
                }
            }
        }
    }

    // ── 脚本路径调试日志 ──────────────────────
    Component.onCompleted: {
        Logger.i("CavaVisualizer", "Widget loaded, bars:", root.barCount)
    }

    Component.onDestruction: {
        bridge.running = false
    }
}
