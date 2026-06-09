<template>
  <div class="profile-wrapper">
    <div v-if="loading" class="loading">Memuat...</div>
    <div v-else class="profile-layout">
      <div class="profile-card">
        <div class="avatar-wrapper">
          <div v-if="!form.photoPreview" class="avatar" :style="{ background: avatarGradient }">
            {{ nameInitial }}
          </div>
          <img v-else class="avatar-img" :src="form.photoPreview" alt="Preview" />
          <label class="avatar-overlay" @click="triggerFileInput">
            <span>Ganti Foto</span>
          </label>
          <input ref="fileInput" type="file" accept="image/*" class="hidden-input" @change="onFileChange" />
        </div>
        <h2>{{ form.name || user?.name }}</h2>
        <div class="badge" :class="roleClass">{{ user?.role }}</div>
      </div>

      <div class="profile-form">
        <div v-if="error" class="alert alert-error">{{ error }}</div>
        <div v-if="success" class="alert alert-success">{{ success }}</div>

        <div class="form-group">
          <label>Nama Lengkap</label>
          <input v-model="form.name" type="text" placeholder="Nama lengkap" />
        </div>
        <div class="form-group">
          <label>Username</label>
          <input v-model="form.username" type="text" placeholder="Username" />
        </div>
        <div class="form-group">
          <label>Nomor HP</label>
          <input v-model="form.phone" type="text" placeholder="Nomor HP" />
        </div>
        <div class="form-group">
          <label>Password Baru (kosongkan jika tidak diubah)</label>
          <input v-model="form.password" type="password" placeholder="Password baru" />
        </div>
        <div class="form-group">
          <label>Konfirmasi Password Baru</label>
          <input v-model="form.passwordConfirm" type="password" placeholder="Konfirmasi password" />
        </div>
        <div class="form-actions">
          <button class="btn-save" :disabled="saving" @click="saveProfile">
            {{ saving ? 'Menyimpan...' : 'Simpan' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useHead } from '@unhead/vue'
import { authAPI } from '../api/auth'
useHead({
  title: 'Profil',
  meta: [
    { name: 'description', content: 'Profil pengguna Ganesha Energi' },
  ],
})

const auth = useAuthStore()
const user = computed(() => auth.user)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const fileInput = ref(null)

const form = ref({
  name: '',
  username: '',
  phone: '',
  password: '',
  passwordConfirm: '',
  photo: null,
  photoPreview: '',
})

const nameInitial = computed(() => {
  return form.value.name?.charAt(0)?.toUpperCase() || user.value?.name?.charAt(0) || '?'
})

const roleClass = computed(() => {
  const r = user.value?.role || ''
  return r.toLowerCase().replace(/\s+/g, '-')
})

const avatarGradient = computed(() => {
  const gradients = [
    'linear-gradient(135deg, #667eea, #764ba2)',
    'linear-gradient(135deg, #f093fb, #f5576c)',
    'linear-gradient(135deg, #4facfe, #00f2fe)',
    'linear-gradient(135deg, #43e97b, #38f9d7)',
    'linear-gradient(135deg, #fa709a, #fee140)',
    'linear-gradient(135deg, #a18cd1, #fbc2eb)',
  ]
  const idx = (user.value?.id || 1) % gradients.length
  return gradients[idx]
})

function triggerFileInput() {
  fileInput.value?.click()
}

function onFileChange(e) {
  const f = e.target.files[0]
  if (!f) return
  form.value.photo = f
  const reader = new FileReader()
  reader.onload = (ev) => {
    form.value.photoPreview = ev.target.result
  }
  reader.readAsDataURL(f)
}

async function saveProfile() {
  error.value = ''
  success.value = ''

  if (form.value.password && form.value.password !== form.value.passwordConfirm) {
    error.value = 'Password dan konfirmasi tidak cocok'
    return
  }

  saving.value = true
  try {
    const fd = new FormData()
    if (form.value.name) fd.append('name', form.value.name)
    if (form.value.username) fd.append('username', form.value.username)
    if (form.value.phone) fd.append('phone', form.value.phone)
    if (form.value.password) fd.append('password', form.value.password)
    if (form.value.photo) fd.append('photo', form.value.photo)

    const res = await authAPI.updateProfile(fd)
    auth.user = res.data.user
    localStorage.setItem('user', JSON.stringify(res.data.user))
    success.value = 'Profil berhasil diperbarui'
    form.value.password = ''
    form.value.passwordConfirm = ''
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan profil'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    const res = await authAPI.getProfile()
    const u = res.data.user
    form.value.name = u.name || ''
    form.value.username = u.username || ''
    form.value.phone = u.phone || ''
    if (u.photo) {
      form.value.photoPreview = u.photo
    }
    auth.user = u
    localStorage.setItem('user', JSON.stringify(u))
  } catch (err) {
    error.value = 'Gagal memuat profil'
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.profile-wrapper {
  min-height: 100vh;
  background: var(--bg-gradient);
  font-family: 'Inter', sans-serif;
  padding: 80px 20px 20px;
  transition: background 0.3s ease;
}
.loading {
  text-align: center;
  padding-top: 60px;
  color: var(--text-secondary);
}
.profile-layout {
  max-width: 500px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.profile-card {
  background: var(--card-bg);
  backdrop-filter: blur(20px);
  border: 1px solid var(--card-border);
  border-radius: 24px;
  padding: 40px 32px 32px;
  text-align: center;
  color: var(--text-primary);
  animation: cardIn 0.6s ease-out;
  position: relative;
}
@keyframes cardIn {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}
.avatar-wrapper {
  position: relative;
  width: 100px;
  height: 100px;
  margin: 0 auto 16px;
  border-radius: 50%;
  overflow: hidden;
  cursor: pointer;
}
.avatar, .avatar-img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
}
.avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  font-weight: 700;
  color: #fff;
}
.avatar-overlay {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
  cursor: pointer;
}
.avatar-wrapper:hover .avatar-overlay {
  opacity: 1;
}
.avatar-overlay span {
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  text-align: center;
}
.hidden-input {
  display: none;
}
.profile-card h2 {
  font-size: 22px;
  margin-bottom: 8px;
}
.badge {
  display: inline-block;
  padding: 4px 14px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.badge.super-admin { background: rgba(255, 193, 7, 0.2); color: #ffc107; }
.badge.administrasi { background: rgba(102, 126, 234, 0.2); color: #667eea; }
.badge.teknisi { background: rgba(81, 207, 102, 0.2); color: #51cf66; }
.badge.logistic { background: rgba(255, 107, 107, 0.2); color: #ff6b6b; }

.profile-form {
  background: var(--card-bg);
  backdrop-filter: blur(20px);
  border: 1px solid var(--card-border);
  border-radius: 24px;
  padding: 32px;
  color: var(--text-primary);
  animation: cardIn 0.6s ease-out 0.1s both;
}
.form-group {
  margin-bottom: 16px;
}
.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  margin-bottom: 6px;
}
.form-group input {
  width: 100%;
  padding: 10px 14px;
  border-radius: 10px;
  border: 1px solid var(--card-border-light);
  background: var(--bg-primary);
  color: var(--text-primary);
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}
.form-group input:focus {
  border-color: #667eea;
}
.form-actions {
  margin-top: 24px;
}
.btn-save {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}
.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.alert {
  padding: 12px 16px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 16px;
}
.alert-error {
  background: rgba(255, 77, 77, 0.15);
  color: #ff4d4d;
  border: 1px solid rgba(255, 77, 77, 0.3);
}
.alert-success {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
  border: 1px solid rgba(81, 207, 102, 0.3);
}
</style>
