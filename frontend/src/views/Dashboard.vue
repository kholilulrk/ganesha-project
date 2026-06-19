<template>
  <div class="dashboard-page">
    <div class="page-header">
      <h1>Dashboard</h1>
      <p>Ringkasan data pekerjaan dan tugas</p>
    </div>

    <div class="stats-grid">
      <div class="stat-card total" @click="goToPekerjaan()">
        <div class="stat-icon">📊</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.total_jobs }}</span>
          <span class="stat-label">Total Pekerjaan</span>
        </div>
      </div>
      <div class="stat-card pending" @click="goToPekerjaan('pending')">
        <div class="stat-icon">📋</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.pending_jobs }}</span>
          <span class="stat-label">Pekerjaan Pending</span>
        </div>
      </div>
      <div class="stat-card progres" @click="goToPekerjaan('progres')">
        <div class="stat-icon">🔧</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.progres_jobs }}</span>
          <span class="stat-label">Pekerjaan Progress</span>
        </div>
      </div>
      <div class="stat-card selesai" @click="goToPekerjaan('done')">
        <div class="stat-icon">✅</div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.completed_jobs }}</span>
          <span class="stat-label">Pekerjaan Selesai</span>
        </div>
      </div>
    </div>

    <div v-if="!isSuperAdmin" class="attendance-card" :class="attendanceCardClass">
      <div class="attendance-body">
        <div class="attendance-icon">{{ attendanceIcon }}</div>
        <div class="attendance-text">
          <strong>{{ attendanceTitle }}</strong>
          <span>{{ attendanceDesc }}</span>
        </div>
        <div class="attendance-actions" v-if="showAttendanceActions">
          <button v-if="showHadirBtn" class="btn-attend hadir" :disabled="attLoading" @click="openHadirModal">Hadir</button>
          <button v-if="showTidakHadirBtn" class="btn-attend tidak-hadir" :disabled="attLoading" @click="openTidakHadirModal">Tidak Hadir</button>
          <button v-if="showMulaiLemburBtn" class="btn-attend lembur" :disabled="attLoading" @click="handleLemburStart">Mulai Lembur</button>
          <button v-if="showAkhiriLemburBtn" class="btn-attend lembur-akhir" :disabled="attLoading" @click="handleLemburEnd">Akhiri Lembur</button>
        </div>
        <div v-if="attendanceStatus" class="attendance-status" :class="attendanceStatusClass">{{ attendanceStatus }}</div>
      </div>
    </div>

    <!-- Modal Hadir -->
    <transition name="modal-fade">
      <div v-if="showHadirModal" class="modal-overlay" @click.self="showHadirModal = false">
        <div class="modal-card modal-sm">
          <div class="modal-header">
            <h2>Absen Hadir</h2>
            <button class="btn-close" @click="showHadirModal = false">✕</button>
          </div>
          <div class="modal-body">
            <p class="modal-desc">Pilih lokasi kerja hari ini:</p>
            <div class="location-options">
              <button class="location-btn" :class="{ active: selectedLocation === 'kantor' }" @click="selectedLocation = 'kantor'">
                <span class="loc-icon">🏢</span>
                <span>Di Kantor</span>
              </button>
              <button class="location-btn" :class="{ active: selectedLocation === 'luar_kota' }" @click="selectedLocation = 'luar_kota'">
                <span class="loc-icon">🚗</span>
                <span>Luar Kota</span>
              </button>
            </div>
            <div v-if="hadirError" class="error-banner">{{ hadirError }}</div>
            <div class="form-actions">
              <button class="btn-cancel" @click="showHadirModal = false">Batal</button>
              <button class="btn-save" :disabled="attLoading" @click="handleHadir">
                <span v-if="attLoading" class="spinner-sm" />
                <span v-else>Konfirmasi Hadir</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Modal Tidak Hadir -->
    <transition name="modal-fade">
      <div v-if="showTidakHadirModal" class="modal-overlay" @click.self="showTidakHadirModal = false">
        <div class="modal-card modal-sm">
          <div class="modal-header">
            <h2>Tidak Hadir</h2>
            <button class="btn-close" @click="showTidakHadirModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>Alasan Tidak Hadir</label>
              <textarea v-model="tidakHadirReason" placeholder="Tuliskan alasan..." rows="3" class="form-input" />
            </div>
            <div v-if="tidakHadirError" class="error-banner">{{ tidakHadirError }}</div>
            <div class="form-actions">
              <button class="btn-cancel" @click="showTidakHadirModal = false">Batal</button>
              <button class="btn-save" :disabled="attLoading || !tidakHadirReason.trim()" @click="handleTidakHadir">
                <span v-if="attLoading" class="spinner-sm" />
                <span v-else>Konfirmasi</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <transition name="modal-fade">
      <div v-if="showCreateForm" class="modal-overlay" @click.self="closeCreateForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>Tambah Pekerjaan</h2>
            <button class="btn-close" @click="closeCreateForm">✕</button>
          </div>
          <form @submit.prevent="handleCreateJob" class="job-form">
            <div class="form-group">
              <label>Nama Pekerjaan</label>
              <input v-model="createForm.name" type="text" placeholder="Nama pekerjaan" required />
            </div>
            <div class="form-group">
              <label>Deskripsi Pekerjaan</label>
              <textarea v-model="createForm.description" placeholder="Deskripsi pekerjaan" rows="3" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Nilai Pekerjaan (Rp)</label>
                <input v-model="createForm.value" type="text" placeholder="0" @input="formatValueInput" />
              </div>
              <div class="form-group">
                <label>Tanggal Kontrak</label>
                <input v-model="createForm.contract_date" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Share (Role)</label>
              <div class="checkbox-group">
                <label v-for="role in roleOptions" :key="role" class="checkbox-label">
                  <input type="checkbox" :value="role" v-model="createForm.share" />
                  <span>{{ role }}</span>
                </label>
              </div>
              <label v-if="createForm.share.includes('Teknisi')" class="checkbox-label" style="margin-top:8px">
                <input type="checkbox" v-model="createForm.allTeknisi" />
                <span>Semua Teknisi</span>
              </label>
              <div v-if="usersByRole && createForm.share.length && !createForm.allTeknisi" class="user-checkboxes">
                <div v-for="role in createForm.share" :key="role" class="user-group">
                  <label class="user-group-label">{{ role }}</label>
                  <div v-if="usersByRole[role] && usersByRole[role].length" class="checkbox-group">
                    <label v-for="u in usersByRole[role]" :key="u.ID" class="checkbox-label user-item">
                      <input type="checkbox" :value="u.ID" v-model="createForm.assigned_to" />
                      <span>{{ u.name }} ({{ u.username }})</span>
                    </label>
                  </div>
                  <p v-else class="no-users">Tidak ada user dengan role {{ role }}</p>
                </div>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Status</label>
                <select v-model="createForm.status">
                  <option value="pending">Pending</option>
                  <option value="progres">Progres</option>
                  <option value="done">Done</option>
                </select>
              </div>
              <div class="form-group">
                <label>Dateline</label>
                <input v-model="createForm.dateline" type="date" />
              </div>
            </div>
            <div class="form-group">
              <label>Referensi Dokumen (PDF)</label>
              <select v-model="createForm.spektek" class="doc-select">
                <option value="">Pilih dokumen</option>
                <option v-for="doc in pdfDocuments" :key="doc.ID" :value="doc.file_path">
                  {{ doc.nama_dokumen }}
                </option>
              </select>
              <button v-if="createForm.spektek" type="button" class="btn-clear-doc" @click="createForm.spektek = ''">Hapus pilihan</button>
            </div>
            <div v-if="createError" class="error-banner">{{ createError }}</div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeCreateForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="createLoading">
                <span v-if="createLoading" class="spinner-sm" />
                <span v-else>Tambah</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

    <transition name="toast-slide">
      <div v-if="showAnnouncementToast" class="announcement-toast" @click="showAnnouncementToast = false">
        <span class="toast-icon">&#128240;</span>
        <div class="toast-body">
          <span class="toast-title">Pengumuman Baru</span>
          <span class="toast-text">{{ latestAnnouncement?.title }}</span>
        </div>
      </div>
    </transition>

    <div v-if="stats.announcements?.length" class="announcements-section">
      <div class="section-header">
        <h2>&#128240; Pengumuman</h2>
      </div>
      <div class="announcement-list">
        <div v-for="a in stats.announcements" :key="a.ID" class="announcement-item">
          <div class="announcement-header">
            <span class="announcement-title">{{ a.title }}</span>
            <span class="announcement-date">{{ formatDate(a.start_at) }} - {{ formatDate(a.end_at) }}</span>
          </div>
          <p v-if="a.content" class="announcement-content">{{ a.content }}</p>
        </div>
      </div>
    </div>

    <div v-if="stats.expiring_surats?.length" class="section warning-section">
      <div class="section-header">
        <h2>&#9888;&#65039; Surat Akan Kadaluarsa</h2>
        <span class="warning-count">{{ stats.expiring_surats.length }} surat</span>
      </div>
      <div class="surat-list">
        <div v-for="surat in stats.expiring_surats" :key="surat.ID" class="surat-item">
          <div class="surat-info">
            <span class="surat-name">{{ surat.nama_surat }}</span>
            <span class="surat-meta">{{ surat.jenis_surat }} &#183; {{ sisaHari(surat.masa_berlaku) }}</span>
          </div>
          <span class="surat-badge" :class="surat.jenis_surat">{{ surat.jenis_surat }}</span>
        </div>
      </div>
      <router-link to="/monitoring-surat" class="section-link">Lihat semua &#8594;</router-link>
    </div>

    <div class="section">
      <h2>Pekerjaan Terbaru</h2>
      <div class="pending-list" v-if="stats.recent_pending?.length">
        <div v-for="job in stats.recent_pending" :key="job.ID" class="pending-item" @click="goToPekerjaan()">
          <div class="pending-info">
            <span class="pending-name">{{ job.name }}</span>
            <span class="pending-meta">{{ job.share }} · {{ formatDate(job.contract_date) }}</span>
          </div>
          <span class="status-badge" :class="job.status">{{ job.status || 'pending' }}</span>
        </div>
      </div>
      <div v-else class="empty-section">
        <p>Tidak ada pekerjaan</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { usePermissionStore } from '../stores/permissions'
