<template>
  <div class="dokumen-page">
    <div class="page-header">
      <div>
        <h1>Upload Dokumen</h1>
        <p>Kelola dokumen dan bagikan ke pengguna</p>
      </div>
      <button class="btn-add" @click="showForm = true">
        <span>+</span> Upload Dokumen
      </button>
    </div>

    <transition name="modal-fade">
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editing ? 'Edit Dokumen' : 'Upload Dokumen' }}</h2>
            <button class="btn-close" @click="closeForm">&times;</button>
          </div>
          <form @submit.prevent="handleSubmit" class="dokumen-form" enctype="multipart/form-data">
            <div class="form-group">
              <label>Nama Dokumen</label>
              <input v-model="form.nama_dokumen" type="text" placeholder="Nama dokumen" required />
            </div>
            <div class="form-group">
              <label>Tipe Dokumen</label>
              <select v-model="form.tipe_dokumen" required>
                <option value="">Pilih tipe</option>
                <option value="PDF">PDF</option>
                <option value="Excel">Excel</option>
                <option value="Word">Word</option>
                <option value="JPG">JPG</option>
                <option value="PNG">PNG</option>
              </select>
            </div>
            <div class="form-group">
              <label>Upload File</label>
              <div class="file-upload-wrapper">
                <input ref="fileInput" type="file" :accept="fileAccept" @change="onFileChange" class="file-input-hidden" />
                <button type="button" class="file-upload-btn" @click="$refs.fileInput.click()">
                  <span v-if="form.file">{{ form.file.name }}</span>
                  <span v-else>+ Pilih File</span>
                </button>
                <button v-if="form.file" type="button" class="file-remove-btn" @click="removeFile">&times;</button>
              </div>
            </div>
            <div class="form-group">
              <label>Deskripsi</label>
              <textarea v-model="form.deskripsi" placeholder="Deskripsi dokumen" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label>Bagikan ke</label>
              <select v-model="form.share_mode" class="share-select">
                <option value="all">Semua Role</option>
                <option value="specific">Role Tertentu</option>
              </select>
            </div>
            <div v-if="form.share_mode === 'specific'" class="form-group">
              <label>Pilih Pengguna</label>
              <div class="user-checkboxes">
                <div v-for="group in usersByRole" :key="group.role" class="user-group">
                  <label class="user-group-label">{{ group.role }}</label>
                  <label v-for="u in group.users" :key="u.ID" class="checkbox-label">
                    <input type="checkbox" :value="u.ID" v-model="form.shared_to" />
                    <span>{{ u.name }} ({{ u.username }})</span>
                  </label>
                  <p v-if="!group.users.length" class="no-users">Tidak ada user</p>
                </div>
              </div>
            </div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="loading">
                <span v-if="loading" class="spinner-sm" />
                <span v-else>{{ editing ? 'Simpan' : 'Upload' }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

    <transition name="modal-fade">
      <div v-if="showDetail && detailDoc" class="modal-overlay" @click.self="showDetail = false">
        <div class="modal-card">
          <div class="modal-header">
            <h2>Detail Dokumen</h2>
            <button class="btn-close" @click="showDetail = false">&times;</button>
          </div>
          <div class="detail-body">
            <div v-if="detailDoc.tipe_dokumen === 'PDF'" class="detail-row preview-row">
              <label>Preview</label>
              <div class="pdf-embed">
                <iframe :src="fileUrl(detailDoc.file_path)" class="pdf-frame"></iframe>
              </div>
            </div>
            <div v-else-if="['JPG','PNG'].includes(detailDoc.tipe_dokumen)" class="detail-row preview-row">
              <label>Preview</label>
              <img :src="fileUrl(detailDoc.file_path)" class="img-preview" />
            </div>
            <div class="detail-row">
              <label>Nama Dokumen</label>
              <span>{{ detailDoc.nama_dokumen }}</span>
            </div>
            <div class="detail-row">
              <label>Tipe</label>
              <span class="tipe-badge" :class="detailDoc.tipe_dokumen">{{ detailDoc.tipe_dokumen }}</span>
            </div>
            <div class="detail-row">
              <label>Deskripsi</label>
              <span>{{ detailDoc.deskripsi || '-' }}</span>
            </div>
            <div class="detail-row">
              <label>Dibagikan ke</label>
              <span v-if="detailDoc.share_mode === 'all'">Semua Role</span>
              <span v-else>{{ sharedToNames(detailDoc.shared_to) }}</span>
            </div>
            <div class="detail-row">
              <label>Tanggal Upload</label>
              <span>{{ formatDate(detailDoc.CreatedAt) }}</span>
            </div>
            <div class="detail-actions">
              <a :href="fileUrl(detailDoc.file_path)" target="_blank" class="btn-save">Download</a>
              <button class="btn-cancel" @click="showDetail = false">Tutup</button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <transition name="toast-fade">
      <div v-if="toast.visible" class="toast-notification">{{ toast.message }}</div>
    </transition>

    <div class="table-wrapper">
      <table class="dokumen-table">
        <thead>
          <tr>
            <th>Nama Dokumen</th>
            <th>Tipe</th>
            <th>Deskripsi</th>
            <th>Dibagikan ke</th>
            <th>Tanggal Upload</th>
            <th class="th-actions">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="doc in documents" :key="doc.ID" class="table-row">
            <td class="td-name">{{ doc.nama_dokumen }}</td>
            <td>
              <span class="tipe-badge" :class="doc.tipe_dokumen">{{ doc.tipe_dokumen }}</span>
            </td>
            <td class="td-desc">{{ doc.deskripsi || '-' }}</td>
            <td>
              <span v-if="doc.share_mode === 'all'" class="share-badge all">Semua Role</span>
              <span v-else class="share-badge specific">
                {{ sharedToNames(doc.shared_to) }}
              </span>
            </td>
            <td class="td-date">{{ formatDate(doc.CreatedAt) }}</td>
            <td class="td-actions">
              <button class="btn-icon detail" @click="showDetail = true; detailDoc = doc" title="Detail">&#128269;</button>
              <a :href="fileUrl(doc.file_path)" target="_blank" class="btn-icon view" title="Download">&#128229;</a>
              <button class="btn-icon edit" @click="editDoc(doc)" title="Edit">&#9998;&#65039;</button>
              <button class="btn-icon delete" @click="deleteDoc(doc.ID)" title="Hapus">&#128465;&#65039;</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="!documents.length" class="empty-state">
        <div class="empty-icon">&#128196;</div>
        <p>Belum ada dokumen</p>
        <button class="btn-add" @click="showForm = true">Upload Dokumen</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { documentAPI } from '../api/document'
import { userAPI } from '../api/user'
useHead({
  title: 'Dokumen',
  meta: [
    { name: 'description', content: 'Kelola dokumen Ganesha Energi' },
  ],
})

const documents = ref([])
const showForm = ref(false)
const editing = ref(false)
const editId = ref(null)
const loading = ref(false)
const error = ref('')
const allUsers = ref([])
const fileInput = ref(null)

const showDetail = ref(false)
const detailDoc = ref(null)
const toast = reactive({ visible: false, message: '' })
let toastTimer = null

function showToast(msg) {
  toast.message = msg
  toast.visible = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.visible = false }, 2000)
}

