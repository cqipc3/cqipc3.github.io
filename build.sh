#!/usr/bin/env bash
# 极简静态博客构建脚本。依赖:pandoc、perl
# 用法:./build.sh        构建到 public/
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(dirname "$0")"

source site.conf
OUT=public
US=$'\x1f'
rm -rf "$OUT"
mkdir -p "$OUT"

# ---------- 工具函数 ----------
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

urlenc()   { printf '%s' "$1" | perl -pe 's/([^A-Za-z0-9_.~\/-])/sprintf("%%%02X",ord($1))/ge'; }
html_esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
json_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# ---------- 构建信息 ----------
commit=$(git rev-parse --short HEAD 2>/dev/null || echo dev)
dirty=""
[ -z "$(git status --porcelain 2>/dev/null)" ] || dirty=1   # 本地有未提交的改动
builddate=$(date -u +%F)
pandocver=$(pandoc --version | head -n1 | awk '{print $2}')
REPO_URL=${REPO_URL:-}

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
  perl filters/preprocess.pl < "$in" | sed "s|{{repo}}|$REPO_URL|g; s|{{commit}}|$commit|g" > "$tmp"
  mkdir -p "$dir"
  BLOG_ROOT="$root" pandoc "$tmp" \
    -f markdown+hard_line_breaks+lists_without_preceding_blankline+wikilinks_title_after_pipe \
    -t html5 --no-highlight --template=template.html --lua-filter=filters/obsidian.lua \
    -V site-title="$SITE_TITLE" -V site-desc="$SITE_DESC" -V lang="$SITE_LANG" \
    -V root="$root" -V repo="$REPO_URL" -V commit="$commit" -V builddate="$builddate" \
    ${dirty:+-V dirty=1} -V pandoc="$pandocver" "$@" -o "$dir/index.html"
  rm -f "$tmp"
}

# 源文件与修改历史链接
source_args() { # source_args <相对路径>
  [ -n "$REPO_URL" ] || return 0
  local p; p=$(urlenc "$1")
  printf '%s\n' -V "source=$REPO_URL/blob/$REPO_BRANCH/$p" -V "history=$REPO_URL/commits/$REPO_BRANCH/$p"
}

