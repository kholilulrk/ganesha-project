<template>
  <div class="sph-detail-page">
    <div class="no-print" style="margin-bottom:16px;display:flex;gap:8px;flex-wrap:wrap;">
      <button class="btn-back" @click="$router.push('/sph')">Kembali</button>
      <button class="btn-print" @click="cetak">Cetak / Download PDF</button>
    </div>

    <div v-if="loading" class="loading-state">Memuat data...</div>
    <div v-else-if="error" class="error-banner">{{ error }}</div>

    <div v-else ref="printArea" class="print-area">
      <!-- Kop Surat -->
      <div class="header-section">
        <div class="company-name">PT GANESHA ENERGI INDONESIA</div>
        <div class="company-detail">Engineering · Procurement · Construction</div>
        <div class="company-detail" style="font-size:11px;margin-top:2px;">Jl. Laksda M Nazir No. 42, Perak Barat, Surabaya</div>
      </div>

      <div class="doc-title">KALKULASI PENAWARAN HARGA</div>
      <div class="doc-subtitle">(KPH)</div>

      <!-- Informasi SPH -->
      <table class="info-table">
        <tr>
          <td class="label">Nomor SPH</td>
          <td class="value">: {{ sph.nomor_sph || '-' }}</td>
        </tr>
        <tr>
          <td class="label">Tanggal</td>
          <td class="value">: {{ formatDate(sph.tanggal_sph) }}</td>
        </tr>
        <tr>
          <td class="label">Jenis</td>
          <td class="value">: {{ sph.jenis === 'luar_kota' ? 'Luar Kota' : 'Dalam Kota' }}</td>
        </tr>
        <tr>
          <td class="label">Pekerjaan</td>
          <td class="value">: {{ sph.job?.name || '-' }}</td>
        </tr>
      </table>

      <!-- Rincian Biaya -->
      <div class="section-title">A. RINCIAN BIAYA LANGSUNG</div>
      <table class="rincian-table">
        <tr>
          <td>Nilai Jasa</td>
          <td class="amount">{{ formatRupiah(sph.nilai_jasa) }}</td>
        </tr>
        <tr>
          <td>Nilai Material</td>
          <td class="amount">{{ formatRupiah(sph.nilai_material) }}</td>
        </tr>
        <tr>
          <td>Transport per Hari ({{ sph.jumlah_hari || 0 }} hari x {{ jumlahTeknisi }} teknisi)</td>
          <td class="amount">{{ formatRupiah(totalTransport) }}</td>
        </tr>
        <tr>
          <td>Uang Makan per Hari ({{ sph.jumlah_hari || 0 }} hari x {{ jumlahTeknisi }} teknisi)</td>
          <td class="amount">{{ formatRupiah(totalUangMakan) }}</td>
        </tr>
        <tr v-if="sph.akomodasi">
          <td>Akomodasi</td>
          <td class="amount">{{ formatRupiah(sph.akomodasi) }}</td>
        </tr>
        <tr v-if="sph.biaya_lain">
          <td>Biaya Lain{{ sph.keterangan_biaya_lain ? ' (' + sph.keterangan_biaya_lain + ')' : '' }}</td>
          <td class="amount">{{ formatRupiah(sph.biaya_lain) }}</td>
        </tr>
        <tr class="total-row">
          <td>Total Biaya Langsung</td>
          <td class="amount">{{ formatRupiah(totalBiayaLangsung) }}</td>
        </tr>
      </table>

      <!-- Upah Teknisi -->
      <div class="section-title">B. UPAH TEKNISI</div>
      <table class="rincian-table">
        <thead>
          <tr>
            <th>Nama</th>
            <th>Upah/Bulan</th>
            <th>Jumlah Bulan</th>
            <th>Subtotal</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!(sph.teknisi || []).length">
            <td colspan="4" style="text-align:center;color:var(--text-muted);font-style:italic;">Tidak ada teknisi</td>
          </tr>
          <tr v-for="t in (sph.teknisi || [])" :key="t.ID">
            <td>{{ t.nama_teknisi }}</td>
            <td class="amount">{{ formatRupiah(t.upah_per_bulan) }}</td>
            <td style="text-align:center;">{{ t.jumlah_bulan }}</td>
            <td class="amount">{{ formatRupiah((t.upah_per_bulan || 0) * (t.jumlah_bulan || 0)) }}</td>
          </tr>
        </tbody>
        <tfoot v-if="(sph.teknisi || []).length">
          <tr class="total-row">
            <td colspan="3">Total Upah Teknisi</td>
            <td class="amount">{{ formatRupiah(totalUpahTeknisi) }}</td>
          </tr>
        </tfoot>
      </table>

      <!-- Biaya Tidak Langsung -->
      <div class="section-title">C. BIAYA TIDAK LANGSUNG</div>
      <table class="rincian-table">
        <tr>
          <td>Biaya Tidak Langsung</td>
          <td class="amount">{{ formatRupiah(sph.overhead) }}</td>
        </tr>
      </table>

      <!-- Rekapitulasi -->
      <div class="section-title">D. REKAPITULASI</div>
      <table class="rekap-table">
        <tr>
          <td>Total Biaya</td>
          <td class="amount">{{ formatRupiah(totalBiayaSemua) }}</td>
        </tr>
        <tr>
          <td>Margin Keuntungan</td>
          <td class="amount">{{ sph.margin_keuntungan || 0 }}%</td>
        </tr>
        <tr class="grand-total">
          <td>HARGA PENAWARAN</td>
          <td class="amount">{{ formatRupiah(hargaPenawaranAkhir) }}</td>
        </tr>
      </table>

      <div v-if="sph.catatan" class="catatan-section">
        <div class="section-title">E. CATATAN</div>
        <p class="catatan-text">{{ sph.catatan }}</p>
      </div>

      <div class="ttd-section">
        <div style="text-align:center;">
          <div>Surabaya, {{ formatDate(sph.tanggal_sph) }}</div>
          <div style="margin-top:60px;font-weight:600;">(____________________)</div>
          <div style="font-size:12px;color:var(--text-muted);margin-top:4px;">Direktur</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { sphAPI } from '../api/sph'