import { useHead } from '@unhead/vue'
import { dashboardAPI } from '../api/dashboard'
useHead({
  title: 'Dashboard',
  meta: [
    { name: 'description', content: 'Dashboard Ganesha Energi - ringkasan pekerjaan dan tugas' },
  ],
})
import { jobAPI } from '../api/job'
import { userAPI } from '../api/user'
import { documentAPI } from '../api/document'
import { attendanceAPI } from '../api/attendance'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const perms = usePermissionStore()
const auth = useAuthStore()
const isSuperAdmin = computed(() => auth.user?.role === 'Super Admin')

const canCreate = computed(() => perms.can('pekerjaan', 'create'))

const stats = ref({
  pending_jobs: 0,
  uncompleted_teknisi: 0,
  uncompleted_logistic: 0,
  uncompleted_jobs: 0,
  recent_pending: [],
})

// Attendance
const attendanceRecord = ref(null)
const attLoading = ref(false)
const showHadirModal = ref(false)
const showTidakHadirModal = ref(false)
const selectedLocation = ref('kantor')
const tidakHadirReason = ref('')
const hadirError = ref('')
const tidakHadirError = ref('')

const currentHour = ref(new Date().getHours())
const currentMinute = ref(new Date().getMinutes())

let attTimer = null

function updateTime() {
  const now = new Date()
  currentHour.value = now.getHours()
  currentMinute.value = now.getMinutes()
}

