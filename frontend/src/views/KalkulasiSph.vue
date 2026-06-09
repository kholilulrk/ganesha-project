<template>
  <div class="sph-page">
    <div class="page-header">
      <div>
        <h1>Kalkulasi SPH</h1>
        <p>Pilih jenis perhitungan harga penawaran</p>
      </div>
    </div>

    <div class="pilihan-grid">
      <div class="pilihan-card" @click="$router.push('/sph/form/dalam-kota')">
        <div class="pilihan-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="3" width="20" height="14" rx="2"/>
            <line x1="8" y1="21" x2="16" y2="21"/>
            <line x1="12" y1="17" x2="12" y2="21"/>
            <path d="M6 12h2l2 3 4-6 2 3h2"/>
          </svg>
        </div>
        <h3>Dalam Kota</h3>
        <p>Perhitungan harga penawaran untuk area dalam kota</p>
        <span class="pilihan-action">Pilih &rarr;</span>
      </div>

      <div class="pilihan-card" @click="$router.push('/sph/form/luar-kota')">
        <div class="pilihan-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/>
            <line x1="2" y1="12" x2="22" y2="12"/>
            <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
          </svg>
        </div>
        <h3>Luar Kota</h3>
        <p>Perhitungan harga penawaran untuk area luar kota</p>
        <span class="pilihan-action">Pilih &rarr;</span>
      </div>
    </div>

    <div class="sph-table-section">
      <div class="section-title">
        <h2>Riwayat SPH</h2>
        <p v-if="sphs.length">Total {{ sphs.length }} data</p>
      </div>

      <div v-if="error" class="error-banner">{{ error }}</div>

      <div class="table-wrapper">
        <table class="sph-table">
          <thead>
            <tr>
              <th>Nama Pekerjaan</th>
              <th>Tipe</th>
              <th>Total Biaya</th>
              <th>Harga Penawaran</th>
              <th>Tanggal</th>
              <th class="th-actions">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(sph, i) in sphs" :key="sph.ID" class="table-row" :style="{ '--i': i }">
              <td class="td-name">{{ sph.job?.name || '-' }}</td>
              <td>
                <span class="tipe-badge" :class="sph.jenis">
                  {{ sph.jenis === 'luar_kota' ? 'Luar Kota' : 'Dalam Kota' }}
                </span>
              </td>
              <td class="td-amount">{{ formatRupiah(totalBiaya(sph)) }}</td>
              <td class="td-amount utama">{{ formatRupiah(hargaPenawaran(sph)) }}</td>
              <td class="td-date">{{ formatDate(sph.tanggal_sph) }}</td>
              <td class="td-actions">
                <button class="btn-icon view" @click="$router.push('/sph/detail/' + sph.ID)" title="Detail">👁️</button>
                <button class="btn-icon edit" @click="editSph(sph)" title="Edit">✏️</button>
                <button class="btn-icon delete" @click="deleteSph(sph.ID)" title="Hapus">🗑️</button>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-if="!sphs.length" class="empty-state">
          <div class="empty-icon">📄</div>
          <p>Belum ada data SPH</p>
          <p class="empty-hint">Buat SPH baru dengan memilih jenis di atas</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { sphAPI } from '../api/sph'

useHead({
  title: 'Kalkulasi SPH',
  meta: [{ name: 'description', content: 'Kalkulasi Surat Penawaran Harga' }],
})

const router = useRouter()
const sphs = ref([])
const error = ref('')

function totalBiaya(sph) {
  const jmlTeknisi = Math.max((sph.teknisi || []).length, 1)
  const transport = (sph.transport_per_hari || 0) * (sph.jumlah_hari || 0) * jmlTeknisi
  const uangMakan = (sph.uang_makan_per_hari || 0) * (sph.jumlah_hari || 0) * jmlTeknisi
  const upahTeknisi = (sph.teknisi || []).reduce((sum, t) => {
    return sum + ((t.upah_per_bulan || 0) * (t.jumlah_bulan || 0))
  }, 0)
  return (sph.nilai_jasa || 0)
    + (sph.nilai_material || 0)
    + transport
    + uangMakan
    + (sph.akomodasi || 0)
    + (sph.biaya_lain || 0)
    + upahTeknisi
    + (sph.overhead || 0)
}

function hargaPenawaran(sph) {
  const margin = (sph.margin_keuntungan || 0) / 100
  return totalBiaya(sph) * (1 + margin)
}

function formatRupiah(val) {
  return 'Rp ' + Math.round(val).toLocaleString('id-ID')
}

function formatDate(d) {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric', month: 'long', day: 'numeric',
  })
}

function editSph(sph) {
  const jenis = sph.jenis === 'luar_kota' ? 'luar-kota' : 'dalam-kota'
  router.push('/sph/form/' + jenis + '?edit=' + sph.ID)
}

async function deleteSph(id) {
  if (!confirm('Yakin ingin menghapus SPH ini?')) return
  try {
    await sphAPI.delete(id)
    await loadSph()
  } catch (e) {
    error.value = 'Gagal menghapus SPH'
  }
}

async function loadSph() {
  try {
    const res = await sphAPI.getAll()
    sphs.value = res.data.sphs
  } catch (e) {
    error.value = 'Gagal memuat data SPH'
  }
}

onMounted(() => {
  loadSph()
})
</script>

<style scoped>
.sph-page {
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

.pilihan-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 40px;
}

.pilihan-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 20px;
  padding: 36px 28px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.pilihan-card:hover {
  border-color: #667eea;
  transform: translateY(-4px);
  box-shadow: 0 12px 40px rgba(102, 126, 234, 0.15);
}

.pilihan-icon {
  color: #667eea;
  margin-bottom: 16px;
}

.pilihan-card h3 {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.pilihan-card p {
  font-size: 14px;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: 16px;
}

.pilihan-action {
  font-size: 14px;
  font-weight: 600;
  color: #667eea;
  transition: gap 0.2s;
}

.pilihan-card:hover .pilihan-action {
  letter-spacing: 1px;
}

.sph-table-section {
  margin-top: 8px;
}

.section-title {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 16px;
}

.section-title h2 {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
}

.section-title p {
  font-size: 13px;
  color: var(--text-muted);
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

.table-wrapper {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  overflow-x: auto;
  animation: fadeIn 0.5s ease;
}

.sph-table {
  width: 100%;
  border-collapse: collapse;
}

.sph-table thead {
  background: var(--table-header-bg);
}

.sph-table th {
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
  width: 120px;
}

.table-row {
  transition: background 0.2s;
  animation: rowIn 0.4s ease both;
  animation-delay: calc(var(--i) * 0.05s);
}

@keyframes rowIn {
  from { opacity: 0; transform: translateX(-10px); }
  to { opacity: 1; transform: translateX(0); }
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

.td-amount {
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.td-amount.utama {
  color: #667eea;
}

.td-date {
  white-space: nowrap;
}

.tipe-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.tipe-badge.dalam_kota {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.tipe-badge.luar_kota {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
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

.btn-icon.view:hover {
  background: rgba(102, 126, 234, 0.15);
}

.btn-icon.edit:hover {
  background: rgba(255, 193, 7, 0.15);
}

.btn-icon.delete:hover {
  background: rgba(255, 107, 107, 0.15);
}

.empty-state {
  text-align: center;
  padding: 48px 20px;
  color: var(--text-muted);
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.empty-state p {
  font-size: 16px;
  margin-bottom: 4px;
}

.empty-hint {
  font-size: 13px !important;
  color: var(--text-dim);
}
</style>
