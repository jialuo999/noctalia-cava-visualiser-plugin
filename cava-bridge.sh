#! /bin/bash
# cava-bridge.sh — 被 BarWidget.qml 通过 Process 调用
# 输出格式：
#   ACTIVE:<bars>   当音频活跃时，每帧输出一次
#   IDLE            当没有音频时输出

BARS="${1:-12}"
FRAMERATE="${2:-30}" # 可选参数，控制 cava 输出帧率，默认为 30 FPS
ASCII_MAX=16  # cava 输出值域上限，QML 侧 /10.0 归一化依赖此值
CONF=$(mktemp /tmp/noctalia_cava_XXXXXX.conf)
if ! [[ "$FRAMERATE" =~ ^[0-9]+$ ]] || [[ "$FRAMERATE" -lt 1 ]]; then
    FRAMERATE=30
fi

cleanup() {
    trap - EXIT INT TERM
    pkill -P $$ 2>/dev/null
    wait 2>/dev/null
    rm -f "$CONF"
    echo "IDLE"
    exit 0
}
trap cleanup EXIT INT TERM

is_audio_active() {
    pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"
}

start_cava() {
    local interval
    interval=$(awk -v fps="$FRAMERATE" 'BEGIN { if (fps <= 0) fps=30; printf "%.6f", 1 / fps }')
    cat > "$CONF" <<EOF
[general]
bars = $BARS
framerate = $FRAMERATE

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $ASCII_MAX
EOF
    # cava 每行输出一帧，格式为 "0;3;7;2;...;\n"，直接加前缀 ACTIVE:
    # 末尾分号由 cava 自带，QML 侧 split 后过滤空元素即可
    cava -p "$CONF" 2>/dev/null \
        | while IFS= read -r line; do
            echo "ACTIVE:$line"
            sleep "$interval"
        done &
    CAVA_PID=$!
}

stop_cava() {
    if [[ -n "$CAVA_PID" ]] && kill -0 "$CAVA_PID" 2>/dev/null; then
        kill "$CAVA_PID" 2>/dev/null
        wait "$CAVA_PID" 2>/dev/null
    fi
    CAVA_PID=""
}

CAVA_PID=""
echo "IDLE"

while true; do
    if is_audio_active; then
        # 音频活跃，确保 cava 在跑
        if [[ -z "$CAVA_PID" ]] || ! kill -0 "$CAVA_PID" 2>/dev/null; then
            stop_cava
            start_cava
        fi
        sleep 1
    else
        # 无音频，停掉 cava
        if [[ -n "$CAVA_PID" ]] && kill -0 "$CAVA_PID" 2>/dev/null; then
            stop_cava
            echo "IDLE"
        fi
        # 被动等待，不轮询
        timeout 5s pactl subscribe 2>/dev/null \
            | grep --line-buffered "sink-input" \
            | head -n 1 > /dev/null
    fi
done