const isAttendanceTime = computed(() => {
  const totalMin = currentHour.value * 60 + currentMinute.value
  return totalMin >= 30 && currentHour.value < 17
})

const isOvertimeTime = computed(() => {
  return currentHour.value >= 17 && currentHour.value < 24
})

const showAttendanceActions = computed(() => {
  if (isOvertimeTime.value) {
    if (!attendanceRecord.value) return false
    if (attendanceRecord.value.type === 'tidak_hadir') return false
    if (attendanceRecord.value.location === 'luar_kota') return false
    if (attendanceRecord.value.type === 'lembur' && !attendanceRecord.value.lembur_end) return true
    if (attendanceRecord.value.type === 'lembur' && attendanceRecord.value.lembur_end) return false
    return true
  }
  if (!attendanceRecord.value) return true
  return false
})

const showHadirBtn = computed(() => {
  if (isOvertimeTime.value) return false
  return !attendanceRecord.value
})

const showTidakHadirBtn = computed(() => {
  if (isOvertimeTime.value) return false
  return !attendanceRecord.value
})

const showMulaiLemburBtn = computed(() => {
  if (!isOvertimeTime.value) return false
  if (!attendanceRecord.value) return false
  if (attendanceRecord.value.type === 'tidak_hadir') return false
  if (attendanceRecord.value.location === 'luar_kota') return false
  return attendanceRecord.value.type !== 'lembur'
})

