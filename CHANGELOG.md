# Changelog

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [v1.0.0] - 2026-11-03

首个公开版本。

### 新增
- **五步流水线**：剧本分镜 → 场景合成 → H3 首帧生视频 → 配音字幕 → 竖屏剪辑
- `scripts/h3_i2v.py`：ComfyUI API 调用，H3 首帧生视频（含音画同出、双 VAE 解码）
- `scripts/run_h3.ps1`：安全运行器——自动起 ComfyUI（`--lowvram --reserve-vram`）、生成完成卸载模型并关闭服务，避免撑爆桌面端内存
- `scripts/compose_frame.py`：把角色立绘合成进场景图作为首帧（自动缩放、柔和阴影、色调统一）
- `scripts/tts_line.ps1`：edge-tts 晓伊音色配音
- `scripts/add_dialogue.sh`：混音 + 烧字幕，输出 1080×1920
- `scripts/compose_vertical.sh`：多镜竖屏合成、0.4s 交叉淡入
- `prompts/storyboard_template.md`：分镜表模板
- `prompts/h3_prompt_rules.md`：H3 提示词规则与动作幅度词库
- `SKILL.md`：面向 agent 的技能说明

### 已验证
- 640×352 / 124 帧 / 6 步 ≈ 110~160 秒
- 768×768 / 124 帧 / 8 步 ≈ 330~370 秒（RTX 5060Ti 16G / 16G 内存）
- 大幅动作（转身 180°、原地蹦跳、双手挥）不会破坏场景连续性
- 实拍成品：25 秒五镜短片（起床 / 打招呼 / 捧饭碗 / 炸毛 / 蹭镜头）
