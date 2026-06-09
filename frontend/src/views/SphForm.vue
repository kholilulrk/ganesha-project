<template>
  <div class="sph-form-page">
    <div class="page-header">
      <div>
        <h1>{{ editing ? 'Edit SPH' : 'Kalkulasi SPH' }} - {{ isDalamKota ? 'Dalam Kota' : 'Luar Kota' }}</h1>
        <p>{{ editing ? 'Perbarui surat penawaran harga' : 'Surat Penawaran Harga' }}</p>
      </div>
      <div class="header-actions">
        <button class="btn-back" @click="$router.push('/sph')">Kembali</button>
        <button class="btn-save" @click="simpanSph" :disabled="saving || loadingData">
          {{ saving ? 'Menyimpan...' : editing ? 'Perbarui' : 'Simpan' }}
        </button>
      </div>
    </div>

    <div v-if="error" class="error-banner">{{ error }}</div>
    <div v-if="success" class="success-banner">{{ success }}</div>

    <!-- Informasi SPH -->
    <div class="form-section">
      <div class="section-header">
        <span class="section-icon">&#8505;</span>
        <h2>Informasi SPH</h2>
      </div>
      <div class="section-body">
        <div class="form-row">
          <div class="form-group">
            <label>Pekerjaan</label>
            <select v-model="form.job_id" class="form-select" required>
              <option value="">-- Pilih Pekerjaan --</option>
              <option v-for="job in jobs" :key="job.ID" :value="job.ID">{{ job.name }}</option>
            </select>
          </div>
          <div class="form-group">
            <label>Nomor SPH</label>
            <input v-model="form.nomor_sph" type="text" placeholder="Contoh: SPH-001/VI/2026" class="form-input" />
          </div>
          <div class="form-group">
            <label>Tanggal SPH</label>
            <input v-model="form.tanggal_sph" type="date" class="form-input" />
          </div>
        </div>
      </div>
    </div>

    <!-- Biaya Langsung -->
    <div class="form-section">
      <div class="section-header">
        <span class="section-icon">&#128176;</span>
        <h2>Biaya Langsung</h2>
      </div>
      <div class="section-body">
        <div class="form-row">
          <div class="form-group">
            <label>Nilai Jasa (Rp)</label>
            <input v-model="form.nilai_jasa" type="text" class="form-input rupiah" @input="onRupiahInput('nilai_jasa', $event)" />
          </div>
          <div class="form-group">
            <label>Nilai Material (Rp)</label>
            <input v-model="form.nilai_material" type="text" class="form-input rupiah" @input="onRupiahInput('nilai_material', $event)" />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Transport / Hari (Rp)</label>
            <input v-model="form.transport_per_hari" type="text" class="form-input rupiah" @input="onRupiahInput('transport_per_hari', $event)" />
          </div>
          <div class="form-group">
            <label>Uang Makan / Hari (Rp)</label>
            <input v-model="form.uang_makan_per_hari" type="text" class="form-input rupiah" @input="onRupiahInput('uang_makan_per_hari', $event)" />
          </div>
          <div class="form-group">
            <label>Jumlah Hari</label>
            <input v-model.number="form.jumlah_hari" type="number" min="1" class="form-input" />
          </div>
        </div>
        <div v-if="!isDalamKota" class="form-row">
          <div class="form-group">
            <label>Akomodasi (Rp)</label>
            <input v-model="form.akomodasi" type="text" class="form-input rupiah" @input="onRupiahInput('akomodasi', $event)" />
          </div>
          <div class="form-group" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Biaya Lain Lain (Rp)</label>
            <input v-model="form.biaya_lain" type="text" class="form-input rupiah" @input="onRupiahInput('biaya_lain', $event)" />
          </div>
          <div class="form-group">
            <label>Keterangan Biaya Lain Lain</label>
            <input v-model="form.keterangan_biaya_lain" type="text" placeholder="Keterangan" class="form-input" />
          </div>
        </div>
        <div class="total-card">
          <span class="total-label">Total Biaya Langsung</span>
          <span class="total-value">{{ formatRupiah(totalBiayaLangsung) }}</span>
        </div>
      </div>
    </div>

    <!-- Upah Teknisi -->
    <div class="form-section">
      <div class="section-header">
        <span class="section-icon">&#128119;</span>
        <h2>Upah Teknisi</h2>
        <button class="btn-add-row" @click="tambahTeknisi">+ Tambah Teknisi</button>
      </div>
      <div class="section-body">
        <div v-for="(t, i) in form.teknisi" :key="i" class="teknisi-row">
          <div class="teknisi-fields">
            <div class="form-group">
              <label>Nama Teknisi</label>
              <input v-model="t.nama_teknisi" type="text" placeholder="Nama teknisi" class="form-input" />
            </div>
            <div class="form-group">
              <label>Upah / Bulan (Rp)</label>
              <input v-model="t.upah_per_bulan_display" type="text" class="form-input rupiah" @input="onTeknisiRupiahInput(i, $event)" />
            </div>
            <div class="form-group">
              <label>Jumlah Bulan</label>
              <input v-model.number="t.jumlah_bulan" type="number" min="1" class="form-input" />
            </div>
          </div>
          <button class="btn-remove-row" @click="hapusTeknisi(i)" title="Hapus teknisi">&times;</button>
        </div>
        <div v-if="form.teknisi.length === 0" class="empty-section">
          Belum ada teknisi. Klik "Tambah Teknisi" untuk menambahkan.
        </div>
        <div v-if="form.teknisi.length > 0" class="total-card">
          <span class="total-label">Total Upah Teknisi</span>
          <span class="total-value">{{ formatRupiah(totalUpahTeknisi) }}</span>
        </div>
      </div>
    </div>

    <!-- Biaya Tidak Langsung dan Keuntungan -->
    <div class="form-section">
      <div class="section-header">
        <span class="section-icon">&#128200;</span>
        <h2>Biaya Tidak Langsung dan Keuntungan</h2>
      </div>
      <div class="section-body">
        <div class="form-row">
          <div class="form-group">
            <label>Biaya Tidak Langsung (Rp)</label>
            <input v-model="form.overhead" type="text" class="form-input rupiah" @input="onRupiahInput('overhead', $event)" />
          </div>
          <div class="form-group">
            <label>Margin Keuntungan (%)</label>
            <input v-model.number="form.margin_keuntungan" type="number" min="0" step="0.1" class="form-input" />
          </div>
        </div>
      </div>
    </div>

    <!-- Rekapitulasi -->
    <div class="form-section">
      <div class="section-header">
        <span class="section-icon">&#128203;</span>
        <h2>Rekapitulasi</h2>
      </div>
      <div class="section-body">
        <div class="rekap-grid">
          <div class="rekap-card total-biaya">
            <span class="rekap-label">Total Biaya</span>
            <span class="rekap-value">{{ formatRupiah(totalBiaya) }}</span>
            <span class="rekap-detail">Jasa + Material + Transport + Makan + Akomodasi + Lain + Teknisi + Biaya Tidak Langsung</span>
          </div>
          <div class="rekap-card harga-penawaran">
            <span class="rekap-label">Harga Penawaran</span>
            <span class="rekap-value utama">{{ formatRupiah(hargaPenawaran) }}</span>
            <span class="rekap-detail">Total Biaya + {{ form.margin_keuntungan || 0 }}% margin</span>
          </div>
        </div>
        <div class="form-group" style="margin-top: 16px;">
          <label>Catatan</label>
          <textarea v-model="form.catatan" class="form-input" rows="3" placeholder="Catatan seluruhnya..."></textarea>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { sphAPI } from '../api/sph'
