<template>
  <div class="company-manage">
    <div class="page-header">
      <h1>Kelola Company Profile</h1>
    </div>

    <div v-if="error" class="error-banner">{{ error }}</div>
    <div v-if="success" class="success-banner">{{ success }}</div>

    <!-- Profile Info -->
    <section class="section">
      <h2>Informasi Perusahaan</h2>
      <div class="form-grid">
        <div class="form-group">
          <label>Nama Perusahaan</label>
          <input v-model="form.company_name" type="text" />
        </div>
        <div class="form-group">
          <label>Tagline</label>
          <input v-model="form.tagline" type="text" />
        </div>
        <div class="form-group full">
          <label>Hero Image</label>
          <div class="file-upload-row">
            <input ref="heroFileInput" type="file" accept="image/*" class="hidden-input" @change="onHeroFileChange" />
            <button type="button" class="file-upload-btn" @click="$refs.heroFileInput.click()" :disabled="uploadingHero">
              <span v-if="uploadingHero" class="spinner-sm" />
              <span v-else>Pilih Gambar</span>
            </button>
            <img v-if="form.hero_image" :src="imgUrl(form.hero_image)" class="file-preview" />
          </div>
        </div>
        <div class="form-group full">
          <label>Judul Tentang Kami</label>
          <input v-model="form.about_title" type="text" />
        </div>
        <div class="form-group full">
          <label>Deskripsi Tentang Kami</label>
          <textarea v-model="form.about_desc" rows="4"></textarea>
        </div>
        <div class="form-group full">
          <label>Gambar Tentang Kami</label>
          <div class="file-upload-row">
            <input ref="aboutFileInput" type="file" accept="image/*" class="hidden-input" @change="onAboutFileChange" />
            <button type="button" class="file-upload-btn" @click="$refs.aboutFileInput.click()" :disabled="uploadingAbout">
              <span v-if="uploadingAbout" class="spinner-sm" />
              <span v-else>Pilih Gambar</span>
            </button>
            <img v-if="form.about_image" :src="imgUrl(form.about_image)" class="file-preview" />
          </div>
        </div>
      </div>
      <button class="btn-save" :disabled="saving" @click="saveProfile">
        <span v-if="saving" class="spinner-sm" />
        <span v-else>Simpan Profile</span>
      </button>
    </section>

    <!-- Services -->
    <section class="section">
      <div class="section-header">
        <h2>Layanan</h2>
        <button class="btn-add" @click="openServiceModal()">+ Tambah</button>
      </div>
      <div v-if="services.length" class="item-list">
        <div v-for="s in services" :key="s.ID" class="item-card">
          <div class="item-icon">{{ s.icon || '⚡' }}</div>
          <div class="item-info">
            <strong>{{ s.title }}</strong>
            <p>{{ s.description }}</p>
          </div>
          <div class="item-actions">
            <button class="btn-icon edit" @click="openServiceModal(s)" title="Edit">✏️</button>
            <button class="btn-icon delete" @click="deleteService(s.ID)" title="Hapus">🗑️</button>
          </div>
        </div>
      </div>
      <p v-else class="empty-text">Belum ada layanan</p>
    </section>

    <!-- Partners -->
    <section class="section">
      <div class="section-header">
        <h2>Kerjasama</h2>
        <button class="btn-add" @click="openPartnerModal()">+ Tambah</button>
      </div>
      <div v-if="partners.length" class="item-list">
        <div v-for="p in partners" :key="p.ID" class="item-card">
          <div v-if="p.logo" class="item-logo">
            <img :src="p.logo" :alt="p.name" />
          </div>
          <div class="item-info">
            <strong>{{ p.name }}</strong>
            <p>{{ p.description }}</p>
          </div>
          <div class="item-actions">
            <button class="btn-icon edit" @click="openPartnerModal(p)" title="Edit">✏️</button>
            <button class="btn-icon delete" @click="deletePartner(p.ID)" title="Hapus">🗑️</button>
          </div>
        </div>
      </div>
      <p v-else class="empty-text">Belum ada partner</p>
    </section>

    <!-- Service Modal -->
    <transition name="modal-fade">
      <div v-if="showServiceModal" class="modal-overlay" @click.self="showServiceModal = false">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editingService ? 'Edit Layanan' : 'Tambah Layanan' }}</h2>
            <button class="btn-close" @click="showServiceModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>Judul</label>
              <input v-model="serviceForm.title" type="text" />
            </div>
            <div class="form-group">
              <label>Deskripsi</label>
              <textarea v-model="serviceForm.description" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label>Icon (emoji)</label>
              <input v-model="serviceForm.icon" type="text" placeholder="⚡" />
            </div>
            <div class="form-actions">
              <button class="btn-cancel" @click="showServiceModal = false">Batal</button>
              <button class="btn-save" :disabled="serviceSaving" @click="saveService">
                <span v-if="serviceSaving" class="spinner-sm" />
                <span v-else>Simpan</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Partner Modal -->
    <transition name="modal-fade">
      <div v-if="showPartnerModal" class="modal-overlay" @click.self="showPartnerModal = false">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editingPartner ? 'Edit Partner' : 'Tambah Partner' }}</h2>
            <button class="btn-close" @click="showPartnerModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>Nama Perusahaan/Partner</label>
              <input v-model="partnerForm.name" type="text" />
            </div>
            <div class="form-group">
              <label>Deskripsi</label>
              <textarea v-model="partnerForm.description" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label>Logo (URL)</label>
              <input v-model="partnerForm.logo" type="text" placeholder="https://..." />
            </div>
            <div class="form-group">
              <label>Website</label>
              <input v-model="partnerForm.website" type="text" placeholder="https://..." />
            </div>
            <div class="form-actions">
              <button class="btn-cancel" @click="showPartnerModal = false">Batal</button>
              <button class="btn-save" :disabled="partnerSaving" @click="savePartner">
                <span v-if="partnerSaving" class="spinner-sm" />
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
import { ref, reactive, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { companyAPI } from '../api/company'
import api from '../api/client'

useHead({ title: 'Kelola Company Profile' })

const profile = ref(null)
const services = ref([])
const partners = ref([])
const error = ref('')
const success = ref('')
const saving = ref(false)
const uploadingHero = ref(false)
const uploadingAbout = ref(false)
const heroFileInput = ref(null)
const aboutFileInput = ref(null)

const form = reactive({
  company_name: '',
  tagline: '',
  hero_image: '',
  about_title: '',
  about_desc: '',
  about_image: '',
})

function imgUrl(val) {
  if (!val) return ''
  const path = val.replace(/\\/g, '/')
  if (path.startsWith('uploads/')) return '/' + path
  return val
}

async function uploadFile(file) {
  const fd = new FormData()
  fd.append('file', file)
  const res = await api.post('/upload', fd)
  return res.data.path
}

async function onHeroFileChange(e) {
  const f = e.target.files[0]
  if (!f) return
  uploadingHero.value = true
  try {
    form.hero_image = await uploadFile(f)
  } catch (err) {
    error.value = 'Gagal upload hero image: ' + (err.response?.data?.error || err.message)
  } finally {
    uploadingHero.value = false
  }
}

async function onAboutFileChange(e) {
  const f = e.target.files[0]
  if (!f) return
  uploadingAbout.value = true
  try {
    form.about_image = await uploadFile(f)
  } catch (err) {
    error.value = 'Gagal upload about image: ' + (err.response?.data?.error || err.message)
  } finally {
    uploadingAbout.value = false
  }
}

// Service modal
const showServiceModal = ref(false)
const editingService = ref(null)
const serviceSaving = ref(false)
const serviceForm = reactive({ title: '', description: '', icon: '' })

// Partner modal
const showPartnerModal = ref(false)
const editingPartner = ref(null)
const partnerSaving = ref(false)
const partnerForm = reactive({ name: '', description: '', logo: '', website: '' })

async function loadProfile() {
  try {
    const res = await companyAPI.getProfile()
    profile.value = res.data.profile
    const p = res.data.profile
    form.company_name = p.company_name || ''
    form.tagline = p.tagline || ''
    form.hero_image = p.hero_image || ''
    form.about_title = p.about_title || ''
    form.about_desc = p.about_desc || ''
    form.about_image = p.about_image || ''
    services.value = p.services || []
    partners.value = p.partners || []
  } catch {
    error.value = 'Gagal memuat data'
  }
}

async function saveProfile() {
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    await companyAPI.updateProfile({ ...form })
    success.value = 'Profile berhasil disimpan'
    loadProfile()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    saving.value = false
  }
}

