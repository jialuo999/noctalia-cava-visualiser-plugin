# Cava Visualizer — Noctalia 任务栏音频频谱插件
为 Noctalia 桌面环境提供轻量级音频频谱可视化功能，仅在检测到音频播放时显示频谱动画，无音频时自动隐藏，零闲置资源占用。

## 功能特性
- 🎵 实时音频频谱可视化，适配 PulseAudio/PipeWire 音频环境
- 🎛️ 可自定义频谱条数量、宽度、圆角、对齐方式等样式
- ⚡ 智能资源管理：无音频时自动停止 cava 进程，仅监听音频事件（零 CPU 开销）
- 🎨 双配色模式：适配主题色 / 固定强调色
- 🧩 无缝兼容常见音频应用（包括 QQ 音乐 Electron 客户端）

## 依赖要求
插件运行依赖以下工具，需提前安装：

```bash
# Arch Linux / Manjaro
sudo pacman -S cava pipewire-pulse

# Debian/Ubuntu (需先添加 cava 第三方源)
# sudo add-apt-repository ppa:tehtotalpwnage/cava
# sudo apt update && sudo apt install cava pipewire-pulse
```

## 安装步骤
1. 复制插件目录到 Noctalia 插件路径：
   ```bash
   # 本地插件目录（推荐）
   cp -r cava-visualizer/ ~/.config/noctalia/plugins/

   # 或通过 noctalia-cli 安装（若使用官方插件仓库）
   # noctalia-cli install cava-visualizer
   ```

2. 赋予脚本执行权限：
   ```bash
   chmod +x ~/.config/noctalia/plugins/cava-visualizer/cava-bridge.sh
   ```

3. 启用插件：
   - 打开 Noctalia 设置面板
   - 进入「插件」选项卡，启用「Cava Visualizer」
   - 将「cava-visualizer」添加到任务栏组件列表

## 配置说明
在 Noctalia 插件设置面板中可调整以下参数：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `bars` | 12 | 频谱条数量（建议 4-24 之间） |
| `barWidth` | 6 | 单个频谱条宽度（像素） |
| `barRadius` | 0 | 频谱条圆角半径（像素） |
| `barVerticalAlign` | center | 频谱条垂直对齐方式（top/center/bottom） |
| `colorMode` | theme | 配色模式：<br>- `theme`：跟随系统主题色<br>- `accent`：使用固定紫色强调色 |
| `framerate` | 30 | 频谱更新帧率（默认 30 FPS，可设 60 提升流畅度） |

## 工作原理
插件采用「事件驱动 + 进程隔离」设计，保证低资源占用：

```
Noctalia 任务栏 (BarWidget.qml)
    └── 启动子进程 → cava-bridge.sh
        ├── pactl subscribe ｜ 被动监听音频设备事件（无音频时）
        ├── cava ｜ 音频活跃时启动，输出 ASCII 格式频谱数据
        └── 标准输出 ｜ 向 QML 传递状态：
            - ACTIVE:<频谱数据> ｜ 音频活跃时逐帧输出
            - IDLE ｜ 无音频时输出（触发隐藏动画）
```

### 核心机制
- **音频检测**：通过 `pactl list sink-inputs` 检测活跃音频流，无音频时停止 cava 进程
- **数据传输**：cava 输出 ASCII 格式频谱数据，QML 侧归一化后渲染动画
- **资源优化**：无音频时仅保留 `pactl subscribe` 监听进程，避免无效轮询

## 兼容性说明
- ✅ QQ 音乐（Electron/MPRIS2）：音频流正常被 cava 捕获，频谱显示正常
- ✅ 网易云音乐 / Spotify / 浏览器音频：完美兼容
- ✅ PipeWire/PulseAudio 音频栈：原生支持（需确保默认音频源为 PulseAudio）
- ❌ ALSA 纯音频环境：需手动修改 `cava-bridge.sh` 中 `input.method` 为 `alsa`

## 常见问题
1. **无频谱显示但音频正常播放**
   - 检查 cava 是否安装成功：`cava -v`
   - 确认音频使用 PulseAudio/PipeWire 输出：`pactl info`
   - 验证脚本权限：`chmod +x cava-bridge.sh`

2. **频谱更新卡顿**
   - 降低 `bars` 数量（建议 ≤16）
   - 调整 `framerate` 为 30（默认值）
   - 检查系统资源占用，关闭高负载进程