const showAkhiriLemburBtn = computed(() => {
  if (!isOvertimeTime.value) return false
  if (!attendanceRecord.value) return false
  if (attendanceRecord.value.type !== 'lembur') return false
  return !attendanceRecord.value.lembur_end
})

const attendanceCardClass = computed(() => {
  if (isOvertimeTime.value) return 'overtime'
  if (attendanceRecord.value?.type === 'hadir' || attendanceRecord.value?.type === 'lembur') return 'hadir'
  if (attendanceRecord.value?.type === 'tidak_hadir') return 'absent'
  return ''
})

const attendanceIcon = computed(() => {
  if (isOvertimeTime.value) return '🌙'
  if (attendanceRecord.value?.type === 'hadir') return '✅'
  if (attendanceRecord.value?.type === 'tidak_hadir') return '❌'
  return '📋'
})

const attendanceTitle = computed(() => {
  if (isOvertimeTime.value) return 'Lembur'
  if (attendanceRecord.value?.type === 'hadir' && attendanceRecord.value?.location === 'luar_kota') return 'Hadir (Luar Kota)'
  if (attendanceRecord.value?.type === 'hadir') return 'Sudah Absen Hadir'
  if (attendanceRecord.value?.type === 'tidak_hadir') return 'Tidak Hadir'
  return 'Absen Hari Ini'
})

const attendanceDesc = computed(() => {
  if (isOvertimeTime.value) {
    if (!attendanceRecord.value) return 'Belum absen hari ini'
    if (attendanceRecord.value.type === 'tidak_hadir') return 'Tidak bisa lembur'
    if (attendanceRecord.value.location === 'luar_kota') return 'Tidak bisa lembur (luar kota)'
    if (attendanceRecord.value.type === 'lembur' && attendanceRecord.value.lembur_end) {
      const durasi = hitungDurasi(attendanceRecord.value.lembur_start, attendanceRecord.value.lembur_end)
      return `Lembur selesai · ${durasi}`
    }
    if (attendanceRecord.value.type === 'lembur') return `Mulai ${attendanceRecord.value.lembur_start}`
    return `Absen ${attendanceRecord.value.clock_in} · Klik untuk lembur`
  }
  if (attendanceRecord.value?.type === 'hadir' && attendanceRecord.value?.clock_in) {
    const loc = attendanceRecord.value.location === 'luar_kota' ? 'Luar Kota' : 'Kantor'
    return `Jam ${attendanceRecord.value.clock_in} · ${loc}`
  }
  if (attendanceRecord.value?.type === 'tidak_hadir' && attendanceRecord.value?.reason) {
    return attendanceRecord.value.reason
  }
  if (isAttendanceTime.value) return 'Klik Hadir atau Tidak Hadir'
  if (currentHour.value < 17) return 'Waktu absen belum dimulai (00:30)'
  return ''
})

