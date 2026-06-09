<template>
  <div id="app">
    <Sidebar v-if="isAuthenticated" :collapsed="sidebarCollapsed" @toggle="sidebarCollapsed = !sidebarCollapsed" />
    <div class="main-content" :class="{ shifted: isAuthenticated, collapsed: sidebarCollapsed }">
      <router-view />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from './stores/auth'
import { useThemeStore } from './stores/theme'
import { usePermissionStore } from './stores/permissions'
import Sidebar from './components/Sidebar.vue'

const route = useRoute()
const auth = useAuthStore()
const perms = usePermissionStore()
useThemeStore()
const isAuthenticated = computed(() => auth.isAuthenticated && route.name !== 'PekerjaanShared')
const sidebarCollapsed = ref(false)

watch(isAuthenticated, (val) => {
  if (val) perms.load()
  else perms.reset()
}, { immediate: true })
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root,
[data-theme="dark"] {
  --bg-primary: #0f0c29;
  --bg-secondary: #302b63;
  --bg-tertiary: #24243e;
  --bg-gradient: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
  --text-primary: #fff;
  --text-secondary: rgba(255, 255, 255, 0.6);
  --text-muted: rgba(255, 255, 255, 0.4);
  --text-dim: rgba(255, 255, 255, 0.3);
  --card-bg: rgba(255, 255, 255, 0.05);
  --card-border: rgba(255, 255, 255, 0.1);
  --card-border-light: rgba(255, 255, 255, 0.06);
  --input-bg: rgba(255, 255, 255, 0.06);
  --input-border: rgba(255, 255, 255, 0.1);
  --hover-bg: rgba(255, 255, 255, 0.06);
  --hover-bg-strong: rgba(255, 255, 255, 0.12);
  --modal-bg: rgba(20, 16, 48, 0.98);
  --modal-overlay: rgba(0, 0, 0, 0.6);
  --sidebar-bg: rgba(15, 12, 41, 0.95);
  --table-row-hover: rgba(255, 255, 255, 0.04);
  --table-header-bg: rgba(255, 255, 255, 0.04);
  --spektek-link: #667eea;
  --scrollbar-thumb: rgba(255, 255, 255, 0.15);
  --scrollbar-track: transparent;
}

[data-theme="light"] {
  --bg-primary: #f0f2f5;
  --bg-secondary: #e2e6eb;
  --bg-tertiary: #d1d7e0;
  --bg-gradient: linear-gradient(135deg, #e8ecf1, #d5dce6, #c8d0dc);
  --text-primary: #1a1a2e;
  --text-secondary: rgba(26, 26, 46, 0.6);
  --text-muted: rgba(26, 26, 46, 0.45);
  --text-dim: rgba(26, 26, 46, 0.3);
  --card-bg: rgba(255, 255, 255, 0.85);
  --card-border: rgba(0, 0, 0, 0.1);
  --card-border-light: rgba(0, 0, 0, 0.06);
  --input-bg: rgba(255, 255, 255, 0.9);
  --input-border: rgba(0, 0, 0, 0.15);
  --hover-bg: rgba(0, 0, 0, 0.05);
  --hover-bg-strong: rgba(0, 0, 0, 0.1);
  --modal-bg: rgba(255, 255, 255, 0.98);
  --modal-overlay: rgba(0, 0, 0, 0.4);
  --sidebar-bg: rgba(255, 255, 255, 0.95);
  --table-row-hover: rgba(0, 0, 0, 0.03);
  --table-header-bg: rgba(0, 0, 0, 0.03);
  --spektek-link: #5b6fd8;
  --scrollbar-thumb: rgba(0, 0, 0, 0.15);
  --scrollbar-track: transparent;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: 'Inter', Arial, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  min-height: 100vh;
  transition: background 0.3s ease, color 0.3s ease;
}

::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--scrollbar-track); }
::-webkit-scrollbar-thumb { background: var(--scrollbar-thumb); border-radius: 3px; }

.main-content {
  min-height: 100vh;
  transition: margin-left 0.3s ease;
}

.main-content.shifted {
  margin-left: 260px;
}

.main-content.shifted.collapsed {
  margin-left: 64px;
}

@media print {
  .sidebar { display: none !important; }
  .main-content { margin-left: 0 !important; }
}
</style>
