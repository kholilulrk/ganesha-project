<template>
  <div class="company-page">
    <div v-if="loading" class="loading-state">
      <div class="loader"></div>
    </div>
    <div v-else-if="!profile" class="empty-state">
      <h1>Company Profile</h1>
      <p>Belum ada data profile perusahaan.</p>
    </div>
    <template v-else>
      <nav class="navbar">
        <div class="nav-inner">
          <a href="#" class="nav-brand">
            <img v-if="profile.logo" :src="imgUrl(profile.logo)" :alt="profile.company_name" class="nav-logo" />
            <span v-else class="nav-brand-text">{{ profile.company_name }}</span>
          </a>
          <div class="nav-links">
            <a href="#about" class="nav-link">Tentang</a>
            <a href="#services" class="nav-link">Layanan</a>
            <a href="#partners" class="nav-link">Mitra</a>
          </div>
        </div>
      </nav>
      <section class="hero" :style="heroStyle">
        <div class="hero-overlay"></div>
        <div class="hero-shapes">
          <div class="shape shape-1"></div>
          <div class="shape shape-2"></div>
          <div class="shape shape-3"></div>
        </div>
        <div class="hero-content">
          <div class="hero-badge">Selamat Datang di</div>
          <h1 class="hero-title">{{ profile.company_name }}</h1>
          <p class="hero-tagline">{{ profile.tagline || 'Solusi Energi Terpercaya' }}</p>
          <div class="hero-cta">
            <a href="#about" class="btn btn-primary">Jelajahi</a>
            <a href="#services" class="btn btn-outline">Layanan Kami</a>
          </div>
        </div>
        <div class="hero-scroll">
          <div class="scroll-mouse">
            <div class="scroll-dot"></div>
          </div>
        </div>
      </section>

      <section id="about" class="about section">
        <div class="container">
          <div class="about-grid">
            <div class="about-text reveal">
              <span class="section-tag">Tentang Kami</span>
              <h2>{{ profile.about_title || 'Tentang Kami' }}</h2>
              <p>{{ profile.about_desc }}</p>
            </div>
            <div v-if="profile.about_image" class="about-image-wrapper reveal">
              <div class="about-image">
                <img :src="imgUrl(profile.about_image)" :alt="profile.company_name" />
              </div>
              <div class="about-image-deco"></div>
            </div>
          </div>
        </div>
      </section>

      <section id="services" class="services section">
        <div class="container">
          <div class="section-header reveal">
            <span class="section-tag">Apa Yang Kami Tawarkan</span>
            <h2>Layanan</h2>
            <p class="section-desc">Solusi lengkap untuk kebutuhan energi Anda</p>
          </div>
          <div class="services-grid">
            <div v-for="(s, i) in profile.services" :key="s.ID" class="service-card reveal" :style="{ transitionDelay: `${i * 0.1}s` }">
              <div class="service-icon-wrapper">
                <div class="service-icon">{{ s.icon || '⚡' }}</div>
              </div>
              <h3>{{ s.title }}</h3>
              <p>{{ s.description }}</p>
              <div class="service-shine"></div>
            </div>
          </div>
        </div>
      </section>

      <section id="partners" class="partners section">
        <div class="container">
          <div class="section-header reveal">
            <span class="section-tag">Mitra Kami</span>
            <h2>Kerjasama</h2>
            <p class="section-desc">Berkolaborasi dengan perusahaan terbaik</p>
          </div>
          <div class="partners-grid">
            <div v-for="(p, i) in profile.partners" :key="p.ID" class="partner-card reveal" :style="{ transitionDelay: `${i * 0.08}s` }">
              <div v-if="p.logo" class="partner-logo">
                <img :src="imgUrl(p.logo)" :alt="p.name" />
              </div>
              <h3>{{ p.name }}</h3>
              <p>{{ p.description }}</p>
              <a v-if="p.website" :href="p.website" target="_blank" class="partner-link">Kunjungi Website</a>
            </div>
          </div>
        </div>
      </section>

      <footer class="footer">
        <div class="container">
          <p>&copy; {{ new Date().getFullYear() }} {{ profile.company_name }}. All rights reserved.</p>
        </div>
      </footer>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useHead } from '@unhead/vue'
import { companyAPI } from '../api/company'

useHead({
  title: 'Company Profile',
})

const profile = ref(null)
const loading = ref(true)
let observer = null

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

