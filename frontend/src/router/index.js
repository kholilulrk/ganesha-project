import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Auth from '../views/Auth.vue'
import Dashboard from '../views/Dashboard.vue'
import Profile from '../views/Profile.vue'
import Pekerjaan from '../views/Pekerjaan.vue'
import Permissions from '../views/Permissions.vue'
import KelengkapanDokumen from '../views/KelengkapanDokumen.vue'
import PekerjaanShared from '../views/PekerjaanShared.vue'
import MonitoringAktifSurat from '../views/MonitoringAktifSurat.vue'
import Dokumen from '../views/Dokumen.vue'
import Pengguna from '../views/Pengguna.vue'
import Todo from '../views/Todo.vue'
import Kalender from '../views/Kalender.vue'
import KalkulasiSph from '../views/KalkulasiSph.vue'
import SphForm from '../views/SphForm.vue'
import SphDetail from '../views/SphDetail.vue'
import ActivityLog from '../views/ActivityLog.vue'
import Vendor from '../views/Vendor.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/auth', name: 'Auth', component: Auth, meta: { guest: true } },
  { path: '/dashboard', name: 'Dashboard', component: Dashboard, meta: { requiresAuth: true } },
  { path: '/profile', name: 'Profile', component: Profile, meta: { requiresAuth: true } },
  { path: '/pekerjaan', name: 'Pekerjaan', component: Pekerjaan, meta: { requiresAuth: true } },
  { path: '/permissions', name: 'Permissions', component: Permissions, meta: { requiresAuth: true } },
  { path: '/kelengkapan-dokumen', name: 'KelengkapanDokumen', component: KelengkapanDokumen, meta: { requiresAuth: true } },
  { path: '/monitoring-surat', name: 'MonitoringAktifSurat', component: MonitoringAktifSurat, meta: { requiresAuth: true } },
  { path: '/dokumen', name: 'Dokumen', component: Dokumen, meta: { requiresAuth: true } },
  { path: '/pengguna', name: 'Pengguna', component: Pengguna, meta: { requiresAuth: true } },
  { path: '/todo', name: 'Todo', component: Todo, meta: { requiresAuth: true } },
  { path: '/kalender', name: 'Kalender', component: Kalender, meta: { requiresAuth: true } },
  { path: '/pekerjaan/shared/:token', name: 'PekerjaanShared', component: PekerjaanShared, meta: { public: true } },
  { path: '/sph', name: 'KalkulasiSph', component: KalkulasiSph, meta: { requiresAuth: true } },
  { path: '/sph/form/:jenis', name: 'SphForm', component: SphForm, meta: { requiresAuth: true } },
  { path: '/sph/detail/:id', name: 'SphDetail', component: SphDetail, meta: { requiresAuth: true } },
  { path: '/activity-log', name: 'ActivityLog', component: ActivityLog, meta: { requiresAuth: true } },
  { path: '/vendor', name: 'Vendor', component: Vendor, meta: { requiresAuth: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const roleRestricted = (path) => {
  if (path.startsWith('/permissions') || path.startsWith('/pengguna') || path.startsWith('/activity-log')) {
    return ['Super Admin']
  }
  if (path.startsWith('/kelengkapan-dokumen') || path.startsWith('/monitoring-surat') || path.startsWith('/sph') || path.startsWith('/vendor')) {
    return ['Super Admin', 'Administrasi']
  }
  return null
}

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (to.meta.requiresAuth && !token) {
    next('/auth')
  } else if (to.meta.guest && token) {
    next('/dashboard')
  } else if (token && to.meta.requiresAuth) {
    const user = JSON.parse(localStorage.getItem('user') || 'null')
    const allowed = roleRestricted(to.path)
    if (allowed && !allowed.includes(user?.role)) {
      next('/dashboard')
    } else {
      next()
    }
  } else {
    next()
  }
})

export default router
