# 极简博客

Markdown + pandoc + 一个 shell 脚本,发布到 GitHub Pages。

- 写文章:在 `posts/` 新建 `xxx.md`,头部写 `title` 和 `date`(`draft: true` 为草稿)
- 独立页面:放在 `pages/`
- 站名与简介:改 `site.conf`
- 样式:改 `style.css`(强调色是顶部的 `--accent`)
- 构建:`./build.sh`,输出到 `public/`,依赖 pandoc(Arch:`pacman -S pandoc`)
- 自定义域名:把 `CNAME` 文件放进 `static/`,内容是你的域名

部署:仓库 Settings → Pages → Source 选 "GitHub Actions",推送到 `main` 即自动发布。
