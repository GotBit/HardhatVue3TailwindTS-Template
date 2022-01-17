import { createWebHistory, createRouter } from 'vue-router'

import home from '/src/views/home.vue'
import login from '/src/views/login.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: home,
  },
  {
    path: '/login',
    name: 'Login',
    component: login,
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
