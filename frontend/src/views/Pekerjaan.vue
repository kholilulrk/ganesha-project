<template>
  <div class="pekerjaan-page">
    <div class="page-header">
      <div>
        <h1>Pekerjaan</h1>
        <p>Kelola data pekerjaan</p>
      </div>
      <button v-if="perms.can('pekerjaan', 'create')" class="btn-add" @click="showForm = true">
        <span>+</span> Tambah Pekerjaan
      </button>
    </div>

    <transition name="modal-fade">
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editing ? 'Edit Pekerjaan' : 'Tambah Pekerjaan' }}</h2>
            <button class="btn-close" @click="closeForm">✕</button>
          </div>
          <form @submit.prevent="handleSubmit" class="job-form">
            <div class="form-group">
              <label>Nama Pekerjaan</label>
              <input v-model="form.name" type="text" placeholder="Nama pekerjaan" required />
            </div>
            <div class="form-group">
              <label>Deskripsi Pekerjaan</label>
              <textarea v-model="form.description" placeholder="Deskripsi pekerjaan" rows="3" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Nilai Pekerjaan (Rp)</label>
                <input v-model="form.value" type="text" placeholder="0" @input="formatValueInput" />
              </div>
              <div class="form-group">
                <label>Tanggal Kontrak</label>
                <input v-model="form.contract_date" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Share (Role)</label>
              <div class="checkbox-group">
                <label v-for="role in roleOptions" :key="role" class="checkbox-label">
                  <input type="checkbox" :value="role" v-model="form.share" />
                  <span>{{ role }}</span>
                </label>
              </div>
              <label v-if="form.share.includes('Teknisi')" class="checkbox-label" style="margin-top:8px">
                <input type="checkbox" v-model="form.allTeknisi" />
                <span>Semua Teknisi</span>
              </label>
              <div v-if="usersByRole && form.share.length && !form.allTeknisi" class="user-checkboxes">
                <div v-for="role in form.share" :key="role" class="user-group">
                  <label class="user-group-label">{{ role }}</label>
                  <div v-if="usersByRole[role] && usersByRole[role].length" class="checkbox-group">
                    <label v-for="u in usersByRole[role]" :key="u.ID" class="checkbox-label user-item">
                      <input type="checkbox" :value="u.ID" v-model="form.assigned_to" />
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
                <select v-model="form.status">
                  <option value="pending">Pending</option>
                  <option value="progres">Progres</option>
                  <option value="done">Done</option>
                </select>
              </div>
              <div class="form-group">
                <label>Dateline</label>
                <input v-model="form.dateline" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Referensi Dokumen (PDF)</label>
              <select v-model="form.spektek" class="doc-select">
                <option value="">Pilih dokumen</option>
                <option v-for="doc in pdfDocuments" :key="doc.ID" :value="doc.file_path">
                  {{ doc.nama_dokumen }}
                </option>
              </select>
              <button v-if="form.spektek" type="button" class="btn-clear-doc" @click="form.spektek = ''">Hapus pilihan</button>
            </div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="loading">
                <span v-if="loading" class="spinner-sm" />
                <span v-else>{{ editing ? 'Simpan' : 'Tambah' }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

    <JobDetail :visible="showDetail" :job="selectedJob" @close="showDetail = false" @job-updated="onJobUpdated" />

    <div v-if="error" class="error-banner">{{ error }}</div>

    <transition name="toast-fade">
      <div v-if="toast.visible" class="toast-notification">{{ toast.message }}</div>
    </transition>

    <div class="filter-bar">
      <div class="filter-search">
        <span class="filter-search-icon">🔍</span>
        <input v-model="searchQuery" type="text" placeholder="Cari pekerjaan..." class="filter-input" />
      </div>
      <select v-model="filterStatus" class="filter-select">
        <option value="">Semua Status</option>
        <option value="pending">Pending</option>
        <option value="progres">Progres</option>
        <option value="done">Done</option>
      </select>
      <select v-model="filterShare" class="filter-select">
        <option value="">Semua Role</option>
        <option value="Teknisi">Teknisi</option>
        <option value="Logistic">Logistic</option>
        <option value="Administrasi">Administrasi</option>
      </select>
    </div>

    <div class="table-wrapper">
      <table class="job-table">
        <thead>
          <tr>
            <th>Nama Pekerjaan</th>
            <th>Deskripsi</th>
            <th v-if="!isTeknisiOrLogistic">Nilai (Rp)</th>
            <th v-if="!isTeknisiOrLogistic">Tgl Kontrak</th>
            <th>Share</th>
            <th v-if="auth.user?.role === 'Teknisi' || auth.user?.role === 'Logistic' || auth.user?.role === 'Super Admin' || auth.user?.role === 'Administrasi'">Tugas Logistic</th>
            <th v-if="auth.user?.role === 'Teknisi' || auth.user?.role === 'Super Admin' || auth.user?.role === 'Administrasi'">Tugas Teknisi</th>
            <th>Status</th>
            <th>Dateline</th>
            <th>SPEKTEK</th>
            <th class="th-actions">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(job, i) in filteredJobs" :key="job.ID" class="table-row" :style="{ '--i': i }">
            <td class="td-name">{{ job.name }}</td>
            <td class="td-desc">{{ job.description || '-' }}</td>
            <td v-if="!isTeknisiOrLogistic" class="td-value">{{ formatRupiah(job.value) }}</td>
            <td v-if="!isTeknisiOrLogistic" class="td-date">{{ formatDate(job.contract_date) }}</td>
            <td class="td-share">
              <span v-for="r in (job.share || '').split(',').filter(Boolean)" :key="r" class="role-badge">{{ r }}</span>
              <div v-if="job.assigned_to" class="assigned-users">
                <span v-for="uid in job.assigned_to.split(',').filter(Boolean)" :key="uid" class="user-tag">
                  {{ userName(uid) }}
                </span>
              </div>
              <span v-if="!job.share" class="muted">-</span>
            </td>
            <td v-if="auth.user?.role === 'Teknisi' || auth.user?.role === 'Logistic' || auth.user?.role === 'Super Admin' || auth.user?.role === 'Administrasi'" class="td-task-count">
              <span v-if="job.uncompleted_logistic > 0" class="count-badge warn">{{ job.uncompleted_logistic }}</span>
              <span v-else class="count-badge ok">0</span>
            </td>
            <td v-if="auth.user?.role === 'Teknisi' || auth.user?.role === 'Super Admin' || auth.user?.role === 'Administrasi'" class="td-task-count">
              <span v-if="job.uncompleted_teknisi > 0" class="count-badge warn">{{ job.uncompleted_teknisi }}</span>
              <span v-else class="count-badge ok">0</span>
            </td>
            <td class="td-status">
              <span class="status-badge" :class="job.status">{{ job.status || 'pending' }}</span>
            </td>
            <td class="td-date">{{ formatDate(job.dateline) }}</td>
            <td>
              <a v-if="job.spektek" :href="spektekUrl(job.spektek)" target="_blank" class="spektek-link">📄 PDF</a>
              <span v-else class="muted">-</span>
            </td>
            <td class="td-actions">
              <button class="btn-icon view" @click="viewJob(job)" title="Detail">👁️</button>
              <button class="btn-icon share" @click="shareJob(job)" title="Bagikan ke Customer">🔗</button>
              <button v-if="perms.can('pekerjaan', 'edit')" class="btn-icon edit" @click="editJob(job)" title="Edit">✏️</button>
              <button v-if="perms.can('pekerjaan', 'delete')" class="btn-icon delete" @click="deleteJob(job.ID)" title="Hapus">🗑️</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="!filteredJobs.length" class="empty-state">
        <div class="empty-icon">📋</div>
        <p v-if="jobs.length">{{ 'Tidak ada pekerjaan yang sesuai filter' }}</p>
        <p v-else>Belum ada pekerjaan</p>
        <button v-if="perms.can('pekerjaan', 'create')" class="btn-add" @click="showForm = true">Tambah Pekerjaan</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { jobAPI } from '../api/job'
import { userAPI } from '../api/user'
useHead({
  title: 'Data Pekerjaan',
  meta: [
    { name: 'description', content: 'Kelola data pekerjaan Ganesha Energi' },
  ],
})
import { documentAPI } from '../api/document'
import { usePermissionStore } from '../stores/permissions'
import { useAuthStore } from '../stores/auth'
import JobDetail from '../components/JobDetail.vue'

const perms = usePermissionStore()
const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const isTeknisiOrLogistic = computed(() => auth.user?.role === 'Teknisi' || auth.user?.role === 'Logistic')

const filteredJobs = computed(() => {
  return jobs.value.filter(j => {
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase()
      if (!j.name.toLowerCase().includes(q) && !(j.description || '').toLowerCase().includes(q)) {
        return false
      }
    }
    if (filterStatus.value && j.status !== filterStatus.value) return false
    if (filterShare.value) {
      const shares = (j.share || '').split(',').map(s => s.trim()).filter(Boolean)
      if (!shares.includes(filterShare.value)) return false
    }
    return true
  })
})

