import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createHead } from '@unhead/vue'
import router from './router'
import App from './App.vue'

const app = createApp(App)
const head = createHead()
app.use(createPinia())
app.use(router)
app.use(head)
app.mount('#app')
