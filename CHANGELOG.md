# VSYS 请假自动化 — 变更日志 (CHANGELOG)

> 本文件记录对 "VSYS Leaves" 日历及本项目的所有实质性操作。
> 更早的历史（Codex / Apps Script 三次尝试）见 `archive/OLD_VSYS_LEAVE_SYNC_PRD_AND_CHANGELOG.md`。

## 版本状态

- ✅ **Phase 1 + 1b — 已上线（当前稳定版本，git `main` 基线，tag `phase-1` / `phase-1b-merged`）**
  邮件 → 日历同步：全假别（AL/SL/BL）→ VSYS Leaves；WFH → VSYS MY WFH；混合两边都记。历史数据已修正 + 姓名已标准化 + HK/Malaysia office 分类。本地定时任务 `vsys-leave-sync` 工作日 9:00/15:00 运行。
  Phase 1b 已于 2026-07-15 并回 `main`，首跑验证通过（见 P 段）。
- 🚧 **Phase 2 — 设计中（git `phase-2` 分支）**
  年假天数表格（Leave Record QB 2026）自动登记 + 季度提醒邮件。规则设计进行中。`main` 可随时回撤。

---

## 2026-07-14 — 项目重启、旧自动化退役、历史数据全面修正

本次会话完成了：诊断旧系统 → 退役旧自动化 → 一次性修正日历历史数据 → 归档。所有日历写入均**关闭通知**（不打扰任何人）。

### A. 诊断（发现的问题）
- 确认之前的"自动化"实为多次不同尝试，非单一可维护脚本；根因是让 AI 每次临场判断，缺乏校验。
- 发现 **Google Apps Script 项目 (`syncVsysAttendanceRequests`) 的 20 个 time-based 触发器仍在运行，且错误率 100%**——本地删代码文件 ≠ 停用云端触发器。
- 发现旧数据多类错误：年份错（2030 / 2027）、审批人错当请假人、系统测试邮件被误记、同一请假重复记录、假别标错。

### B. 退役旧自动化（用户手动操作，Claude 指导）
- 用户在 **Codex** 停用 `auto-sync-vsys-leave-emails` / `auto-sync-vsys-leave-emails-17-30` 两个自动化。
- 用户在 **Google Apps Script** 删除全部 20 个触发器。
- 用户在 **Google 账号 → 第三方应用授权** 撤销并删除相关 Apps Script 项目授权（"hr test"、"Untitled project"），从源头封死触发器再生。

### C. 历史数据修正（Claude 通过连接器直接写入 Google Calendar）

**第一批（A 新建 / B 修正 / C 决策）：** 新建 32、修改 15、删除 3。

关键修正：
- 🗑️ 删除错到 **2030-07-12** 的 "AL: Employee 09"（实为 Employee 11 7/15 请假，Employee 09 是审批人；正确记录已存在）
- ✏️ "AL: Employee 14" 错到 **2027-08-03** → 修正为 2026-03-20
- ✏️ "AL: Employee 15" 错到 **2027-04-21** 半天 → 修正为 2026-04-17 全天
- ✏️ "AL: Employee 06" 丧假 → 改前缀为 `BL: Employee 06`（与已有 BL: Employee 16 一致）
- 🗑️ 删除 "AL: Support"（support@ 系统测试邮件）与 "AL: Employee 17"（实为转发他人旧记录，非本人请假）
- ✏️ "AL: Employee 02" 错拉成整周 → 拆回 4/2、4/8 两个单天（重复的 "AL: Employee 02" 复用为 4/8）
- ✏️ "AL: Employee 18" (2026-12-22) → 改名 "AL: Employee 18" 并按用户确认移至 **2025-12-22~24**（邮件"半天/3天"矛盾，暂记 3 天全天，描述已标注）
- 🆕 补建大量 1–5 月缺失记录（Employee 13、Employee 19、Employee 20、Employee 21、Employee 22、Employee 23、Employee 07、Employee 03、Employee 24、Employee 25、Employee 04 等）
- 🆕 Employee 26、Employee 27 春节无薪假按用户决定记为 `AL:`，描述标注 (unpaid leave)