const jobs = ref([])
const showForm = ref(false)
const showDetail = ref(false)
const searchQuery = ref('')
const filterStatus = ref('')
const filterShare = ref('')
const selectedJob = ref(null)
const editing = ref(false)
const editId = ref(null)
const loading = ref(false)
const error = ref('')

const toast = reactive({ visible: false, message: '' })
let toastTimer = null

function showToast(msg) {
  toast.message = msg
  toast.visible = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.visible = false }, 2000)
}

const allDocuments = ref([])
const pdfDocuments = computed(() => allDocuments.value.filter(d => d.tipe_dokumen === 'PDF'))

const roleOptions = ['Teknisi']

const form = reactive({
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

const allUsers = ref([])

async function fetchAllUsers() {
  try {
    const res = await userAPI.getAll()
    allUsers.value = res.data.users
  } catch { /* ignore */ }
}

function userName(id) {
  const u = allUsers.value.find(u => u.ID == id)
  return u ? u.name : id
}

async function fetchUsers() {
  if (!form.share.length) {
    users.value = []
    return
  }
  try {
    const res = await userAPI.getAll({ roles: form.share.join(',') })
    users.value = res.data.users
  } catch {
    users.value = []
  }
}

watch(() => form.share, () => {
  if (!editing.value) {
    form.assigned_to = []
  }
  fetchUsers()
})

onMounted(async () => {
  await perms.load()
  const apiFilters = {}
  if (route.query.share) apiFilters.share = route.query.share
  if (route.query.checklist_incomplete) {
    apiFilters.checklist_incomplete = route.query.checklist_incomplete
  } else if (route.query.status === 'incomplete') {
    apiFilters.checklist_incomplete = 'true'
  } else if (route.query.status) {
    apiFilters.status = route.query.status
  }
  filterStatus.value = (route.query.status === 'incomplete') ? '' : (route.query.status || '')
  filterShare.value = route.query.share || ''
  loadJobs(apiFilters)
  fetchAllUsers()
  try {
    const res = await documentAPI.getAll()
    allDocuments.value = res.data.documents
  } catch { /* ignore */ }
})

async function loadJobs(filters) {
  try {
    const res = await jobAPI.getAll(filters || {})
    jobs.value = res.data.jobs
  } catch (err) {
    error.value = 'Gagal memuat data'
  }
}

function spektekUrl(val) {
  if (!val) return ''
  const path = val.replace(/\\/g, '/')
  if (path.startsWith('uploads/')) return '/' + path
  return '/uploads/spektek/' + path
}

function formatValueInput() {
  form.value = form.value.replace(/[^0-9]/g, '')
  if (form.value) {
    form.value = parseInt(form.value).toLocaleString('id-ID')
  }
}

function parseValue(val) {
  return val.replace(/\./g, '')
}

function formatRupiah(val) {
  return Number(val).toLocaleString('id-ID')
}

function formatDate(d) {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric', month: 'long', day: 'numeric',
  })
}

