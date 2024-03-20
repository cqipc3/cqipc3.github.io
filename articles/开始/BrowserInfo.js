// 导入 UAParser.js
const UAParser = require('ua-parser-js');

// 创建一个 UAParser 实例
const parser = new UAParser();

// 获取浏览器信息
const browserInfo = parser.getBrowser();
console.log(browserInfo);

export default{
    browserInfo:browserInfo
}