const attendanceStatus = computed(() => {
  if (isOvertimeTime.value && attendanceRecord.value?.type === 'lembur' && attendanceRecord.value?.lembur_end) {
    const durasi = hitungDurasi(attendanceRecord.value.lembur_start, attendanceRecord.value.lembur_end)
    return `Durasi: ${durasi}`
  }
  return ''
})

const attendanceStatusClass = computed(() => {
  return 'status-done'
})

function hitungDurasi(clockIn, clockOut) {
  if (!clockIn || !clockOut) return '-'
  const [h1, m1] = clockIn.split(':').map(Number)
  const [h2, m2] = clockOut.split(':').map(Number)
  let totalMenit = (h2 * 60 + m2) - (h1 * 60 + m1)
  if (totalMenit < 0) totalMenit += 24 * 60
  const jam = Math.floor(totalMenit / 60)
  const menit = totalMenit % 60
  return `${jam}j ${menit}m`
}

async function fetchTodayAttendance() {
  try {
    const res = await attendanceAPI.getToday()
    attendanceRecord.value = res.data.attendance || null
  } catch { /* ignore */ }
}

function openHadirModal() {
  selectedLocation.value = 'kantor'
  hadirError.value = ''
  showHadirModal.value = true
}

function openTidakHadirModal() {
  tidakHadirReason.value = ''
  tidakHadirError.value = ''
  showTidakHadirModal.value = true
}

async function handleHadir() {
  attLoading.value = true
  hadirError.value = ''
  try {
    const res = await attendanceAPI.hadir(selectedLocation.value)
    attendanceRecord.value = res.data.attendance
    showHadirModal.value = false
  } catch (err) {
    hadirError.value = err.response?.data?.error || 'Gagal absen'
  } finally {
    attLoading.value = false
  }
}

async function handleTidakHadir() {
  if (!tidakHadirReason.value.trim()) return
  attLoading.value = true
  tidakHadirError.value = ''
  try {
    const res = await attendanceAPI.tidakHadir(tidakHadirReason.value.trim())
    attendanceRecord.value = res.data.attendance
    showTidakHadirModal.value = false
  } catch (err) {
    tidakHadirError.value = err.response?.data?.error || 'Gagal absen'
  } finally {
    attLoading.value = false
  }
}

async function handleLemburStart() {
  attLoading.value = true
  try {
    const res = await attendanceAPI.lemburStart()
    attendanceRecord.value = res.data.attendance
  } catch (err) {
    alert(err.response?.data?.error || 'Gagal mulai lembur')
  } finally {
    attLoading.value = false
  }
}

async function handleLemburEnd() {
  attLoading.value = true
  try {
    const res = await attendanceAPI.lemburEnd()
    attendanceRecord.value = res.data.attendance
  } catch (err) {
    alert(err.response?.data?.error || 'Gagal akhiri lembur')
  } finally {
    attLoading.value = false
  }
}

const showAnnouncementToast = ref(false)
const latestAnnouncement = ref(null)
let prevAnnouncementIds = []

const showCreateForm = ref(false)
const createLoading = ref(false)
const createError = ref('')
const allDocuments = ref([])
const pdfDocuments = computed(() => allDocuments.value.filter(d => d.tipe_dokumen === 'PDF'))
const roleOptions = ['Teknisi']

const createForm = reactive({
  name: '',
  description: '',
  value: '',
  contract_date: '',
  share: [],
  status: 'pending',
  dateline: '',
  assigned_to: [],
  spektek: '',
  allTeknisi: false,
})

const users = ref([])
const usersByRole = computed(() => {
  const map = {}
  for (const r of roleOptions) {
    map[r] = users.value.filter(u => u.role === r)
  }
  return map
})

async function fetchUsers() {
  if (!createForm.share.length) {
    users.value = []
    return
  }
  try {
    const res = await userAPI.getAll({ roles: createForm.share.join(',') })
    users.value = res.data.users
  } catch {
    users.value = []
  }
}

