#!/usr/bin/env bash
# Render templates/<task>/SKILL.md with your config.json into build/<task>/SKILL.md.
# Then register the tasks in Claude Code (see README "安装").
set -euo pipefail
cd "$(dirname "$0")"

for f in config.json roster.json; do
  if [ ! -f "$f" ]; then
    echo "缺少 $f —— 先执行: cp ${f%.json}.example.json $f  然后填入你自己的值" >&2
    exit 1
  fi
done

python3 - "$PWD" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
cfg = json.loads((root / "config.json").read_text())
values = {
    "PROJECT_DIR": str(root),
    "GMAIL_ACCOUNT": cfg["gmailAccount"],
    "TIMEZONE": cfg["timezone"],
    "LEAVE_CALENDAR_NAME": cfg["leaveCalendarName"],
    "LEAVE_CALENDAR_ID": cfg["leaveCalendarId"],
    "ATTENDANCE_CALENDAR_NAME": cfg["attendanceCalendarName"],
    "ATTENDANCE_CALENDAR_ID": cfg["attendanceCalendarId"],
    "SYSTEM_NOTIFICATION_SENDER": cfg["systemNotificationSender"],
    "GMAIL_LABELS": cfg["gmailLabels"],
    "HOLIDAY_REGION": cfg["holidayRegion"],
    "HOLIDAY_PREFIX": cfg["holidayPrefix"],
    "LEAVE_SHEET_NAME": cfg["leaveSheetName"],
    "LEAVE_SHEET_FILE_ID": cfg["leaveSheetFileId"],
    "SHEET_TABS": cfg["sheetTabs"],
}
for tpl in sorted((root / "templates").glob("*/SKILL.md")):
    text = tpl.read_text()
    for k, v in values.items():
        text = text.replace("{{" + k + "}}", v)
    left = sorted(set(re.findall(r"\{\{[A-Z_]+\}\}", text)))
    if left:
        sys.exit(f"{tpl}: 未填的占位符 {left}")
    out = root / "build" / tpl.parent.name / "SKILL.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    print(f"生成 {out.relative_to(root)}")
PY

echo
echo "下一步：在 Claude Code（桌面版）里打开本文件夹，粘贴 README「安装」第 4 步那段话，注册两个定时任务。"
