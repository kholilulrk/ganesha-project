<template>
  <div class="pengguna-page">
    <div class="page-header">
      <div>
        <h1>Pengguna</h1>
        <p>Daftar seluruh pengguna terdaftar</p>
      </div>
      <button v-if="isSuperAdmin" class="btn-add" @click="showAddForm">
        <span>+</span> Tambah Pengguna
      </button>
    </div>

    <div class="table-wrapper">
      <table class="user-table">
        <thead>
          <tr>
            <th>Nama</th>
            <th>Username</th>
            <th>Role</th>
            <th>Telepon</th>
            <th>Daftar Pada</th>
            <th v-if="isSuperAdmin" class="th-actions">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in users" :key="u.ID" class="table-row">
            <td class="td-name">{{ u.name }}</td>
            <td>{{ u.username }}</td>
            <td>
              <span class="role-badge" :class="u.role">{{ u.role }}</span>
            </td>
            <td>{{ u.phone || '-' }}</td>
            <td class="td-date">{{ formatDate(u.CreatedAt) }}</td>
            <td v-if="isSuperAdmin" class="td-actions">
              <button class="btn-icon edit" @click="editUser(u)" title="Edit">&#9998;&#65039;</button>
              <button class="btn-icon delete" @click="deleteUser(u.ID)" title="Hapus">&#128465;&#65039;</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <transition name="modal-fade">
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editId ? 'Edit Pengguna' : 'Tambah Pengguna' }}</h2>
            <button class="btn-close" @click="closeForm">&times;</button>
          </div>
          <form @submit.prevent="handleSubmit" class="user-form">
            <div class="form-group">
              <label>Nama</label>
              <input v-model="form.name" type="text" placeholder="Nama lengkap" required />
            </div>
            <div class="form-group">
              <label>Username</label>
              <input v-model="form.username" type="text" placeholder="Username" required />
            </div>
            <div class="form-group">
              <label>Role</label>
              <select v-model="form.role" required>
                <option value="Administrasi">Administrasi</option>
                <option value="Teknisi">Teknisi</option>
                <option value="Logistic">Logistic</option>
              </select>
            </div>
            <div class="form-group">
              <label>Nomor Telepon</label>
              <input v-model="form.phone" type="text" placeholder="Nomor telepon" />
            </div>
            <div class="form-group">
              <label>Password <span class="muted">{{ editId ? '(kosongkan jika tidak diganti)' : '' }}</span></label>
              <input v-model="form.password" type="password" :placeholder="editId ? 'Password baru' : 'Password'" :required="!editId" />
            </div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="loading">
                <span v-if="loading" class="spinner-sm" />
                <span v-else>Simpan</span>
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
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { userAPI } from '../api/user'
import { useAuthStore } from '../stores/auth'
useHead({
  title: 'Pengguna',
  meta: [
    { name: 'description', content: 'Kelola pengguna Ganesha Energi' },
  ],
})

const auth = useAuthStore()
const isSuperAdmin = computed(() => auth.user?.role === 'Super Admin')

const users = ref([])
const showForm = ref(false)
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
  name: '',
  username: '',
  role: '',
  phone: '',
  password: '',
})

function showAddForm() {
  editId.value = null
  form.name = ''
  form.username = ''
  form.role = ''
  form.phone = ''
  form.password = ''
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editId.value = null
  form.name = ''
  form.username = ''
  form.role = ''
  form.phone = ''
  form.password = ''
}

function editUser(u) {
  editId.value = u.ID
  form.name = u.name
  form.username = u.username
  form.role = u.role
  form.phone = u.phone || ''
  form.password = ''
  showForm.value = true
}

async function handleSubmit() {
  loading.value = true
  error.value = ''
  try {
    const data = {
      name: form.name,
      username: form.username,
      role: form.role,
      phone: form.phone,
      password: form.password,
    }
    if (editId.value) {
      if (!data.password) delete data.password
      await userAPI.update(editId.value, data)
      showToast('Pengguna berhasil diperbarui')
    } else {
      await userAPI.create(data)
      showToast('Pengguna berhasil ditambahkan')
    }
    closeForm()
    await loadUsers()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    loading.value = false
  }
}

async function deleteUser(id) {
  if (!confirm('Yakin ingin menghapus pengguna ini?')) return
  try {
    await userAPI.delete(id)
    showToast('Pengguna berhasil dihapus')
    await loadUsers()
  } catch (err) {
    error.value = 'Gagal menghapus data'
  }
}

async function loadUsers() {
  try {
    const res = await userAPI.getAll()
    users.value = res.data.users
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

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.pengguna-page {
  padding: 24px;
  max-width: 900px;
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

.table-wrapper {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  overflow-x: auto;
  animation: fadeIn 0.5s ease;
}

.user-table {
  width: 100%;
  border-collapse: collapse;
}

.user-table thead {
  background: var(--table-header-bg);
}

.user-table th {
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

.role-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.role-badge.Super\ Admin {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.role-badge.Administrasi {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.role-badge.Teknisi {
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.role-badge.Logistic {
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

.btn-icon.edit:hover {
  background: rgba(102, 126, 234, 0.15);
}

.btn-icon.delete:hover {
  background: rgba(255, 107, 107, 0.15);
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

.user-form {
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

.muted {
  color: var(--text-dim);
  font-size: 12px;
  font-weight: 400;
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