**第二批（C4 / C5 / D 收尾）：** 新建 2、修改 1、删除 2。
- C4 Employee 15 "Backdate my Leaves"：日期仅在 PDF 附件内，工具无法读取；用户确认为 **2025 年信息，忽略不建**。
- C5 Employee 14 2/6 半天：交叉核对确认为下午半天，用户确认已休 → 🆕 新建 `AL: Employee 14 (Half-Day PM)` 2026-02-06。
- D "AL: Employee 10" 三条（3/20、4/15、6/22）：经查**全部是审批人被错记成请假人**，真实请假人均为 Employee 13。
  - 3/20 → ✏️ 改为 "AL: Employee 13" 3/9 全天 + 🆕 补建 3/11 全天
  - 4/15 → 🗑️ 删除（Employee 13 已有正确的 4/15–24 记录）
  - 6/22 → 🗑️ 删除（Employee 13 已有正确的 6/16 记录）

**历史修正累计：新建 ~34、修改 ~17、删除 5。** D 类无邮件来源的手动记录一律未动。

### D. 待人工确认的遗留项
- Employee 18 12/22–24：邮件"半天"与"3天"矛盾，当前记为 3 天全天（2025），如需精确到半天请告知。
- Employee 25 4/10：按邮件原文"On leave"记为整天（原预期半天），如实际为半天请告知。

### E. 归档
- 建立统一项目文件夹：`/Users/nerolifu/Documents/Claude/Leave Arrangement/`
- 新增 `PRD.md`（完整需求 + 防呆规则）、`CHANGELOG.md`（本文件）。
- 旧 PRD 与 cache 从 `mycodebase/HR ` **复制**（原件保留）至 `archive/`。

### F. 记忆固化
- 写入长期记忆：本项目目标、"先讨论后执行"的工作偏好。

---

## 2026-07-14 (续) — 补建 Employee 14 2/6、修正 Employee 10 三条误记、姓名标准化建立

### G. C4/C5/D 收尾（发现于用户追问 "Employee 01 请假为何没更新" 之后展开的进一步核查）
- **C4 Employee 15 "Backdate my Leaves"**：日期只在 PDF 附件内，工具无法读取；用户确认是 **2025 年信息，忽略不建**。
- **C5 Employee 14 2/6 半天**：用户确认已休假。交叉核对邮件确认为**下午半天**，无独立主管批准邮件在案。🆕 新建 `AL: Employee 14 (Half-Day PM)` 2026-02-06。
- **D "AL: Employee 10" 三条（3/20、4/15、6/22）**：全部核实为**审批人被错记成请假人**，真实请假人均为 Employee 13。
  - 3/20 → ✏️ 改为 "AL: Employee 13" 3/9 全天 + 🆕 补建 3/11 全天
  - 4/15、6/22 → 🗑️ 删除（Employee 13 已有对应正确记录）

### H. 发现现存自动化空窗期
- 用户询问 Employee 01 7/14 当天新发的请假邮件（7/27–8/3）为何没进日历。
- **原因确认**：Codex 自动化已停用、Claude Code 定时任务尚未搭建，当前**没有任何东西在自动同步新邮件**。此事件按用户要求**暂不写入**，留作 Phase 1 定时自动化上线后的第一个测试用例。
- **附带发现**：Employee 01 的历史记录本身存在同人多名字重复问题（见下）。

### I. 姓名标准化（Preferred Name）
- 用户提供两份公司花名册：**Malaysia Office Basic Info**（Google Sheet）、**QB Office Basic Info.xlsx**（Drive），共 26 人的官方 Preferred Name。
- 发现并请用户修正了花名册自身的错误：`Employee 28` 与 `Employee 29` 曾共用同一邮箱 `employee29@example.com`；用户已在源表格改为 `employee28@example.com` / `employee29@example.com` 分开。
- 确定命名格式：`<TYPE>: <PreferredName>`，冒号后统一留一个空格。
- 确定"花名册覆盖不到的人"的处理规则：按邮箱本地部分推算显示名（如 `employee24@example.com` → `Employee 24`），非姓名格式的邮箱（纯数字个人邮箱、连写无分隔符）退回 Gmail 显示名（如 `employee18@example.com` → `Employee 18`）。
- 两个 "Employee 04" 明确消歧：`employee04@example.com` → `Employee 04`；`employee08@example.com` → `Employee 08`。
- 新增 **`roster.json`**（项目根目录）作为姓名规则与花名册数据的唯一来源，供以后自动化直接读取，不再散落在文档描述里。
- `PRD.md` 新增 3.1 节"姓名标准化"，第 5 节防呆规则更新姓名规则并补充历史教训（Employee 01/Employee 02 多名字重复案例）。
- **注意：本次只是把规则和数据存档，尚未对日历上现存事件执行实际改名操作**，执行前需与用户确认是否也覆盖可通过花名册匹配到人的 D 类手动记录。

