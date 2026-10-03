#!/data/data/com.termux/files/usr/bin/bash
# 心轨一键捕获(Termux 版):桌面点一下 → 弹窗输入 → 自动提交推送,半分钟后上线。
# 依赖:pkg install gh git jq termux-api,另需安装 Termux:API 应用
# 用法:复制到 ~/.shortcuts/ 后,桌面添加 Termux 小部件选中它
set -euo pipefail
cd ~/blog || exit 1

# 弹窗输入;取消则静默退出
res=$(termux-dialog text -t "想到什么?" 2>/dev/null) || exit 0
text=$(printf '%s' "$res" | jq -r '.text // empty')
[ -n "$text" ] || exit 0

git pull --rebase -q
f="thoughts/$(date +%Y%m%d-%H%M%S).md"
printf '%s\n' "$text" > "$f"
git add "$f" && git commit -qm "心轨" && git push -q
termux-toast "已记入心轨 ✓"