function openServiceModal(service) {
  editingService.value = service || null
  serviceForm.title = service?.title || ''
  serviceForm.description = service?.description || ''
  serviceForm.icon = service?.icon || ''
  showServiceModal.value = true
}

async function saveService() {
  serviceSaving.value = true
  error.value = ''
  try {
    if (editingService.value) {
      await companyAPI.updateService(editingService.value.ID, { ...serviceForm })
    } else {
      await companyAPI.createService({ ...serviceForm })
    }
    showServiceModal.value = false
    loadProfile()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    serviceSaving.value = false
  }
}

async function deleteService(id) {
  if (!confirm('Hapus layanan ini?')) return
  error.value = ''
  try {
    await companyAPI.deleteService(id)
    loadProfile()
  } catch (err) {
    error.value = 'Gagal menghapus'
  }
}

function openPartnerModal(partner) {
  editingPartner.value = partner || null
  partnerForm.name = partner?.name || ''
  partnerForm.description = partner?.description || ''
  partnerForm.logo = partner?.logo || ''
  partnerForm.website = partner?.website || ''
  showPartnerModal.value = true
}

async function savePartner() {
  partnerSaving.value = true
  error.value = ''
  try {
    if (editingPartner.value) {
      await companyAPI.updatePartner(editingPartner.value.ID, { ...partnerForm })
    } else {
      await companyAPI.createPartner({ ...partnerForm })
    }
    showPartnerModal.value = false
    loadProfile()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan'
  } finally {
    partnerSaving.value = false
  }
}

