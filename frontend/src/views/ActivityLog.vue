<template>
  <div class="activity-page">
    <div class="page-header">
      <div>
        <h1>Activity Log</h1>
        <p>Memantau semua aktivitas pengguna</p>
      </div>
    </div>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <div class="retention-card">
      <div class="retention-info">
        <span class="retention-icon">&#128337;</span>
        <span>Log otomatis dihapus setelah </span>
        <span class="retention-value">{{ retentionDays }}</span>
        <select v-model.number="editDays" class="retention-select">
          <option v-for="n in [7,14,30,60,90,180]" :key="n" :value="n">{{ n }} hari</option>
        </select>
        <button v-if="editDays !== retentionDays" class="btn-save-retention" @click="saveRetention">Simpan</button>
      </div>
    </div>

    <div class="filter-bar">
      <div class="filter-search">
        <span class="filter-search-icon">&#128269;</span>
        <input v-model="searchQuery" type="text" placeholder="Cari username, aksi, halaman..." class="filter-input" />
      </div>
      <select v-model="filterAction" class="filter-select">
        <option value="">Semua Aksi</option>
        <option value="create">Create</option>
        <option value="update">Update</option>
        <option value="delete">Delete</option>
      </select>
    </div>

    <div class="table-wrapper">
      <table class="log-table">
        <thead>
          <tr>
            <th>Waktu</th>
            <th>Username</th>
            <th>Role</th>
            <th>Aksi</th>
            <th>Halaman</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(log, i) in filteredLogs" :key="log.ID" class="table-row" :style="{ '--i': i }">
            <td class="td-date">{{ formatDate(log.CreatedAt) }}</td>
            <td class="td-username">{{ log.username }}</td>
            <td><span class="role-badge">{{ log.role }}</span></td>
            <td><span class="action-badge" :class="log.action">{{ log.action }}</span></td>
            <td class="td-detail">{{ log.detail }}</td>
          </tr>
        </tbody>
      </table>
      <div v-if="!filteredLogs.length" class="empty-state">
        <div class="empty-icon">&#128203;</div>
        <p>{{ logs.length ? 'Tidak ada log yang sesuai filter' : 'Belum ada aktivitas' }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import api from '../api/client'

useHead({
  title: 'Activity Log',
  meta: [{ name: 'description', content: 'Monitor semua aktivitas pengguna' }],
})

const logs = ref([])
const error = ref('')
const searchQuery = ref('')
const filterAction = ref('')
const retentionDays = ref(30)
const editDays = ref(30)

const filteredLogs = computed(() => {
  return logs.value.filter(log => {
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase()
      if (!log.username?.toLowerCase().includes(q) &&
          !log.action?.toLowerCase().includes(q) &&
          !log.detail?.toLowerCase().includes(q)) {
        return false
      }
    }
    if (filterAction.value && log.action !== filterAction.value) return false
    return true
  })
})

function formatDate(d) {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

async function loadLogs() {
  try {
    const res = await api.get('/activity-logs')
    logs.value = res.data.activity_logs || []
  } catch (e) {
    if (e.response?.status === 403) {
      error.value = 'Hanya Super Admin yang dapat melihat activity log'
    } else {
      error.value = 'Gagal memuat activity log'
    }
  }
}

async function loadSettings() {
  try {
    const res = await api.get('/activity-logs/settings')
    retentionDays.value = res.data.retention_days
    editDays.value = res.data.retention_days
  } catch (e) {
    /* ignore */
  }
}

async function saveRetention() {
  try {
    await api.put('/activity-logs/settings', { retention_days: editDays.value })
    retentionDays.value = editDays.value
  } catch (e) {
    error.value = 'Gagal menyimpan pengaturan'
  }
}

onMounted(() => {
  loadLogs()
  loadSettings()
})
</script>

<style scoped>
.activity-page {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
}

.page-header p {
  color: var(--text-secondary);
  font-size: 14px;
  margin-top: 4px;
}

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 13px;
}

.retention-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 12px;
  padding: 14px 20px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
}

.retention-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-secondary);
  flex-wrap: wrap;
}

.retention-icon {
  font-size: 18px;
}

.retention-value {
  font-weight: 700;
  color: var(--text-primary);
  margin-right: 4px;
}

.retention-select {
  padding: 4px 8px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
  cursor: pointer;
}

.retention-select:focus {
  border-color: #667eea;
}

.btn-save-retention {
  padding: 5px 14px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.btn-save-retention:hover {
  opacity: 0.9;
}

.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.filter-search {
  position: relative;
  flex: 1;
  min-width: 200px;
}

.filter-search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 14px;
  pointer-events: none;
}

.filter-input {
  width: 100%;
  padding: 10px 14px 10px 36px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.filter-input:focus {
  border-color: #667eea;
}

.filter-select {
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s;
  min-width: 140px;
}

.filter-select:focus {
  border-color: #667eea;
}

.filter-select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.table-wrapper {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  overflow-x: auto;
  animation: fadeIn 0.5s ease;
}

.log-table {
  width: 100%;
  border-collapse: collapse;
}

.log-table thead {
  background: var(--table-header-bg);
}

.log-table th {
  padding: 14px 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 1px solid var(--card-border-light);
  white-space: nowrap;
}

.table-row {
  transition: background 0.2s;
  animation: rowIn 0.4s ease both;
  animation-delay: calc(var(--i) * 0.02s);
}

@keyframes rowIn {
  from { opacity: 0; transform: translateX(-10px); }
  to { opacity: 1; transform: translateX(0); }
}

.table-row:hover {
  background: var(--table-row-hover);
}

.table-row td {
  padding: 12px 16px;
  border-bottom: 1px solid var(--card-border-light);
  font-size: 13px;
  color: var(--text-secondary);
}

.td-date {
  white-space: nowrap;
  font-size: 12px;
}

.td-username {
  font-weight: 600;
  color: var(--text-primary);
}

.role-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.action-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.action-badge.create {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.action-badge.update {
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.action-badge.delete {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.td-detail {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-primary);
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-muted);
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.empty-state p {
  font-size: 16px;
}
</style>