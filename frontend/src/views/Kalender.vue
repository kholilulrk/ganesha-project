<template>
  <div class="kalender-page">
    <div class="page-header">
      <h1>Kalender</h1>
      <p>Event dan kegiatan</p>
    </div>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <div class="calendar-wrap">
      <FullCalendar :options="calendarOptions" ref="calendarRef" />
    </div>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h2>{{ editing ? 'Edit Event' : 'Event Baru' }}</h2>
            <button class="modal-close" @click="closeModal">&times;</button>
          </div>
          <div class="modal-body">
            <div class="form-field">
              <label>Judul</label>
              <input v-model="formTitle" placeholder="Nama event..." class="form-input" />
            </div>
            <div class="form-field">
              <label>Deskripsi</label>
              <textarea v-model="formDesc" placeholder="Deskripsi (opsional)" class="form-input form-textarea" rows="3"></textarea>
            </div>
            <div class="form-row">
              <div class="form-field">
                <label>Tanggal</label>
                <input v-model="formDate" type="date" class="form-input" />
              </div>
              <div class="form-field">
                <label>Waktu</label>
                <input v-model="formTime" type="time" class="form-input" />
              </div>
            </div>
            <div class="form-field">
              <label>Warna</label>
              <div class="color-picker">
                <div v-for="c in colors" :key="c" class="color-swatch" :class="{ active: formColor === c }" :style="{ background: c }" @click="formColor = c"></div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button v-if="editing" class="btn btn-danger" @click="deleteEvent">Hapus</button>
            <button class="btn btn-secondary" @click="closeModal">Batal</button>
            <button class="btn btn-primary" @click="saveEvent" :disabled="!canSave">
              {{ editing ? 'Simpan' : 'Tambah' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import interactionPlugin from '@fullcalendar/interaction'
import { calendarAPI } from '../api/calendar'

useHead({
  title: 'Kalender',
  meta: [
    { name: 'description', content: 'Kalender event Ganesha Energi' },
  ],
})

const error = ref('')
const calendarRef = ref(null)
const showModal = ref(false)
const editing = ref(false)
const editId = ref(null)

const formTitle = ref('')
const formDesc = ref('')
const formDate = ref('')
const formTime = ref('')
const formColor = ref('#667eea')

const colors = [
  '#667eea', '#764ba2', '#51cf66', '#ff6b6b',
  '#fcc419', '#339af0', '#f06595', '#20c997',
]

const canSave = computed(() => formTitle.value.trim() !== '' && formDate.value !== '')

function todayStr() {
  const d = new Date()
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
}

function resetForm() {
  formTitle.value = ''
  formDesc.value = ''
  formDate.value = todayStr()
  formTime.value = ''
  formColor.value = '#667eea'
}

function closeModal() {
  showModal.value = false
  editing.value = false
  editId.value = null
  error.value = ''
  resetForm()
}

function openCreateModal(dateStr) {
  editing.value = false
  editId.value = null
  resetForm()
  formDate.value = dateStr
  showModal.value = true
}

function openEditModal(event) {
  editing.value = true
  editId.value = event.id
  formTitle.value = event.title
  formDesc.value = event.extendedProps.description || ''
  formDate.value = event.startStr.slice(0, 10)
  formTime.value = event.extendedProps.time || ''
  formColor.value = event.backgroundColor || '#667eea'
  showModal.value = true
}

async function loadEvents() {
  try {
    const res = await calendarAPI.getAll()
    calendarOptions.value.events = res.data.events.map(e => ({
      id: e.ID,
      title: e.title,
      start: e.date + (e.time ? 'T' + e.time : ''),
      allDay: !e.time,
      backgroundColor: e.color,
      borderColor: e.color,
      textColor: '#fff',
      extendedProps: {
        description: e.description,
        time: e.time,
      },
    }))
  } catch {
    error.value = 'Gagal memuat event'
  }
}

async function saveEvent() {
  error.value = ''
  const payload = {
    title: formTitle.value.trim(),
    description: formDesc.value,
    date: formDate.value,
    time: formTime.value,
    color: formColor.value,
  }
  try {
    if (editing.value && editId.value) {
      await calendarAPI.update(editId.value, payload)
    } else {
      await calendarAPI.create(payload)
    }
    closeModal()
    await loadEvents()
  } catch (e) {
    error.value = 'Gagal menyimpan event: ' + (e.response?.data?.error || e.message)
  }
}

async function deleteEvent() {
  if (!editId.value) return
  if (!confirm('Hapus event ini?')) return
  error.value = ''
  try {
    await calendarAPI.delete(editId.value)
    closeModal()
    await loadEvents()
  } catch (e) {
    error.value = 'Gagal menghapus event: ' + (e.response?.data?.error || e.message)
  }
}

const calendarOptions = ref({
  plugins: [dayGridPlugin, interactionPlugin],
  initialView: 'dayGridMonth',
  firstDay: 1,
  height: 650,
  headerToolbar: {
    left: 'prev,next today',
    center: 'title',
    right: 'dayGridMonth,dayGridWeek,dayGridDay',
  },
  buttonText: {
    today: 'Hari Ini',
    month: 'Bulan',
    week: 'Minggu',
    day: 'Hari',
  },
  events: [],
  editable: false,
  selectable: true,
  dateClick(info) {
    openCreateModal(info.dateStr)
  },
  eventClick(info) {
    openEditModal(info.event)
  },
  noEventsText: 'Tidak ada event',
  dayMaxEvents: true,
  moreLinkText: (num) => `+${num} lagi`,
})

onMounted(() => {
  loadEvents()
})
</script>

<style scoped>
.kalender-page {
  padding: 24px;
  max-width: 1100px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  margin-bottom: 20px;
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

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 13px;
}

.calendar-wrap {
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 16px;
  padding: 20px;
  overflow: hidden;
}

:deep(.fc) {
  --fc-border-color: var(--card-border);
  --fc-page-bg-color: transparent;
  --fc-neutral-bg-color: var(--card-bg);
  --fc-list-event-hover-bg-color: var(--hover-bg);
  --fc-today-bg-color: rgba(102, 126, 234, 0.08);
  --fc-event-bg-color: #667eea;
  --fc-event-border-color: #667eea;
  --fc-event-text-color: #fff;
  --fc-more-link-bg-color: var(--hover-bg);
  --fc-more-link-text-color: var(--text-secondary);
  font-family: 'Inter', sans-serif;
}

:deep(.fc .fc-toolbar-title) {
  color: var(--text-primary);
  font-size: 18px;
  font-weight: 600;
}

:deep(.fc .fc-button) {
  background: var(--hover-bg);
  border: 1px solid var(--card-border-light);
  color: var(--text-secondary);
  font-family: 'Inter', sans-serif;
  font-size: 13px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 8px;
  transition: all 0.2s;
}

:deep(.fc .fc-button:hover) {
  background: var(--hover-bg-strong);
  color: var(--text-primary);
}

:deep(.fc .fc-button-primary:not(:disabled).fc-button-active) {
  background: rgba(102, 126, 234, 0.2);
  color: #667eea;
  border-color: rgba(102, 126, 234, 0.3);
}

:deep(.fc .fc-button-primary:disabled) {
  opacity: 0.5;
}

:deep(.fc .fc-daygrid-day-number) {
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 500;
  padding: 6px;
}

:deep(.fc .fc-col-header-cell-cushion) {
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  text-decoration: none;
  padding: 10px 4px;
}

:deep(.fc .fc-daygrid-day.fc-day-today) {
  background: rgba(102, 126, 234, 0.08);
}

:deep(.fc .fc-daygrid-day) {
  cursor: pointer;
}

:deep(.fc .fc-daygrid-day-frame) {
  min-height: 80px;
}

:deep(.fc .fc-day-other .fc-daygrid-day-top) {
  opacity: 0.3;
}

:deep(.fc .fc-event) {
  border-radius: 6px;
  padding: 2px 6px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  border: none;
  margin: 1px 4px;
}

:deep(.fc .fc-more-link) {
  font-size: 12px;
  font-weight: 500;
}

:deep(.fc .fc-daygrid-more-link) {
  color: var(--text-secondary);
}

:deep(.fc .fc-daygrid-week-number) {
  color: var(--text-muted);
  font-size: 11px;
}

:deep(.fc .fc-non-business) {
  background: transparent;
}

:deep(.fc .fc-scrollgrid) {
  border-color: var(--card-border-light);
}

:deep(.fc th) {
  border-color: var(--card-border-light);
}

:deep(.fc td) {
  border-color: var(--card-border-light);
}

:deep(.fc .fc-daygrid-day-events) {
  min-height: 20px;
}

:deep(.fc .fc-day-today .fc-daygrid-day-number) {
  background: rgba(102, 126, 234, 0.2);
  border-radius: 50%;
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--modal-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.2s ease;
}

.modal {
  background: var(--modal-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  width: 460px;
  max-width: 90vw;
  max-height: 85vh;
  overflow-y: auto;
  animation: slideUp 0.25s ease;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 0;
}

.modal-header h2 {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
}

.modal-close {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 24px;
  cursor: pointer;
  padding: 4px;
  line-height: 1;
  border-radius: 6px;
  transition: background 0.2s;
}

.modal-close:hover {
  background: var(--hover-bg);
}

.modal-body {
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.form-field label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.form-input {
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
}

.form-input:focus {
  border-color: #667eea;
}

.form-textarea {
  resize: vertical;
  min-height: 60px;
}

.form-row {
  display: flex;
  gap: 12px;
}

.color-picker {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.color-swatch {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  cursor: pointer;
  border: 3px solid transparent;
  transition: all 0.2s;
}

.color-swatch:hover {
  transform: scale(1.15);
}

.color-swatch.active {
  border-color: var(--text-primary);
  transform: scale(1.15);
}

.modal-footer {
  display: flex;
  gap: 8px;
  padding: 0 24px 20px;
  justify-content: flex-end;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: default;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.btn-secondary {
  background: var(--hover-bg);
  color: var(--text-secondary);
}

.btn-secondary:hover {
  background: var(--hover-bg-strong);
  color: var(--text-primary);
}

.btn-danger {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
  margin-right: auto;
}

.btn-danger:hover {
  background: rgba(255, 107, 107, 0.25);
}
</style>
