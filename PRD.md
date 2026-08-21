# VSYS 请假自动化 — 产品需求文档 (PRD)

**Owner:** Nancy Fu (nancy.fu@v.systems)
**平台:** Claude Code (Desktop)，通过已授权的 Gmail / Google Calendar 连接器操作
**创建日期:** 2026-07-14
**当前版本:** ✅ **Phase 1（已上线，运行良好）** — 邮件 → 日历 AL 自动同步，历史数据已清理 + 姓名已标准化，本地定时任务 `vsys-leave-sync` 工作日 9:00/15:00 运行。
**开发中:** 🚧 **Phase 2**（年假天数表格自动登记 + 季度提醒邮件）— 在 git `phase-2` 分支上进行，`main` 分支保留 Phase 1 基线以便回撤。

---

## 1. 目标

自动读取 `nancy.fu@v.systems` 邮箱里与请假相关的邮件，识别请假信息，并按照 "VSYS Leaves" 日历现有的标注规范，自动把请假事件登记到日历上，减少手动整理工作，避免漏记。

分两个阶段：
- **Phase 1** — 邮件 → 日历自动同步（含一次性历史修正 + 后续定时自动化）
- **Phase 2** — 年假天数表格自动登记 + 季度提醒邮件（待 Phase 1 稳定后开始）

---

## 2. 关键资源

| 资源 | 标识 |
|---|---|
| Gmail 账号 | nancy.fu@v.systems |
| 目标日历 | **VSYS Leaves** (`<VSYS_LEAVES_CALENDAR_ID>`) |
| 时区 | Asia/Hong_Kong |
| WFH/OOO 日历 | **VSYS MY Attendance**（原名 "VSYS MY WFH"，用户 2026-08-04 改名并扩展用途，`<VSYS_ATTENDANCE_CALENDAR_ID>`） |

---

## 3. 日历标注规范（从现有数据反推 + 已统一）

| 前缀 | 含义 | 日历 |
|---|---|---|
| `AL:` | 年假 / 事假 / 无薪假 / day off / time off | VSYS Leaves |
| `SL:` | 病假 / 医疗假 | VSYS Leaves |
| `BL:` | 丧假 (bereavement / compassionate) | VSYS Leaves |
| `WFH:` | 在家办公 (work from home) | **VSYS MY Attendance** |
| `OOO:` | 联系不上/不在办公室（通常来自本人邮箱自动回复，2026-08-04 新增） | **VSYS MY Attendance** |
| `HK-` | 香港公众假期 | VSYS Leaves |

**日历路由（Phase 1b + OOO 扩展）**：所有**请假**类型 → `VSYS Leaves`；**WFH / OOO** → `VSYS MY Attendance`（原名 "VSYS MY WFH"，不分 HK/Malaysia）。**混合情况**（同一封邮件既请假又 WFH）→ 两个日历各记一条。日历 ID 见 `roster.json.calendarRouting`。

> ⚠️ **待确认**：改名后的日历描述里写着也覆盖 SL（病假），但目前规则**未改**——SL 仍然进 VSYS Leaves，不进 Attendance。如果这个也要改，需要用户明确确认（影响面较大，涉及 Phase 1 路由规则）。

### 3.3 OOO（Out of Office，2026-08-04 新增）

- **判定门槛低于正式请假**：OOO 自动回复本身就是本人邮箱发出的，不存在"审批人误记成请假人"的风险；只要能确定"是谁"+"大致哪几天"即可记录，不需要像 AL/SL/BL 那样找批准邮件链。
- **起始日推算**：自动回复通常只写"几号回来"，不写起始日 → 用**该自动回复邮件本身的日期**作为起始日，并在事件描述里注明是推算值。
- **不影响 Phase 2**：OOO 不是表格 Type of Leave 下拉里的选项，不扣任何假别余额，纯粹是日历备忘。
- **已接入 Phase 1 自动化**：`vsys-leave-sync` 定时任务会自动识别 Out Of Office 自动回复邮件并建 OOO 条目（见任务 prompt）。
- 详见 `roster.json.oooRule`。

**事件格式：**
- **整天 / 多天**：标题 `AL: <姓名>`，all-day 事件。多天时 `end.date` 为最后一天的**次日**（Google all-day 结束日为排他）。
- **半天 AM**：标题 `AL: <姓名> (Half-Day AM)`，定时事件 09:00–13:00 HKT。
- **半天 PM**：标题 `AL: <姓名> (Half-Day PM)`，定时事件 14:00–18:00 HKT。
- **冒号格式统一为「冒号 + 一个空格」**：`AL: Nancy`，不用 `AL:Nancy`（无空格）或全角冒号。
- **描述栏**统一写来源，便于日后排查，**并注意隐私**（2026-07-21 确认）：
  ```
  Source email: <邮件主题>
  From: <寄件人>
  Message date: <邮件日期>
  Approved by: <批准人姓名>
  ```
  - **只保留"被谁批准"这一事实**，**不写**请假/WFH 的具体原因（如病情、私人事务细节），**不写**批准人回复的原话引用。
  - 找不到明确批准人时：省略 "Approved by" 这一行，不编造。
  - 此规则适用于**以后新写入**的事件；历史事件的回溯清理范围见 CHANGELOG。

