<template>
  <div class="sidebar" :class="{ collapsed }">
    <div class="sidebar-header">
      <div class="logo-small">G</div>
      <span v-if="!collapsed" class="brand-name">Ganesha</span>
      <button class="toggle-btn" @click="$emit('toggle')">
        <span class="arrow" :class="{ rotated: collapsed }">◀</span>
      </button>
    </div>
    <div class="user-info" v-if="!collapsed && user">
      <img v-if="user.photo" class="avatar-img" :src="user.photo" alt="avatar" />
      <div v-else class="avatar">{{ user.name.charAt(0) }}</div>
      <div class="user-detail">
        <span class="user-name">{{ user.name }}</span>
        <span class="user-role">{{ user.role }}</span>
      </div>
    </div>
    <nav class="sidebar-nav">
      <router-link to="/dashboard" class="nav-item" active-class="active">
        <span class="nav-icon">📊</span>
        <span v-if="!collapsed">Dashboard</span>
      </router-link>
      <div v-if="isLimitedRole" class="nav-item nav-parent" :class="{ active: pekerjaanOpen }" @click="pekerjaanOpen = !pekerjaanOpen">
        <span class="nav-icon">📋</span>
        <span v-if="!collapsed">Pekerjaan</span>
        <span v-if="!collapsed && hasUncompleted" class="red-dot" />
        <span v-if="!collapsed" class="arrow" :class="{ rotated: pekerjaanOpen }">▶</span>
      </div>
      <template v-if="isLimitedRole && (!collapsed ? pekerjaanOpen : true)">
        <router-link to="/pekerjaan" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">📋</span>
          <span v-if="!collapsed">Data Pekerjaan</span>
          <span v-if="!collapsed && hasUncompleted" class="red-dot" />
        </router-link>
        <router-link to="/dokumen" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">📄</span>
          <span v-if="!collapsed">Upload Dokumen</span>
        </router-link>
      </template>
      <router-link to="/todo" class="nav-item" active-class="active">
        <span class="nav-icon">✅</span>
        <span v-if="!collapsed">To-do List</span>
      </router-link>
      <router-link to="/kalender" class="nav-item" active-class="active">
        <span class="nav-icon">📅</span>
        <span v-if="!collapsed">Kalender</span>
      </router-link>
      <div v-if="!isLimitedRole" class="nav-item nav-parent" :class="{ active: pekerjaanOpen }" @click="pekerjaanOpen = !pekerjaanOpen">
        <span class="nav-icon">📋</span>
        <span v-if="!collapsed">Pekerjaan</span>
        <span v-if="!collapsed" class="arrow" :class="{ rotated: pekerjaanOpen }">▶</span>
      </div>
      <template v-if="!isLimitedRole && (!collapsed ? pekerjaanOpen : true)">
        <router-link to="/pekerjaan" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">📋</span>
          <span v-if="!collapsed">Data Pekerjaan</span>
          <span v-if="!collapsed && hasUncompleted" class="red-dot" />
        </router-link>
        <router-link to="/kelengkapan-dokumen" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">📎</span>
          <span v-if="!collapsed">Kelengkapan Dokumen</span>
        </router-link>
        <router-link to="/sph" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">🧮</span>
          <span v-if="!collapsed">Kalkulasi SPH</span>
        </router-link>
        <router-link to="/dokumen" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">&#128203;</span>
          <span v-if="!collapsed">Upload Dokumen</span>
        </router-link>
      </template>
        <router-link v-if="!isLimitedRole" to="/absensi" class="nav-item" active-class="active">
          <span class="nav-icon">📋</span>
          <span v-if="!collapsed">Data Absensi</span>
        </router-link>
        <router-link v-if="!isLimitedRole" to="/pengumuman" class="nav-item" active-class="active">
          <span class="nav-icon">&#128240;</span>
          <span v-if="!collapsed">Pengumuman</span>
        </router-link>
        <router-link v-if="!isLimitedRole" to="/vendor" class="nav-item" active-class="active">
        <span class="nav-icon">&#127970;</span>
        <span v-if="!collapsed">Vendor</span>
      </router-link>
      <div v-if="!isLimitedRole" class="nav-item nav-parent" :class="{ active: monitoringOpen }" @click="monitoringOpen = !monitoringOpen">
        <span class="nav-icon">&#128200;</span>
        <span v-if="!collapsed">Monitoring</span>
        <span v-if="!collapsed" class="arrow" :class="{ rotated: monitoringOpen }">&#9654;</span>
      </div>
      <template v-if="!collapsed ? monitoringOpen : true">
        <router-link v-if="!isLimitedRole" to="/monitoring-surat" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">&#128196;</span>
          <span v-if="!collapsed">Aktif Surat</span>
        </router-link>
        <router-link v-if="user?.role === 'Super Admin'" to="/activity-log" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">&#128203;</span>
          <span v-if="!collapsed">Activity Log</span>
        </router-link>
      </template>
      <div class="nav-item nav-parent" :class="{ active: pengaturanOpen }" @click="pengaturanOpen = !pengaturanOpen">
        <span class="nav-icon">⚙️</span>
        <span v-if="!collapsed">Pengaturan</span>
        <span v-if="!collapsed" class="arrow" :class="{ rotated: pengaturanOpen }">▶</span>
      </div>
      <template v-if="!collapsed ? pengaturanOpen : true">
        <router-link to="/profile" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">👤</span>
          <span v-if="!collapsed">Profile</span>
        </router-link>
        <router-link v-if="user?.role === 'Super Admin'" to="/pengguna" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">👥</span>
          <span v-if="!collapsed">Pengguna</span>
        </router-link>
        <router-link v-if="user?.role === 'Super Admin'" to="/permissions" class="nav-item sub-item" active-class="active">
          <span class="nav-icon">🔐</span>
          <span v-if="!collapsed">Atur Akses</span>
        </router-link>
        <div class="nav-item sub-item theme-sub-item" @click="themeStore.toggle">
          <span class="nav-icon">{{ themeStore.theme === 'dark' ? '☀️' : '🌙' }}</span>
          <span v-if="!collapsed">{{ themeStore.theme === 'dark' ? 'Mode Terang' : 'Mode Gelap' }}</span>
        </div>
      </template>
      <div v-if="user?.role === 'Super Admin' && !collapsed" class="role-switch">
        <label class="role-label">Lihat sebagai:</label>
        <select class="role-select" :value="perms.previewRole || ''" @change="onPreviewChange">
          <option value="">Super Admin</option>
          <option value="Administrasi">Administrasi</option>
          <option value="Teknisi">Teknisi</option>
          <option value="Logistic">Logistic</option>
        </select>
      </div>
    </nav>
    <div class="sidebar-footer">
      <button class="nav-item logout-btn" @click="handleLogout">
        <span class="nav-icon">🚪</span>
        <span v-if="!collapsed">Keluar</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { usePermissionStore } from '../stores/permissions'