function viewJob(job) {
  selectedJob.value = job
  showDetail.value = true
}

function onJobUpdated(updated) {
  selectedJob.value = updated
  const idx = jobs.value.findIndex(j => j.ID === updated.ID)
  if (idx !== -1) jobs.value[idx] = updated
}

async function shareJob(job) {
  try {
    let token = job.share_token
    if (!token) {
      const res = await jobAPI.generateShareLink(job.ID)
      token = res.data.share_token
      job.share_token = token
    }
    const url = window.location.origin + '/pekerjaan/shared/' + token
    if (navigator.clipboard) {
      await navigator.clipboard.writeText(url)
    } else {
      const ta = document.createElement('textarea')
      ta.value = url
      ta.style.position = 'fixed'
      ta.style.opacity = '0'
      document.body.appendChild(ta)
      ta.select()
      document.execCommand('copy')
      document.body.removeChild(ta)
    }
    showToast('Tersalin')
  } catch (e) {
    alert('Gagal: ' + (e.response?.data?.error || e.message))
  }
}

function closeForm() {
  showForm.value = false
  editing.value = false
  editId.value = null
  form.name = ''
  form.description = ''
  form.value = ''
  form.contract_date = ''
  form.share = []
  form.status = 'pending'
  form.dateline = ''
  form.assigned_to = []
  form.spektek = ''
  form.allTeknisi = false
  users.value = []
}

