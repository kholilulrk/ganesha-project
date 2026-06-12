<template>
  <div class="auth-wrapper">
    <div class="auth-container">
      <div class="auth-card">
        <div class="brand">
          <div class="logo">⚡</div>
          <h1>Ganesha</h1>
          <p>Management System</p>
        </div>

        <div class="tabs">
          <button
            :class="['tab', { active: tab === 'login' }]"
            @click="switchTab('login')"
          >
            Masuk
          </button>
          <button
            :class="['tab', { active: tab === 'register' }]"
            @click="switchTab('register')"
          >
            Daftar
          </button>
          <div class="tab-slider" :style="{ left: tab === 'login' ? '0%' : '50%' }" />
        </div>

        <transition name="fade-slide" mode="out-in">
          <form v-if="tab === 'login'" key="login" @submit.prevent="handleLogin" class="auth-form">
            <div class="input-group">
              <label>Username</label>
              <div class="input-field">
                <span class="icon">👤</span>
                <input v-model="loginForm.username" type="text" placeholder="Masukkan username" required autocomplete="username" />
              </div>
            </div>
            <div class="input-group">
              <label>Password</label>
              <div class="input-field">
                <span class="icon">🔒</span>
                <input v-model="loginForm.password" type="password" placeholder="Masukkan password" required autocomplete="current-password" />
              </div>
            </div>
            <button type="submit" class="btn-submit" :disabled="loading">
              <span v-if="loading" class="spinner" />
              <span v-else>Masuk</span>
            </button>
            <p v-if="loginError" class="error-msg">{{ loginError }}</p>
          </form>

          <form v-else key="register" @submit.prevent="handleRegister" class="auth-form">
            <div class="input-group">
              <label>Nama Lengkap</label>
              <div class="input-field">
                <span class="icon">📝</span>
                <input v-model="registerForm.name" type="text" placeholder="Nama lengkap" required />
              </div>
            </div>
            <div class="input-group">
              <label>Role</label>
              <div class="input-field">
                <span class="icon">🏷️</span>
                <select v-model="registerForm.role" required>
                  <option value="" disabled>Pilih role</option>
                  <option value="Administrasi">Administrasi</option>
                  <option value="Teknisi">Teknisi</option>
                  <option value="Logistic">Logistic</option>
                </select>
              </div>
            </div>
            <div class="input-group">
              <label>Username</label>
              <div class="input-field">
                <span class="icon">👤</span>
                <input v-model="registerForm.username" type="text" placeholder="Buat username" required autocomplete="off" />
              </div>
            </div>
            <div class="input-group">
              <label>Password</label>
              <div class="input-field">
                <span class="icon">🔒</span>
                <input v-model="registerForm.password" type="password" placeholder="Minimal 6 karakter" required minlength="6" autocomplete="new-password" />
              </div>
            </div>
            <button type="submit" class="btn-submit" :disabled="loading">
              <span v-if="loading" class="spinner" />
              <span v-else>Daftar</span>
            </button>
            <p v-if="registerSuccess" class="success-msg">{{ registerSuccess }}</p>
            <p v-if="registerError" class="error-msg">{{ registerError }}</p>
          </form>
        </transition>
      </div>

      <div class="decor-circle c1" />
      <div class="decor-circle c2" />
      <div class="decor-circle c3" />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
useHead({
  title: 'Masuk atau Daftar',
  meta: [
    { name: 'description', content: 'Masuk atau daftar akun Ganesha Energi' },
  ],
})

const auth = useAuthStore()
const router = useRouter()

const tab = ref('login')
const loading = ref(false)
const loginError = ref('')
const registerError = ref('')
const registerSuccess = ref('')

const loginForm = reactive({
  username: '',
  password: '',
})

const registerForm = reactive({
  name: '',
  role: '',
  username: '',
  password: '',
})

function switchTab(t) {
  tab.value = t
  loginError.value = ''
  registerError.value = ''
  registerSuccess.value = ''
}

async function handleLogin() {
  loading.value = true
  loginError.value = ''
  try {
    await auth.login({ username: loginForm.username, password: loginForm.password })
    router.push('/dashboard')
  } catch (err) {
    loginError.value = err.response?.data?.error || 'Login gagal'
  } finally {
    loading.value = false
  }
}