import { jobAPI } from '../api/job'

useHead({
  title: 'Kalkulasi SPH',
  meta: [{ name: 'description', content: 'Form Kalkulasi Surat Penawaran Harga' }],
})

const route = useRoute()
const router = useRouter()
const isDalamKota = computed(() => route.params.jenis === 'dalam-kota')
const editing = ref(false)
const editId = ref(null)
const loadingData = ref(false)

const jobs = ref([])
const form = reactive({
  job_id: '',
  nomor_sph: '',
  tanggal_sph: new Date().toISOString().split('T')[0],
  nilai_jasa: 0,
  nilai_material: 0,
  transport_per_hari: 0,
  uang_makan_per_hari: 0,
  jumlah_hari: 1,
  akomodasi: 0,
  biaya_lain: 0,
  keterangan_biaya_lain: '',
  overhead: 0,
  margin_keuntungan: 0,
  catatan: '',
  teknisi: [],
})

const saving = ref(false)
const error = ref('')
const success = ref('')

const jumlahTeknisi = computed(() => form.teknisi.length)

const totalTransport = computed(() => {
  return (parseFloat(form.transport_per_hari) || 0) * (form.jumlah_hari || 0) * Math.max(jumlahTeknisi.value, 1)
})

const totalUangMakan = computed(() => {
  return (parseFloat(form.uang_makan_per_hari) || 0) * (form.jumlah_hari || 0) * Math.max(jumlahTeknisi.value, 1)
})