import { useRouter } from 'vue-router'
import { dashboardAPI } from '../api/dashboard'

defineProps({
  collapsed: Boolean,
})
defineEmits(['toggle'])

const auth = useAuthStore()
const themeStore = useThemeStore()
const perms = usePermissionStore()
const router = useRouter()

const stats = ref({
  uncompleted_teknisi: 0,
  uncompleted_logistic: 0,
})

const hasUncompleted = computed(() => {
  const role = user.value?.role
  if (role === 'Teknisi') return stats.value.uncompleted_teknisi > 0
  if (role === 'Logistic') return stats.value.uncompleted_logistic > 0
  return stats.value.uncompleted_teknisi > 0 || stats.value.uncompleted_logistic > 0
})

const user = computed(() => auth.user)
const isLimitedRole = computed(() => auth.user?.role === 'Teknisi' || auth.user?.role === 'Logistic')

const pekerjaanOpen = ref(true)
const monitoringOpen = ref(false)
const pengaturanOpen = ref(true)

onMounted(async () => {
  await fetchUncompletedCount()
})

async function fetchUncompletedCount() {
  try {
    const res = await dashboardAPI.getStats()
    stats.value.uncompleted_teknisi = res.data.uncompleted_teknisi || 0
    stats.value.uncompleted_logistic = res.data.uncompleted_logistic || 0
  } catch {
    // ignore
  }
}

function onPreviewChange(e) {
  perms.setPreview(e.target.value || null)
}

