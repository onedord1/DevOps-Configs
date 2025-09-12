import './assets/main.scss'
import './otel'
import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import Toast from 'vue-toastification'
import { toastOptions } from './plugins/toast'

/**
 * Please describe the following code block ...
 */
const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(vuetify)
app.use(Toast, toastOptions)

app.mount('#app')
