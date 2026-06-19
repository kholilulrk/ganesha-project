<template>
  <div class="company-page">
    <div v-if="loading" class="loading-state">Memuat...</div>
    <div v-else-if="!profile" class="empty-state">
      <h1>Company Profile</h1>
      <p>Belum ada data profile perusahaan.</p>
    </div>
    <template v-else>
      <!-- Hero -->
      <section class="hero" :style="heroStyle">
        <div class="hero-overlay"></div>
        <div class="hero-content">
          <h1>{{ profile.company_name }}</h1>
          <p>{{ profile.tagline }}</p>
        </div>
      </section>

      <!-- About -->
      <section class="about section">
        <div class="container">
          <div class="about-grid">
            <div class="about-text">
              <h2>{{ profile.about_title || 'Tentang Kami' }}</h2>
              <p>{{ profile.about_desc }}</p>
            </div>
            <div v-if="profile.about_image" class="about-image">
              <img :src="imgUrl(profile.about_image)" :alt="profile.company_name" />
            </div>
          </div>
        </div>
      </section>

      <!-- Services -->
      <section class="services section">
        <div class="container">
          <h2>Layanan</h2>
          <div class="services-grid">
            <div v-for="s in profile.services" :key="s.ID" class="service-card">
              <div class="service-icon">{{ s.icon || '⚡' }}</div>
              <h3>{{ s.title }}</h3>
              <p>{{ s.description }}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Partners -->
      <section class="partners section">
        <div class="container">
          <h2>Kerjasama</h2>
          <div class="partners-grid">
            <div v-for="p in profile.partners" :key="p.ID" class="partner-card">
              <div v-if="p.logo" class="partner-logo">
                <img :src="imgUrl(p.logo)" :alt="p.name" />
              </div>
              <h3>{{ p.name }}</h3>
              <p>{{ p.description }}</p>
              <a v-if="p.website" :href="p.website" target="_blank" class="partner-link">Kunjungi</a>
            </div>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { companyAPI } from '../api/company'

useHead({
  title: 'Company Profile',
})

const profile = ref(null)
const loading = ref(true)

function imgUrl(val) {
  if (!val) return ''
  const path = val.replace(/\\/g, '/')
  if (path.startsWith('uploads/')) return '/' + path
  return val
}

const heroStyle = computed(() => {
  if (!profile.value?.hero_image) return {}
  return { backgroundImage: `url(${imgUrl(profile.value.hero_image)})` }
})

onMounted(async () => {
  try {
    const res = await companyAPI.getProfile()
    profile.value = res.data.profile
  } catch {
    profile.value = null
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.company-page {
  min-height: 100vh;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  color: var(--text-muted);
  font-size: 18px;
}

.hero {
  position: relative;
  min-height: 70vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
  background-size: cover;
  background-position: center;
  overflow: hidden;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
}

.hero-content {
  position: relative;
  text-align: center;
  color: #fff;
  z-index: 1;
  padding: 24px;
}

.hero-content h1 {
  font-size: 48px;
  font-weight: 800;
  margin-bottom: 16px;
}

.hero-content p {
  font-size: 20px;
  opacity: 0.9;
  max-width: 600px;
  margin: 0 auto;
}

.section {
  padding: 80px 24px;
}

.container {
  max-width: 1100px;
  margin: 0 auto;
}

.section h2 {
  font-size: 32px;
  font-weight: 700;
  text-align: center;
  margin-bottom: 48px;
  color: var(--text-primary);
}

.about {
  background: var(--bg-primary);
}

.about-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 48px;
  align-items: center;
}

.about-text h2 {
  text-align: left;
  margin-bottom: 20px;
}

.about-text p {
  font-size: 16px;
  line-height: 1.8;
  color: var(--text-secondary);
  white-space: pre-line;
}

.about-image img {
  width: 100%;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

.services {
  background: var(--bg-secondary);
}

.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

.service-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 32px 24px;
  text-align: center;
  transition: transform 0.2s, box-shadow 0.2s;
}

.service-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.1);
}

.service-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.service-card h3 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--text-primary);
}

.service-card p {
  font-size: 14px;
  color: var(--text-secondary);
  line-height: 1.6;
}

.partners {
  background: var(--bg-primary);
}

.partners-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 24px;
}

.partner-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 32px 24px;
  text-align: center;
  transition: transform 0.2s;
}

.partner-card:hover {
  transform: translateY(-4px);
}

.partner-logo {
  width: 80px;
  height: 80px;
  margin: 0 auto 16px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.partner-logo img {
  max-width: 100%;
  max-height: 100%;
  border-radius: 12px;
}

.partner-card h3 {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--text-primary);
}

.partner-card p {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.5;
  margin-bottom: 12px;
}

.partner-link {
  display: inline-block;
  padding: 6px 16px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  text-decoration: none;
}

@media (max-width: 768px) {
  .hero-content h1 { font-size: 32px; }
  .hero-content p { font-size: 16px; }
  .about-grid { grid-template-columns: 1fr; }
  .section { padding: 48px 16px; }
  .section h2 { font-size: 24px; margin-bottom: 32px; }
}
</style>
