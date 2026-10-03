# 极简博客

Markdown + pandoc + 一个 shell 脚本,发布到 GitHub Pages。

- 写文章:在 `posts/` 新建 `xxx.md`(`draft: true` 为草稿)。`title` 默认取文件名,`date` 默认取第一次提交的日期
- 独立页面:放在 `pages/`
- 站名与简介:改 `site.conf`
- 样式:改 `style.css`(强调色是顶部的 `--accent`)
- 构建:`./build.sh`,输出到 `public/`,依赖 pandoc(Arch:`pacman -S pandoc`)
- 自定义域名:把 `CNAME` 文件放进 `static/`,内容是你的域名

部署:仓库 Settings → Pages → Source 选 "GitHub Actions",推送到 `main` 即自动发布。

## 用 Obsidian 写作

把这个仓库作为**独立的 vault** 打开(不要放私人笔记,仓库是公开的)。

- 图片放 `static/img/`,Obsidian 里把"附件默认存放路径"设成它
- 支持 `![[图.png]]`、`[[双链]]`、`> [!note]` 提示框、`==高亮==`、`%%注释%%`
- 不支持:笔记内嵌 `![[笔记]]`(降级为链接)、公式、Mermaid
- 用 Obsidian Git 插件提交并推送到 `main`;`.obsidian/` 已在 `.gitignore` 中
- 示例见 `posts/obsidian.md`

## 构建信息

页脚的提交号、日期、pandoc 版本和页面体积都是构建时算出来的。源文件与修改历史链接指向 `site.conf` 里的 `REPO_URL`(仓库改名后记得同步)。