function revealVisible() {
  document.querySelectorAll('.reveal').forEach((el) => {
    const rect = el.getBoundingClientRect()
    if (rect.top < window.innerHeight) {
      el.classList.add('visible')
    }
  })
}

function initReveal() {
  revealVisible()
  observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible')
          observer.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.1 }
  )
  document.querySelectorAll('.reveal:not(.visible)').forEach((el) => observer.observe(el))
  setTimeout(() => {
    document.querySelectorAll('.reveal:not(.visible)').forEach((el) => el.classList.add('visible'))
  }, 3000)
}

onMounted(async () => {
  try {
    const res = await companyAPI.getProfile()
    profile.value = res.data.profile
    await nextTick()
    initReveal()
  } catch {
    profile.value = null
  } finally {
    loading.value = false
  }
})

onUnmounted(() => {
  if (observer) observer.disconnect()
})
</script>

<style scoped>
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(40px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  50% { transform: translateY(-20px) rotate(3deg); }
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@keyframes scrollHint {
  0%, 100% { transform: translateY(0); opacity: 1; }
  50% { transform: translateY(6px); opacity: 0.4; }
}

@keyframes shine {
  0% { left: -100%; }
  50% { left: 100%; }
  100% { left: 100%; }
}

.company-page {
  --accent-1: #1E90FF;
  --accent-2: #EED202;
  --accent-gradient: linear-gradient(135deg, #1E90FF, #EED202);
  --accent-warm: #EED202;
  --text-dark: #0f172a;
  --text-body: #334155;
  --text-light: #64748b;
  --bg-white: #ffffff;
  --bg-light: #f8fafc;
  --bg-section: #f1f5f9;
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 20px rgba(0, 0, 0, 0.08);
  --shadow-lg: 0 10px 40px rgba(0, 0, 0, 0.12);
  --shadow-xl: 0 20px 60px rgba(0, 0, 0, 0.15);
  --radius-md: 12px;
  --radius-lg: 20px;
  --radius-xl: 28px;
  min-height: 100vh;
  background: var(--bg-white);
  color: var(--text-body);
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  overflow-x: hidden;
}

.loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
}

.loader {
  width: 40px;
  height: 40px;
  border: 3px solid var(--bg-section);
  border-top-color: var(--accent-1);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  color: var(--text-light);
  font-size: 18px;
}

/* ===== NAVBAR ===== */

.navbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  animation: fadeIn 0.6s ease;
}

.nav-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
}

.nav-brand {
  text-decoration: none;
  display: flex;
  align-items: center;
}

.nav-logo {
  height: 36px;
  width: auto;
  object-fit: contain;
}

.nav-brand-text {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-dark);
}

.nav-links {
  display: flex;
  gap: 24px;
}

.nav-link {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-body);
  text-decoration: none;
  transition: color 0.2s;
}

.nav-link:hover {
  color: var(--accent-1);
}

/* ===== REVEAL ANIMATION ===== */

.reveal {
  opacity: 0;
  transform: translateY(40px);
  transition: opacity 0.7s ease, transform 0.7s ease;
}

.reveal.visible {
  opacity: 1;
  transform: translateY(0);
}

/* ===== HERO ===== */

.hero {
  position: relative;
  min-height: 100vh;
  padding-top: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 50%, #1a365d 100%);
  background-size: cover;
  background-position: center;
  overflow: hidden;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(15, 23, 42, 0.85) 0%,
    rgba(30, 58, 95, 0.7) 50%,
    rgba(26, 54, 93, 0.8) 100%
  );
}