---

## 2026-07-14 (续) — 全日历姓名标准化执行 + 收尾修正

### J. 姓名标准化批量执行（按 roster.json v3）
- 扫描 183 条请假事件，**改名 136 条、删除重复 6 条、保留 15 条、本已正确 26 条**。全部关闭通知。
- 改名类型：去姓留 Preferred Name（`Employee 13`→`Employee 13` 等）、花名册映射（`Employee 01`→`Employee 01`、`Employee 02`/`Employee 02`→`Employee 02`、`Employee 30...`→`Employee 30`）、两个 Employee 04 消歧（`Employee 08`→`Employee 08`）、邮箱推算（`Employee 18`→`Employee 18`、外部合作方 `Employee 44`/`Employee 21`/`Employee 24`/`Employee 19`/`Employee 15` 去姓留名）、格式统一（全角冒号/无空格/半天后缀 → `AL: Name (Half-Day AM/PM)`）。
- 删除的 6 条重复：改名后与另一条完全重合的（Employee 02 5/8、Employee 31 5/28、Employee 18 6/16、Employee 05 6/18、Employee 01 6/18 PM、Employee 01 6/30 AM），各保留带来源邮件的一条。
- 保留未改：离职且花名册无 Preferred Name（Employee 32、Employee 33）、无法识别的手动记录（Employee 34、Employee 35、Employee 36、Employee 37 等）。

### K. 收尾修正（用户逐条确认后执行）
- **Employee 09 6/29 半天**：确认为审批人误记（Employee 09 在批准 Employee 01 的请假），且 Employee 01 本人 6/30、7/9 半天已正确在册 → 🗑️ 删除 `AL: Employee 09 (Half-Day AM)` 2026-06-29。
- **Employee 16 → Employee 16**：确认源表格笔误（小写 y），✏️ 改正日历 3 条（2/16 AL、2/20 BL、5/6 AL）+ roster.json。
- **Employee 38 → Employee 38**：确认源表格 preferredName 栏笔误，✏️ 改正日历 1 条（3/19）+ roster.json。
- **Employee 39（SL 3/2）**：用户表示这条不用看，保持原样。
- roster.json 升级至 v3：新增 `yk.goh → Employee 09`，修正 Employee 16 / Employee 38 两处笔误并加注说明。

### L. 仍待人工留意（未处理）
- `AL: Employee 30` 2026-05-28 有两条重叠（手动 2 天 5/28–29 + 邮件来源 1 天 5/28），按“不合并不同时段”规则未动，建议后续人工确认是否重复。

---

## 2026-07-14 (续) — Phase 1 流程首次端到端测试（浏览器实操演示）

### M. Employee 01 7/27–8/3 请假：第一个真实测试用例，通过 ✅
- 按用户要求，**在浏览器里手动实操**走了一遍 Phase 1 完整流程（非后台 API，全程可视给用户看）：
  1. 打开 Gmail → 找到并读取 Employee 01 的 "Annual Leave Request"（27 July – 3 Aug，6 working days，family trip；Employee 09 回复 "Ok" 已批准）。
  2. 按规则解析：请假人 `employee01@example.com` → roster → **Employee 01**；假别 **AL**；日期 **7/27–8/3**（整段多天）。
  3. 打开 Google Calendar → 周视图 → 全天区域新建事件。
  4. 标题 `AL: Employee 01`；日期 Jul 27 → Aug 3, 2026（UI 结束日含当天）；全天；日历选 **VSYS Leaves**；描述填来源邮件信息。
  5. 保存成功，日历上确认显示多天全天横幅 `AL: Employee 01`。
- **结论**：解析 + 命名 + 写入逻辑端到端跑通。这条即为之前预留的测试用例，现已正式在册。
- **备注**：本次是手动浏览器演示，用于验证流程；真正的定时自动化（无人值守）尚未搭建。

---

## 2026-07-15 — Phase 1 定时自动化已搭建