async function handleRegister() {
  loading.value = true
  registerError.value = ''
  registerSuccess.value = ''
  try {
    await auth.register({
      name: registerForm.name,
      role: registerForm.role,
      username: registerForm.username,
      password: registerForm.password,
    })
    registerSuccess.value = 'Pendaftaran berhasil! Silakan masuk.'
    registerForm.name = ''
    registerForm.role = ''
    registerForm.username = ''
    registerForm.password = ''
    setTimeout(() => { tab.value = 'login' }, 1500)
  } catch (err) {
    registerError.value = err.response?.data?.error || 'Pendaftaran gagal'
  } finally {
    loading.value = false
  }
}
</script>

<style>
.auth-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-gradient);
  font-family: 'Inter', sans-serif;
  overflow: hidden;
  position: relative;
  transition: background 0.3s ease;
}

.auth-container {
  position: relative;
  width: 100%;
  max-width: 440px;
  padding: 20px;
  z-index: 1;
}

.auth-card {
  background: var(--card-bg);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid var(--card-border);
  border-radius: 24px;
  padding: 40px 32px;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
  animation: cardIn 0.8s ease-out;
}

@keyframes cardIn {
  from {
    opacity: 0;
    transform: translateY(40px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.brand {
  text-align: center;
  margin-bottom: 32px;
}

.logo {
  width: 64px;
  height: 64px;
  margin: 0 auto 16px;
  background: linear-gradient(135deg, #4F46E5, #7C3AED);
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
  color: #fff;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.brand h1 {
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 700;
  letter-spacing: -0.5px;
}

.brand p {
  color: var(--text-secondary);
  font-size: 14px;
  margin-top: 4px;
}

.tabs {
  display: flex;
  position: relative;
  background: var(--input-bg);
  border-radius: 12px;
  padding: 4px;
  margin-bottom: 28px;
}

.tab {
  flex: 1;
  padding: 10px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  position: relative;
  z-index: 1;
  transition: color 0.3s;
  font-family: 'Inter', sans-serif;
}

.tab.active {
  color: #fff;
}

.tab-slider {
  position: absolute;
  top: 4px;
  bottom: 4px;
  width: calc(50% - 4px);
  background: linear-gradient(135deg, #667eea, #764ba2);
  border-radius: 10px;
  transition: left 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 0;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.input-group label {
  color: var(--text-secondary);
  font-size: 13px;
  font-weight: 500;
  margin-bottom: 6px;
  display: block;
}

.input-field {
  display: flex;
  align-items: center;
  background: var(--input-bg);
  border: 1px solid var(--input-border);
  border-radius: 12px;
  padding: 0 14px;
  transition: border-color 0.3s, box-shadow 0.3s;
}

.input-field:focus-within {
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
}

.input-field .icon {
  font-size: 16px;
  margin-right: 10px;
  opacity: 0.6;
}

.input-field input,
.input-field select {
  width: 100%;
  padding: 14px 0;
  border: none;
  background: transparent;
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
}

.input-field select {
  cursor: pointer;
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
}

.input-field select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.input-field input::placeholder {
  color: var(--text-dim);
}

.btn-submit {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  font-family: 'Inter', sans-serif;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
}

.btn-submit:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
}

.btn-submit:active:not(:disabled) {
  transform: translateY(0);
}

.btn-submit:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-msg {
  color: #ff6b6b;
  font-size: 13px;
  text-align: center;
  margin-top: 4px;
}

.success-msg {
  color: #51cf66;
  font-size: 13px;
  text-align: center;
  margin-top: 4px;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.35s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateX(20px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateX(-20px);
}

.decor-circle {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.4;
  animation: pulse 6s ease-in-out infinite;
  pointer-events: none;
}

.c1 {
  width: 300px;
  height: 300px;
  background: #667eea;
  top: -100px;
  right: -80px;
}

.c2 {
  width: 200px;
  height: 200px;
  background: #764ba2;
  bottom: -60px;
  left: -60px;
  animation-delay: -2s;
}

.c3 {
  width: 150px;
  height: 150px;
  background: #f093fb;
  top: 50%;
  left: -40px;
  animation-delay: -4s;
}

@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 0.3; }
  50% { transform: scale(1.1); opacity: 0.5; }
}
</style>
