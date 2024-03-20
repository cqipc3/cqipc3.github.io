import Theme from 'vitepress/theme'
import BrowserInfo from '../components/BrowserInfo.vue'
import './style/var.css'
export default {
  ...Theme,
  enhanceApp({ app }) {
    app.component('BrowserInfo', BrowserInfo)
  }
}
