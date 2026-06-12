<template>
  <div class="absensi-page">
    <div class="page-header">
      <h1>Data Absensi</h1>
      <p>Riwayat absensi dan lembur karyawan</p>
    </div>

    <div class="filter-bar">
      <div class="filter-group">
        <label>Tanggal</label>
        <input v-model="filterDate" type="date" class="filter-input" @change="fetchReport" />
      </div>
      <div class="filter-group">
        <label>Role</label>
        <select v-model="filterRole" class="filter-input" @change="fetchReport">
          <option value="">Semua Role</option>
          <option value="Teknisi">Teknisi</option>
          <option value="Logistic">Logistic</option>
          <option value="Administrasi">Administrasi</option>
        </select>
      </div>
      <button class="btn-refresh" @click="fetchReport">↻ Refresh</button>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner" />
      <span>Memuat data...</span>
    </div>

    <div v-else-if="error" class="error-banner">{{ error }}</div>

    <div v-else class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>No</th>
            <th>Nama</th>
            <th>Role</th>
            <th>Tipe</th>
            <th>Jam Masuk</th>
            <th>Lokasi</th>
            <th>Lembur Mulai</th>
            <th>Lembur Selesai</th>
            <th>Durasi Lembur</th>
            <th v-if="perms.can('absensi', 'edit') || perms.can('absensi', 'delete')">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!records.length">
            <td colspan="10" class="empty-row">Belum ada data absensi</td>
          </tr>
          <tr v-for="(r, i) in records" :key="r.ID" :class="rowClass(r)">
            <td>{{ i + 1 }}</td>
            <td>
              <div class="user-cell">
                <img v-if="r.user?.photo" class="user-avatar-img" :src="r.user.photo" />
                <div v-else class="user-avatar">{{ r.user?.name?.charAt(0) || '?' }}</div>
                <span>{{ r.user?.name || '-' }}</span>
              </div>
            </td>
            <td><span class="role-badge">{{ r.user?.role || '-' }}</span></td>
            <td><span class="type-badge" :class="typeClass(r)">{{ r.type_display || r.type }}</span></td>
            <td>{{ r.clock_in || '-' }}</td>
            <td>{{ locationLabel(r) }}</td>
            <td>{{ r.type === 'lembur' ? (r.lembur_start || '-') : '-' }}</td>
            <td>{{ r.lembur_end || (r.type === 'lembur' ? 'Sedang lembur' : '-') }}</td>
            <td>{{ r.durasi_lembur || '-' }}</td>
            <td v-if="perms.can('absensi', 'edit') || perms.can('absensi', 'delete')">
              <div class="action-btns">
                <button v-if="perms.can('absensi', 'edit')" class="btn-icon edit" @click="openEdit(r)" title="Edit">✏️</button>
                <button v-if="perms.can('absensi', 'delete')" class="btn-icon delete" @click="handleDelete(r)" title="Hapus">🗑️</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal Edit -->
    <transition name="modal-fade">
      <div v-if="editRecord" class="modal-overlay" @click.self="editRecord = null">
        <div class="modal-card modal-sm">
          <div class="modal-header">
            <h2>Edit Absensi</h2>
            <button class="btn-close" @click="editRecord = null">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>Tipe</label>
              <select v-model="editForm.type" class="form-input">
                <option value="hadir">Hadir</option>
                <option value="tidak_hadir">Tidak Hadir</option>
                <option value="lembur">Lembur</option>
              </select>
            </div>
            <div class="form-group">
              <label>Lokasi</label>
              <select v-model="editForm.location" class="form-input">
                <option value="kantor">Kantor</option>
                <option value="luar_kota">Luar Kota</option>
              </select>
            </div>
            <div class="form-group">
              <label>Jam Masuk</label>
              <input v-model="editForm.clock_in" type="time" class="form-input" />
            </div>
            <div class="form-group" v-if="editForm.type === 'lembur'">
              <label>Jam Mulai Lembur</label>
              <input v-model="editForm.lembur_start" type="time" class="form-input" />
            </div>
            <div class="form-group" v-if="editForm.type === 'lembur'">
              <label>Jam Selesai Lembur</label>
              <input v-model="editForm.lembur_end" type="time" class="form-input" />
            </div>
            <div class="form-group">
              <label>Alasan (jika tidak hadir)</label>
              <textarea v-model="editForm.reason" class="form-input" rows="2" />
            </div>
            <div class="form-group">
              <label>Tanggal</label>
              <input v-model="editForm.date" type="date" class="form-input" />
            </div>
            <div v-if="editError" class="error-banner">{{ editError }}</div>
            <div class="form-actions">
              <button class="btn-cancel" @click="editRecord = null">Batal</button>
              <button class="btn-save" :disabled="saving" @click="handleEditSave">
                <span v-if="saving" class="spinner-sm" />
                <span v-else>Simpan</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useHead } from '@unhead/vue'
import { useAuthStore } from '../stores/auth'
import { usePermissionStore } from '../stores/permissions'
import { attendanceAPI } from '../api/attendance'
useHead({
  title: 'Data Absensi',
  meta: [
    { name: 'description', content: 'Data absensi dan lembur karyawan Ganesha Energi' },
  ],
})

const auth = useAuthStore()
const perms = usePermissionStore()

