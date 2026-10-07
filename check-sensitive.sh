#!/usr/bin/env bash
# Scan tracked files for data that must never be published. Run before every push.
# Generic patterns are built in; add your own real names/domains/IDs (one per line)
# to .sensitive-words, which is git-ignored so the blocklist itself never leaks.
set -uo pipefail
cd "$(dirname "$0")"

files=$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')
files=$(echo "$files" | grep -v -E '^(check-sensitive\.sh|\.sensitive-words)$')
fail=0

scan() { # label, extended regex
  hits=$(echo "$files" | xargs grep -n -I -E "$2" 2>/dev/null)
  if [ -n "$hits" ]; then echo "✗ $1"; echo "$hits" | sed 's/^/    /'; fail=1; fi
}

scan "真实 Google 日历 ID"   'c_[a-z0-9]{20,}@group\.calendar\.google\.com'
scan "疑似 Drive/Sheet 文件 ID" '(^|[^A-Za-z0-9_-])1[A-Za-z0-9_-]{32,43}([^A-Za-z0-9_-]|$)'
scan "本机用户路径"         '/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+'
hits=$(echo "$files" | xargs grep -n -I -o -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' 2>/dev/null \
       | grep -v -E '@(example\.(com|org)|partner\.example|group\.calendar\.google\.com|mail\.example|anthropic\.com)$')
if [ -n "$hits" ]; then echo "✗ 非示例邮箱"; echo "$hits" | sed 's/^/    /'; fail=1; fi

if [ -f .sensitive-words ]; then
  while IFS= read -r w; do
    [ -z "$w" ] || [ "${w#\#}" != "$w" ] && continue
    scan "黑名单词: $w" "$(printf '%s' "$w" | sed 's/[.[\*^$/]/\\&/g')"
  done < .sensitive-words
fi

if [ $fail -eq 0 ]; then echo "✓ 未发现敏感信息"; fi
exit $fail