watch(() => createForm.share, () => {
  createForm.assigned_to = []
  fetchUsers()
})

function playNotificationSound() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = 800
    osc.type = 'sine'
    gain.gain.setValueAtTime(0.3, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3)
    osc.start(ctx.currentTime)
    osc.stop(ctx.currentTime + 0.3)
  } catch { /* ignore */ }
}

function checkNewAnnouncements() {
  const announcements = stats.value.announcements || []
  if (!announcements.length) return
  const currentIds = announcements.map(a => a.ID)
  const newOnes = announcements.filter(a => !prevAnnouncementIds.includes(a.ID))
  if (newOnes.length) {
    latestAnnouncement.value = newOnes[0]
    showAnnouncementToast.value = true
    playNotificationSound()
    setTimeout(() => { showAnnouncementToast.value = false }, 5000)
  }
  prevAnnouncementIds = currentIds
}

onMounted(async () => {
  await perms.load()
  updateTime()
  attTimer = setInterval(updateTime, 30000)
  try {
    const res = await dashboardAPI.getStats()
    stats.value = res.data
    checkNewAnnouncements()
  } catch { /* ignore */ }
  try {
    const res = await documentAPI.getAll()
    allDocuments.value = res.data.documents
  } catch { /* ignore */ }
  if (!isSuperAdmin.value) {
    fetchTodayAttendance()
  }
})

function goToPekerjaan(status, share, checklistIncomplete) {
  const query = {}
  if (status) query.status = status
  if (share) query.share = share
  if (checklistIncomplete) query.checklist_incomplete = checklistIncomplete
  router.push({ path: '/pekerjaan', query })
}

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleDateString('id-ID', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

function sisaHari(tgl) {
  const now = new Date()
  const expire = new Date(tgl)
  const diff = Math.ceil((expire - now) / (1000 * 60 * 60 * 24))
  if (diff <= 1) return 'Besok kadaluarsa'
  return `${diff} hari lagi`
}

function openCreateForm() {
  showCreateForm.value = true
}

function closeCreateForm() {
  showCreateForm.value = false
  createForm.name = ''
  createForm.description = ''
  createForm.value = ''
  createForm.contract_date = ''
  createForm.share = []
  createForm.status = 'pending'
  createForm.dateline = ''
  createForm.assigned_to = []
  createForm.spektek = ''
  createForm.allTeknisi = false
  users.value = []
}

function formatValueInput() {
  createForm.value = createForm.value.replace(/[^0-9]/g, '')
  if (createForm.value) {
    createForm.value = parseInt(createForm.value).toLocaleString('id-ID')
  }
}

function parseValue(val) {
  return val.replace(/\./g, '')
}

async function handleCreateJob() {
  createLoading.value = true
  createError.value = ''
  try {
    const assignedTo = createForm.allTeknisi ? '' : createForm.assigned_to.join(',')
    const data = {
      name: createForm.name,
      description: createForm.description,
      value: parseValue(createForm.value),
      contract_date: createForm.contract_date,
      share: createForm.share.join(','),
      status: createForm.status,
      dateline: createForm.dateline || '',
      assigned_to: assignedTo,
      spektek: createForm.spektek,
    }
    await jobAPI.create(data)
    closeCreateForm()
    const res = await dashboardAPI.getStats()
    stats.value = res.data
  } catch (err) {
    createError.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    createLoading.value = false
  }
}
</script>

<style scoped>
.dashboard-page {
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
  margin-bottom: 28px;
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 32px;
}

.stat-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 14px;
  transition: transform 0.2s, box-shadow 0.2s;
  cursor: pointer;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.stat-icon {
  font-size: 28px;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  flex-shrink: 0;
}

.stat-card.total .stat-icon { background: rgba(102, 126, 234, 0.15); }
.stat-card.pending .stat-icon { background: rgba(255, 193, 7, 0.15); }
.stat-card.progres .stat-icon { background: rgba(245, 158, 11, 0.15); }
.stat-card.selesai .stat-icon { background: rgba(81, 207, 102, 0.15); }

.stat-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
}