### 3.1 姓名标准化（2026-07-14 新增）

标题里的 `<姓名>` 一律使用 **Preferred Name**，规则和权威数据见同目录下的 **[`roster.json`](roster.json)**（唯一姓名真相来源，不在别处重复维护）：

1. **邮箱能在 `roster.json` 的 `roster[]` 里查到** → 用对应的 `preferredName`（来自 Malaysia Office Basic Info / QB Office Basic Info 两份公司花名册）。
2. **两位曾用同一简称的员工消歧**：`employee04@example.com` → `Employee 04`；`employee08@example.com` → `Employee 08`。日历上不允许出现裸的、未消歧的简称。
3. **邮箱不在花名册里** → 按 `roster.json.fallbackRule` 从邮箱本地部分推算：取 `.`/`_`/数字 切分后的第一段并首字母大写（如 `employee13@example.com` → `Employee 13`，`employee24@example.com` → `Employee 24`）。
4. **本地部分不像姓名格式**（纯数字个人邮箱、连写无分隔符）→ 退回 Gmail 寄件人显示名的名字部分（已知例外见 `roster.json.knownExceptions`，如 `employee18@example.com` → `Employee 18`）。
5. **无对应来源邮件的手动记录（D 类）**默认不重命名；只有能通过 `roster.json` 里 `employeeFullName` 括号昵称明确对应到人时（如 `Koh Wei Mien (Carol)` ↔ 日历上的 `Carol`）才可能纳入重命名范围，执行前需与用户确认范围。

### 3.2 Office 归属（HK / Malaysia，Phase 1b 新增）

每人所属办公室记在 `roster.json` 的 `office` 字段，规则：**在 Malaysia Office Basic Info 表里 = Malaysia；其余所有人（QB 员工 + 香港实习生 + ABT/volmart 等外部合作方）= HK**，未知默认 HK。此归属用于记录与 Phase 2 参考，**不影响日历路由**（所有 WFH 仍统一进 VSYS MY WFH）。

---

## 4. 邮件识别范围

搜索 Gmail（Inbox + Sent），关键词覆盖：`annual leave`、`leave request`、`leave application`、`day off`、`time off`、`half-day`、`请假`。
高信号来源标签（若有）：`HR/Leave`、`Malaysia/Leave`。

---

## 5. 取值规则（防呆机制 — 均为实战验证有效）

这些规则是针对旧自动化实际发生过的 bug 制定的，**必须内置到任何自动化流程中**：

1. **审批人 ≠ 请假人（最重要，反复踩坑）**：请假人一律以邮件串中**最早的原始请假邮件的寄件人**为准；批准 / FYI / "ok" / "Noted" 回复只用于确认"已批准"，**绝不**作为请假人或日期来源。
   - *历史教训：旧自动化系统性地把"回复/审批的人"当成请假人。经理/审批人（Employee 04、Employee 09、Employee 10、Employee 01、Employee 11、Employee 12）是重灾区——每批一次别人的假，就给自己造一条假。例：Employee 04 批 Employee 40/Employee 41/Employee 02 的 WFH → 记成 Employee 04 的 WFH；Employee 03 回复 Employee 36 的辞职邮件（"11 May 是你最后一天"）→ 记成 Employee 03 5/11 请假。*
   - **防错机制**：登记任何人的假前，必须能找到一封**此人本人**发出的原始请假邮件；只在别人邮件里以回复/审批身份出现 → 不记。此规则对**请假日历和 WFH 日历都适用**。
0. **邮件为最终准，日历只做 cross-check**：录入表格/判定请假，一律以**邮件**为最终确认版本；日历是从邮件生成的派生视图（且历史上被旧自动化污染过），只能用来交叉核对，冲突时**以邮件为准**。
0b. **扣假期天数只算工作日（跳过周末 + 法定节假日）**：Phase 2 表格里的"No. of day(s) Taken"、以及任何"扣了几天假"的计算，**必须排除周六周日和香港公众假期**（落在这些日子上的不计天数），半天算 0.5。公众假期以日历里的 `HK-` 全年清单为准。详见 PHASE2_DESIGN §3.4。
2. **日期年份合理性校验**：解析出的请假年份必须等于邮件年份或至多次年；若某种解读会得到明显离谱的年份（如 2027 / 2030），判定为解析错误，标记为"需人工确认"而非硬写入。
   - *历史教训：曾出现 2030-07-12、2027-08-03、2027-04-21 等错误事件。*
