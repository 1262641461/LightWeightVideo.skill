# LightWeightVideo.skill

> 把**一张 Q 版角色立绘**变成**一条能直接发抖音的竖屏动画短片**——全本地运行，零 API 成本。
>
> 基于 ComfyUI + MiniMax H3（fp8）+ Z-Image + edge-tts，16G 显存 / 16G 内存即可跑通。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v1.0.0-green.svg)](CHANGELOG.md)

---

## 它解决什么问题

用 AI 做「角色短片」的痛点从来不是生成一张好看的图，而是：

1. **角色会变脸** —— 换个镜头就换个人
2. **场景不连续** —— 上一镜海底，下一镜变沙漠
3. **动作太小** —— 只会微微晃，像 PPT
4. **成本高** —— 云端视频 API 一条几块到几十块

这套流水线把四个问题都用**本地 + 首帧法**解决：同一张合成好的首帧喂给 H3，角色/场景/画风天然一致；动作幅度由提示词控制，实测大动作不会让场景崩坏。

## 效果示例

| 镜头 | 内容 |
|---|---|
| S1 | 海底背影，尾巴慢摆，气泡上浮 |
| S2 | 猛地转身 180° → 蹦一下 → 转回来 |
| S3 | 双手举起挥动，歪头笑 |

输出：`1080×1920 / 24fps / 带配音与字幕`，25 秒一条，全程约 30 分钟、成本 0。

## 流水线

```
剧本 + 分镜表
      │
      ▼
场景空镜（Z-Image）──┐
                      ├─▶ 角色合成首帧（Pillow）
角色立绘 ─────────────┘          │
                                 ▼
                    H3 首帧生视频（ComfyUI，768×768 / 124 帧 / 8 步）
                                 │
                                 ▼
                    竖屏铺底 + 字幕 + 配音（ffmpeg + edge-tts 晓伊）
                                 │
                                 ▼
                          1080×1920 MP4
```

## 快速开始

### 1. 依赖

| 组件 | 说明 |
|---|---|
| ComfyUI | ≥ 0.43，需原生支持 `MiniMaxH3ImageToVideo` / `MiniMaxH3ReferenceToVideo` |
| 视频模型 | `minimax_h3_ref2va_pruned_fp8_scaled.safetensors`（20.96 GB）→ `models/diffusion_models` |
| 文本编码器 | `qwen3vl_32b_minimax_h3_nvfp4.safetensors`（15.69 GB）→ `models/text_encoders` |
| VAE | `minimax_h3_video_vae.safetensors`（5.21 GB）+ `minimax_h3_audio_vae.safetensors`（0.61 GB）→ `models/vae` |
| 生图 | Z-Image-Turbo GGUF（场景空镜用，可选） |
| 工具 | Python 3.10+、Pillow、ffmpeg、edge-tts |

> ⚠️ **GGUF 版 H3 不可用**：ComfyUI-GGUF 不认识该架构，会报 `Unknown model architecture`。必须用官方 fp8。

### 2. 配置

```powershell
$env:COMFY_DIR = "D:\ComfyUI"                 # ComfyUI 目录
$env:COMFY_PY  = "D:\ComfyUI\venv\Scripts\python.exe"
# 可选：$env:FFMPEG / $env:FFPROBE / $env:EDGE_TTS
```

```bash
export COMFY_DIR=/opt/ComfyUI
export COMFY_PY=/opt/ComfyUI/venv/bin/python
```

### 3. 五步出片

```powershell
# ① 角色合成进场景，当作首帧
python scripts/compose_frame.py bg.png char.png scene.png

# ② H3 生成（每镜约 5~6 分钟）
powershell -ExecutionPolicy Bypass -File scripts/run_h3.ps1 `
  -Prompt "Keep the original 2D chibi anime style. She turns around 180 degrees, then waves both hands, tail swings widely, bubbles drift, camera fixed." `
  -Image scene.png -OutPrefix "h3/shot1" -W 768 -H 768 -Len 124 -Steps 8

# ③ 配音（晓伊音色）
powershell -ExecutionPolicy Bypass -File scripts/tts_line.ps1 -Text "主人早上好，本鱼起床了。" -Out voice.wav

# ④ 混音 + 字幕（输出 1080×1920）
bash scripts/add_dialogue.sh shot1.mp4 voice.wav "主人早上好，本鱼起床了。" out1.mp4

# ⑤ 多镜合成
bash scripts/compose_vertical.sh final.mp4 none out1.mp4 out2.mp4 out3.mp4
```

## 性能参考（RTX 5060Ti 16G / 内存 16G）

| 设置 | 耗时 |
|---|---|
| 640×352 / 124 帧 / 6 步 | 110 ~ 160 秒 |
| 768×768 / 124 帧 / 8 步 | 330 ~ 370 秒 |

- H3 支持最长 **362 帧（≈15 秒）单镜**
- 音画同出：一条视频自带环境音，可直接混入人声

## 提示词怎么写

H3 对**身体动作**敏感，对**情绪形容词**几乎没反应。四条规则：

1. 写身体反应，不写情绪（「手指攥紧」而非「很生气」）
2. 写变化过程（从 → 到 → 再到）
3. 写动作因果（她抬手碰到耳朵，耳朵抖了一下）
4. 写物理连续性（同一人、同一场景、气泡方向一致）

幅度词库：

| 幅度 | 写法 |
|---|---|
| 小 | `sways gently` / `waves once` |
| 中 | `waves twice` / `tilts her head` |
| 大 | `turns around 180 degrees` / `hops once` / `waves both hands enthusiastically` / `tail swings widely` |

更多见 [prompts/h3_prompt_rules.md](prompts/h3_prompt_rules.md)。

## 常见坑

- **跑 H3 时桌面程序崩溃**：提交内存（内存+页面文件）不足。Windows 上把页面文件设到 32 GB 以上并重启，`run_h3.ps1` 已内置 `--reserve-vram` 与跑完卸载模型。
- **`Invalid image file`**：参考图必须放在 `ComfyUI/input/` 下，只传文件名。
- **整条片变成静止图**：ffmpeg 里 `overlay ... shortest=1` 配单帧背景会把视频压成几帧，改用 `pad` 或循环输入。
- **人物变真人 / 变别的生物**：用「首帧法」（`MiniMaxH3ImageToVideo`），不要用纯参考图（ref2va）配强动作提示词。
- **GGUF 报架构错误**：见上，换 fp8。

## 目录

```
.
├── README.md
├── SKILL.md                     # 面向 agent 的技能说明（五步流程 + 参数 + 坑）
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── VERSION
├── prompts/
│   ├── storyboard_template.md   # 分镜表模板
│   └── h3_prompt_rules.md       # 提示词规则与幅度词库
└── scripts/
    ├── h3_i2v.py                # ComfyUI API 调用：H3 首帧生视频
    ├── run_h3.ps1               # 安全跑 H3（起服务→生成→卸模型→关服务）
    ├── compose_frame.py         # 角色合成进场景当首帧
    ├── tts_line.ps1             # 晓伊配音
    ├── add_dialogue.sh          # 混音 + 字幕
    └── compose_vertical.sh      # 竖屏铺底 + 交叉淡入
```

## 适用与限制

**适合**：单个原创角色、10~30 秒、1~6 个镜头、竖屏短视频、系列化日更。

**不适合**：多人对话、复杂运镜、超过 15 秒的单镜、需要精确口型的长时间独白。

## 许可

[MIT](LICENSE) © 2026 1262641461
