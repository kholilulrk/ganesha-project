<template>
  <div class="pengumuman-page">
    <div class="page-header">
      <h1>Pengumuman</h1>
      <button class="btn-add" @click="openCreate">
        <span>+</span> Tambah Pengumuman
      </button>
    </div>

    <div v-if="loading" class="loading">Memuat...</div>

    <div v-else-if="!announcements.length" class="empty">
      <p>Belum ada pengumuman</p>
    </div>

    <div v-else class="table-wrapper">
      <table class="data-table">
        <thead>
          <tr>
            <th>Judul</th>
            <th>Konten</th>
            <th>Mulai</th>
            <th>Selesai</th>
            <th>Status</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="a in announcements" :key="a.ID">
            <td class="title-cell">{{ a.title }}</td>
            <td class="content-cell">{{ a.content }}</td>
            <td>{{ formatDate(a.start_at) }}</td>
            <td>{{ formatDate(a.end_at) }}</td>
            <td>
              <span class="status-badge" :class="getStatusClass(a)">{{ getStatusLabel(a) }}</span>
            </td>
            <td class="actions-cell">
              <button class="btn-icon" title="Edit" @click="openEdit(a)">&#9998;</button>
              <button class="btn-icon" :title="a.is_active ? 'Nonaktifkan' : 'Aktifkan'" @click="handleToggle(a)">
                <span v-if="a.is_active">&#10060;</span>
                <span v-else>&#9989;</span>
              </button>
              <button class="btn-icon btn-danger" title="Hapus" @click="handleDelete(a)">&#128465;</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <transition name="modal-fade">
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editing ? 'Edit Pengumuman' : 'Tambah Pengumuman' }}</h2>
            <button class="btn-close" @click="closeForm">&#10005;</button>
          </div>
          <form @submit.prevent="handleSave" class="form-body">
            <div class="form-group">
              <label>Judul <span class="required">*</span></label>
              <input v-model="form.title" type="text" placeholder="Judul pengumuman" required />
            </div>
            <div class="form-group">
              <label>Konten</label>
              <textarea v-model="form.content" placeholder="Isi pengumuman" rows="4" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Tanggal Mulai <span class="required">*</span></label>
                <input v-model="form.start_at" type="date" required />
              </div>
              <div class="form-group">
                <label>Tanggal Selesai <span class="required">*</span></label>
                <input v-model="form.end_at" type="date" required />
              </div>
            </div>
            <div v-if="formError" class="error-banner">{{ formError }}</div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="saving">
                <span v-if="saving" class="spinner-sm" />
                <span v-else>Simpan</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { announcementAPI } from '../api/announcement'

useHead({
  title: 'Pengumuman',
  meta: [
    { name: 'description', content: 'Kelola pengumuman' },
  ],
})

const announcements = ref([])
const loading = ref(true)
const showForm = ref(false)
const editing = ref(null)
const saving = ref(false)
const formError = ref('')

const form = ref({
  title: '',
  content: '',
  start_at: '',
  end_at: '',
})

onMounted(async () => {
  await loadData()
})

async function loadData() {
  loading.value = true
  try {
    const res = await announcementAPI.getAll()
    announcements.value = res.data.announcements || []
  } catch {
    announcements.value = []
  } finally {
    loading.value = false
  }
}

function formatDate(d) {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

function getStatusClass(a) {
  const now = new Date()
  const start = new Date(a.start_at)
  const end = new Date(a.end_at)
  if (!a.is_active) return 'inactive'
  if (now < start) return 'scheduled'
  if (now > end) return 'expired'
  return 'active'
}

function getStatusLabel(a) {
  const now = new Date()
  const start = new Date(a.start_at)
  const end = new Date(a.end_at)
  if (!a.is_active) return 'Nonaktif'
  if (now < start) return 'Terjadwal'
  if (now > end) return 'Kadaluarsa'
  return 'Aktif'
}

function openCreate() {
  editing.value = null
  form.value = { title: '', content: '', start_at: '', end_at: '' }
  formError.value = ''
  showForm.value = true
}

function openEdit(a) {
  editing.value = a
  form.value = {
    title: a.title,
    content: a.content || '',
    start_at: a.start_at ? a.start_at.substring(0, 10) : '',
    end_at: a.end_at ? a.end_at.substring(0, 10) : '',
  }
  formError.value = ''
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editing.value = null
  formError.value = ''
}

async function handleSave() {
  saving.value = true
  formError.value = ''
  try {
    if (editing.value) {
      await announcementAPI.update(editing.value.ID, form.value)
    } else {
      await announcementAPI.create(form.value)
    }
    closeForm()
    await loadData()
  } catch (err) {
    formError.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    saving.value = false
  }
}

async function handleToggle(a) {
  try {
    await announcementAPI.toggle(a.ID)
    await loadData()
  } catch {
    // ignore
  }
}

async function handleDelete(a) {
  if (!confirm(`Hapus pengumuman "${a.title}"?`)) return
  try {
    await announcementAPI.delete(a.ID)
    await loadData()
  } catch {
    // ignore
  }
}
</script>

<style scoped>
.pengumuman-page {
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

.btn-add {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  border: none;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.2s;
}

.btn-add:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

.loading, .empty {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-dim);
  font-size: 14px;
}

.table-wrapper {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  overflow: hidden;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  text-align: left;
  padding: 14px 16px;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  background: var(--hover-bg);
  border-bottom: 1px solid var(--card-border-light);
}

.data-table td {
  padding: 14px 16px;
  font-size: 13px;
  color: var(--text-primary);
  border-bottom: 1px solid var(--card-border);
}

.data-table tr:last-child td {
  border-bottom: none;
}

.data-table tr:hover td {
  background: var(--hover-bg);
}

.title-cell {
  font-weight: 600;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.content-cell {
  max-width: 250px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: var(--text-secondary);
}

.status-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
}

.status-badge.active {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.status-badge.inactive {
  background: rgba(201, 201, 201, 0.15);
  color: #999;
}

.status-badge.scheduled {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.status-badge.expired {
  background: rgba(255, 107, 107, 0.15);
  color: #ef4444;
}

.actions-cell {
  display: flex;
  gap: 6px;
}

.btn-icon {
  width: 32px;
  height: 32px;
  border: none;
  background: var(--hover-bg);
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  transition: background 0.2s;
  color: var(--text-secondary);
}

.btn-icon:hover {
  background: var(--hover-bg-strong);
  color: var(--text-primary);
}

.btn-icon.btn-danger:hover {
  background: rgba(255, 107, 107, 0.15);
  color: #ef4444;
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
  max-width: 540px;
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

.form-body {
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

.required {
  color: #ef4444;
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
  min-height: 80px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
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
</style>
