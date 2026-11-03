# h3-chibi-short

把一张 Q 版角色立绘做成 15 秒竖屏 AI 动画短片，**全程本地、零 API 成本**。

## 它能做什么
- 输入：一张角色立绘（透明底 PNG）+ 一句剧本
- 输出：1080×1920 / 24fps / 带配音字幕的短视频
- 适配：16G 显存 + 16G 内存的机器（RTX 5060Ti 实测）

## 快速开始
```bash
# 1. 角色合成进场景（当首帧）
python scripts/compose_frame.py bg.png char.png scene.png

# 2. H3 生成（每镜约 5~6 分钟）
powershell -ExecutionPolicy Bypass -File scripts/run_h3.ps1 `
  -Prompt "Keep the original 2D chibi anime style. She turns around 180 degrees then waves both hands, tail swings widely, bubbles drift, camera fixed." `
  -Image scene.png -OutPrefix "h3/shot1" -W 768 -H 768 -Len 124 -Steps 8

# 3. 配音（晓伊）
powershell -ExecutionPolicy Bypass -File scripts/tts_line.ps1 -Text "主人——你看见本鱼了呀。" -Out voice.wav

# 4. 混音 + 字幕
bash scripts/add_dialogue.sh shot1.mp4 voice.wav "主人——你看见本鱼了呀。" out1.mp4

# 5. 竖屏合成
bash scripts/compose_vertical.sh final.mp4 title.png out1.mp4 out2.mp4 out3.mp4
```

## 依赖
- ComfyUI ≥ 0.43 + 原生 H3 节点
- `minimax_h3_ref2va_pruned_fp8_scaled`（21G）+ `qwen3vl_32b_minimax_h3_nvfp4`（15.7G）+ 视频/音频 VAE
- ffmpeg、Pillow、edge-tts（晓伊）

## 关键约束
- 提交内存（RAM+PageFile）必须 ≥ 40G，否则跑 H3 时桌面程序会被系统杀掉
- 跑完必须卸载模型并关闭 ComfyUI（`run_h3.ps1` 已内置）
- 参考图必须放在 `ComfyUI/input/` 下

细节见 [SKILL.md](SKILL.md)。
