<template>
  <div class="surat-page">
    <div class="page-header">
      <div>
        <h1>Monitoring Aktif Surat</h1>
        <p>Kelola surat aktif dan masa berlaku</p>
      </div>
      <button class="btn-add" @click="showForm = true">
        <span>+</span> Tambah Surat
      </button>
    </div>

    <transition name="modal-fade">
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editing ? 'Edit Surat' : 'Tambah Surat' }}</h2>
            <button class="btn-close" @click="closeForm">&times;</button>
          </div>
          <form @submit.prevent="handleSubmit" class="surat-form">
            <div class="form-group">
              <label>Nama Surat</label>
              <input v-model="form.nama_surat" type="text" placeholder="Nama surat" required />
            </div>
            <div class="form-group">
              <label>Start Aktif</label>
              <input v-model="form.start_aktif" type="date" required />
            </div>
            <div class="form-group">
              <label>Jenis Surat</label>
              <select v-model="form.jenis_surat" required>
                <option value="">Pilih jenis surat</option>
                <option value="SIK">SIK (Surat Izin Kerja)</option>
                <option value="SC">SC (Security Clearance)</option>
              </select>
            </div>
            <div v-if="form.jenis_surat" class="info-box">
              <strong>Masa berlaku:</strong>
              {{ form.jenis_surat === 'SIK' ? '1 bulan' : '3 bulan' }} setelah tanggal aktif
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

    <div v-if="error" class="error-banner">{{ error }}</div>

    <transition name="toast-fade">
      <div v-if="toast.visible" class="toast-notification">{{ toast.message }}</div>
    </transition>

    <div class="table-wrapper">
      <table class="surat-table">
        <thead>
          <tr>
            <th>Nama Surat</th>
            <th>Start Aktif</th>
            <th>Jenis Surat</th>
            <th>Masa Berlaku</th>
            <th>Sisa Waktu</th>
            <th class="th-actions">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="surat in surats" :key="surat.ID" class="table-row" :class="{ 'expiring': isExpiring(surat), 'expired': isExpired(surat) }">
            <td class="td-name">{{ surat.nama_surat }}</td>
            <td class="td-date">{{ formatDate(surat.start_aktif) }}</td>
            <td>
              <span class="jenis-badge" :class="surat.jenis_surat">{{ surat.jenis_surat }}</span>
            </td>
            <td class="td-date">{{ formatDate(surat.masa_berlaku) }}</td>
            <td>
              <span class="sisa-waktu" :class="{ warning: isExpiring(surat), danger: isExpired(surat) }">
                {{ sisaWaktu(surat) }}
              </span>
            </td>
            <td class="td-actions">
              <button class="btn-icon edit" @click="editSurat(surat)" title="Edit">&#9998;&#65039;</button>
              <button class="btn-icon delete" @click="deleteSurat(surat.ID)" title="Hapus">&#128465;&#65039;</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="!surats.length" class="empty-state">
        <div class="empty-icon">&#128196;</div>
        <p>Belum ada surat</p>
        <button class="btn-add" @click="showForm = true">Tambah Surat</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { suratAPI } from '../api/surat'
useHead({
  title: 'Monitoring Surat',
  meta: [
    { name: 'description', content: 'Monitoring surat aktif Ganesha Energi' },
  ],
})

const surats = ref([])
const showForm = ref(false)
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

const form = reactive({
  nama_surat: '',
  start_aktif: '',
  jenis_surat: '',
})

function closeForm() {
  showForm.value = false
  editing.value = false
  editId.value = null
  form.nama_surat = ''
  form.start_aktif = ''
  form.jenis_surat = ''
}

function editSurat(surat) {
  editing.value = true
  editId.value = surat.ID
  form.nama_surat = surat.nama_surat
  form.start_aktif = surat.start_aktif.substring(0, 10)
  form.jenis_surat = surat.jenis_surat
  showForm.value = true
}

async function handleSubmit() {
  loading.value = true
  error.value = ''
  try {
    const data = {
      nama_surat: form.nama_surat,
      start_aktif: form.start_aktif,
      jenis_surat: form.jenis_surat,
    }
    if (editing.value) {
      await suratAPI.update(editId.value, data)
      showToast('Surat berhasil diperbarui')
    } else {
      await suratAPI.create(data)
      showToast('Surat berhasil ditambahkan')
    }
    closeForm()
    await loadSurats()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    loading.value = false
  }
}

async function deleteSurat(id) {
  if (!confirm('Yakin ingin menghapus surat ini?')) return
  try {
    await suratAPI.delete(id)
    showToast('Surat berhasil dihapus')
    await loadSurats()
  } catch (err) {
    error.value = 'Gagal menghapus data'
  }
}

async function loadSurats() {
  try {
    const res = await suratAPI.getAll()
    surats.value = res.data.surats
  } catch (err) {
    error.value = 'Gagal memuat data'
  }
}

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleDateString('id-ID', {
    year: 'numeric', month: 'long', day: 'numeric',
  })
}

function isExpired(surat) {
  return new Date(surat.masa_berlaku) < new Date()
}

function isExpiring(surat) {
  if (isExpired(surat)) return false
  const now = new Date()
  const expire = new Date(surat.masa_berlaku)
  const diff = expire - now
  const days = Math.ceil(diff / (1000 * 60 * 60 * 24))
  return days <= 7
}

function sisaWaktu(surat) {
  const now = new Date()
  const expire = new Date(surat.masa_berlaku)
  const diff = expire - now
  if (diff <= 0) return 'Kadaluarsa'
  const days = Math.ceil(diff / (1000 * 60 * 60 * 24))
  if (days > 30) {
    const months = Math.floor(days / 30)
    return `${months} bulan`
  }
  return `${days} hari`
}

onMounted(() => {
  loadSurats()
})
</script>

<style scoped>
.surat-page {
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
  max-width: 460px;
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

.surat-form {
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
.form-group select:focus {
  border-color: #667eea;
}

.form-group select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.info-box {
  padding: 12px 14px;
  border-radius: 10px;
  background: rgba(102, 126, 234, 0.1);
  color: var(--text-secondary);
  font-size: 13px;
  border: 1px solid rgba(102, 126, 234, 0.2);
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

.surat-table {
  width: 100%;
  border-collapse: collapse;
}

.surat-table thead {
  background: var(--table-header-bg);
}

.surat-table th {
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
}

.table-row:hover {
  background: var(--table-row-hover);
}

.table-row.expiring {
  background: rgba(255, 193, 7, 0.06);
}

.table-row.expiring:hover {
  background: rgba(255, 193, 7, 0.12);
}

.table-row.expired {
  background: rgba(255, 107, 107, 0.06);
}

.table-row.expired:hover {
  background: rgba(255, 107, 107, 0.12);
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

.td-date {
  color: var(--text-secondary);
}

.jenis-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.jenis-badge.SIK {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.jenis-badge.SC {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.sisa-waktu {
  font-weight: 600;
  font-size: 13px;
  color: var(--text-primary);
}

.sisa-waktu.warning {
  color: #ffc107;
}

.sisa-waktu.danger {
  color: #ff6b6b;
}

.table-row.expired .td-name,
.table-row.expired .td-date {
  opacity: 0.6;
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

.btn-icon.edit:hover {
  background: rgba(102, 126, 234, 0.15);
}

.btn-icon.delete:hover {
  background: rgba(255, 107, 107, 0.15);
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