# ---------- 收集文章(按日期倒序) ----------
entries=()
while IFS= read -r line; do [ -n "$line" ] && entries+=("$line"); done < <(
  for f in posts/*.md; do
    [ -e "$f" ] || continue
    [ "$(meta "$f" draft)" = "true" ] && continue
    title=$(meta "$f" title); [ -n "$title" ] || title=$(basename "$f" .md)
    date=$(meta "$f" date); [ -n "$date" ] || date=$(file_date "$f")
    printf '%s\n' "${date:0:10}$US$(slug_of "$f")$US$title$US$(meta "$f" summary)$US$f"
  done | sort -r
)

# ---------- 渲染文章(带上一篇/下一篇) ----------
n=${#entries[@]}
for ((i = 0; i < n; i++)); do
  IFS=$US read -r date slug title summary file <<< "${entries[i]}"
  extra=()
  # 更新的一篇在前一项,更早的一篇在后一项
  if ((i > 0)); then
    IFS=$US read -r _ nslug ntitle _ _ <<< "${entries[i-1]}"
    extra+=(-V "newer-url=../$nslug/" -V "newer-title=$(html_esc "$ntitle")")
  fi
  if ((i < n - 1)); then
    IFS=$US read -r _ pslug ptitle _ _ <<< "${entries[i+1]}"
    extra+=(-V "older-url=../$pslug/" -V "older-title=$(html_esc "$ptitle")")
  fi
  while IFS= read -r a; do [ -n "$a" ] && extra+=("$a"); done < <(source_args "$file")
  render "$file" "$OUT/$slug" "../" -V post=1 --metadata title="$title" --metadata date="$date" ${extra[@]+"${extra[@]}"}
done

# ---------- 首页:按年份分组 ----------
index=$(mktemp)
{
  year=""
  for e in ${entries[@]+"${entries[@]}"}; do
    IFS=$US read -r date slug title summary _ <<< "$e"
    if [ "${date:0:4}" != "$year" ]; then
      [ -n "$year" ] && echo "</ul></section>"
      year=${date:0:4}
      echo "<section class=\"year\"><h2>$year</h2><ul>"
    fi
    echo "<li><time datetime=\"$date\">${date:5}</time><div><a href=\"$slug/\">$title</a><p class=\"summary\">$summary</p></div></li>"
  done
  [ -n "$year" ] && echo "</ul></section>"
} > "$index"

# 心轨:thoughts/ 里一条一个文件,时间取该文件第一次提交的时刻
thoughts_rows=""
for f in thoughts/*.md; do
  [ -e "$f" ] || continue
  ts=$(git log --diff-filter=A --format=%aI -- "$f" 2>/dev/null | tail -n1)
  [ -n "$ts" ] || ts=$(date -r "$f" +%Y-%m-%dT%H:%M:%S)
  thoughts_rows+="$ts|$f"$'\n'
done
if [ -n "$thoughts_rows" ]; then
  {
    echo '<section class="thoughts"><h2>心轨</h2><ul>'
    printf '%s' "$thoughts_rows" | sort -r | head -n 3 | while IFS='|' read -r ts f; do
      line=$(awk 'NR==1&&/^---[[:space:]]*$/{infm=1;next} infm&&/^---[[:space:]]*$/{infm=0;next} !infm' "$f" | grep -m1 -v '^[[:space:]]*$')
      esc=$(printf '%s' "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
      echo "<li><time datetime=\"$ts\">${ts:0:10} ${ts:11:5}</time><p>$esc</p></li>"
    done
    echo '</ul><p class="more"><a href="thoughts/">更多 →</a></p></section>'
  } >> "$index"
fi

render "$index" "$OUT" "" -V index=1 --metadata title="$SITE_TITLE"
rm -f "$index"

# ---------- 独立页面(如 about) ----------
for f in pages/*.md; do
  [ -e "$f" ] || continue
  title=$(meta "$f" title); [ -n "$title" ] || title=$(basename "$f" .md)
  extra=()
  while IFS= read -r a; do [ -n "$a" ] && extra+=("$a"); done < <(source_args "$f")
  render "$f" "$OUT/$(slug_of "$f")" "../" --metadata title="$title" ${extra[@]+"${extra[@]}"}
done

# 心轨时间线页:所有想法按时间倒序拼成一篇渲染
if [ -n "$thoughts_rows" ]; then
  tl=$(mktemp)
  {
    echo '::: {.timeline}'
    while IFS='|' read -r ts f; do
      [ -n "$ts" ] || continue
      echo
      echo "## ${ts:0:10} · ${ts:11:5}"
      echo
      awk 'NR==1&&/^---[[:space:]]*$/{infm=1;next} infm&&/^---[[:space:]]*$/{infm=0;next} !infm{print}' "$f"
    done < <(printf '%s' "$thoughts_rows" | sort -r)
    echo
    echo ':::'
  } > "$tl"
  render "$tl" "$OUT/thoughts" "../" -V timeline=1 --metadata title="心轨"
  rm -f "$tl"
fi

cp style.css site.js "$OUT/"
[ -d static ] && cp -r static/. "$OUT/" && rm -f "$OUT/.gitkeep"

# ---------- 填入页面体积等统计 ----------
shared=$(( $(wc -c < "$OUT/style.css") + $(wc -c < "$OUT/site.js") ))
while IFS= read -r page; do
  imgbytes=0; imgs=0
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    imgs=$((imgs + 1))
    name=$(basename "${src%%\?*}"); name=$(printf '%b' "${name//%/\\x}")
    [ -f "$OUT/img/$name" ] && imgbytes=$((imgbytes + $(wc -c < "$OUT/img/$name")))
  done < <(grep -o '<img [^>]*src="[^"]*"' "$page" | sed 's/.*src="//; s/"$//' | grep -v '^https\?:' || true)
  ext=$( (grep -oE '<(img|script|link)[^>]*(src|href)="https?://' "$page" || true) | wc -l)
  bytes=$(( $(wc -c < "$page") - 10 + 3 + shared + imgbytes ))
  kb=$(awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1024}')
  reqs=$((3 + imgs))
  if [ "$ext" -eq 0 ]; then extlabel="无外部资源"; else extlabel="外部资源 $ext 个"; fi
  perl -pi -e "s/\@\@WEIGHT\@\@/$kb/g; s/\@\@REQS\@\@/$reqs/g; s/\@\@EXT\@\@/$extlabel/g" "$page"
done < <(find "$OUT" -name index.html)

echo "构建完成:$OUT/"