function handleLogout() {
  auth.logout()
  router.push('/auth')
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  width: 260px;
  background: var(--sidebar-bg);
  backdrop-filter: blur(20px);
  border-right: 1px solid var(--card-border-light);
  display: flex;
  flex-direction: column;
  z-index: 200;
  transition: width 0.3s ease, background 0.3s ease;
  overflow: hidden;
  min-height: 0;
}
.sidebar.collapsed {
  width: 64px;
}
.sidebar.collapsed .nav-item {
  padding: 12px;
  justify-content: center;
}
.sidebar.collapsed .nav-item.sub-item {
  padding-left: 12px;
}
.sidebar.collapsed .nav-icon {
  min-width: unset;
  font-size: 20px;
}
.sidebar-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px 16px;
  border-bottom: 1px solid var(--card-border-light);
}
.sidebar.collapsed .sidebar-header {
  justify-content: center;
  padding: 20px 0;
}
.sidebar.collapsed .logo-small {
  display: none;
}
.sidebar.collapsed .toggle-btn {
  margin-left: 0;
}
.logo-small {
  width: 36px;
  height: 36px;
  min-width: 36px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  font-weight: 700;
  color: #fff;
}
.brand-name {
  color: var(--text-primary);
  font-size: 16px;
  font-weight: 600;
  white-space: nowrap;
}
.toggle-btn {
  margin-left: auto;
  background: var(--hover-bg);
  border: none;
  color: var(--text-muted);
  width: 28px;
  height: 28px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}
.toggle-btn:hover {
  background: var(--hover-bg-strong);
}
.arrow {
  display: inline-block;
  transition: transform 0.3s;
  font-size: 10px;
}
.arrow.rotated {
  transform: rotate(180deg);
}
.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  border-bottom: 1px solid var(--card-border-light);
}
.user-info .avatar,
.user-info .avatar-img {
  width: 40px;
  height: 40px;
  min-width: 40px;
  border-radius: 50%;
}
.user-info .avatar-img {
  object-fit: cover;
}
.user-info .avatar {
  background: linear-gradient(135deg, #667eea, #764ba2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}
.user-detail {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.user-name {
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 600;
}
.user-role {
  color: var(--text-muted);
  font-size: 11px;
}
.sidebar-nav {
  flex: 1;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow-y: auto;
  min-height: 0;
}
.nav-section {
  padding: 16px 12px 4px;
}
.nav-section-label {
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.8px;
}
.nav-item.sub-item {
  padding-left: 44px;
}
.nav-item.sub-item .nav-icon {
  min-width: 20px;
  font-size: 16px;
}
.nav-parent {
  cursor: pointer;
}
.nav-parent .arrow {
  margin-left: auto;
  font-size: 8px;
  transition: transform 0.2s;
  color: var(--text-muted);
}
.nav-parent .arrow.rotated {
  transform: rotate(90deg);
}
.sidebar.collapsed .nav-parent .arrow {
  display: none;
}
.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border-radius: 10px;
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
  border: none;
  background: transparent;
  cursor: pointer;
  width: 100%;
  font-family: 'Inter', sans-serif;
  overflow: hidden;
}
.nav-item span:not(.nav-icon):not(.arrow) {
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 0;
}
.nav-item:hover {
  background: var(--hover-bg);
  color: var(--text-primary);
}
.nav-item.active {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}
.nav-icon {
  font-size: 18px;
  min-width: 24px;
  text-align: center;
}
.badge-count {
  margin-left: auto;
  background: #ef4444;
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.red-dot {
  margin-left: auto;
  width: 8px;
  height: 8px;
  min-width: 8px;
  border-radius: 50%;
  background: #ef4444;
}
.role-switch {
  padding: 4px 12px 8px;
}
.sidebar.collapsed .role-switch {
  display: none;
}
.role-label {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 4px;
  font-weight: 500;
}
.role-select {
  width: 100%;
  padding: 6px 8px;
  border-radius: 6px;
  border: 1px solid var(--card-border-light);
  background: var(--card-bg);
  color: var(--text-primary);
  font-size: 12px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  outline: none;
}
.role-select:focus {
  border-color: #667eea;
}
.theme-sub-item {
  cursor: pointer;
}
.logout-btn {
  margin-top: auto;
}
.sidebar-footer {
  padding: 8px;
  border-top: 1px solid var(--card-border-light);
}
</style>
