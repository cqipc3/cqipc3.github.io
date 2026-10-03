/* 深浅色切换。没有脚本时页面照常可读,跟随系统设置。 */
(function () {
  "use strict";

  var root = document.documentElement;
  var btn = document.querySelector(".theme");
  if (!btn) return;

  var mq = matchMedia("(prefers-color-scheme: dark)");
  function isDark() { return root.dataset.theme ? root.dataset.theme === "dark" : mq.matches; }
  function sync() { btn.setAttribute("aria-checked", isDark()); }

  btn.hidden = false;
  sync();
  btn.addEventListener("click", function () {
    var next = isDark() ? "light" : "dark";
    root.dataset.theme = next;
    try { localStorage.setItem("theme", next); } catch (e) {}
    sync();
  });
  if (mq.addEventListener) mq.addEventListener("change", sync);
})();