### N. 创建本地定时任务 `vsys-leave-sync`
- 用户决定：先用**本地定时任务**（明确知道其"仅 App 开启时运行"的限制；云端例程虽能无人值守但存在连接器在无头环境失效的风险，暂缓）。
- 平台：Claude Code scheduled task（`~/.claude/scheduled-tasks/vsys-leave-sync/SKILL.md`）。
- 时间：工作日 **9:00 & 15:00** 香港时间（cron `0 9,15 * * 1-5`；系统加几分钟分散延迟，显示约 09:04）。
- 任务 prompt 自包含：读 roster.json → 扫最近 14 天请假邮件 → 仅处理 AL（SL/WFH/BL 跳过）→ 7 条防呆规则 → 查重 → 写入 VSYS Leaves（关闭通知）→ 判断不了跳过并报告 → 完成后通知用户。
- **待用户操作**：在侧边栏「Scheduled」点一次 **Run now**，用于预授权 Gmail/Calendar 工具（避免以后无人值守时卡权限弹窗），同时作为首次实测（查重逻辑保证不会重复写入）。

## 2026-07-15 — Phase 1b（git `phase-1b` 分支）

### O. 扩展范围：全假别 + WFH + 混合 + office 分类
- 用户需求：① 按香港/马来西亚两张表给人员标 office 并长期记住；② WFH 记到 WFH 日历；③ 所有请假类型都记（不止 AL），除 WFH 外都进 Leave 日历，WFH 进 WFH 日历；④ 混合情况两边都记。
- **Office 分类**：Malaysia 表 16 人 = Malaysia；其余（QB 12 人 + 香港实习生/外部合作方）= HK，默认 HK。写入 `roster.json` v4 每人 `office` 字段 + `officeClassification` 规则块。用户明确：Employee 13/Employee 14/Employee 25 是香港实习生，Employee 24/Employee 19（ABT/volmart）也统一算香港。
- **日历路由**：所有请假（AL/SL/BL/无薪假）→ VSYS Leaves；WFH → VSYS MY WFH（不分办公室）；混合 → 两边各一条。写入 `roster.json` v4 `calendarRouting`。
- **WFH 标题格式**：扫 VSYS MY WFH 日历确认——自动化建的用 `WFH: <Name> (Half-Day AM/PM)`（与请假同体系），员工自建的是 "<Name> WFH"。采用 `WFH: <PreferredName>`，并让任务对员工自建的 "Name WFH" 做去重识别。
- **roster.json v4**：加 office 字段、officeClassification、calendarRouting、WFH 命名；补上之前漏收录的 `employee20`（HK）。
- **定时任务 `vsys-leave-sync` prompt 更新**：扩到全假别 + WFH + 混合 + 双日历路由 + WFH 去重（识别 "Name WFH" 自建条目）。
- PRD 更新：前缀表加 WFH、新增 §3.2 Office 归属、§6 范围说明。
- **注意**：本次只更新了"going-forward"的自动化行为与文档，**未回头清理历史 WFH 日历的旧命名**（那批仍是 "Employee 02"/"Employee 30" 等全名 + 员工自建的 "Name WFH"）。如需统一历史 WFH 命名，另作为一个任务。

### P. Phase 1b 首跑 + 并回 main（2026-07-15）
- **首跑（真实运行）**：扫最近 14 天邮件。结果 0 写入——Employee 01（7/27–8/3）、Employee 11（7/15）都识别到但已存在→正确跳过；无 WFH 请求邮件（员工自建 "Name WFH" 已识别为存在）；一条 Google Chat 里的 Employee 04 请假闲聊因人/日期不明确→标 needs-human 跳过。验证 dedup + 新逻辑正常。
- **git**：`phase-1b` 以 fast-forward 并回 `main`（tag `phase-1b-merged`）；`phase-2` 分支基于新 main 重建；删除已合并的 `phase-1b` 分支。

## 2026-07-16 — Phase 2 试点 + 发现系统性"审批误记"污染 + 全日历清扫

### Q. Employee 01 试点（浏览器填表，通过）
- 浏览器把 Employee 01 4/1 起请假填入 Leave Record QB 2026（Employee01 tab）。验证 workflow：按列填、避开下拉格 Tab 陷阱；Summary/Balance 是公式自动算（Balance=F3−B8）。
- 删除无依据的 `AL: Employee 01 2026-05-14`（日历+sheet 双删；无来源邮件、邮箱查无）。
- 修正 Balance 显示取整：改为显示 1 位小数（11.5 而非 12）。