const form = reactive({
  nama_dokumen: '',
  tipe_dokumen: '',
  file: null,
  deskripsi: '',
  share_mode: 'all',
  shared_to: [],
})

const fileAccept = computed(() => {
  const map = { PDF: '.pdf', Excel: '.xls,.xlsx', Word: '.doc,.docx', JPG: '.jpg,.jpeg', PNG: '.png' }
  return map[form.tipe_dokumen] || ''
})

const usersByRole = computed(() => {
  const roles = ['Super Admin', 'Administrasi', 'Teknisi', 'Logistic']
  return roles.map(role => ({
    role,
    users: allUsers.value.filter(u => u.role === role),
  }))
})

function sharedToNames(sharedTo) {
  if (!sharedTo) return '-'
  const ids = sharedTo.split(',').map(Number)
  return ids.map(id => {
    const u = allUsers.value.find(u => u.ID === id)
    return u ? u.name : id
  }).join(', ') || '-'
}

function fileUrl(path) {
  return '/' + path.replace(/\\/g, '/')
}

function onFileChange(e) {
  form.file = e.target.files[0] || null
}

function removeFile() {
  form.file = null
  if (fileInput.value) fileInput.value.value = ''
}

function closeForm() {
  showForm.value = false
  editing.value = false
  editId.value = null
  form.nama_dokumen = ''
  form.tipe_dokumen = ''
  form.file = null
  form.deskripsi = ''
  form.share_mode = 'all'
  form.shared_to = []
  if (fileInput.value) fileInput.value.value = ''
}

function editDoc(doc) {
  editing.value = true
  editId.value = doc.ID
  form.nama_dokumen = doc.nama_dokumen
  form.tipe_dokumen = doc.tipe_dokumen
  form.file = null
  form.deskripsi = doc.deskripsi || ''
  form.share_mode = doc.share_mode || 'all'
  form.shared_to = (doc.shared_to || '').split(',').map(Number).filter(Boolean)
  showForm.value = true
}