.stat-label {
  font-size: 12px;
  color: var(--text-muted);
  font-weight: 500;
}

.section {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  padding: 24px;
}

.section h2 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 16px;
}

.pending-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.pending-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.2s;
}

.pending-item:hover {
  background: var(--hover-bg-strong);
}

.pending-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pending-name {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.pending-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.pending-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.empty-section {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-dim);
  font-size: 14px;
}

.announcement-toast {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 9999;
  display: flex;
  align-items: center;
  gap: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  padding: 16px 20px;
  border-radius: 14px;
  box-shadow: 0 8px 32px rgba(102, 126, 234, 0.35);
  cursor: pointer;
  max-width: 360px;
  animation: toastIn 0.4s ease;
}

@keyframes toastIn {
  from { opacity: 0; transform: translateX(40px); }
  to { opacity: 1; transform: translateX(0); }
}

.toast-slide-enter-active { animation: toastIn 0.4s ease; }
.toast-slide-leave-active { transition: opacity 0.3s, transform 0.3s; }
.toast-slide-leave-to { opacity: 0; transform: translateX(40px); }

.toast-icon {
  font-size: 28px;
  flex-shrink: 0;
}

.toast-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.toast-title {
  font-size: 13px;
  font-weight: 700;
}

.toast-text {
  font-size: 12px;
  opacity: 0.9;
}

.announcements-section {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
}

.announcement-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.announcement-item {
  padding: 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  border-left: 4px solid #667eea;
}

.announcement-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 4px;
}

.announcement-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.announcement-date {
  font-size: 11px;
  color: var(--text-muted);
  white-space: nowrap;
}

.announcement-content {
  font-size: 13px;
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.5;
}

.warning-section {
  border: 1px solid rgba(255, 193, 7, 0.3);
  margin-bottom: 24px;
  animation: pulse-warning 2s infinite;
}

@keyframes pulse-warning {
  0%, 100% { box-shadow: 0 0 0 0 rgba(255, 193, 7, 0); }
  50% { box-shadow: 0 0 12px 2px rgba(255, 193, 7, 0.15); }
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.warning-count {
  font-size: 12px;
  font-weight: 600;
  color: #ffc107;
  background: rgba(255, 193, 7, 0.15);
  padding: 4px 10px;
  border-radius: 8px;
}

.surat-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 12px;
}

.surat-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--hover-bg);
  border-radius: 10px;
  transition: background 0.2s;
}

.surat-item:hover {
  background: var(--hover-bg-strong);
}

