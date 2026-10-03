-- pandoc Lua 过滤器:让 Obsidian 的图片路径、双链、提示框在站内正常工作。
-- 由 build.sh 通过环境变量传入:
--   BLOG_ROOT   当前页面到站点根目录的相对路径(如 "../")
--   BLOG_SLUGS  每行 "文件名<TAB>网址目录名",列出所有文章和页面
local root = os.getenv("BLOG_ROOT") or ""

local slugs = {}
for line in (os.getenv("BLOG_SLUGS") or ""):gmatch("[^\n]+") do
  local stem, slug = line:match("^(.-)\t(.+)$")
  if stem then slugs[stem:lower()] = slug end
end

local function decode(s)
  return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end
local function encode(s)
  return (s:gsub("[^%w%-%._~/]", function(c)
    -- 保留 UTF-8 多字节字符,让中文文件名在地址里保持可读
    if c:byte() >= 128 then return c end
    return string.format("%%%02X", c:byte())
  end))
end
local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

-- 图片:相对路径一律指向 static/img/ 里的同名文件
function Image(el)
  local src = el.src
  if src:match("^%a[%w+.-]*:") or src:match("^/") or src:match("^#") then return nil end
  local name = decode(src):match("([^/]+)$")
  if name and exists("static/img/" .. name) then
    el.src = root .. "img/" .. encode(name)
  else
    io.stderr:write("警告:找不到图片 static/img/" .. tostring(name) .. "\n")
  end
  el.attributes.loading = "lazy"
  return el
end

-- 双链:[[文章]] / [[文章|别名]] / [[文章#小标题]]
function Link(el)
  if el.title ~= "wikilink" then return nil end
  local target, anchor = decode(el.target):match("^([^#]*)#?(.*)$")
  local slug = slugs[target:lower()]
  if not slug then
    io.stderr:write("警告:双链指向的笔记不存在:" .. target .. "\n")
    return pandoc.Span(el.content, pandoc.Attr("", { "wikilink-missing" }))
  end
  local href = root .. encode(slug) .. "/"
  if anchor ~= "" then
    -- 模仿 pandoc 的标题 ID 生成规则:小写、空格换成 -、删除标点符号
    local out = {}
    for _, cp in utf8.codes(anchor:lower()) do
      local c = utf8.char(cp)
      if c:match("%s") then
        out[#out+1] = "-"
      elseif not ((cp < 128 and c:match("%p") and not c:match("[-_.]"))
               or (cp >= 0x3000 and cp <= 0x303F)
               or (cp >= 0xFF00 and cp <= 0xFF20)) then
        out[#out+1] = c
      end
    end
    href = href .. "#" .. table.concat(out)
  end
  return pandoc.Link(el.content, href)
end

-- 提示框:> [!note] 标题
local labels = {
  note = "笔记", info = "信息", tip = "提示", important = "重要", warning = "注意",
  caution = "注意", danger = "危险", bug = "问题", example = "示例", quote = "引用",
  abstract = "摘要", summary = "摘要", todo = "待办", success = "完成", failure = "失败",
  question = "疑问", hint = "提示", check = "完成", done = "完成", error = "错误",
}
function BlockQuote(el)
  local first = el.content[1]
  if not first or (first.t ~= "Para" and first.t ~= "Plain") then return nil end
  local head = first.content[1]
  if not head or head.t ~= "Str" then return nil end
  local kind = head.text:match("^%[!([%w_-]+)%][%+%-]?$")
  if not kind then return nil end
  kind = kind:lower()

  local i, title, body = 2, pandoc.Inlines({}), pandoc.Inlines({})
  while first.content[i] and first.content[i].t == "Space" do i = i + 1 end
  while first.content[i] and first.content[i].t ~= "SoftBreak" and first.content[i].t ~= "LineBreak" do
    title:insert(first.content[i]); i = i + 1
  end
  i = i + 1
  while first.content[i] do body:insert(first.content[i]); i = i + 1 end

  if #title == 0 then title = pandoc.Inlines({ pandoc.Str(labels[kind] or kind) }) end
  local blocks = { pandoc.Div({ pandoc.Plain(title) }, pandoc.Attr("", { "callout-title" })) }
  if #body > 0 then blocks[#blocks + 1] = pandoc.Para(body) end
  for k = 2, #el.content do blocks[#blocks + 1] = el.content[k] end
  return pandoc.Div(blocks, pandoc.Attr("", { "callout", "callout-" .. kind }))
end