const records = ref([])
const loading = ref(true)
const error = ref('')
const filterDate = ref(new Date().toISOString().split('T')[0])
const filterRole = ref('')

const editRecord = ref(null)
const editForm = ref({})
const saving = ref(false)
const editError = ref('')

onMounted(() => {
  fetchReport()
})

function locationLabel(r) {
  if (r.type === 'tidak_hadir') return '-'
  if (r.location === 'luar_kota') return '🚗 Luar Kota'
  return '🏢 Kantor'
}

function rowClass(r) {
  if (r.type === 'tidak_hadir') return 'row-absent'
  if (r.type === 'lembur') return 'row-overtime'
  return ''
}

function typeClass(r) {
  if (r.type === 'hadir' && r.location === 'luar_kota') return 'type-luar'
  if (r.type === 'lembur') return 'type-lembur'
  if (r.type === 'tidak_hadir') return 'type-absent'
  return 'type-hadir'
}

async function fetchReport() {
  loading.value = true
  error.value = ''
  try {
    const params = { date: filterDate.value }
    if (filterRole.value) params.role = filterRole.value
    const res = await attendanceAPI.getReport(params)
    records.value = res.data.attendance || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal memuat data'
    records.value = []
  } finally {
    loading.value = false
  }
}

function openEdit(r) {
  editRecord.value = r
  editForm.value = {
    type: r.type,
    location: r.location || 'kantor',
    clock_in: r.clock_in || '',
    clock_out: r.clock_out || '',
    lembur_start: r.lembur_start || '',
    lembur_end: r.lembur_end || '',
    reason: r.reason || '',
    date: r.date || filterDate.value,
  }
  editError.value = ''
}

async function handleEditSave() {
  saving.value = true
  editError.value = ''
  try {
    await attendanceAPI.update(editRecord.value.ID, editForm.value)
    editRecord.value = null
    await fetchReport()
  } catch (err) {
    editError.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    saving.value = false
  }
}

async function handleDelete(r) {
  if (!confirm(`Hapus absensi ${r.user?.name} tanggal ${r.date}?`)) return
  try {
    await attendanceAPI.delete(r.ID)
    await fetchReport()
  } catch (err) {
    alert(err.response?.data?.error || 'Gagal menghapus')
  }
}
</script>

<style scoped>
.absensi-page {
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

.filter-bar {
  display: flex;
  gap: 12px;
  align-items: flex-end;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-group label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
}

.filter-input {
  padding: 8px 12px;
  border: 1px solid var(--card-border);
  border-radius: 8px;
  font-size: 13px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-family: inherit;
}

.filter-input:focus {
  outline: none;
  border-color: #667eea;
}

.btn-refresh {
  padding: 8px 16px;
  border: 1px solid var(--card-border);
  border-radius: 8px;
  background: var(--card-bg);
  color: var(--text-secondary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
}

.btn-refresh:hover {
  background: var(--hover-bg);
  border-color: #667eea;
  color: #667eea;
}

.loading-state {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 40px;
  justify-content: center;
  color: var(--text-muted);
  font-size: 14px;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid var(--card-border);
  border-top-color: #667eea;
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

.table-wrap {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.data-table th {
  padding: 12px 14px;
  text-align: left;
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  color: var(--text-muted);
  border-bottom: 1px solid var(--card-border-light);
  white-space: nowrap;
  background: var(--hover-bg);
}

.data-table td {
  padding: 11px 14px;
  color: var(--text-primary);
  border-bottom: 1px solid var(--card-border-light);
  white-space: nowrap;
}

.data-table tr:last-child td {
  border-bottom: none;
}

.data-table tbody tr:hover {
  background: var(--hover-bg);
}

.data-table tbody tr.row-absent {
  background: rgba(255, 107, 107, 0.03);
}

.data-table tbody tr.row-overtime {
  background: rgba(245, 158, 11, 0.03);
}

.empty-row {
  text-align: center;
  color: var(--text-dim);
  padding: 40px !important;
  font-style: italic;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.user-avatar,
.user-avatar-img {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  flex-shrink: 0;
  object-fit: cover;
}

.user-avatar {
  background: linear-gradient(135deg, #667eea, #764ba2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
}

.role-badge {
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  background: var(--hover-bg-strong);
  color: var(--text-secondary);
}

.type-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}

.type-badge.type-hadir {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.type-badge.type-luar {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.type-badge.type-lembur {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
}

.type-badge.type-absent {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.action-btns {
  display: flex;
  gap: 4px;
}

.btn-icon {
  padding: 4px 8px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
  background: transparent;
}

.btn-icon.edit:hover {
  background: rgba(102, 126, 234, 0.1);
}

.btn-icon.delete:hover {
  background: rgba(255, 107, 107, 0.1);
}

/* Modal reuse */
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
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  animation: modalSlideIn 0.25s ease;
}

@keyframes modalSlideIn {
  from { opacity: 0; transform: translateY(20px) scale(0.97); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.modal-sm .modal-card {
  max-width: 480px;
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

.modal-body {
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

.form-input {
  padding: 10px 14px;
  border: 1px solid var(--card-border);
  border-radius: 10px;
  font-size: 14px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-family: inherit;
  width: 100%;
  box-sizing: border-box;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15);
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
  font-family: inherit;
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
  font-family: inherit;
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

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}
</style>