### R. 根因：旧自动化"审批人被误记为请假人"（系统性）
- 改用**邮件为准**核对老员工假期时发现：日历里多条"无本人邮件依据"条目，全是旧自动化（6/30 版）把**回复/审批邮件的人**当成请假人。
- 铁证：Employee 03 `AL 5/11` 来自 **Employee 36 辞职邮件**"11 May 是最后一天"（Employee 03 只是回复）；Employee 04 `WFH 5/11`（批 Employee 40）、`WFH 6/23`（批 Employee 02）、`AL 4/10`（批 Employee 41）全是审批回复被误记。
- 经理/审批人（Employee 04、Employee 09、Employee 10、Employee 01、Employee 11、Employee 12）为重灾区。上轮清理没扫 WFH 日历、且信任了貌似正规的引用未回读源邮件，故漏网。

### S. 防错机制（写入 PRD §5 / PHASE2_DESIGN §5）
- **邮件 = 最终确认版本；日历只做 cross-check，冲突以邮件为准。**
- 登记前必须找到"此人本人"发出的原始请假邮件；仅以审批/回复出现 → 不记。请假 + WFH 两日历都适用。

### T. 全日历清扫（执行中）
- 对 VSYS Leaves + VSYS MY WFH 两日历全量逐条对邮件验证，删除"审批误记 / 无邮件依据"条目；不确定的留人工。结果见后续记录。

### U. 老员工表格更新（EMAIL 为准，4/1 起）
- Employee 02 / Employee 03 / Employee 04 / Employee 05 / Employee 06 的 2026 tab 按邮件核对结果填入。

## 2026-07-17 — Phase 2 老员工填表 + 全日历清扫 + 表格结构升级

### V. 老员工表格填入（EMAIL 为准，4/1 起，浏览器操作）
按邮件核对结果填入 6 人（Employee 07 无请假）：
- **Employee 01** AL 7.5 → Balance 11.5（删无据 5/14 后）
- **Employee 02** AL 6.5 + WFH 2.0 → Balance 11.5（9 条，含 5/13 混合、5/28、6/23）
- **Employee 03** AL 6 + SL 1 → Balance 8.0
- **Employee 04** AL 6 + Birthday 1 → Balance 14.0
- **Employee 05** AL 1 → Balance 17.0
- **Employee 06** BL 1（丧假）→ Balance 19.30
- 浏览器操作教训：输入多行会自动滚动导致按坐标点击错位；改用**名称框跳转**定位每列起点，可靠。已写入 PHASE2_DESIGN §4.1。

### W. 全日历"审批误记"清扫（后台任务）
两日历逐条对邮件验证，删除 **审批人被误记为请假人 / 无邮件依据** 条目：
- 已删（第一轮）：Employee 03 5/11（Employee 36 辞职日）、Employee 04 4/10（批 Employee 41）
- 已删（第二轮）：Employee 04 WFH 5/11（批 Employee 40）、Employee 04 WFH 6/23（批 Employee 02）、Employee 42 5/22（招聘应聘者）、Employee 30 6/10（新人入职日）
- 修/补：Employee 02 6/23 WFH 改 AM；删 Employee 12 5/20、Employee 11 7/1 的重复半天；补 Employee 02 5/13 AM AL、5/28 PM WFH（5/13 PM WFH 已存在，旧名 Employee 02）。
- 结论：经理/审批人是重灾区，根因见 R 段。

### X. 表格结构升级：全 8 个 tab（用户 2026-07-17 定）
- **新增 "Birthday Leave" 独立列**（G 列，SUMIF 汇总）——之前生日假不进任何汇总列。
- **修 "Others" 合计公式**：`SUMIF(...,"Others*",...)+SUMIF(...,"BL",...)`——原公式精确匹配 "Others" 导致 "Others, refer to remarks" 不汇总；现用通配。
- **类型下拉新增 "BL"**（丧假）——8 个 tab 全部加；**BL 折入 Others 列**（用户决定，不单独设列）。Employee 06 丧假类型改为 BL。
- 8 个 tab 布局有两种（合计行 6 或 8、数据行 10/12/13），公式范围按各 tab 调整。

