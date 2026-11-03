#!/bin/bash
# 给一个镜头混入配音并压字幕
# 用法：bash add_dialogue.sh in.mp4 voice.wav "字幕文字" out.mp4 [人声起始秒 0.7] [字幕结束秒 3.8]
set -e
IN="$1"; VOICE="$2"; LINE="$3"; OUT="$4"
DELAY="${5:-0.7}"
SUB_END="${6:-3.8}"
DELAY_MS=$(python -c "print(int(float('$DELAY')*1000))")

FF="${FFMPEG:-D:/ruanjian/DSH/workspace/tools/ffmpeg.exe}"
FONT="${FONT:-C\\:/Windows/Fonts/msyh.ttc}"

"$FF" -y -loglevel error -i "$IN" -i "$VOICE" -filter_complex "\
[0:v]scale=1080:1080:flags=lanczos,pad=1080:1920:0:420:color=0x0B1430,\
drawtext=fontfile='${FONT}':text='${LINE}':fontcolor=white:fontsize=54:borderw=4:bordercolor=black@0.55:x=(w-text_w)/2:y=1560:enable='between(t,${DELAY},${SUB_END})'[v];\
[0:a]volume=0.22[bg];\
[1:a]adelay=${DELAY_MS}|${DELAY_MS},volume=1.7[vo];\
[bg][vo]amix=inputs=2:duration=first:dropout_transition=0[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -pix_fmt yuv420p -crf 18 -r 24 -c:a aac -b:a 160k "$OUT"

echo "SAVED $OUT"