async function handleSubmit() {
  loading.value = true
  error.value = ''
  try {
    if (editing.value) {
      const data = {
        nama_dokumen: form.nama_dokumen,
        tipe_dokumen: form.tipe_dokumen,
        deskripsi: form.deskripsi,
        share_mode: form.share_mode,
        shared_to: form.shared_to.join(','),
      }
      await documentAPI.update(editId.value, data)
      showToast('Dokumen berhasil diperbarui')
    } else {
      const fd = new FormData()
      fd.append('nama_dokumen', form.nama_dokumen)
      fd.append('tipe_dokumen', form.tipe_dokumen)
      fd.append('deskripsi', form.deskripsi)
      fd.append('share_mode', form.share_mode)
      fd.append('shared_to', form.shared_to.join(','))
      if (form.file) fd.append('file', form.file)
      await documentAPI.create(fd)
      showToast('Dokumen berhasil diupload')
    }
    closeForm()
    await loadDocuments()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    loading.value = false
  }
}

async function deleteDoc(id) {
  if (!confirm('Yakin ingin menghapus dokumen ini?')) return
  try {
    await documentAPI.delete(id)
    showToast('Dokumen berhasil dihapus')
    await loadDocuments()
  } catch (err) {
    error.value = 'Gagal menghapus data'
  }
}

async function loadDocuments() {
  try {
    const res = await documentAPI.getAll()
    documents.value = res.data.documents
  } catch (err) {
    error.value = 'Gagal memuat data'
  }
}

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleDateString('id-ID', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

onMounted(async () => {
  loadDocuments()
  try {
    const res = await userAPI.getAll()
    allUsers.value = res.data.users
  } catch { /* ignore */ }
})
</script>

<style scoped>
.dokumen-page {
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
  font-size: 18px;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.dokumen-form {
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

.share-select {
  cursor: pointer;
}

.user-checkboxes {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 240px;
  overflow-y: auto;
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

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--text-secondary);
  font-size: 13px;
  cursor: pointer;
  padding: 3px 0;
}

.checkbox-label input[type="checkbox"] {
  width: 16px;
  height: 16px;
  accent-color: #667eea;
}

.no-users {
  color: var(--text-dim);
  font-size: 12px;
  font-style: italic;
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

.table-wrapper {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  overflow-x: auto;
  animation: fadeIn 0.5s ease;
}

.dokumen-table {
  width: 100%;
  border-collapse: collapse;
}

.dokumen-table thead {
  background: var(--table-header-bg);
}

.dokumen-table th {
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
  width: 120px;
}

.table-row {
  transition: background 0.2s;
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
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.td-date {
  color: var(--text-secondary);
}

.tipe-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.tipe-badge.PDF { background: rgba(255, 77, 77, 0.15); color: #ff4d4d; }
.tipe-badge.Excel { background: rgba(81, 207, 102, 0.15); color: #51cf66; }
.tipe-badge.Word { background: rgba(102, 126, 234, 0.15); color: #667eea; }
.tipe-badge.JPG { background: rgba(255, 193, 7, 0.15); color: #ffc107; }
.tipe-badge.PNG { background: rgba(255, 159, 67, 0.15); color: #ff9f43; }

.share-badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
}

.share-badge.all {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.share-badge.specific {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
  max-width: 150px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  color: var(--text-secondary);
}

.btn-icon:hover {
  background: var(--hover-bg-strong);
}

.btn-icon.view:hover { background: rgba(102, 126, 234, 0.15); }
.btn-icon.edit:hover { background: rgba(81, 207, 102, 0.15); }
.btn-icon.delete:hover { background: rgba(255, 107, 107, 0.15); }

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

.detail-body {
  padding: 20px 24px;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 16px;
}

.detail-row label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-row span {
  font-size: 14px;
  color: var(--text-primary);
}

.detail-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid var(--card-border-light);
}

.detail-actions .btn-save {
  text-decoration: none;
  text-align: center;
}

.preview-row .pdf-embed {
  width: 100%;
  height: 400px;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--card-border-light);
}

.preview-row .pdf-frame {
  width: 100%;
  height: 100%;
  border: none;
}

.preview-row .img-preview {
  max-width: 100%;
  max-height: 400px;
  border-radius: 8px;
  object-fit: contain;
  border: 1px solid var(--card-border-light);
}
</style>
