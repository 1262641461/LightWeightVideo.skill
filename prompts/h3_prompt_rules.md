# H3 提示词写法（实测有效）

## 核心
H3 吃「身体动作 + 场景连续性」，不吃「情绪形容词」。
动作幅度由**动词**决定，不由「很」「非常」决定。

## 四条规则（来自 HellGrind 提示词法）
1. **写身体反应，不写情绪结果**
   - ✗「她很生气」
   - ✓「呼吸变重，手指攥到发白，视线定住对方」
2. **写变化过程，不写表演状态**
   - ✓「从愣住 → 犹豫 → 抬头」三段
3. **写动作因果，不写运镜术语**
   - ✗「推镜头」
   - ✓「她抬手碰了碰耳朵，镜头才慢慢靠近」
4. **写物理连续性**
   - 同一个人、同一处场景、同一套衣服，气泡/光柱方向要前后一致

## 模板
```
Keep the original 2D chibi anime illustration style.
<角色在做什么：主语 + 动词 + 幅度>
<配角细节：尾巴/头发/裙摆/耳朵>
<场景反应：气泡、光柱、水波>
<镜头：fixed camera / slow push in / pull back>
```

## 幅度词库
| 幅度 | 英文 | 实测效果 |
|---|---|---|
| 小 | `sways gently`, `waves once` | 只有轻微起伏 |
| 中 | `waves twice`, `tilts her head` | 明显动作，画面稳 |
| 大 | `turns around 180 degrees`, `hops once`, `waves both hands enthusiastically`, `tail swings widely` | 转身/蹦跳，场景不崩 |

## 已验证的负面
- 纯参考图（ref2va）容易被提示词带跑（Q 版会被认成真人）
- **首帧法（ImageToVideo）身份保持最好**，优先用它
- cfg 低于 3 容易崩坏成别的画面；默认 5 左右配合 6~8 步即可