function editJob(job) {
  editing.value = true
  editId.value = job.ID
  form.name = job.name
  form.description = job.description || ''
  form.value = formatRupiah(job.value)
  form.contract_date = job.contract_date ? job.contract_date.substring(0, 10) : ''
  form.share = (job.share || '').split(',').filter(s => s === 'Teknisi')
  form.allTeknisi = false
  form.status = job.status || 'pending'
  form.dateline = job.dateline ? job.dateline.substring(0, 10) : ''
  form.assigned_to = (job.assigned_to || '').split(',').map(Number).filter(Boolean)
  form.spektek = job.spektek || ''
  showForm.value = true
}

async function handleSubmit() {
  loading.value = true
  error.value = ''
  try {
    const assignedTo = form.allTeknisi ? '' : form.assigned_to.join(',')
    const data = {
      name: form.name,
      description: form.description,
      value: parseValue(form.value),
      contract_date: form.contract_date,
      share: form.share.join(','),
      status: form.status,
      dateline: form.dateline || '',
      assigned_to: assignedTo,
      spektek: form.spektek,
    }
    if (editing.value) {
      await jobAPI.update(editId.value, data)
    } else {
      await jobAPI.create(data)
    }
    closeForm()
    await loadJobs()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    loading.value = false
  }
}

async function deleteJob(id) {
  if (!confirm('Yakin ingin menghapus pekerjaan ini?')) return
  try {
    await jobAPI.delete(id)
    await loadJobs()
  } catch (err) {
    error.value = 'Gagal menghapus data'
  }
}
</script>