3. **忽略系统测试 / 自动通知邮件**：来自 `support@v.systems` 的 "New Leave Request from …" 系统通知日期范围不可靠，一律忽略，只信真人撰写的请假邮件。
4. **写入前查重**：创建任何事件前，先在该人该日期窗口 `list_events` 查询，确认没有对应记录才创建，避免重复。
5. **姓名规范**：按第 3.1 节 + `roster.json` 统一为 Preferred Name；同一人任何时候只用一种写法，不混用全名 / 缩写 / 花名 / 大小写变体。
   - *历史教训：Employee 01 同时出现 "Employee 01"、"Employee 01" 两种名字、Employee 02 同时出现 "Employee 02"/"Employee 02"/"Employee 02" 三种名字，导致同一次请假被重复记录两遍。*
6. **交叉核对**：遇到主邮件里批准状态不明的情况，可搜索同一日期附近的其他邮件确认是否另有批准。
7. **判断不了就跳过**：无法确定日期 / 人 / 假别时，跳过并记为"待人工确认"，不猜测、不乱写、不发邮件打扰用户。

---

## 6. Phase 1 — 定时自动化（待搭建）

- **触发**：Claude Code scheduled task，工作日 2 次/天，cron `0 9,15 * * 1-5`（本地时区）。
- ⚠️ **重要限制**：Claude Code 定时任务**仅在 App 开启时运行**；到点时若 App 关闭，则在下次打开 App 时补跑。不具备旧 Apps Script 那种云端 24h 自动运行能力。此为已知取舍。
- **每次运行逻辑**：扫描新的请假邮件 → 按第 5 节规则解析 → 写入 VSYS Leaves → 判断不了的跳过留待人工抽查。
- **范围**：Phase 1 上线时只处理 `AL`；**Phase 1b（2026-07-15）已扩展为全假别（AL/SL/BL）+ WFH + 混合**，定时任务 prompt 已相应更新。

### 6.1 流程已验证（2026-07-14）

用 Employee 01 7/27–8/3 请假作为首个测试用例，在浏览器里手动实操走通了完整流程（读邮件→解析→查重→写入 VSYS Leaves），确认逻辑无误。多天全天事件在 UI 里的填法：结束日填**最后一天当天**（UI 结束日含当天，与 API 的排他 end.date 不同）。搭定时自动化时按此逻辑固化。

---

## 7. Phase 2 — 年假表格 + 季度提醒

详细设计见 `PHASE2_DESIGN.md`。核心机制（2026-07-21 定）：

- **日历自动化（Phase 1/1b）实时运行不变**：定时任务 `vsys-leave-sync` 照常工作日 9:00/15:00 写日历。
- **表格登记改为"月度只读比对 + 用户在场手动同步"**，原因：Sheets 无写 API，只能靠浏览器模拟操作，无人值守时若写错没人能当场发现（历史教训见 CHANGELOG Employee 01/Nancy From/To 列事故）。
  - 定时任务 `vsys-phase2-monthly-diff`：每月**第一个星期一 10:00**（cron `0 10 * * 1` + 内置"日期>7 则跳过"自检，规避 1 号可能是周末）运行，**只读不写**——比对上月邮件确认的请假/WFH 与表格现有明细，生成"待登记清单"报告（含工作日天数、异常标记），不做任何写入。
  - 用户看到报告后主动说"同步表格"，由 Claude 在场时用浏览器逐条写入 + 回读核对。
- 每季度给每位员工发邮件，提醒剩余未用年假天数（Phase 2b，未启动，发送需逐次用户确认）。
- 表格中的"姓名 ↔ 邮箱"对照可复用为 Phase 1 的花名册，提高姓名匹配准确率。

---

## 8. 历史背景（为何重建）

旧自动化经历三次尝试（详见 `archive/OLD_VSYS_LEAVE_SYNC_PRD_AND_CHANGELOG.md`）：
1. Codex 浏览器自动化（2026-06-26）
2. Google Apps Script + 20 个定时触发器（2026-06-30，错误率高达 100%）
3. 回滚回 Codex（2026-06-30）

问题根源：两个平台都让 AI **每次临场自由判断**邮件内容，缺乏确定性校验兜底，导致抓错年份 / 姓名 / 假别。且删除本地脚本 ≠ 停用云端触发器，一度出现多套系统并行写入、重复记录。

本次重建的核心改进：**用明确规则（第 5 节）约束 AI 判断**，而非放任自由发挥。

已于 2026-07-14 彻底退役旧自动化（详见 CHANGELOG.md）。
