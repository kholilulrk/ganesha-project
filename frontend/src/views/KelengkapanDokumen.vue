<template>
  <div class="dokumen-page">
    <div class="page-header">
      <h1>Kelengkapan Dokumen</h1>
      <p v-if="error" class="error-msg">{{ error }}</p>
    </div>

    <div class="job-selector">
      <label>Pilih Pekerjaan</label>
      <select v-model="selectedJobId" @change="loadDocuments">
        <option value="">-- Pilih Pekerjaan --</option>
        <option v-for="job in jobs" :key="job.ID" :value="job.ID">{{ job.name }}</option>
      </select>
    </div>

    <div v-if="selectedJobId" class="dokumen-content">
      <div class="doc-section">
        <h2>Dokumen Unggahan</h2>
        <div class="doc-grid">
          <div v-for="doc in docTypes" :key="doc.key" class="doc-card">
            <div class="doc-header">
              <span class="doc-label">{{ doc.label }}</span>
              <span class="doc-format">{{ doc.format }}</span>
            </div>
            <div v-if="getDocument(doc.key)" class="doc-file">
              <span class="file-name">{{ getDocument(doc.key).file_name }}</span>
              <a v-if="getDocument(doc.key)" :href="getFileUrl(getDocument(doc.key).file_path)" target="_blank" class="btn-icon-small" title="Lihat">👁</a>
              <button class="btn-icon-small danger" @click="deleteDocument(doc.key)" title="Hapus">✕</button>
            </div>
            <div class="doc-upload">
              <button class="btn-upload" @click="uploadDocument(doc.key)" :disabled="uploading === doc.key">
                <span v-if="uploading === doc.key" class="spinner-sm" />
                <span v-else>{{ getDocument(doc.key) ? 'Ganti File' : 'Upload' }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="verif-section">
        <h2>Verifikasi</h2>
        <div class="verif-grid">
          <label v-for="v in verificationSteps" :key="v.key" class="verif-check">
            <input type="checkbox" :checked="getVerification(v.key)" @change="toggleVerification(v.key, $event.target.checked)" />
            <span>{{ v.label }}</span>
          </label>
        </div>
      </div>

      <div class="progress-section">
        <h2>Progres Pekerjaan</h2>
        <select :value="progress" @change="updateProgress">
          <option value="">-- Pilih Progres --</option>
          <option v-for="s in progressOptions" :key="s" :value="s">{{ s }}</option>
        </select>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import api from '../api/client'
useHead({
  title: 'Kelengkapan Dokumen',
  meta: [
    { name: 'description', content: 'Kelengkapan dokumen pekerjaan Ganesha Energi' },
  ],
})

const jobs = ref([])
const selectedJobId = ref('')
const documents = ref([])
const verifications = ref([])
const progress = ref('')
const error = ref('')
const uploading = ref('')

const docTypes = [
  { key: 'SIK', label: 'SIK (Surat Izin Kerja)', format: 'PDF', accept: '.pdf' },
  { key: 'SPK', label: 'SPK (Surat Perintah Kerja)', format: 'PDF', accept: '.pdf' },
  { key: 'SPEKTEK', label: 'SPEKTEK (Spesifikasi Data Teknis)', format: 'PDF / Excel', accept: '.pdf,.xls,.xlsx' },
  { key: 'SPH', label: 'SPH (Surat Penawaran Harga)', format: 'PDF / Excel', accept: '.pdf,.xls,.xlsx' },
  { key: 'BAST', label: 'BAST (Berita Acara Serah Terima)', format: 'PDF', accept: '.pdf' },
  { key: 'BA_MULAI', label: 'BA Mulai', format: 'PDF', accept: '.pdf' },
]

const verificationSteps = [
  { key: 'VERIFIKASI_I', label: 'Verifikasi I' },
  { key: 'VERIFIKASI_II', label: 'Verifikasi II' },
  { key: 'VERIFIKASI_III', label: 'Verifikasi III' },
  { key: 'SEA_TRIAL', label: 'Sea Trial' },
]

const progressOptions = [
  'Pembuatan SPH', 'Pengajuan SPH', 'SPH disetujui', 'DP',
  'Survey Pekerjaan', 'Pembongkaran', 'Verifikasi I', 'Pembelian Material',
  'Proses Perbaikan', 'Verifikasi II', 'Pemasangan Material', 'Uji Coba',
  'Verifikasi III', 'Penagihan Pelunasan', 'Lunas',
]

onMounted(async () => {
  try {
    const res = await api.get('/jobs')
    jobs.value = res.data.jobs || res.data || []
  } catch {
    error.value = 'Gagal memuat daftar pekerjaan'
  }
})

function getDocument(type) {
  return documents.value.find(d => d.doc_type === type)
}

function getVerification(step) {
  const v = verifications.value.find(v => v.step === step)
  return v ? v.checked : false
}

function getFileUrl(filePath) {
  return '/' + filePath.replace(/\\/g, '/')
}

async function loadDocuments() {
  if (!selectedJobId.value) return
  error.value = ''
  try {
    const res = await api.get(`/jobs/${selectedJobId.value}/documents`)
    documents.value = res.data.documents || []
    verifications.value = res.data.verifications || []
    progress.value = res.data.progress || ''
  } catch {
    error.value = 'Gagal memuat dokumen'
  }
}

async function uploadDocument(docType) {
  const doc = docTypes.find(d => d.key === docType)
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = doc.accept
  input.onchange = async () => {
    const file = input.files[0]
    if (!file) return
    error.value = ''
    uploading.value = docType
    const form = new FormData()
    form.append('file', file)
    form.append('doc_type', docType)
    try {
      await api.post(`/jobs/${selectedJobId.value}/documents`, form)
      await loadDocuments()
    } catch (err) {
      error.value = 'Upload gagal: ' + (err.response?.data?.error || err.message)
    } finally {
      uploading.value = ''
    }
  }
  input.click()
}

async function deleteDocument(docType) {
  const doc = getDocument(docType)
  if (!doc) return
  error.value = ''
  try {
    await api.delete(`/jobs/${selectedJobId.value}/documents/${doc.id}`)
    await loadDocuments()
  } catch (err) {
    error.value = 'Gagal hapus: ' + (err.response?.data?.error || err.message)
  }
}

async function toggleVerification(step, checked) {
  error.value = ''
  try {
    await api.put(`/jobs/${selectedJobId.value}/verification`, { step, checked })
    await loadDocuments()
  } catch (err) {
    error.value = 'Gagal simpan: ' + (err.response?.data?.error || err.message)
  }
}

async function updateProgress(e) {
  const val = e.target.value
  error.value = ''
  try {
    await api.put(`/jobs/${selectedJobId.value}/progress`, { progress: val })
    progress.value = val
  } catch (err) {
    error.value = 'Gagal simpan: ' + (err.response?.data?.error || err.message)
  }
}
</script>

<style scoped>
.dokumen-page {
  padding: 24px;
  max-width: 960px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
.error-msg {
  color: #ff6b6b;
  font-size: 13px;
  margin-top: 4px;
}
.page-header h1 {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 24px;
}
.job-selector {
  margin-bottom: 24px;
}
.job-selector label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  margin-bottom: 6px;
}
.job-selector select {
  width: 100%;
  max-width: 400px;
  padding: 10px 14px;
  border-radius: 10px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  outline: none;
}
.job-selector select:focus {
  border-color: #667eea;
}
.dokumen-content {
  display: flex;
  flex-direction: column;
  gap: 28px;
}
.doc-section h2,
.verif-section h2,
.progress-section h2 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 14px;
}
.doc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}
.doc-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 14px;
}
.doc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.doc-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}
.doc-format {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
  background: var(--hover-bg);
  padding: 2px 8px;
  border-radius: 4px;
}
.doc-file {
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--hover-bg);
  padding: 6px 10px;
  border-radius: 6px;
  margin-bottom: 8px;
}
.file-name {
  flex: 1;
  font-size: 12px;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.btn-icon-small {
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  color: var(--text-muted);
  text-decoration: none;
  transition: background 0.2s;
}
.btn-icon-small:hover {
  background: var(--hover-bg);
}
.btn-icon-small.danger:hover {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}
.btn-upload {
  width: 100%;
  padding: 8px;
  border: 1px dashed var(--card-border);
  border-radius: 8px;
  background: transparent;
  color: var(--text-muted);
  font-size: 12px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.btn-upload:hover:not(:disabled) {
  border-color: #667eea;
  color: #667eea;
  background: rgba(102, 126, 234, 0.05);
}
.btn-upload:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.spinner-sm {
  width: 14px;
  height: 14px;
  border: 2px solid var(--card-border);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
.verif-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.verif-check {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 10px;
  cursor: pointer;
  font-size: 13px;
  color: var(--text-secondary);
  transition: all 0.2s;
}
.verif-check:has(input:checked) {
  border-color: #51cf66;
  background: rgba(81, 207, 102, 0.08);
  color: #51cf66;
}
.verif-check input[type="checkbox"] {
  width: 16px;
  height: 16px;
  accent-color: #51cf66;
}
.progress-section select {
  width: 100%;
  max-width: 400px;
  padding: 10px 14px;
  border-radius: 10px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  outline: none;
}
.progress-section select:focus {
  border-color: #667eea;
}
</style>