async function deletePartner(id) {
  if (!confirm('Hapus partner ini?')) return
  error.value = ''
  try {
    await companyAPI.deletePartner(id)
    loadProfile()
  } catch (err) {
    error.value = 'Gagal menghapus'
  }
}

onMounted(loadProfile)
</script>

<style scoped>
.company-manage {
  padding: 24px;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  margin-bottom: 28px;
}

.page-header h1 {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
}

.section {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
}

.section h2 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 16px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h2 {
  margin-bottom: 0;
}

.hidden-input {
  display: none;
}

.file-upload-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.file-upload-btn {
  padding: 8px 16px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  color: var(--text-primary);
  font-family: inherit;
  transition: background 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.file-upload-btn:hover:not(:disabled) {
  background: var(--hover-bg);
}

.file-upload-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.file-preview {
  height: 80px;
  border-radius: 8px;
  object-fit: cover;
  border: 1px solid var(--card-border);
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group.full {
  grid-column: 1 / -1;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
}

.form-group input,
.form-group textarea,
.form-group select {
  padding: 10px 14px;
  border: 1px solid var(--card-border);
  border-radius: 10px;
  font-size: 14px;
  background: var(--input-bg);
  color: var(--text-primary);
  transition: border-color 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15);
}

.form-group textarea {
  resize: vertical;
}

.item-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.item-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  transition: background 0.2s;
}

.item-card:hover {
  background: var(--hover-bg-strong);
}

.item-icon {
  font-size: 32px;
  width: 48px;
  text-align: center;
  flex-shrink: 0;
}

.item-logo {
  width: 48px;
  height: 48px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.item-logo img {
  max-width: 100%;
  max-height: 100%;
  border-radius: 8px;
}

.item-info {
  flex: 1;
  min-width: 0;
}

.item-info strong {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.item-info p {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-actions {
  display: flex;
  gap: 4px;
  flex-shrink: 0;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  font-size: 14px;
  transition: background 0.2s;
}

.btn-icon.edit:hover { background: rgba(102, 126, 234, 0.15); }
.btn-icon.delete:hover { background: rgba(255, 107, 107, 0.15); }

.btn-add {
  padding: 8px 16px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: transform 0.2s;
}

.btn-add:hover {
  transform: translateY(-1px);
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
  font-family: inherit;
  transition: opacity 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.btn-save:hover:not(:disabled) { opacity: 0.9; }
.btn-save:disabled { opacity: 0.6; cursor: not-allowed; }

.btn-cancel {
  padding: 10px 20px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  border-radius: 10px;
  font-size: 14px;
  cursor: pointer;
  color: var(--text-secondary);
  font-family: inherit;
  font-weight: 500;
}

.btn-cancel:hover {
  background: var(--hover-bg);
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
  color: #ef4444;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 12px;
}

.success-banner {
  background: rgba(81, 207, 102, 0.1);
  color: #51cf66;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 12px;
}

.empty-text {
  color: var(--text-dim);
  font-size: 14px;
  text-align: center;
  padding: 24px;
}

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
  background: var(--modal-bg);
  border-radius: 16px;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
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
  color: var(--text-primary);
  margin: 0;
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
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.modal-body {
  padding: 24px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid var(--card-border-light);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

@media (max-width: 768px) {
  .form-grid { grid-template-columns: 1fr; }
}
</style>
