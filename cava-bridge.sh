#!/bin/bash
# cava-bridge.sh — 被 BarWidget.qml 通过 Process 调用
# 输出格式：
#   ACTIVE:<bars>   当音频活跃时，每帧输出一次
#   IDLE            当没有音频时输出

BARS="${1:-12}"
FRAMERATE="${2:-30}" # 可选参数，控制 cava 输出帧率，默认为 30 FPS
CHARS="▁▂▃▄▅▆▇█"
LEN=$(( ${#CHARS} - 1 ))
CONF=$(mktemp /tmp/noctalia_cava_XXXXXX.conf)

cleanup() {
    trap - EXIT INT TERM
    pkill -P $$ 2>/dev/null
    wait 2>/dev/null
    rm -f "$CONF"
    echo "IDLE"
    exit 0
}
trap cleanup EXIT INT TERM

# 生成 sed 替换字典（数字 → 字符）
make_sed_dict() {
    local dict="s/;//g;"
    for ((i=0; i<=LEN; i++)); do
        dict="${dict}s/$i/${CHARS:$i:1}/g;"
    done
    echo "$dict"
}

is_audio_active() {
    pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"
}

start_cava() {
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
ascii_max_range = $LEN
EOF
    local sed_dict
    sed_dict=$(make_sed_dict)
    # cava 每行输出一帧，通过 sed 转换为字符后加前缀 ACTIVE:
    cava -p "$CONF" 2>/dev/null \
        | sed -u "$sed_dict" \
        | while IFS= read -r line; do
            echo "ACTIVE:$line"
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