### Y. Nancy tab —— 先误"从头重做"、后按用户要求回撤（2026-07-17）
- **错误做法（已撤销）**：把 Nancy 已有的 10 行数据清空、从邮件重填 12 行。问题：① 不该清空重做——tab 已有数据应先核对完整性再针对性补/改；② 重填时用 `\t` 想分 From/To 列，但浏览器 Tab 不跳格，导致 From/To 都挤进 A 列、B 列空（同 Employee 01 的 bug）。
- **用户反馈（已入长期记忆 [[feedback-verify-existing-before-rebuild]]）**："本身如果有填写应该先核对是否完整而不是直接从头开始做。"
- **回撤**：已恢复 Nancy 原始 10 行（From/To 正确分列）+ 合计公式改回原 `C12:C41`。当前 = 上一版本：AL 8、SL 1、WFH 3、Balance 9.30。结构列（Birthday/BL）保留。
- **遗留供参考**（回撤前的邮件核对结论，供之后"先核对再针对性修"用，非现在执行）：5-Dec 应为 AM 半天（非 PM）；4 天假应 30-Mar 起（非 31-Mar，公式 C12 也漏算了 5-Dec/2-Jan 使总额显示 8 而非 8.5）；缺 3-Mar、29-May 两天 WFH；20-Apr 病假半/整天待定。

## 2026-07-21 — 日历描述隐私收紧 + 历史回溯清理 + Phase 2 月度只读比对任务

### Z. 日历事件描述栏隐私格式（用户发现问题并确认改法）
- **起因**：用户截图发现 Employee 07 WFH 事件描述栏完整暴露了请假原因（"to avoid spreading germs to colleagues"）和批准人回复原话（"No problem, feel better!"），认为不该展示这么细。
- **新格式（PRD.md §3 已更新）**：描述栏只保留 `Source email` / `From` / `Message date` / `Approved by: <批准人姓名>` 四项；**不写**请假/WFH 具体原因，**不写**批准人回复原话。找不到明确批准人 → 省略该行，不编造。只影响**以后新写入**的事件。
- **历史回溯范围（用户定）**：只清理 **2026 年 6–7 月**的事件，更早的不动。

### AA. 历史回溯清理执行（后台子任务，2026-07-21）
- 扫描 VSYS Leaves + VSYS MY WFH 两日历 6/1–7/31 共 148 条事件，其中 28 条有描述文字需要检查。
- **改写 10 条**为新格式：Employee 01 AL 7/27–8/3、Employee 40 AL 7/27、Nancy WFH 7/20–21、**Employee 07 WFH 7/21**（用户截图的那条）、Employee 02 WFH 7/22 → 均改为 `Source email/From/Message date/Approved by`；Employee 13 半天假 7/20 无明确批准人 → 省略 Approved-by 行。
- **清空 4 条**（Employee 13 AL 6/1–6/5、Employee 04 AL 6/11、Employee 43 半天 AL 6/15、Nancy AL 7/2–7/3）：原描述只是一句自由文本原因，没有任何 Source email/From/Message date 可保留，按规则不编造，直接清空。
- 18 条本已合规或无泄露内容，未动；120 条本来无描述，无需处理。全程 `notificationLevel: NONE`。

### AB. 新建定时任务 `vsys-phase2-monthly-diff`（只读，不写入）
- **用户需求讨论**：是否把"登记日历"和"登记表格"合并成一次运行？因表格只能靠浏览器写入（无写 API），无人值守时出错没人能当场发现（Employee 01/Nancy 的教训）。讨论后用户选择**方案 B**：日历照旧实时自动；表格改为"定时只读生成待办清单 + 用户在场时手动触发实际写入"。
- **排期**：用户要求"每月第一个星期一 10:00"（而非固定 1 号，避开 1 号可能是周末）。Cron 用 `0 10 * * 1`（每周一 10:00，系统显示约 10:06），任务 prompt 内置**第一步自检**：若当天日期 > 7 号则立即停止不做任何事，从而只在"当月第一个星期一"真正执行（规避 cron day-of-month/day-of-week 字段的 OR 语义歧义）。
- **任务职责（结构性只读）**：只加载 Gmail/Calendar/Drive 的**读**工具，不加载任何写入/浏览器工具。流程：读上个月邮件确认的请假/WFH → 与日历 cross-check → 读表格现有明细去重 → 算工作日天数（跳过周末+港假）→ 标记生日假/余额异常 → 只输出"待登记清单"报告，不做任何写入。
- 之后由用户在电脑前说"同步表格"，再由 Claude 现场浏览器逐条写入 + 回读核对（沿用 PHASE2_DESIGN §4.1 方法）。

## 2026-08-04 — VSYS MY WFH 改名为 VSYS MY Attendance + 新增 OOO 类型