const totalBiayaLangsung = computed(() => {
  return (parseFloat(form.nilai_jasa) || 0)
    + (parseFloat(form.nilai_material) || 0)
    + totalTransport.value
    + totalUangMakan.value
    + (parseFloat(form.akomodasi) || 0)
    + (parseFloat(form.biaya_lain) || 0)
})

const totalUpahTeknisi = computed(() => {
  return form.teknisi.reduce((sum, t) => {
    return sum + ((parseFloat(t.upah_per_bulan) || 0) * (t.jumlah_bulan || 0))
  }, 0)
})

const totalBiaya = computed(() => {
  return totalBiayaLangsung.value + totalUpahTeknisi.value + (parseFloat(form.overhead) || 0)
})

const hargaPenawaran = computed(() => {
  const margin = (parseFloat(form.margin_keuntungan) || 0) / 100
  return totalBiaya.value * (1 + margin)
})

function parseRupiah(val) {
  if (typeof val === 'string') {
    return val.replace(/[^0-9]/g, '')
  }
  return String(val)
}

function formatRupiah(val) {
  const num = typeof val === 'string' ? parseFloat(parseRupiah(val)) : (val || 0)
  return 'Rp ' + Math.round(num).toLocaleString('id-ID')
}

function onRupiahInput(field, event) {
  const raw = event.target.value.replace(/[^0-9]/g, '')
  form[field] = raw ? parseInt(raw) : 0
  event.target.value = raw ? parseInt(raw).toLocaleString('id-ID') : ''
}

function onTeknisiRupiahInput(index, event) {
  const raw = event.target.value.replace(/[^0-9]/g, '')
  form.teknisi[index].upah_per_bulan = raw ? parseInt(raw) : 0
  form.teknisi[index].upah_per_bulan_display = raw ? parseInt(raw).toLocaleString('id-ID') : ''
}

function tambahTeknisi() {
  form.teknisi.push({
    nama_teknisi: '',
    upah_per_bulan: 0,
    upah_per_bulan_display: '',
    jumlah_bulan: 1,
  })
}

function hapusTeknisi(index) {
  form.teknisi.splice(index, 1)
}

function preparePayload() {
  return {
    job_id: parseInt(form.job_id),
    nomor_sph: form.nomor_sph,
    tanggal_sph: form.tanggal_sph,
    jenis: isDalamKota.value ? 'dalam_kota' : 'luar_kota',
    nilai_jasa: parseFloat(form.nilai_jasa) || 0,
    nilai_material: parseFloat(form.nilai_material) || 0,
    transport_per_hari: parseFloat(form.transport_per_hari) || 0,
    uang_makan_per_hari: parseFloat(form.uang_makan_per_hari) || 0,
    jumlah_hari: form.jumlah_hari || 1,
    akomodasi: parseFloat(form.akomodasi) || 0,
    biaya_lain: parseFloat(form.biaya_lain) || 0,
    keterangan_biaya_lain: form.keterangan_biaya_lain,
    overhead: parseFloat(form.overhead) || 0,
    margin_keuntungan: parseFloat(form.margin_keuntungan) || 0,
    catatan: form.catatan,
    teknisi: form.teknisi.map(t => ({
      nama_teknisi: t.nama_teknisi,
      upah_per_bulan: parseFloat(t.upah_per_bulan) || 0,
      jumlah_bulan: t.jumlah_bulan || 1,
    })),
  }
}

async function simpanSph() {
  if (!form.job_id) {
    error.value = 'Silakan pilih pekerjaan terlebih dahulu'
    return
  }
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    if (editing.value) {
      await sphAPI.update(editId.value, preparePayload())
      success.value = 'SPH berhasil diperbarui!'
    } else {
      await sphAPI.create(preparePayload())
      success.value = 'SPH berhasil disimpan!'
    }
    setTimeout(() => router.push('/sph'), 1500)
  } catch (e) {
    error.value = 'Gagal menyimpan SPH: ' + (e.response?.data?.error || e.message)
  } finally {
    saving.value = false
  }
}

