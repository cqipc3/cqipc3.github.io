/* 深浅色切换、vim 式按键、: 命令行。无依赖;没有脚本时页面照常可读。 */
(function () {
  "use strict";

  var root = document.documentElement;
  var base = root.dataset.root || "";
  var $ = function (s) { return document.querySelector(s); };

  /* ---------- 主题 ---------- */
  var btn = $(".theme");
  var mq = matchMedia("(prefers-color-scheme: dark)");
  function isDark() { return root.dataset.theme ? root.dataset.theme === "dark" : mq.matches; }
  function syncBtn() { if (btn) btn.setAttribute("aria-checked", isDark()); }
  function setTheme(t) {
    root.dataset.theme = t;
    try { localStorage.setItem("theme", t); } catch (e) {}
    syncBtn();
  }
  if (btn) {
    btn.hidden = false;
    syncBtn();
    btn.addEventListener("click", function () { setTheme(isDark() ? "light" : "dark"); });
  }
  if (mq.addEventListener) mq.addEventListener("change", syncBtn);

  /* ---------- 页面跳转与滚动 ---------- */
  function go(path) { location.href = base + path; }
  function goLink(sel) { var a = $(sel); if (a) location.href = a.href; return !!a; }
  function scrollBy(dy) { window.scrollBy({ top: dy, behavior: "auto" }); }
  function toTop() { window.scrollTo({ top: 0 }); }
  function toBottom() { window.scrollTo({ top: document.documentElement.scrollHeight }); }

  /* ---------- 首页列表:j/k 选择,Enter 打开 ---------- */
  var items = [].slice.call(document.querySelectorAll("section.year li"));
  var sel = -1;
  function select(i) {
    if (!items.length) return;
    i = Math.max(0, Math.min(items.length - 1, i));
    if (sel >= 0) items[sel].classList.remove("sel");
    sel = i;
    items[sel].classList.add("sel");
    items[sel].scrollIntoView({ block: "nearest" });
  }
  function openSelected() {
    if (sel < 0) return false;
    var a = items[sel].querySelector("a");
    if (a) location.href = a.href;
    return true;
  }

  /* ---------- 文章清单(用到时才加载) ---------- */
  var posts = null;
  function loadPosts() {
    if (posts) return Promise.resolve(posts);
    return fetch(base + "posts.json").then(function (r) { return r.json(); })
      .then(function (j) { posts = j; return j; });
  }
  function match(list, q) {
    q = q.trim().toLowerCase();
    if (!q) return list.slice();
    var exact = list.filter(function (p) { return p.url.replace(/\/$/, "").toLowerCase() === q; });
    if (exact.length) return exact;
    return list.filter(function (p) {
      return (p.title + " " + p.url + " " + p.summary).toLowerCase().indexOf(q) !== -1;
    });
  }

  /* ---------- 命令行 ---------- */
  var bar, out, input, mode = ":", history = [], hpos = 0;

  function buildBar() {
    if (bar) return;
    bar = document.createElement("div");
    bar.id = "cmd";
    bar.hidden = true;
    out = document.createElement("div");
    out.className = "cmd-out";
    out.hidden = true;
    var form = document.createElement("form");
    input = document.createElement("input");
    input.type = "text";
    input.autocomplete = "off";
    input.spellcheck = false;
    input.setAttribute("aria-label", "命令行");
    form.appendChild(input);
    bar.appendChild(out);
    bar.appendChild(form);
    document.body.appendChild(bar);

    form.addEventListener("submit", function (e) { e.preventDefault(); run(input.value); });
    input.addEventListener("input", function () {
      var v = input.value;
      if (v === "") return closeBar();
      if (v[0] !== ":" && v[0] !== "/") input.value = v = ":" + v;
      mode = v[0];
      preview(v);
    });
    input.addEventListener("keydown", function (e) {
      if (e.key === "Escape") { e.preventDefault(); closeBar(); }
      else if (e.key === "ArrowUp") { e.preventDefault(); recall(-1); }
      else if (e.key === "ArrowDown") { e.preventDefault(); recall(1); }
      else if (e.key === "Tab") { e.preventDefault(); complete(); }
    });
  }

  function openBar(prefix) {
    buildBar();
    closeHelp();
    mode = prefix;
    bar.hidden = false;
    input.value = prefix;
    hideOut();
    input.focus();
  }
  function closeBar() {
    if (!bar) return;
    bar.hidden = true;
    hideOut();
    input.blur();
  }
  function hideOut() { if (out) { out.hidden = true; out.textContent = ""; } }

  /* 在输出区写几行;每行可以是文字,或 {text, href} */
  function show(lines) {
    out.textContent = "";
    lines.forEach(function (l) {
      var row = document.createElement("div");
      if (typeof l === "string") row.textContent = l;
      else if (Array.isArray(l)) {
        row.className = "kv";
        l.forEach(function (t) { var sp = document.createElement("span"); sp.textContent = t; row.appendChild(sp); });
      } else {
        var a = document.createElement("a");
        a.href = l.href;
        a.textContent = l.text;
        row.appendChild(a);
      }
      out.appendChild(row);
    });
    out.hidden = !lines.length;
  }
  function postLine(p) { return { text: p.date + "  " + p.title, href: base + p.url }; }

  function recall(d) {
    if (!history.length) return;
    hpos = Math.max(0, Math.min(history.length, hpos + d));
    input.value = hpos === history.length ? ":" : history[hpos];
  }

  var commands = {
    help: function () {
      show([
        ["help", "显示这份说明"],
        ["ls", "列出所有文章"],
        ["open <关键词>", "打开文章;有多篇匹配时列出(别名 o)"],
        ["/关键词", "搜索,回车跳到第一个匹配"],
        ["random", "随机一篇"],
        ["next / prev", "更新的一篇 / 更早的一篇"],
        ["home about colophon", "站内页面(q 回首页)"],
        ["source", "查看本页源文件"],
        ["theme [dark|light]", "切换主题"]
      ]);
    },
    ls: function () {
      return loadPosts().then(function (l) { show(l.map(postLine)); });
    },
    open: function (arg) {
      return loadPosts().then(function (l) {
        var m = match(l, arg);
        if (!arg.trim()) return show(["用法:open <关键词>"]);
        if (!m.length) return show(["没有匹配:" + arg]);
        if (m.length === 1) return (location.href = base + m[0].url);
        show(m.map(postLine));
      });
    },
    search: function (arg) {
      return loadPosts().then(function (l) {
        var m = match(l, arg);
        if (!arg.trim()) return closeBar();
        if (!m.length) return show(["没有匹配:" + arg]);
        location.href = base + m[0].url;
      });
    },
    random: function () {
      return loadPosts().then(function (l) {
        if (l.length) location.href = base + l[Math.floor(Math.random() * l.length)].url;
      });
    },
    next: function () { if (!goLink('a[rel="next"]')) show(["没有更新的文章了"]); },
    prev: function () { if (!goLink('a[rel="prev"]')) show(["没有更早的文章了"]); },
    home: function () { go(""); },
    about: function () { go("about/"); },
    colophon: function () { go("colophon/"); },
    source: function () { if (!goLink(".source-link")) show(["这个页面没有源文件链接"]); },
    theme: function (arg) {
      arg = arg.trim();
      if (arg === "dark" || arg === "light") setTheme(arg);
      else if (!arg) setTheme(isDark() ? "light" : "dark");
      else show(["用法:theme [dark|light]"]);
    }
  };
  commands.o = commands.open;
  commands.q = commands.home;

  function run(raw) {
    var v = raw.trim();
    if (v.length <= 1) return closeBar();
    history.push(raw);
    hpos = history.length;
    var cmd, arg;
    if (v[0] === "/") { cmd = "search"; arg = v.slice(1); }
    else {
      var s = v.slice(1).trim().split(/\s+/);
      cmd = s.shift();
      arg = s.join(" ");
    }
    if (!Object.prototype.hasOwnProperty.call(commands, cmd)) {
      show(["不是命令:" + cmd + "(输入 help 查看可用命令)"]);
      return;
    }
    Promise.resolve(commands[cmd](arg)).catch(function () {
      show(["无法加载文章列表"]);
    });
  }

  /* 输入时即时列出匹配的文章 */
  function preview(v) {
    var arg = null;
    if (v[0] === "/") arg = v.slice(1);
    else { var m = /^:(?:open|o)\s+(.*)$/.exec(v); if (m) arg = m[1]; }
    if (arg === null || !arg.trim()) return hideOut();
    loadPosts().then(function (l) {
      if (input.value !== v) return;
      var hits = match(l, arg).slice(0, 8);
      if (hits.length) show(hits.map(postLine)); else show(["没有匹配:" + arg]);
    }).catch(hideOut);
  }

  function complete() {
    var m = /^:(\w*)$/.exec(input.value);
    if (!m) return;
    var names = Object.keys(commands).filter(function (n) { return n.indexOf(m[1]) === 0 && n.length > 1; });
    if (names.length === 1) input.value = ":" + names[0] + " ";
    else if (names.length) show([names.join("   ")]);
  }

  /* ---------- 快捷键帮助 ---------- */
  var help;
  function toggleHelp() {
    if (help && !help.hidden) return closeHelp();
    if (!help) {
      help = document.createElement("div");
      help.id = "keys";
      help.setAttribute("role", "dialog");
      help.setAttribute("aria-label", "快捷键");
      help.innerHTML =
        "<div class=\"panel\"><h2>快捷键</h2><dl>" +
        "<dt>j k</dt><dd>下 / 上(首页:选择文章)</dd>" +
        "<dt>d u</dt><dd>向下 / 向上翻半页</dd>" +
        "<dt>gg G</dt><dd>到顶部 / 到底部</dd>" +
        "<dt>Enter</dt><dd>打开选中的文章</dd>" +
        "<dt>[ ]</dt><dd>更早 / 更新的一篇</dd>" +
        "<dt>gh ga gc</dt><dd>首页 / 关于 / colophon</dd>" +
        "<dt>t</dt><dd>切换深浅色</dd>" +
        "<dt>/</dt><dd>搜索文章</dd>" +
        "<dt>:</dt><dd>命令行(输入 help)</dd>" +
        "<dt>Esc</dt><dd>关闭</dd></dl></div>";
      help.addEventListener("click", closeHelp);
      document.body.appendChild(help);
    }
    closeBar();
    help.hidden = false;
  }
  function closeHelp() { if (help) help.hidden = true; }

  /* ---------- 按键 ---------- */
  var gPending = false, gTimer;
  document.addEventListener("keydown", function (e) {
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    var t = e.target;
    if (t && (t.tagName === "INPUT" || t.tagName === "TEXTAREA" || t.tagName === "SELECT" || t.isContentEditable)) return;
    var k = e.key, handled = true;

    if (k === "Escape") { closeHelp(); closeBar(); return; }

    if (gPending) {
      gPending = false; clearTimeout(gTimer);
      if (k === "g") toTop();
      else if (k === "h") go("");
      else if (k === "a") go("about/");
      else if (k === "c") go("colophon/");
      else handled = false;
      if (handled) e.preventDefault();
      return;
    }

    switch (k) {
      case "j": items.length ? select(sel + 1) : scrollBy(80); break;
      case "k": items.length ? select(sel < 0 ? 0 : sel - 1) : scrollBy(-80); break;
      case "d": scrollBy(innerHeight / 2); break;
      case "u": scrollBy(-innerHeight / 2); break;
      case "G": toBottom(); break;
      case "g": gPending = true; gTimer = setTimeout(function () { gPending = false; }, 700); break;
      case "Enter": handled = items.length ? openSelected() : false; break;
      case "[": handled = goLink('a[rel="prev"]'); break;
      case "]": handled = goLink('a[rel="next"]'); break;
      case "t": if (e.repeat) return; setTheme(isDark() ? "light" : "dark"); break;
      case "?": if (e.repeat) return; toggleHelp(); break;
      case ":": if (e.repeat) return; openBar(":"); break;
      case "/": if (e.repeat) return; openBar("/"); break;
      default: handled = false;
    }
    if (handled) e.preventDefault();
  });
})();
