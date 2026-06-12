<template>
  <div class="home-wrapper">
    <div class="home-content">
      <div class="logo-big"><img class="logo-img" src="/logo.png" alt="Ganesha" /></div>
      <h1>Ganesha Management System</h1>
      <p>Sistem manajemen untuk Administrasi, Teknisi, dan Logistic</p>
      <div class="actions">
        <router-link to="/auth" class="btn-primary">Mulai</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useHead } from '@unhead/vue'
useHead({
  title: 'Ganesha Energi',
  meta: [
    { name: 'description', content: 'Sistem manajemen pekerjaan Ganesha Energi untuk Administrasi, Teknisi, dan Logistic' },
    { property: 'og:title', content: 'Ganesha Energi' },
    { property: 'og:description', content: 'Sistem manajemen pekerjaan untuk Administrasi, Teknisi, dan Logistic' },
    { property: 'og:type', content: 'website' },
  ],
})
</script>

<style scoped>
.home-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-gradient);
  font-family: 'Inter', sans-serif;
  color: var(--text-primary);
  text-align: center;
  padding: 20px;
  transition: background 0.3s ease;
}

.home-content {
  animation: fadeUp 0.8s ease-out;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

.logo-big {
  width: 96px;
  height: 96px;
  margin: 0 auto 24px;
  background: linear-gradient(135deg, #4F46E5, #7C3AED);
  border-radius: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  animation: float 3s ease-in-out infinite;
}

.logo-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

h1 {
  font-size: 28px;
  margin-bottom: 12px;
}

p {
  color: var(--text-secondary);
  font-size: 16px;
  margin-bottom: 32px;
}

.actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.btn-primary {
  padding: 14px 40px;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  text-decoration: none;
  font-weight: 600;
  font-size: 15px;
  transition: transform 0.2s, box-shadow 0.2s;
  display: inline-block;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
}
</style>