async function loadEditData(id) {
  try {
    loadingData.value = true
    const res = await sphAPI.getById(id)
    const sph = res.data.sph
    editing.value = true
    editId.value = sph.ID
    form.job_id = sph.job_id
    form.nomor_sph = sph.nomor_sph || ''
    form.tanggal_sph = sph.tanggal_sph ? sph.tanggal_sph.substring(0, 10) : ''
    form.nilai_jasa = sph.nilai_jasa || 0
    form.nilai_material = sph.nilai_material || 0
    form.transport_per_hari = sph.transport_per_hari || 0
    form.uang_makan_per_hari = sph.uang_makan_per_hari || 0
    form.jumlah_hari = sph.jumlah_hari || 1
    form.akomodasi = sph.akomodasi || 0
    form.biaya_lain = sph.biaya_lain || 0
    form.keterangan_biaya_lain = sph.keterangan_biaya_lain || ''
    form.overhead = sph.overhead || 0
    form.margin_keuntungan = sph.margin_keuntungan || 0
    form.catatan = sph.catatan || ''
    form.teknisi = (sph.teknisi || []).map(t => ({
      nama_teknisi: t.nama_teknisi || '',
      upah_per_bulan: t.upah_per_bulan || 0,
      upah_per_bulan_display: (t.upah_per_bulan || 0) ? Math.round(t.upah_per_bulan).toLocaleString('id-ID') : '',
      jumlah_bulan: t.jumlah_bulan || 1,
    }))
  } catch (e) {
    error.value = 'Gagal memuat data SPH'
  } finally {
    loadingData.value = false
  }
}

onMounted(async () => {
  try {
    const res = await jobAPI.getAll()
    jobs.value = res.data.jobs
  } catch (e) {
    error.value = 'Gagal memuat data pekerjaan'
  }
  const editParam = route.query.edit
  if (editParam) {
    await loadEditData(editParam)
  }
})
</script>

<style scoped>
.sph-form-page {
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
  align-items: flex-start;
  margin-bottom: 24px;
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

.btn-back {
  padding: 10px 20px;
  border: 1px solid var(--card-border);
  border-radius: 10px;
  background: transparent;
  color: var(--text-secondary);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: all 0.2s;
}

.btn-back:hover {
  background: var(--hover-bg);
  color: var(--text-primary);
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
  transition: all 0.2s;
}

.btn-save:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: default;
}

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 13px;
}

.success-banner {
  background: rgba(81, 207, 102, 0.1);
  border: 1px solid rgba(81, 207, 102, 0.3);
  color: #51cf66;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 13px;
}

.form-section {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  margin-bottom: 20px;
  overflow: hidden;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 20px;
  border-bottom: 1px solid var(--card-border-light);
  background: var(--hover-bg);
}

.section-header h2 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  flex: 1;
}

.section-icon {
  font-size: 20px;
}

.section-body {
  padding: 20px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
}

.form-row:last-child {
  margin-bottom: 0;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
}

.form-input, .form-select {
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
  width: 100%;
}

.form-input:focus, .form-select:focus {
  border-color: #667eea;
}

.form-select {
  cursor: pointer;
}

.form-select option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

textarea.form-input {
  resize: vertical;
  min-height: 80px;
}

.total-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1));
  border: 1px solid rgba(102, 126, 234, 0.2);
  border-radius: 12px;
  margin-top: 16px;
}

.total-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.total-value {
  font-size: 20px;
  font-weight: 700;
  color: #667eea;
}

.btn-add-row {
  padding: 8px 16px;
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 8px;
  background: rgba(102, 126, 234, 0.1);
  color: #667eea;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: all 0.2s;
}

.btn-add-row:hover {
  background: rgba(102, 126, 234, 0.2);
}

.teknisi-row {
  display: flex;
  gap: 12px;
  align-items: flex-end;
  margin-bottom: 12px;
  padding: 16px;
  background: var(--hover-bg);
  border-radius: 12px;
}

.teknisi-fields {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 12px;
  flex: 1;
}

.btn-remove-row {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 8px;
  background: rgba(255, 107, 107, 0.1);
  color: #ff6b6b;
  font-size: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
}

.btn-remove-row:hover {
  background: rgba(255, 107, 107, 0.2);
}

.empty-section {
  text-align: center;
  padding: 24px;
  color: var(--text-muted);
  font-size: 14px;
  font-style: italic;
}

.rekap-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.rekap-card {
  padding: 20px 24px;
  border-radius: 14px;
  border: 1px solid var(--card-border-light);
}

.rekap-card.total-biaya {
  background: rgba(102, 126, 234, 0.08);
}

.rekap-card.harga-penawaran {
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.15), rgba(118, 75, 162, 0.15));
  border-color: rgba(102, 126, 234, 0.3);
}

.rekap-label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
}

.rekap-value {
  display: block;
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
}

.rekap-value.utama {
  font-size: 28px;
  color: #667eea;
}

.rekap-detail {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 6px;
}
</style>
