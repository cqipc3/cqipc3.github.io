export default {
  title: "CQIPC-IS-WIKI", //站点标题
  description: "一个vue3组件库", //mate标签description，多用于搜索引擎抓取摘要
  lastUpdated: true,
  themeConfig: {
    lastUpdatedText: "最后更新", 
    siteTitle: "CQIPC-IS-WIKI",
    logo: "/construction.png",
    head: [
      ['link', { rel: 'icon', href: '/favicon.ico' }] //浏览器标签icon
    ],
    socialLinks: [
      //{ icon: "github", link: "https://github.com/CQIPC3" },
      { icon: "twitter", link: "https://crunchxx.cn" },
      // You can also add custom icons by passing SVG as string:
      {
        icon: {
          svg: '<svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Dribbble</title><path d="M12...6.38z"/></svg>',
        },
        link: "...",
      },
    ],
    footer: {
      message: '重庆工业职业技术学院',
      copyright: 'Copyright © 2024',  },
      
    nav: [
      { text: "首页", link: "/" },
      {
        text: "导航",
        items: [
          {
            items: [
              { text: "介绍", link: "articles/就开始吧/介绍" },
              // { text: "通用", link: "/item-A2" },
            ],
          },
          {
            items: [
             // { text: "B1", link: "/item-B1" },
              //{ text: "B2", link: "/item-B2" },
            ],
          },
        ],
      },
    ],
    sidebar: {
      "/articles/": [
        {
          text: "CQIPC-IS-WIKI",
          collapsible: true,
          
          items: [
            { text: "介绍", link: "/articles/就开始吧/介绍.md" },
            { text: "使用指南",link: "/articles/就开始吧/使用指南.md",},
             { text: "更新日志", link: "/articles/就开始吧/更新日志.md" },
          ],
        },
        {
          text: "杂谈或者通用",
          collapsible: true,
          collapsed: true,
          items: [
            {
              text: "初始",
              link: "/articles/Reverse/1.md",
            },
          ],
        },
     
        {
          text: "Pwn - 未知领域",
          collapsible: true,
          collapsed: true,
          items: [
            {
              text: "开篇",
              link: "/articles/Pwn/1.md",
            },
          ],
        },
        {
          text: "Web - 未知领域 ",
          collapsible: true,
          collapsed: true,
          items: [
            {
              text: "冲吧",
              link: "/articles/Web/1.md",
            },
          ],
        },
        {
          text: "Network - 网络管理",
          collapsible: true,
          collapsed: true,
          items: [
            {
              text: "起始",
              link: "/articles/网络管理/1.md",
            },
          ],
        },
        {
          text: "Reverse - 逆向工程",
          collapsible: true,
          collapsed: true,
          items: [
            {
              text: "初始",
              link: "/articles/Reverse/1.md",
            },
          ],
        },
   
      ],
    },
  },
};

