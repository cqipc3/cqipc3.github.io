<template>
    <div>{{ browserInfo.name }}浏览器</div>
  </template>
  
  <script>
  import UAParser from 'ua-parser-js';
  
  export default {
    data() {
      const parser = new UAParser();
      return {
        browserInfo: parser.getBrowser(),
      };
    },
  };
  </script>

 <style scoped>
 div{
  color: red;
 }
 </style>
  