.surat-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.surat-name {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.surat-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.surat-badge {
  padding: 3px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.surat-badge.SIK {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
}

.surat-badge.SC {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.section-link {
  display: block;
  text-align: center;
  font-size: 13px;
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
  padding: 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.section-link:hover {
  background: rgba(102, 126, 234, 0.1);
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
  background: #fff;
  border-radius: 16px;
  width: 100%;
  max-width: 640px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  animation: modalSlideIn 0.25s ease;
}

@keyframes modalSlideIn {
  from { opacity: 0; transform: translateY(20px) scale(0.97); }
  to { opacity: 1; transform: translateY(0) scale(1); }
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
  transition: background 0.2s;
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.job-form {
  padding: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 16px;
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
  transition: border-color 0.2s, box-shadow 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15);
}

.form-group textarea {
  resize: vertical;
  min-height: 70px;
}

.form-group select option {
  padding: 8px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.checkbox-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 4px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  cursor: pointer;
  padding: 6px 12px;
  background: var(--hover-bg);
  border-radius: 8px;
  transition: background 0.2s;
  user-select: none;
}

.checkbox-label:hover {
  background: var(--hover-bg-strong);
}

.checkbox-label input[type="checkbox"] {
  width: auto;
  margin: 0;
}

.user-checkboxes {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.user-group-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 4px;
  display: block;
}

.user-item {
  font-size: 12px;
}

.no-users {
  font-size: 12px;
  color: var(--text-dim);
  font-style: italic;
  padding: 4px 0;
}

.doc-select {
  width: 100%;
}

.btn-clear-doc {
  align-self: flex-start;
  border: none;
  background: none;
  color: #ef4444;
  font-size: 12px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.2s;
}

.btn-clear-doc:hover {
  background: rgba(239, 68, 68, 0.1);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid var(--card-border-light);
}

.btn-cancel {
  padding: 10px 20px;
  border: 1px solid var(--card-border);
  background: var(--card-bg);
  border-radius: 10px;
  font-size: 14px;
  cursor: pointer;
  color: var(--text-secondary);
  transition: background 0.2s, border-color 0.2s;
  font-weight: 500;
}

.btn-cancel:hover {
  background: var(--hover-bg);
  border-color: var(--text-muted);
}

.btn-save {
  padding: 10px 24px;
  border: none;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-save:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-1px);
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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

.modal-body {
  padding: 24px;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

/* Attendance Card */
.attendance-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 24px;
  transition: all 0.3s;
}

.attendance-card.hadir {
  border-color: #51cf66;
  background: rgba(81, 207, 102, 0.04);
}

.attendance-card.absent {
  border-color: #ff6b6b;
  background: rgba(255, 107, 107, 0.04);
}

.attendance-card.overtime {
  border-color: #f59e0b;
  background: rgba(245, 158, 11, 0.04);
}

.attendance-body {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

.attendance-icon {
  font-size: 28px;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  background: var(--hover-bg);
  flex-shrink: 0;
}

.attendance-card.hadir .attendance-icon {
  background: rgba(81, 207, 102, 0.15);
}

.attendance-card.absent .attendance-icon {
  background: rgba(255, 107, 107, 0.15);
}

.attendance-card.overtime .attendance-icon {
  background: rgba(245, 158, 11, 0.15);
}

.attendance-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 140px;
}

.attendance-text strong {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.attendance-text span {
  font-size: 12px;
  color: var(--text-muted);
}

.attendance-actions {
  display: flex;
  gap: 8px;
  margin-left: auto;
}

.btn-attend {
  padding: 8px 18px;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-family: inherit;
  white-space: nowrap;
}

.btn-attend:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-attend.hadir {
  background: linear-gradient(135deg, #51cf66, #2b8a3e);
  color: #fff;
}

.btn-attend.hadir:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(81, 207, 102, 0.3);
}

.btn-attend.tidak-hadir {
  background: linear-gradient(135deg, #ff6b6b, #c92a2a);
  color: #fff;
}

.btn-attend.tidak-hadir:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
}

.btn-attend.lembur {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: #fff;
}

.btn-attend.lembur:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}

.btn-attend.lembur-akhir {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
}

.btn-attend.lembur-akhir:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.attendance-status {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 8px;
  white-space: nowrap;
}

.attendance-status.status-done {
  background: rgba(81, 207, 102, 0.15);
  color: #51cf66;
}

.modal-sm .modal-card {
  max-width: 420px;
}

.modal-desc {
  color: var(--text-secondary);
  font-size: 14px;
  margin-bottom: 16px;
}

.location-options {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.location-btn {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 16px;
  border: 2px solid var(--card-border);
  border-radius: 12px;
  background: var(--card-bg);
  cursor: pointer;
  transition: all 0.2s;
  font-family: inherit;
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
}

.location-btn:hover {
  border-color: #667eea;
}

.location-btn.active {
  border-color: #667eea;
  background: rgba(102, 126, 234, 0.06);
  color: #667eea;
}

.loc-icon {
  font-size: 24px;
}

.form-input {
  padding: 10px 14px;
  border: 1px solid var(--card-border);
  border-radius: 10px;
  font-size: 14px;
  background: var(--input-bg);
  color: var(--text-primary);
  transition: border-color 0.2s;
  font-family: inherit;
  width: 100%;
  box-sizing: border-box;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15);
}

@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
