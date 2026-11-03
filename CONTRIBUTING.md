# 贡献指南

感谢你愿意改进 **LightWeightVideo.skill**。

## 可以贡献什么

- 新的提示词模板（不同画风、不同动作类型）
- 更多后处理脚本（转场、音效、字幕样式）
- 在其他显卡 / 内存配置下的实测数据
- 文档修正与翻译

## 提交前

1. **不要提交任何密钥**：API Key、访问令牌、Cookie、个人信息一律不可进入仓库
2. **不要硬编码本机路径**：脚本请用环境变量（`COMFY_DIR` / `COMFY_PY` / `FFMPEG` 等）
3. **不要提交生成产物**：`*.mp4` / `*.wav` / `*.mp3` / `_work/` / `_test/` 已在 `.gitignore` 中
4. 脚本保持可独立运行，并在 PR 描述里写清测试环境（显卡、显存、内存）

## 流程

```bash
git clone https://github.com/1262641461/LightWeightVideo.skill.git
cd LightWeightVideo.skill
git checkout -b feat/your-feature
# 修改…
git commit -m "feat: 你的改动"
git push origin feat/your-feature
```

然后在 GitHub 上发起 Pull Request，说明：
- 改了什么
- 怎么验证的（跑了哪条命令、得到什么结果）
- 有没有副作用

## 代码风格

- Shell：`bash`，关键步骤加 `set -e`
- PowerShell：避免在 `.ps1` 里写中文注释（Windows PowerShell 5.1 编码会乱），必要时用英文
- Python：3.10+，只依赖 `Pillow` / `requests`
- 文档：中文为主，术语保留英文原文