.hero-shapes {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.shape {
  position: absolute;
  border-radius: 50%;
  opacity: 0.08;
  animation: float 8s ease-in-out infinite;
}

.shape-1 {
  width: 500px;
  height: 500px;
  top: -150px;
  right: -100px;
  background: linear-gradient(135deg, #1E90FF, #EED202);
  animation-delay: 0s;
}

.shape-2 {
  width: 350px;
  height: 350px;
  bottom: -80px;
  left: -80px;
  background: linear-gradient(135deg, #1E90FF, #87CEEB);
  animation-delay: -3s;
}

.shape-3 {
  width: 200px;
  height: 200px;
  top: 40%;
  left: 60%;
  background: linear-gradient(135deg, #EED202, #FFA500);
  animation-delay: -5s;
  animation-duration: 12s;
}

.hero-content {
  position: relative;
  z-index: 2;
  text-align: center;
  padding: 24px;
  max-width: 800px;
  animation: fadeInUp 1s ease 0.2s both;
}

.hero-badge {
  display: inline-block;
  padding: 8px 20px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 50px;
  font-size: 13px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.8);
  letter-spacing: 0.5px;
  margin-bottom: 24px;
  animation: fadeInUp 1s ease 0.4s both;
}

.hero-title {
  font-size: clamp(40px, 7vw, 72px);
  font-weight: 800;
  color: #fff;
  line-height: 1.1;
  letter-spacing: -1.5px;
  margin-bottom: 16px;
  animation: fadeInUp 1s ease 0.6s both;
}

.hero-tagline {
  font-size: clamp(16px, 2vw, 22px);
  color: rgba(255, 255, 255, 0.7);
  font-weight: 300;
  line-height: 1.6;
  max-width: 600px;
  margin: 0 auto 36px;
  animation: fadeInUp 1s ease 0.8s both;
}

.hero-cta {
  display: flex;
  gap: 16px;
  justify-content: center;
  flex-wrap: wrap;
  animation: fadeInUp 1s ease 1s both;
}

.btn {
  display: inline-flex;
  align-items: center;
  padding: 14px 32px;
  border-radius: 50px;
  font-size: 15px;
  font-weight: 600;
  text-decoration: none;
  transition: all 0.3s ease;
  cursor: pointer;
  font-family: inherit;
}

.btn-primary {
  background: linear-gradient(135deg, #1E90FF, #EED202);
  color: #fff;
  box-shadow: 0 4px 20px rgba(30, 144, 255, 0.4);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(30, 144, 255, 0.5);
}

.btn-outline {
  background: transparent;
  color: #fff;
  border: 2px solid rgba(255, 255, 255, 0.3);
}

.btn-outline:hover {
  border-color: #fff;
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

.hero-scroll {
  position: absolute;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2;
  animation: fadeIn 1s ease 1.5s both;
}

.scroll-mouse {
  width: 24px;
  height: 40px;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-radius: 12px;
  position: relative;
}

.scroll-dot {
  width: 4px;
  height: 8px;
  background: rgba(255, 255, 255, 0.7);
  border-radius: 2px;
  position: absolute;
  top: 8px;
  left: 50%;
  transform: translateX(-50%);
  animation: scrollHint 1.5s ease infinite;
}

/* ===== SECTIONS ===== */

.section {
  padding: 100px 24px;
}

.container {
  max-width: 1100px;
  margin: 0 auto;
}

.section-header {
  text-align: center;
  margin-bottom: 56px;
}

.section-tag {
  display: inline-block;
  padding: 6px 16px;
  background: linear-gradient(135deg, rgba(30, 144, 255, 0.1), rgba(238, 210, 2, 0.1));
  color: var(--accent-1);
  border-radius: 50px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  margin-bottom: 16px;
}

.section-header h2 {
  font-size: clamp(28px, 4vw, 40px);
  font-weight: 800;
  color: var(--text-dark);
  letter-spacing: -1px;
  margin-bottom: 12px;
}

.section-desc {
  font-size: 16px;
  color: var(--text-light);
  max-width: 500px;
  margin: 0 auto;
}

/* ===== ABOUT ===== */

.about {
  background: var(--bg-white);
}

.about-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: center;
}

.about-text {
  position: relative;
  overflow: hidden;
}

.about-text::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    repeating-linear-gradient(
      45deg,
      transparent,
      transparent 28px,
      rgba(30, 144, 255, 0.06) 28px,
      rgba(30, 144, 255, 0.06) 29px
    ),
    repeating-linear-gradient(
      -45deg,
      transparent,
      transparent 40px,
      rgba(30, 144, 255, 0.04) 40px,
      rgba(30, 144, 255, 0.04) 41px
    );
  pointer-events: none;
  z-index: 0;
  border-radius: var(--radius-lg);
}

.about-text > * {
  position: relative;
  z-index: 1;
}

.about-text h2 {
  font-size: clamp(26px, 3.5vw, 36px);
  font-weight: 800;
  color: var(--text-dark);
  letter-spacing: -1px;
  margin: 16px 0 20px;
}

.about-text p {
  font-size: 16px;
  line-height: 1.9;
  color: var(--text-body);
  white-space: pre-line;
  text-align: justify;
}

.about-image-wrapper {
  position: relative;
}

.about-image {
  position: relative;
  z-index: 2;
  border-radius: var(--radius-lg);
  overflow: hidden;
  box-shadow: var(--shadow-xl);
}

.about-image img {
  width: 100%;
  display: block;
  transition: transform 0.6s ease;
}

.about-image-wrapper:hover .about-image img {
  transform: scale(1.05);
}

.about-image-deco {
  position: absolute;
  width: 100%;
  height: 100%;
  top: 20px;
  left: 20px;
  border: 3px solid #1E90FF;
  border-radius: var(--radius-lg);
  z-index: 1;
  opacity: 0.3;
}

/* ===== SERVICES ===== */

.services {
  background: var(--bg-section);
}

.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.service-card {
  position: relative;
  background: var(--bg-white);
  border-radius: var(--radius-lg);
  padding: 40px 28px 32px;
  text-align: center;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  box-shadow: var(--shadow-sm);
  cursor: default;
}

.service-card:hover {
  transform: translateY(-8px);
  box-shadow: var(--shadow-lg);
}

.service-card:hover .service-shine {
  animation: shine 0.8s ease;
}

.service-shine {
  position: absolute;
  top: 0;
  left: -100%;
  width: 60%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.4), transparent);
  pointer-events: none;
}

.service-icon-wrapper {
  width: 72px;
  height: 72px;
  margin: 0 auto 20px;
  background: linear-gradient(135deg, rgba(30, 144, 255, 0.1), rgba(238, 210, 2, 0.1));
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.service-card:hover .service-icon-wrapper {
  background: var(--accent-gradient);
  transform: scale(1.1) rotate(-5deg);
  box-shadow: 0 8px 24px rgba(30, 144, 255, 0.3);
}

.service-icon {
  font-size: 32px;
  line-height: 1;
  transition: transform 0.3s ease;
}

.service-card:hover .service-icon {
  transform: scale(1.1);
}

.service-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-dark);
  margin-bottom: 8px;
}

