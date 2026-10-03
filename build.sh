#!/usr/bin/env bash
# 极简静态博客构建脚本。依赖:pandoc、perl
# 用法:./build.sh        构建到 public/
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(dirname "$0")"

source site.conf
OUT=public
rm -rf "$OUT"
mkdir -p "$OUT"

# 读取 Markdown 头部的某个字段
meta() { sed -n "/^---\$/,/^---\$/{s/^$2:[[:space:]]*//p}" "$1" | head -n1 | sed 's/^["'\'']\(.*\)["'\'']$/\1/'; }

# 没写 date 时,用文件第一次提交的日期;还没提交过就用修改日期
file_date() {
  local d
  d=$(git log --diff-filter=A --follow --format=%as -- "$1" 2>/dev/null | tail -n1 || true)
  [ -n "$d" ] || d=$(date -r "$1" +%F)
  echo "$d"
}

# 文件名 -> 网址目录名(空格换成短横线)
slug_of() { local s; s=$(basename "$1" .md); echo "${s// /-}"; }

# 所有文章和页面,供 [[双链]] 查找
slugs=""
for f in posts/*.md pages/*.md; do
  [ -e "$f" ] || continue
  slugs+="$(basename "$f" .md)"$'\t'"$(slug_of "$f")"$'\n'
done
export BLOG_SLUGS="$slugs"

render() { # render <input.md> <output-dir> <root> [extra pandoc args]
  local in=$1 dir=$2 root=$3; shift 3
  local tmp; tmp=$(mktemp)
  perl filters/preprocess.pl < "$in" > "$tmp"
  mkdir -p "$dir"
  BLOG_ROOT="$root" pandoc "$tmp" \
    -f markdown+hard_line_breaks+lists_without_preceding_blankline+wikilinks_title_after_pipe \
    -t html5 --no-highlight --template=template.html --lua-filter=filters/obsidian.lua \
    -V site-title="$SITE_TITLE" -V site-desc="$SITE_DESC" -V lang="$SITE_LANG" \
    -V root="$root" "$@" -o "$dir/index.html"
  rm -f "$tmp"
}

# 文章
rows=""
for f in posts/*.md; do
  [ -e "$f" ] || continue
  [ "$(meta "$f" draft)" = "true" ] && continue
  slug=$(slug_of "$f")
  title=$(meta "$f" title); [ -n "$title" ] || title=$(basename "$f" .md)
  date=$(meta "$f" date); [ -n "$date" ] || date=$(file_date "$f")
  date=${date:0:10}
  summary=$(meta "$f" summary)
  render "$f" "$OUT/$slug" "../" -V post=1 --metadata title="$title" --metadata date="$date"
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
  title=$(meta "$f" title); [ -n "$title" ] || title=$(basename "$f" .md)
  render "$f" "$OUT/$(slug_of "$f")" "../" --metadata title="$title"
done

cp style.css "$OUT/"
[ -d static ] && cp -r static/. "$OUT/" && rm -f "$OUT/.gitkeep"
echo "构建完成:$OUT/"