### AC. 起因：Employee 10 的 OOO 自动回复邮件该记在哪
- 用户发现 Employee 10 有一封 "Out Of Office" 自动回复邮件（2026-07-30 发出，"will only be back to office on 10 Aug 2026"），问该新建一个日历分组还是加进现有的。
- 核实后确认：这**不是正式请假申请**（无假别、无起始日、无审批），按 PRD 防呆规则不该直接记成 AL/SL 等具体假别。
- 用户决定：**把这类"联系不上/OOO"信息，和 WFH 一起，都放进原来的 WFH 日历**，并已把该日历改名为 **"VSYS MY Attendance"**（日历 ID 不变，仍是 `c_26a95cdd...`）。

### AD. OOO 规则确立（用户逐条确认）
- 命名格式沿用现有惯例：`OOO: <PreferredName>`。
- **判定门槛降低**：OOO 自动回复是本人邮箱自己发的，没有"审批人误记成请假人"的风险，不需要额外找批准邮件，只要能确定人+大致日期即可记录。
- **起始日推算规则**：自动回复通常只写"几号回来"、不写起始日 → 用**该邮件自身日期**当起始日，描述里注明是推算值。
- **已接入 Phase 1 自动化**：`vsys-leave-sync` 定时任务 prompt 已更新（新增 Step 3b OOO 处理逻辑、Step 1/2/4/6/7 相应调整），以后会自动识别 Out Of Office 自动回复邮件并建 OOO 条目。
- **不影响 Phase 2**：OOO 不在表格 Type of Leave 下拉里，不扣任何假别余额。
- 全部写入 `roster.json`（v5，新增 `oooRule` 块 + `calendarRouting.attendance`）与 `PRD.md`（§3 表格新增 OOO 行 + 新增 §3.3）。

### AE. 顺手发现并补的一个漏洞：`vsys-leave-sync` 的描述格式没跟上 7/21 的隐私规则
- 回顾时发现：7/21 定的"描述栏只留 Source email/From/Message date/Approved by"隐私规则，只改了 `PRD.md` 文档，**忘了同步改真正在跑的 `vsys-leave-sync` 定时任务 prompt**——它 Step 6 里还是旧的"自由文本备注"格式。这次一并修正，避免以后自动化继续按旧格式写入。

### AF. 已执行：Employee 10 的 OOO 条目
- 在 VSYS MY Attendance 新建 `OOO: Employee 10`，2026-07-30 → 2026-08-09（8/10 回办公室，end.date 排他到 8/10），描述含来源邮件信息 + 起始日推算说明，`notificationLevel: NONE`。

### AG. 待确认 / 已知限制
- **SL 是否也要挪到 Attendance**：日历新描述里写了也含 SL，但用户只确认了 WFH+OOO，SL 暂不变（仍在 VSYS Leaves）——如需改动请明确告知。
- **日历名称尾部空格**：用户要求把 "VSYS MY Attendance " 后面的空格删掉，但**当前连接的日历工具没有"改日历名称/描述"的能力**（只能读写事件，不能改日历本身的 summary），需要用户自己在 Google Calendar 设置里手动改一下（日历设置 → 该日历 → 改名）。

## 待办（下一步）
1. Nancy tab：按"先核对完整性、再针对性修"的正确流程处理（用户可能自行处理，如其他 tab）。上方 Y 段列了待核对点。
2. Employee 01 以外 6 个老员工 tab 的 From/To 分列（用户表示自行清理）。
2. （可选）统一历史 WFH 日历旧命名到 Preferred Name（如 Employee 02→Employee 02）。
3. 老员工表格的 go-through 复核（AL 余额已列于 V 段）。
4. Phase 2b：季度提醒邮件（每次发送需用户确认）。
5. 每月第一个星期一 `vsys-phase2-monthly-diff` 首次运行后，跟进报告结果并按需现场同步表格。
6. 用户手动去掉 "VSYS MY Attendance" 日历名称尾部的空格（工具无法直接改）。
7. 确认 SL 是否也要从 VSYS Leaves 挪到 VSYS MY Attendance（当前未改）。

### 已完成（勾除）
- ~~执行姓名标准化改名~~ ✅ 2026-07-14 完成（J/K 段）
- ~~Employee 01 7/27–8/3 测试用例写入~~ ✅ 2026-07-14 完成（M 段）
