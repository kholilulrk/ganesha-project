<template>
  <div class="dashboard-page">
    <div class="page-header">
      <h1>Dashboard</h1>
      <p>Ringkasan data pekerjaan dan tugas</p>
    </div>

    <div class="stats-grid">
      <div class="stat-card pending" @click="goToPekerjaan('pending')">
        <div class="stat-icon">📋</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.pending_jobs }}</span>
          <span class="stat-label">Pekerjaan Pending</span>
        </div>
      </div>
      <div class="stat-card teknisi" @click="goToPekerjaan('incomplete')">
        <div class="stat-icon">🔧</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.uncompleted_jobs }}</span>
          <span class="stat-label">Pekerjaan Belum Selesai</span>
        </div>
      </div>
      <div class="stat-card logistic" @click="goToPekerjaan('', '', 'Logistic')">
        <div class="stat-icon">📦</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.uncompleted_logistic }}</span>
          <span class="stat-label">Tugas Logistic Belum Selesai</span>
        </div>
      </div>
      <div v-if="canCreate" class="stat-card add" @click="openCreateForm">
        <div class="stat-icon">➕</div>
        <div class="stat-body">
          <span class="stat-value">Baru</span>
          <span class="stat-label">Buat Pekerjaan</span>
        </div>
      </div>
    </div>

    <transition name="modal-fade">
      <div v-if="showCreateForm" class="modal-overlay" @click.self="closeCreateForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>Tambah Pekerjaan</h2>
            <button class="btn-close" @click="closeCreateForm">✕</button>
          </div>
          <form @submit.prevent="handleCreateJob" class="job-form">
            <div class="form-group">
              <label>Nama Pekerjaan</label>
              <input v-model="createForm.name" type="text" placeholder="Nama pekerjaan" required />
            </div>
            <div class="form-group">
              <label>Deskripsi Pekerjaan</label>
              <textarea v-model="createForm.description" placeholder="Deskripsi pekerjaan" rows="3" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Nilai Pekerjaan (Rp)</label>
                <input v-model="createForm.value" type="text" placeholder="0" @input="formatValueInput" />
              </div>
              <div class="form-group">
                <label>Tanggal Kontrak</label>
                <input v-model="createForm.contract_date" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Share (Role)</label>
              <div class="checkbox-group">
                <label v-for="role in roleOptions" :key="role" class="checkbox-label">
                  <input type="checkbox" :value="role" v-model="createForm.share" />
                  <span>{{ role }}</span>
                </label>
              </div>
              <label v-if="createForm.share.includes('Teknisi')" class="checkbox-label" style="margin-top:8px">
                <input type="checkbox" v-model="createForm.allTeknisi" />
                <span>Semua Teknisi</span>
              </label>
              <div v-if="usersByRole && createForm.share.length && !createForm.allTeknisi" class="user-checkboxes">
                <div v-for="role in createForm.share" :key="role" class="user-group">
                  <label class="user-group-label">{{ role }}</label>
                  <div v-if="usersByRole[role] && usersByRole[role].length" class="checkbox-group">
                    <label v-for="u in usersByRole[role]" :key="u.ID" class="checkbox-label user-item">
                      <input type="checkbox" :value="u.ID" v-model="createForm.assigned_to" />
                      <span>{{ u.name }} ({{ u.username }})</span>
                    </label>
                  </div>
                  <p v-else class="no-users">Tidak ada user dengan role {{ role }}</p>
                </div>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Status</label>
                <select v-model="createForm.status">
                  <option value="pending">Pending</option>
                  <option value="progres">Progres</option>
                  <option value="done">Done</option>
                </select>
              </div>
              <div class="form-group">
                <label>Dateline</label>
                <input v-model="createForm.dateline" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Referensi Dokumen (PDF)</label>
              <select v-model="createForm.spektek" class="doc-select">
                <option value="">Pilih dokumen</option>
                <option v-for="doc in pdfDocuments" :key="doc.ID" :value="doc.file_path">
                  {{ doc.nama_dokumen }}
                </option>
              </select>
              <button v-if="createForm.spektek" type="button" class="btn-clear-doc" @click="createForm.spektek = ''">Hapus pilihan</button>
            </div>
            <div v-if="createError" class="error-banner">{{ createError }}</div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeCreateForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="createLoading">
                <span v-if="createLoading" class="spinner-sm" />
                <span v-else>Tambah</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

    <div v-if="stats.expiring_surats?.length" class="section warning-section">
      <div class="section-header">
        <h2>&#9888;&#65039; Surat Akan Kadaluarsa</h2>
        <span class="warning-count">{{ stats.expiring_surats.length }} surat</span>
      </div>
      <div class="surat-list">
        <div v-for="surat in stats.expiring_surats" :key="surat.ID" class="surat-item">
          <div class="surat-info">
            <span class="surat-name">{{ surat.nama_surat }}</span>
            <span class="surat-meta">{{ surat.jenis_surat }} &#183; {{ sisaHari(surat.masa_berlaku) }}</span>
          </div>
          <span class="surat-badge" :class="surat.jenis_surat">{{ surat.jenis_surat }}</span>
        </div>
      </div>
      <router-link to="/monitoring-surat" class="section-link">Lihat semua &#8594;</router-link>
    </div>

    <div class="section">
      <h2>Pekerjaan Pending Terbaru</h2>
      <div class="pending-list" v-if="stats.recent_pending?.length">
        <div v-for="job in stats.recent_pending" :key="job.ID" class="pending-item" @click="goToPekerjaan('pending')">
          <div class="pending-info">
            <span class="pending-name">{{ job.name }}</span>
            <span class="pending-meta">{{ job.share }} · {{ formatDate(job.contract_date) }}</span>
          </div>
          <span class="pending-badge">Pending</span>
        </div>
      </div>
      <div v-else class="empty-section">
        <p>Tidak ada pekerjaan pending</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { usePermissionStore } from '../stores/permissions'
