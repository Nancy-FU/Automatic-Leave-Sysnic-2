# 请假自动化 (Automatic Leave Sync)

用 [Claude Code](https://claude.com/claude-code) 把公司邮箱里的请假 / WFH / OOO 邮件，自动整理进 Google Calendar 和年假记录表——不用再手动读邮件、算工作日、填表格。

> 本仓库是私有工作仓库的**公开、脱敏版**：规则、文档和两个定时任务 prompt 与线上版本同步，但员工姓名 / 邮箱 / 日历 ID / 表格 ID / 公司信息已替换为占位符（`Employee NN`、`{{CONFIG_KEY}}`、虚构示例人名）。填上你自己的配置即可直接使用。

---

## 两个定时任务

| 任务 | 时间 | 做什么 | 会写入吗 |
|---|---|---|---|
| `leave-sync` | 工作日 9:00 / 15:00 | 扫最近 14 天邮件 → 识别请假 / WFH / OOO → 按规则解析人、日期、假别 → 查重后写入日历 | ✅ 写日历（有查重、不发通知） |
| `leave-monthly-diff` | 每月第一个星期一 10:00 | 只读比对上月邮件与年假记录表，输出"待登记清单"（含工作日天数、异常标记） | ❌ 结构性只读，连写工具都不加载 |

两者是上下游：日常同步负责日历；月度比对负责找出表格还没登记的条目，由你在场时说 "sync sheet" 再写入表格（Sheets 没有写 API，只能浏览器操作，必须有人在场核对）。

## 安装

前提：Claude Code 桌面版，已连接 **Gmail**、**Google Calendar**、**Google Drive** 连接器；本机有 `python3`。

1. 克隆仓库：
   ```bash
   git clone https://github.com/Nancy-FU/Automatic-Leave-Sysnic-2.git
   ```
2. 复制并填写配置（这两个文件已被 `.gitignore` 排除，不会被提交）：
   ```bash
   cp config.example.json config.json
   ```
   ```bash
   cp roster.example.json roster.json
   ```
   - `config.json`：你的 Gmail、两个日历的名称和 ID（Google Calendar → 日历设置 → "集成日历" → 日历 ID）、年假表格的名称和 fileId（表格 URL 里 `/d/` 后那一段）、时区、公众假期前缀等。
   - `roster.json`：员工花名册——邮箱 → 显示名 / 办公室 / 生日。这是姓名的唯一来源。
3. 生成任务 prompt：
   ```bash
   ./install.sh
   ```
   会把 `templates/*/SKILL.md` 里的 `{{占位符}}` 换成你的配置，输出到 `build/`（同样不提交）。有漏填的占位符会报错。
4. 在 Claude Code 里打开本文件夹，粘贴下面这段话注册定时任务：
   > 请用 `build/leave-sync/SKILL.md` 的完整内容（去掉开头的 frontmatter）作为 prompt，创建定时任务 `leave-sync`，cron `0 9,15 * * 1-5`；再用 `build/leave-monthly-diff/SKILL.md` 创建定时任务 `leave-monthly-diff`，cron `0 10 * * 1`。
5. 建议先在 Claude Code 的定时任务列表里对 `leave-sync` 点一次 "Run now"，看报告是否符合预期。

> ⚠️ Claude Code 定时任务**只在 App 开着时运行**；到点时 App 关着，会在下次打开时补跑。
>
> `leave-monthly-diff` 的 cron 每周一都会触发，prompt 第一步会检查"今天是否 ≤ 7 号"，不是就直接停止——这是有意为之（cron 的日期与星期同时限定是 OR 语义，靠不住）。

### 改规则之后

改了 `templates/` 里的规则，要**重新跑 `./install.sh`，并更新 Claude Code 里正在跑的那个定时任务**——只改文件不会影响线上行为（见 `CHANGELOG.md` 教训 4）。

### 推送前自检

```bash
./check-sensitive.sh
```

扫描所有已跟踪文件里的真实日历 ID、Drive 文件 ID、本机路径和非示例邮箱。可以把你自己公司的真实人名 / 域名逐行写进 `.sensitive-words`（已 git-ignore），一并检查。

## 目录结构

```
README.md                       本文件
PRD.md                          产品需求文档 —— 目标、日历标注规范、防呆规则（§5 最重要）
PHASE2_DESIGN.md                Phase 2 设计文档 —— 表格结构、计算规则、浏览器操作细则
CHANGELOG.md                    变更日志 —— 规则是怎么演变成今天这样的、教训、待办
templates/
  leave-sync/SKILL.md           日常同步任务 prompt 模板
  leave-monthly-diff/SKILL.md   月度只读比对任务 prompt 模板
config.example.json             配置模板 → 复制为 config.json
roster.example.json             花名册模板 → 复制为 roster.json
install.sh                      用 config.json 渲染模板到 build/
check-sensitive.sh              推送前敏感信息扫描
```

文档（PRD / PHASE2_DESIGN / CHANGELOG）里的 `{{LEAVE_CALENDAR_NAME}}` 等占位符对应 `config.json` 的同名配置；`Employee NN` 是脱敏后的真实案例人物，保留案例是为了说明每条规则背后的"为什么"。

## 核心设计原则

1. **邮件 = 最终确认版本，日历/表格只是派生视图**——冲突时以邮件为准（`PRD.md` §5）。
2. **审批人 ≠ 请假人**——请假人一律以邮件串中最早的原始请假邮件寄件人为准，这是历史上踩坑最多的一条。
3. **无人值守的动作必须结构性只读或可回滚**——能自动写日历（有查重、有规则），但表格写入必须有人在场核对。
4. **规则变了，要同步检查"正在跑的那个东西"**——文档、模板、线上定时任务三处一起改。
5. **隐私最小化**——日历事件描述栏只记来源和"谁批准的"，不记请假原因或审批人回复原话。

## 两个阶段

| 阶段 | 状态 | 做什么 |
|---|---|---|
| **Phase 1 / 1b** | ✅ 已上线 | 邮件 → 日历自动同步（`leave-sync`） |
| **Phase 2a** | ✅ 闭环已跑通 | 月度只读比对（`leave-monthly-diff`）+ 用户在场同步表格 |
| Phase 2b | 未开始 | 每季度提醒每人剩余年假 |

## 如果你想复用这套思路

最值得复用的不是代码，而是**踩过的坑总结成的规则**（`PRD.md` §5、`CHANGELOG.md` "沉淀下来的教训"）：审批人误记请假人、Tab 键在表格里不跳格、清空重做前先核对完整性、改规则要同步改任务 prompt……这些教训跨团队通用。