.service-card p {
  font-size: 14px;
  color: var(--text-light);
  line-height: 1.7;
}

/* ===== PARTNERS ===== */

.partners {
  background: var(--bg-white);
}

.partners-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 24px;
}

.partner-card {
  background: var(--bg-section);
  border: 1px solid transparent;
  border-radius: var(--radius-lg);
  padding: 36px 24px 28px;
  text-align: center;
  transition: all 0.4s ease;
}

.partner-card:hover {
  border-color: rgba(30, 144, 255, 0.2);
  background: var(--bg-white);
  box-shadow: var(--shadow-md);
  transform: translateY(-4px);
}

.partner-logo {
  width: 88px;
  height: 88px;
  margin: 0 auto 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-white);
  border-radius: 50%;
  padding: 12px;
  box-shadow: var(--shadow-sm);
  transition: all 0.3s ease;
}

.partner-card:hover .partner-logo {
  box-shadow: var(--shadow-md);
  transform: scale(1.05);
}

.partner-logo img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.partner-card h3 {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-dark);
  margin-bottom: 6px;
}

.partner-card p {
  font-size: 13px;
  color: var(--text-light);
  line-height: 1.6;
  margin-bottom: 16px;
}

.partner-link {
  display: inline-block;
  padding: 8px 20px;
  background: var(--accent-gradient);
  color: #fff;
  border-radius: 50px;
  font-size: 12px;
  font-weight: 600;
  text-decoration: none;
  transition: all 0.3s ease;
  box-shadow: 0 4px 16px rgba(30, 144, 255, 0.3);
}

.partner-link:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(30, 144, 255, 0.4);
}

/* ===== FOOTER ===== */

.footer {
  background: var(--text-dark);
  color: rgba(255, 255, 255, 0.5);
  text-align: center;
  padding: 32px 24px;
  font-size: 13px;
}

/* ===== RESPONSIVE ===== */

#about, #services, #partners {
  scroll-margin-top: 80px;
}

@media (max-width: 768px) {
  .section {
    padding: 60px 20px;
  }

  .about-grid {
    grid-template-columns: 1fr;
    gap: 40px;
  }

  .about-image-deco {
    display: none;
  }

  .services-grid {
    grid-template-columns: 1fr;
  }

  .partners-grid {
    grid-template-columns: 1fr;
  }

  .hero-cta {
    flex-direction: column;
    align-items: center;
  }

  .btn {
    width: 100%;
    max-width: 240px;
    justify-content: center;
  }
}

@media (min-width: 769px) and (max-width: 1024px) {
  .services-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .partners-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>

<style>
html {
  scroll-behavior: smooth;
}
</style>