useHead({
  title: 'Detail SPH',
  meta: [{ name: 'description', content: 'Detail Surat Penawaran Harga' }],
})

const route = useRoute()
const router = useRouter()
const sph = ref(null)
const loading = ref(true)
const error = ref('')

const jumlahTeknisi = computed(() => Math.max((sph.value?.teknisi || []).length, 1))

const totalTransport = computed(() => {
  if (!sph.value) return 0
  return (sph.value.transport_per_hari || 0) * (sph.value.jumlah_hari || 0) * jumlahTeknisi.value
})

const totalUangMakan = computed(() => {
  if (!sph.value) return 0
  return (sph.value.uang_makan_per_hari || 0) * (sph.value.jumlah_hari || 0) * jumlahTeknisi.value
})

const totalBiayaLangsung = computed(() => {
  if (!sph.value) return 0
  return (sph.value.nilai_jasa || 0)
    + (sph.value.nilai_material || 0)
    + totalTransport.value
    + totalUangMakan.value
    + (sph.value.akomodasi || 0)
    + (sph.value.biaya_lain || 0)
})

const totalUpahTeknisi = computed(() => {
  if (!sph.value) return 0
  return (sph.value.teknisi || []).reduce((sum, t) => {
    return sum + ((t.upah_per_bulan || 0) * (t.jumlah_bulan || 0))
  }, 0)
})

const totalBiayaSemua = computed(() => {
  if (!sph.value) return 0
  return totalBiayaLangsung.value + totalUpahTeknisi.value + (sph.value.overhead || 0)
})

const hargaPenawaranAkhir = computed(() => {
  if (!sph.value) return 0
  const margin = (sph.value.margin_keuntungan || 0) / 100
  return totalBiayaSemua.value * (1 + margin)
})

function formatRupiah(val) {
  if (!val) return 'Rp 0'
  return 'Rp ' + Math.round(val).toLocaleString('id-ID')
}

function formatDate(d) {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric', month: 'long', day: 'numeric',
  })
}

function cetak() {
  window.print()
}

