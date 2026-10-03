---
title: 你好，世界
summary: 新博客的第一篇文章,也是一次 Obsidian 发布流程的完整测试——图片、双链、提示框、高亮、注释都在里面。
---

新博客在根域名 [cqipc3.github.io](https://cqipc3.github.io/) 正式上线了。这篇文章是我在 Obsidian 里写好、`git push` 之后自动构建发布的,==从推送到上线大约只要半分钟==。%%这一整句是注释,只有编辑器里能看到,网站上不会出现。%%

## 图片

下面这张图是测试用的嵌入图片,放在 `static/img/` 里,用的是 Obsidian 的 `![[文件名|说明]]` 写法:

![[hello-test.svg|发布流程示意]]

## 双链

链到站内文章:[[obsidian|用 Obsidian 写作]]、[[how-to-write]]。链到不存在的笔记时,会显示成带虚线的文字,提醒我还没写:[[VitePress 旧站的迁移记录]]。

## 提示框

> [!tip] 三步发布
> 在 `posts/` 新建 Markdown → 用 Obsidian Git 插件提交推送 → GitHub Actions 自动构建上线。

> [!warning]
> 没写标题的提示框会用类型名当标题,比如这个会显示"注意"。

## 基础语法

列表和代码块也顺带验一下:

1. 在 Obsidian 里写 `posts/xxx.md`
2. 推送到 `main` 分支
3. 等 Actions 跑完,刷新页面

```shell
git add posts/hello-world.md static/img/hello-test.svg
git commit -m "发布第一篇文章"
git push
```

接下来我会把 [[VitePress 旧站的迁移记录]] 补上——如果你在看这篇文章,说明整条链路都通了。
