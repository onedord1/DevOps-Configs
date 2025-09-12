import './assets/main.scss'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './otel'
import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import Toast from 'vue-toastification'
import { toastOptions } from './plugins/toast'

import QuickopsSplash from '@/assets/animation/QuickOps_Splash.json'
import lottie from 'lottie-web'

/**
 * Get the splash element
 */
const splashElem = document.getElementById('splash')

/**
 * Get the app dom element
 */
const appElem = document.getElementById('app')

/**
 * Key in which splash screen showing flag is stored in local storage
 */
const SPLASH_KEY = 'lastSplashShown'
/**
 * Interval after which splash screen will be shown again
 */
const SPLASH_INTERVAL = 4 * 60 * 60 * 1000 // 4 hours
/**
 * Get current date
 */
const now = Date.now()
/**
 * Get the last known time when the splash screen as shown (if any)
 */
const lastShown = parseInt(localStorage.getItem(SPLASH_KEY) ?? '', 10)

/**
 * Logic to show splash screen
 * If lastShown value is not present or 24 hours have passed since last shown and user is NOT visiting oauth route
 */
const shouldShowSplash =
  (isNaN(lastShown) || now - lastShown > SPLASH_INTERVAL) &&
  !window.location.pathname.toLowerCase().startsWith('/oauth')

/**
 * If splash screen is shown
 */
if (shouldShowSplash) {
  /**
   * Hide the app element
   */
  if (appElem?.style) {
    appElem.style.display = 'none'
  }
  /**
   * Show splash screen
   */
  if (splashElem) {
    lottie.loadAnimation({
      container: splashElem,
      renderer: 'svg',
      loop: false,
      autoplay: true,
      animationData: QuickopsSplash
    })
  }

  // set current time after splash shown
  localStorage.setItem(SPLASH_KEY, now.toString())
} else {
  /**
   * Otherwise, hide splash screen
   */
  if (splashElem?.style) {
    splashElem.style.display = 'none'
  }

  /**
   * And show app element
   */
  if (appElem?.style) {
    appElem.style.display = 'block'
  }
}

/**
 * Initialize vue app
 */
const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(vuetify)
app.use(Toast, toastOptions)

app.mount('#app')

/**
 * Add timer to show app element after splash is completed
 */
if (shouldShowSplash) {
  setTimeout(() => {
    /**
     * Hide splash
     */
    if (splashElem?.style) {
      splashElem.style.display = 'none'
    }
    /**
     * Show app
     */
    if (appElem?.style) {
      appElem.style.display = 'block'
    }
  }, 5000)
}