import { useHead } from '@unhead/vue'
import { dashboardAPI } from '../api/dashboard'
useHead({
  title: 'Dashboard',
  meta: [
    { name: 'description', content: 'Dashboard Ganesha Energi - ringkasan pekerjaan dan tugas' },
  ],
})
import { jobAPI } from '../api/job'
import { userAPI } from '../api/user'
import { documentAPI } from '../api/document'

const router = useRouter()
const perms = usePermissionStore()

const canCreate = computed(() => perms.can('pekerjaan', 'create'))

const stats = ref({
  pending_jobs: 0,
  uncompleted_teknisi: 0,
  uncompleted_logistic: 0,
  uncompleted_jobs: 0,
  recent_pending: [],
})

const showCreateForm = ref(false)
const createLoading = ref(false)
const createError = ref('')
const allDocuments = ref([])
const pdfDocuments = computed(() => allDocuments.value.filter(d => d.tipe_dokumen === 'PDF'))
const roleOptions = ['Teknisi']

const createForm = reactive({
  name: '',
  description: '',
  value: '',
  contract_date: '',
  share: [],
  status: 'pending',
  dateline: '',
  assigned_to: [],
  spektek: '',
  allTeknisi: false,
})

const users = ref([])
const usersByRole = computed(() => {
  const map = {}
  for (const r of roleOptions) {
    map[r] = users.value.filter(u => u.role === r)
  }
  return map
})

async function fetchUsers() {
  if (!createForm.share.length) {
    users.value = []
    return
  }
  try {
    const res = await userAPI.getAll({ roles: createForm.share.join(',') })
    users.value = res.data.users
  } catch {
    users.value = []
  }
}

watch(() => createForm.share, () => {
  createForm.assigned_to = []
  fetchUsers()
})

onMounted(async () => {
  await perms.load()
  try {
    const res = await dashboardAPI.getStats()
    stats.value = res.data
  } catch { /* ignore */ }
  try {
    const res = await documentAPI.getAll()
    allDocuments.value = res.data.documents
  } catch { /* ignore */ }
})

function goToPekerjaan(status, share, checklistIncomplete) {
  const query = {}
  if (status) query.status = status
  if (share) query.share = share
  if (checklistIncomplete) query.checklist_incomplete = checklistIncomplete
  router.push({ path: '/pekerjaan', query })
}

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleDateString('id-ID', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

function sisaHari(tgl) {
  const now = new Date()
  const expire = new Date(tgl)
  const diff = Math.ceil((expire - now) / (1000 * 60 * 60 * 24))
  if (diff <= 1) return 'Besok kadaluarsa'
  return `${diff} hari lagi`
}

function openCreateForm() {
  showCreateForm.value = true
}

function closeCreateForm() {
  showCreateForm.value = false
  createForm.name = ''
  createForm.description = ''
  createForm.value = ''
  createForm.contract_date = ''
  createForm.share = []
  createForm.status = 'pending'
  createForm.dateline = ''
  createForm.assigned_to = []
  createForm.spektek = ''
  createForm.allTeknisi = false
  users.value = []
}

function formatValueInput() {
  createForm.value = createForm.value.replace(/[^0-9]/g, '')
  if (createForm.value) {
    createForm.value = parseInt(createForm.value).toLocaleString('id-ID')
  }
}

function parseValue(val) {
  return val.replace(/\./g, '')
}

async function handleCreateJob() {
  createLoading.value = true
  createError.value = ''
  try {
    const assignedTo = createForm.allTeknisi ? '' : createForm.assigned_to.join(',')
    const data = {
      name: createForm.name,
      description: createForm.description,
      value: parseValue(createForm.value),
      contract_date: createForm.contract_date,
      share: createForm.share.join(','),
      status: createForm.status,
      dateline: createForm.dateline || '',
      assigned_to: assignedTo,
      spektek: createForm.spektek,
    }
    await jobAPI.create(data)
    closeCreateForm()
    const res = await dashboardAPI.getStats()
    stats.value = res.data
  } catch (err) {
    createError.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    createLoading.value = false
  }
}
</script>

<style scoped>
.dashboard-page {
  padding: 24px;
  max-width: 1000px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  margin-bottom: 28px;
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 32px;
}

.stat-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 14px;
  transition: transform 0.2s, box-shadow 0.2s;
  cursor: pointer;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.stat-card.add {
  cursor: pointer;
  border-style: dashed;
  border-color: var(--accent-primary, #667eea);
}

.stat-card.add:hover {
  background: rgba(102, 126, 234, 0.06);
}

.stat-icon {
  font-size: 28px;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  flex-shrink: 0;
}

.stat-card.pending .stat-icon { background: rgba(255, 193, 7, 0.15); }
.stat-card.teknisi .stat-icon { background: rgba(102, 126, 234, 0.15); }
.stat-card.logistic .stat-icon { background: rgba(81, 207, 102, 0.15); }
.stat-card.add .stat-icon { background: rgba(102, 126, 234, 0.1); }

.stat-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
}

.stat-card.add .stat-value {
  font-size: 18px;
}

.stat-label {
  font-size: 12px;
  color: var(--text-muted);
  font-weight: 500;
}

.section {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  padding: 24px;
}

.section h2 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 16px;
}