<style scoped>
.pekerjaan-page {
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

.btn-add {
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: 'Inter', sans-serif;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-add:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--modal-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  backdrop-filter: blur(4px);
}

.modal-card {
  background: var(--modal-bg);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 32px;
  width: 100%;
  max-width: 520px;
  max-height: 90vh;
  overflow-y: auto;
  animation: modalIn 0.3s ease;
}

@keyframes modalIn {
  from { opacity: 0; transform: scale(0.95) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.modal-header h2 {
  color: var(--text-primary);
  font-size: 18px;
  font-weight: 600;
}

.btn-close {
  background: var(--hover-bg);
  border: none;
  color: var(--text-muted);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.job-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  color: var(--text-secondary);
  font-size: 13px;
  font-weight: 500;
}

.form-group input,
.form-group textarea,
.form-group select {
  padding: 12px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  border-color: #667eea;
}

.form-group textarea {
  resize: vertical;
}

.form-group select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.file-upload-wrapper {
  display: flex;
  gap: 8px;
  align-items: center;
}

.file-input-hidden {
  display: none;
}

.file-upload-btn {
  flex: 1;
  padding: 10px 14px;
  border: 1px dashed var(--card-border);
  border-radius: 10px;
  background: var(--card-bg);
  color: var(--text-muted);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: border-color 0.2s, background 0.2s;
  text-align: left;
}

.file-upload-btn:hover {
  border-color: #667eea;
  background: rgba(102, 126, 234, 0.06);
}

.file-remove-btn {
  padding: 10px 12px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  transition: border-color 0.2s, color 0.2s;
}

.file-remove-btn:hover {
  border-color: #ff6b6b;
  color: #ff6b6b;
}

.spektek-link {
  color: var(--spektek-link);
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  transition: color 0.2s;
}

.spektek-link:hover {
  color: #764ba2;
  text-decoration: underline;
}

.doc-select {
  padding: 12px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s;
}

.doc-select:focus {
  border-color: #667eea;
}

.doc-select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.btn-clear-doc {
  margin-top: 6px;
  padding: 6px 12px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: transparent;
  color: var(--text-muted);
  font-size: 12px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: border-color 0.2s, color 0.2s;
  align-self: flex-start;
}

.btn-clear-doc:hover {
  border-color: #ff6b6b;
  color: #ff6b6b;
}

.checkbox-group {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--text-secondary);
  font-size: 14px;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  width: 16px;
  height: 16px;
  accent-color: #667eea;
}

.user-checkboxes {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.user-group {
  padding: 10px 12px;
  background: var(--card-bg);
  border-radius: 8px;
  border: 1px solid var(--card-border-light);
}

.user-group-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
  margin-bottom: 6px;
  display: block;
}

.user-item {
  padding: 4px 0;
}

.no-users {
  color: var(--text-dim);
  font-size: 12px;
  font-style: italic;
}

.assigned-users {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  margin-top: 4px;
}

.user-tag {
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 8px;
}

.btn-cancel {
  padding: 10px 20px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: transparent;
  color: var(--text-secondary);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: background 0.2s;
}

.btn-cancel:hover {
  background: var(--hover-bg);
}

.btn-save {
  padding: 10px 24px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 100px;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-save:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.btn-save:disabled {
  opacity: 0.7;
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
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 20px;
  font-size: 13px;
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
  min-width: 150px;
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

.job-table {
  width: 100%;
  border-collapse: collapse;
}

.job-table thead {
  background: var(--table-header-bg);
}

.job-table th {
  padding: 14px 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 1px solid var(--card-border-light);
}

.th-actions {
  text-align: center;
  width: 100px;
}

.table-row {
  transition: background 0.2s;
  animation: rowIn 0.4s ease both;
  animation-delay: calc(var(--i) * 0.05s);
}

@keyframes rowIn {
  from { opacity: 0; transform: translateX(-10px); }
  to { opacity: 1; transform: translateX(0); }
}

.table-row:hover {
  background: var(--table-row-hover);
}

.table-row td {
  padding: 14px 16px;
  border-bottom: 1px solid var(--card-border-light);
  font-size: 14px;
  color: var(--text-secondary);
}

.td-name {
  font-weight: 600;
  color: var(--text-primary);
}

.td-desc {
  color: var(--text-muted);
  max-width: 240px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.td-value {
  font-weight: 600;
  color: #51cf66;
  font-variant-numeric: tabular-nums;
}

.td-date {
  color: var(--text-secondary);
}

.td-share {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.role-badge {
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.muted {
  color: var(--text-dim);
}

.td-task-count {
  text-align: center;
}

.count-badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 700;
  min-width: 24px;
  text-align: center;
}

.count-badge.ok {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.count-badge.warn {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.td-status {
  text-align: center;
}

.status-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.status-badge.pending {
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.status-badge.progres {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.status-badge.done {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.td-actions {
  text-align: center;
  white-space: nowrap;
}

.btn-icon {
  background: var(--hover-bg);
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
  margin: 0 2px;
}

.btn-icon:hover {
  background: var(--hover-bg-strong);
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
  margin-bottom: 20px;
}

.detail-card {
  max-width: 480px;
}

.detail-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 10px 12px;
  background: var(--card-bg);
  border-radius: 8px;
}

.detail-label {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.detail-value {
  font-size: 14px;
  color: var(--text-primary);
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  align-items: center;
}

.btn-icon.view:hover {
  background: rgba(102, 126, 234, 0.15);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.toast-notification {
  position: fixed;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  background: #333;
  color: #fff;
  padding: 12px 24px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  z-index: 999;
  box-shadow: 0 8px 24px rgba(0,0,0,0.2);
  font-family: 'Inter', sans-serif;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(12px);
}
</style>
