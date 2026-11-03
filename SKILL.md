---
name: h3-chibi-short
description: 用本机 ComfyUI + MiniMax H3 把一张 Q 版角色立绘做成 15 秒竖屏 AI 动画短片（剧本→分镜→资产合成→H3 首帧生视频→配音字幕→剪辑），全本地零成本，适配 16G 显存 / 16G 内存。
---

# h3-chibi-short：Q 版角色 AI 短片流水线

把「一张角色立绘」变成「一条能发抖音的竖屏动画」，全程本地，不花 API 钱。
本流程来自秋叶 ComfyUI 17 课（剧本→分镜→资产→H3→剪辑）的落地版本，已在本机 5060Ti 16G 实测跑通。

## 什么时候用
- 有固定 Q 版 / 二次元角色立绘（透明底 PNG 最好）
- 想做 10~20 秒、单角色、1~3 个镜头的短动画
- 不想花钱、也不想建模

## 硬前提
| 项 | 要求 |
|---|---|
| ComfyUI | 原生支持 `MiniMaxH3ImageToVideo` 等节点（本机 0.43.0 已验证） |
| 模型 | `minimax_h3_ref2va_pruned_fp8_scaled.safetensors`（20.96G）放 `models/diffusion_models` |
| 文本编码器 | `qwen3vl_32b_minimax_h3_nvfp4.safetensors`（15.7G）放 `models/text_encoders` |
| VAE | `minimax_h3_video_vae.safetensors`（5.2G）+ `minimax_h3_audio_vae.safetensors`（0.6G）放 `models/vae` |
| 内存 | 提交上限（内存+页面文件）**≥ 40G**，否则桌面端会被系统杀掉 |

> GGUF 版 H3 **不能用**：ComfyUI-GGUF 不认识该架构（`Unknown model architecture`）。

## 五步流程

### 1. 剧本与分镜（10 分钟）
按 `prompts/storyboard_template.md` 写：选题 → 一句话梗概 → 3 镜表格（景别/运镜/时长/画面/声音）。
每镜默认 5 秒（124 帧 @24fps）。

### 2. 场景资产（1 分钟）
- 有空镜就用现成的；没有就让 Z-Image 生成一张：
  `python tools/sd/zimage_test.py "海底空镜，光柱，气泡，珊瑚剪影，2D动漫扁平插画" 768 768 8 42`
- 把角色立绘合到场景里当**首帧**：
  `python scripts/compose_frame.py 场景.png 角色.png 首帧.png`
  （脚本会自动缩放、加柔和阴影、轻微统一色调）

### 3. H3 首帧生视频（每镜 5~6 分钟）
```
powershell -ExecutionPolicy Bypass -File scripts/run_h3.ps1 `
  -Prompt "<英文动作描述>" -Image scene1.png `
  -OutPrefix "h3/shot1" -W 768 -H 768 -Len 124 -Steps 8
```
脚本负责：起 ComfyUI（`--lowvram --reserve-vram 2.5`）→ 提交 → 跑完 `/free` 卸模型 → 关掉 ComfyUI，不常驻占内存。

### 4. 配音与字幕（2 分钟）
```
powershell -ExecutionPolicy Bypass -File scripts/tts_line.ps1 -Text "主人——你看见本鱼了呀。" -Out voice.mp3
bash scripts/add_dialogue.sh shot1.mp4 voice.wav "主人——你看见本鱼了呀。" out1.mp4
```
音色固定 **zh-CN-XiaoyiNeural（晓伊）**。

### 5. 剪辑（1 分钟）
```
bash scripts/compose_vertical.sh out1.mp4 out2.mp4 out3.mp4 title.png final.mp4
```
输出 1080×1920 / 24fps / 每镜 0.4s 交叉淡入。

## 提示词写法（关键）
H3 对「身体动作」敏感，对「情绪形容词」几乎没反应。四条规则：
1. **写身体反应，不写情绪**：「呼吸变重、手指发白」而不是「很生气」
2. **写变化过程**：从 → 到 → 再到
3. **写动作因果**：「她抬手碰了碰耳朵，耳朵抖了一下」
4. **写物理连续性**：同一个人、同一处场景、道具前后一致

动作幅度直接由动词决定：
- 小：`waves once` / `sways gently`
- 大：`turns around 180 degrees` / `hops once` / `waves both hands enthusiastically` / `tail swings widely`
（实测大幅度动作**不会**把场景搞乱，气泡和光柱反而更活）

## 实测耗时（5060Ti 16G / 15.9G 内存）
| 设置 | 耗时 |
|---|---|
| 640×352 / 124 帧 / 6 步 | 110~160 秒 |
| 768×768 / 124 帧 / 8 步 | 330~370 秒 |

## 坑清单
- **渲染时别让 ComfyUI 常驻**：21G 模型会顶爆提交内存，桌面端直接消失（表现为「软件崩了」）
- 页面文件要够：`C:\pagefile.sys 8192 20480` + `D:\pagefile.sys 16384 20480`，改完**必须重启**才生效
- 参考图路径必须在 `ComfyUI/input/` 下，否则 `Invalid image file`
- 合片别用 `overlay ... shortest=1` 配单帧背景，会把整条片压成 2 帧（看上去「完全没动」）
- 交片前先数帧：`ffprobe -show_entries stream=nb_frames`，别信自己的眼睛

## 目录
```
scripts/run_h3.ps1         # 安全跑 H3（起服务→生成→卸模型→关服务）
scripts/compose_frame.py   # 角色合成进场景当首帧
scripts/tts_line.ps1       # 晓伊配音
scripts/add_dialogue.sh    # 混音 + 字幕
scripts/compose_vertical.sh# 竖屏铺底 + 交叉淡入
prompts/storyboard_template.md
prompts/h3_prompt_rules.md
```