.pending-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.pending-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.2s;
}

.pending-item:hover {
  background: var(--hover-bg-strong);
}

.pending-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pending-name {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.pending-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.pending-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.empty-section {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-dim);
  font-size: 14px;
}

.warning-section {
  border: 1px solid rgba(255, 193, 7, 0.3);
  margin-bottom: 24px;
  animation: pulse-warning 2s infinite;
}

@keyframes pulse-warning {
  0%, 100% { box-shadow: 0 0 0 0 rgba(255, 193, 7, 0); }
  50% { box-shadow: 0 0 12px 2px rgba(255, 193, 7, 0.15); }
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.warning-count {
  font-size: 12px;
  font-weight: 600;
  color: #ffc107;
  background: rgba(255, 193, 7, 0.15);
  padding: 4px 10px;
  border-radius: 8px;
}

.surat-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 12px;
}

.surat-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  transition: background 0.2s;
}

.surat-item:hover {
  background: var(--hover-bg-strong);
}

.surat-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.surat-name {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.surat-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.surat-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.surat-badge.SIK {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.surat-badge.SC {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.section-link {
  display: block;
  text-align: center;
  font-size: 13px;
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
  padding: 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.section-link:hover {
  background: rgba(102, 126, 234, 0.1);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--modal-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-card {
  background: #fff;
  border-radius: 16px;
  width: 100%;
  max-width: 640px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  animation: modalSlideIn 0.25s ease;
}

@keyframes modalSlideIn {
  from { opacity: 0; transform: translateY(20px) scale(0.97); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid var(--card-border-light);
}

.modal-header h2 {
  font-size: 18px;
  font-weight: 600;
}

.btn-close {
  width: 32px;
  height: 32px;
  border: none;
  background: var(--hover-bg);
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  transition: background 0.2s;
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.job-form {
  padding: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 16px;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
}

.form-group input,
.form-group textarea,
.form-group select {
  padding: 10px 14px;
  border: 1px solid var(--card-border);
  border-radius: 10px;
  font-size: 14px;
  background: var(--input-bg);
  color: var(--text-primary);
  transition: border-color 0.2s, box-shadow 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15);
}

.form-group textarea {
  resize: vertical;
  min-height: 70px;
}

.form-group select option {
  padding: 8px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.checkbox-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 4px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  cursor: pointer;
  padding: 6px 12px;
  background: var(--hover-bg);
  border-radius: 8px;
  transition: background 0.2s;
  user-select: none;
}

.checkbox-label:hover {
  background: var(--hover-bg-strong);
}

.checkbox-label input[type="checkbox"] {
  width: auto;
  margin: 0;
}

.user-checkboxes {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.user-group-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 4px;
  display: block;
}

.user-item {
  font-size: 12px;
}

.no-users {
  font-size: 12px;
  color: var(--text-dim);
  font-style: italic;
  padding: 4px 0;
}

.doc-select {
  width: 100%;
}

.btn-clear-doc {
  align-self: flex-start;
  border: none;
  background: none;
  color: #ef4444;
  font-size: 12px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.2s;
}

.btn-clear-doc:hover {
  background: rgba(239, 68, 68, 0.1);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid var(--card-border-light);
}

.btn-cancel {
  padding: 10px 20px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  border-radius: 10px;
  font-size: 14px;
  cursor: pointer;
  color: var(--text-secondary);
  transition: background 0.2s, border-color 0.2s;
  font-weight: 500;
}

.btn-cancel:hover {
  background: var(--hover-bg);
  border-color: var(--text-muted);
}

.btn-save {
  padding: 10px 24px;
  border: none;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-save:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-1px);
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner-sm {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  color: #ef4444;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 12px;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