onMounted(async () => {
  const id = route.params.id
  if (!id) {
    error.value = 'ID SPH tidak ditemukan'
    loading.value = false
    return
  }
  try {
    const res = await sphAPI.getById(id)
    sph.value = res.data.sph
  } catch (e) {
    error.value = 'Gagal memuat data SPH'
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.sph-detail-page {
  padding: 24px;
  max-width: 900px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
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

.btn-print {
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

.btn-print:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.loading-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-muted);
  font-size: 16px;
}

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 12px 16px;
  border-radius: 10px;
  font-size: 13px;
}

/* PRINT AREA */
.print-area {
  background: #fff;
  color: #000;
  padding: 40px 48px;
  border-radius: 16px;
  border: 1px solid var(--card-border-light);
}

.header-section {
  text-align: center;
  margin-bottom: 28px;
  padding-bottom: 16px;
  border-bottom: 3px double #333;
}

.company-name {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 2px;
  color: #1a1a2e;
}

.company-detail {
  font-size: 12px;
  color: #555;
  margin-top: 2px;
}

.doc-title {
  text-align: center;
  font-size: 16px;
  font-weight: 700;
  margin-top: 20px;
  margin-bottom: 2px;
  text-decoration: underline;
  color: #1a1a2e;
}

.doc-subtitle {
  text-align: center;
  font-size: 13px;
  color: #555;
  margin-bottom: 24px;
}

.info-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 24px;
}

.info-table td {
  padding: 4px 8px;
  font-size: 13px;
  color: #333;
}

.info-table .label {
  width: 140px;
  font-weight: 600;
  color: #555;
}

.info-table .value {
  font-weight: 500;
}

.section-title {
  font-size: 13px;
  font-weight: 700;
  color: #1a1a2e;
  margin-top: 24px;
  margin-bottom: 10px;
  padding: 6px 12px;
  background: #f0f0f5;
  border-radius: 6px;
}

.rincian-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 4px;
}

.rincian-table th {
  padding: 8px 12px;
  font-size: 11px;
  font-weight: 600;
  color: #555;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  border-bottom: 2px solid #ddd;
  text-align: left;
}

.rincian-table td {
  padding: 8px 12px;
  font-size: 13px;
  color: #333;
  border-bottom: 1px solid #eee;
}

.rincian-table .amount {
  text-align: right;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  width: 180px;
}

.total-row td {
  font-weight: 700;
  color: #1a1a2e;
  border-top: 2px solid #ddd;
  padding-top: 10px;
}

.rekap-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 24px;
}

.rekap-table td {
  padding: 10px 12px;
  font-size: 14px;
  color: #333;
  border-bottom: 1px solid #eee;
}

.rekap-table .amount {
  text-align: right;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  width: 200px;
}

.grand-total td {
  font-size: 16px;
  font-weight: 800;
  color: #667eea;
  border-top: 3px double #667eea;
  padding-top: 12px;
}

.catatan-section {
  margin-bottom: 24px;
}

.catatan-text {
  font-size: 13px;
  color: #555;
  line-height: 1.6;
  padding: 0 12px;
  white-space: pre-wrap;
}

.ttd-section {
  margin-top: 40px;
  display: flex;
  justify-content: flex-end;
  padding-right: 40px;
  font-size: 13px;
  color: #333;
}

/* PRINT STYLES */
@media print {
  .no-print {
    display: none !important;
  }

  .sph-detail-page {
    padding: 0;
    max-width: 100%;
    animation: none;
  }

  .print-area {
    border: none;
    border-radius: 0;
    padding: 10px 24px;
    box-shadow: none;
  }

  .header-section {
    margin-bottom: 12px;
    padding-bottom: 8px;
  }

  .company-name {
    font-size: 18px;
  }

  .doc-title {
    margin-top: 10px;
    font-size: 16px;
  }

  .doc-subtitle {
    margin-bottom: 12px;
  }

  .info-table td {
    padding: 2px 6px;
    font-size: 13px;
  }

  .section-title {
    margin-top: 10px;
    margin-bottom: 4px;
    padding: 4px 8px;
    font-size: 13px;
  }

  .rincian-table td,
  .rincian-table th {
    padding: 4px 8px;
    font-size: 13px;
  }

  .rekap-table td {
    padding: 5px 8px;
    font-size: 14px;
  }

  .grand-total td {
    font-size: 16px;
    padding-top: 6px;
  }

  .catatan-section {
    margin-bottom: 8px;
  }

  .catatan-text {
    font-size: 13px;
    line-height: 1.4;
  }

  .ttd-section {
    margin-top: 16px;
    padding-right: 20px;
    font-size: 13px;
  }

  @page {
    margin: 12mm 10mm;
  }
}
</style>