# Cava Visualizer — Noctalia Bar Plugin

ai生成
检测到音频播放时在任务栏显示频谱可视化，无音频时自动隐藏。

## 依赖

```bash
# Arch Linux
sudo pacman -S cava pipewire-pulse
```

## 安装

将 `cava-visualizer/` 目录复制到 Noctalia 插件目录：

```bash
# 官方插件仓库路径（通过 noctalia-cli 安装）
# 或手动复制到本地插件目录：
cp -r cava-visualizer/ ~/.config/noctalia/plugins/

# 确保脚本有执行权限
chmod +x ~/.config/noctalia/plugins/cava-visualizer/cava-bridge.sh
```

然后在 Noctalia 设置中启用插件，并将 `cava-visualizer` 添加到 bar widgets。

## 配置（插件设置面板）

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `bars` | 12 | 频谱条数量 |
| `colorMode` | `"theme"` | `"theme"` 使用主题色，`"accent"` 使用固定紫色 |

## 工作原理

```
BarWidget.qml
    └── Process → cava-bridge.sh
                    ├── pactl subscribe  (被动监听音频事件，零 CPU 开销)
                    ├── cava             (有音频时运行，输出 ASCII 数据)
                    └── stdout → ACTIVE:<chars> / IDLE
```

- **有音频**：输出 `ACTIVE:▁▃▆▂▇▄...`，widget 显示并动画更新
- **无音频**：输出 `IDLE`，widget 以动画收缩至隐藏

## 关于 QQ 音乐兼容性

QQ 音乐使用 Electron/MPRIS2，音频流走 PipeWire/PulseAudio sink，
cava 通过 `source = auto` 可以捕获到这个流，因此可视化正常工作。
（控制播放不在本插件范围内，这是 MPRIS 支持问题。）
