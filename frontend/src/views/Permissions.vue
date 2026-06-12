<template>
  <div class="permissions-page">
    <div class="page-header">
      <h1>Atur Akses</h1>
      <p>Kelola izin akses per halaman untuk setiap role</p>
      <div class="header-actions">
        <button class="btn-reset" @click="resetDefaults">Reset ke Default</button>
      </div>
    </div>

    <p v-if="error" class="error-msg">{{ error }}</p>
    <p v-if="success" class="success-msg">{{ success }}</p>

    <div class="roles-grid">
      <div v-for="role in roles" :key="role.role" class="role-card">
        <div class="role-header">
          <h2>{{ role.role }}</h2>
          <span class="user-count">{{ role.count }} user</span>
        </div>

        <div v-if="selectedRole === role.role" class="perm-list">
          <div v-for="group in permissionGroups" :key="group.label" class="perm-group">
            <label class="perm-group-label">{{ group.label }}</label>
            <div class="perm-actions">
              <label v-for="act in group.actions" :key="act.value" class="perm-check">
                <input type="checkbox" :value="`${group.resource}.${act.value}`" v-model="editedPerms" />
                <span>{{ act.label }}</span>
              </label>
            </div>
          </div>
          <div class="perm-actions-row">
            <button class="btn-save" @click="savePermissions(role.role)" :disabled="saving">
              <span v-if="saving" class="spinner-sm" />
              <span v-else>Simpan</span>
            </button>
          </div>
        </div>

        <button v-else class="btn-edit" @click="editRole(role.role)">
          Atur Akses
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useHead } from '@unhead/vue'
import { permissionAPI } from '../api/permission'
useHead({
  title: 'Atur Akses',
  meta: [
    { name: 'description', content: 'Atur izin akses pengguna Ganesha Energi' },
  ],
})

const roles = ref([])
const allPermissions = ref({})
const selectedRole = ref(null)
const editedPerms = ref([])
const saving = ref(false)
const error = ref('')
const success = ref('')

const permissionGroups = [
  {
    label: 'Pekerjaan',
    resource: 'pekerjaan',
    actions: [
      { value: 'view', label: 'Lihat' },
      { value: 'create', label: 'Buat' },
      { value: 'edit', label: 'Edit' },
      { value: 'delete', label: 'Hapus' },
    ],
  },
  {
    label: 'Checklist',
    resource: 'checklist',
    actions: [
      { value: 'manage', label: 'Kelola' },
    ],
  },
  {
    label: 'Pengguna',
    resource: 'users',
    actions: [
      { value: 'view', label: 'Lihat' },
      { value: 'create', label: 'Buat' },
      { value: 'edit', label: 'Edit' },
      { value: 'delete', label: 'Hapus' },
    ],
  },
  {
    label: 'Pengumuman',
    resource: 'pengumuman',
    actions: [
      { value: 'view', label: 'Lihat' },
      { value: 'create', label: 'Buat' },
      { value: 'edit', label: 'Edit' },
      { value: 'delete', label: 'Hapus' },
    ],
  },
  {
    label: 'Vendor',
    resource: 'vendor',
    actions: [
      { value: 'view', label: 'Lihat' },
      { value: 'create', label: 'Buat' },
      { value: 'edit', label: 'Edit' },
      { value: 'delete', label: 'Hapus' },
    ],
  },
  {
    label: 'Absensi',
    resource: 'absensi',
    actions: [
      { value: 'view', label: 'Lihat Data' },
    ],
  },
]

const currentPerms = computed(() => {
  if (!selectedRole.value) return []
  return allPermissions.value[selectedRole.value] || []
})

onMounted(async () => {
  try {
    const [rolesRes, permsRes] = await Promise.all([
      permissionAPI.getRoles(),
      permissionAPI.getPermissions(),
    ])
    roles.value = rolesRes.data.roles
    const grouped = {}
    for (const p of permsRes.data.permissions) {
      const role = p.role || p.Role
      const resource = p.resource || p.Resource
      const action = p.action || p.Action
      if (!role || !resource || !action) continue
      if (!grouped[role]) grouped[role] = []
      grouped[role].push(`${resource}.${action}`)
    }
    allPermissions.value = grouped
  } catch (err) {
    error.value = 'Gagal memuat data: ' + (err.response?.data?.error || err.message)
  }
})

function editRole(role) {
  selectedRole.value = role
  editedPerms.value = [...(allPermissions.value[role] || [])]
}

async function savePermissions(role) {
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    await permissionAPI.update(role, editedPerms.value)
    allPermissions.value[role] = [...editedPerms.value]
    success.value = `Izin untuk ${role} berhasil disimpan`
    selectedRole.value = null
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    saving.value = false
  }
}

async function resetDefaults() {
  if (!confirm('Reset semua izin ke default?')) return
  error.value = ''
  success.value = ''
  try {
    await permissionAPI.reset()
    const res = await permissionAPI.getPermissions()
    const grouped = {}
    for (const p of res.data.permissions) {
      const role = p.role || p.Role
      const resource = p.resource || p.Resource
      const action = p.action || p.Action
      if (!role || !resource || !action) continue
      if (!grouped[role]) grouped[role] = []
      grouped[role].push(`${resource}.${action}`)
    }
    allPermissions.value = grouped
    success.value = 'Izin dikembalikan ke default'
    selectedRole.value = null
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal reset'
  }
}
</script>

<style scoped>
.permissions-page {
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
  align-items: flex-start;
  margin-bottom: 28px;
  flex-wrap: wrap;
  gap: 12px;
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

.header-actions {
  display: flex;
  gap: 8px;
}

.btn-reset {
  padding: 8px 16px;
  border: 1px solid var(--card-border);
  border-radius: 8px;
  background: transparent;
  color: var(--text-secondary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: all 0.2s;
}

.btn-reset:hover {
  border-color: #ff6b6b;
  color: #ff6b6b;
}

.error-msg {
  color: #ff6b6b;
  font-size: 13px;
  margin-bottom: 12px;
}

.success-msg {
  color: #51cf66;
  font-size: 13px;
  margin-bottom: 12px;
}

.roles-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.role-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 24px;
}

.role-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.role-header h2 {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
}

.user-count {
  font-size: 12px;
  color: var(--text-muted);
  background: var(--hover-bg);
  padding: 4px 10px;
  border-radius: 8px;
}

.perm-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.perm-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.perm-group-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.perm-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.perm-check {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--text-secondary);
  cursor: pointer;
}

.perm-check input[type="checkbox"] {
  width: 16px;
  height: 16px;
  accent-color: #667eea;
}

.perm-actions-row {
  display: flex;
  gap: 8px;
  padding-top: 8px;
}

.btn-edit {
  padding: 8px 20px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-edit:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102,126,234,0.3);
}

.btn-save {
  padding: 8px 20px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-save:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102,126,234,0.3);
}

.btn-save:disabled {
  opacity: 0.7;
}

.spinner-sm {
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
