#!/bin/bash
# 多镜头竖屏合成：铺底 1080x1920 + 交叉淡入
# 用法：bash compose_vertical.sh out.mp4 [片头标题图|none] shot1.mp4 shot2.mp4 ...
set -e
OUT="$1"; TITLE="$2"; shift 2
SHOTS=("$@")
FF="${FFMPEG:-D:/ruanjian/DSH/workspace/tools/ffmpeg.exe}"
FFP="${FFPROBE:-D:/ruanjian/DSH/workspace/tools/ffprobe.exe}"
BG="${BGCOLOR:-0x0B1430}"
FPS=24
XF=0.4

work="${WORKDIR:-./_work}"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT

n=0
if [ "$TITLE" != "none" ] && [ -f "$TITLE" ]; then
  "$FF" -y -loglevel error -loop 1 -t 1.5 -i "$TITLE" -f lavfi -t 1.5 -i "anullsrc=r=44100:cl=stereo" \
    -vf "scale=1080:1920" -c:v libx264 -pix_fmt yuv420p -crf 18 -r $FPS -c:a aac -b:a 128k -shortest "$work/seg0.mp4"
  n=1
fi

i=0
for s in "${SHOTS[@]}"; do
  i=$((i+1))
  "$FF" -y -loglevel error -i "$s" \
    -vf "scale=1080:1080:flags=lanczos,pad=1080:1920:0:420:color=${BG}" \
    -c:v libx264 -pix_fmt yuv420p -crf 18 -r $FPS -c:a aac -b:a 128k "$work/seg$i.mp4"
done

total=$((n + i))
inputs=(); filt=""; mapv="[v]"; mapa="[a]"
for k in $(seq 0 $((total-1))); do inputs+=(-i "$work/seg$k.mp4"); done

# 逐段 xfade / acrossfade
acc_v="[0:v]"; acc_a="[0:a]"; offset=1.1
for k in $(seq 1 $((total-1))); do
  prev_v=$(echo "$acc_v" | tr -d '[]')
  prev_a=$(echo "$acc_a" | tr -d '[]')
  if [ $k -eq 1 ] && [ $n -eq 1 ]; then offset=1.1; else offset=$(python -c "print(round($offset + 5.1666667 - $XF, 4))"); fi
  filt+="${acc_v}[${k}:v]xfade=transition=fade:duration=${XF}:offset=${offset}[v${k}];"
  filt+="${acc_a}[${k}:a]acrossfade=d=${XF}[a${k}];"
  acc_v="[v${k}]"; acc_a="[a${k}]"
done

"$FF" -y -loglevel error "${inputs[@]}" -filter_complex "${filt%?}" \
  -map "$acc_v" -map "$acc_a" -c:v libx264 -pix_fmt yuv420p -crf 18 -r $FPS -c:a aac -b:a 160k "$OUT"

"$FFP" -v error -select_streams v -show_entries stream=width,height,nb_frames,r_frame_rate \
  -show_entries format=duration -of default=noprint_wrappers=1 "$OUT"
