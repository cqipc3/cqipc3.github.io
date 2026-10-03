#!/usr/bin/env bash
# 极简静态博客构建脚本。依赖:pandoc
# 用法:./build.sh        构建到 public/
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(dirname "$0")"

source site.conf
OUT=public
rm -rf "$OUT"
mkdir -p "$OUT"

# 读取 Markdown 头部的某个字段
meta() { sed -n "/^---\$/,/^---\$/{s/^$2:[[:space:]]*//p}" "$1" | head -n1 | sed 's/^"\(.*\)"$/\1/'; }

render() { # render <input.md> <output-dir> <root> [extra pandoc args]
  local in=$1 dir=$2 root=$3; shift 3
  mkdir -p "$dir"
  pandoc "$in" -f markdown+smart -t html5 --no-highlight --template=template.html \
    -V site-title="$SITE_TITLE" -V site-desc="$SITE_DESC" -V lang="$SITE_LANG" \
    -V root="$root" "$@" -o "$dir/index.html"
}

# 文章
rows=""
for f in posts/*.md; do
  [ -e "$f" ] || continue
  [ "$(meta "$f" draft)" = "true" ] && continue
  slug=$(basename "$f" .md)
  title=$(meta "$f" title); date=$(meta "$f" date); summary=$(meta "$f" summary)
  render "$f" "$OUT/$slug" "../" -V post=1
  rows+="$date|$slug|$title|$summary"$'\n'
done

# 首页:按日期倒序,按年份分组
index=$(mktemp)
{
  year=""
  while IFS='|' read -r date slug title summary; do
    [ -n "$date" ] || continue
    if [ "${date:0:4}" != "$year" ]; then
      [ -n "$year" ] && echo "</ul></section>"
      year=${date:0:4}
      echo "<section class=\"year\"><h2>$year</h2><ul>"
    fi
    echo "<li><time datetime=\"$date\">${date:5}</time><div><a href=\"$slug/\">$title</a><p class=\"summary\">$summary</p></div></li>"
  done < <(printf '%s' "$rows" | sort -r)
  [ -n "$year" ] && echo "</ul></section>"
} > "$index"
render "$index" "$OUT" "" -V index=1 --metadata title="$SITE_TITLE"
rm -f "$index"

# 独立页面(如 about)
for f in pages/*.md; do
  [ -e "$f" ] || continue
  render "$f" "$OUT/$(basename "$f" .md)" "../"
done

cp style.css "$OUT/"
[ -d static ] && cp -r static/. "$OUT/" && rm -f "$OUT/.gitkeep"
echo "构建完成:$OUT/"
