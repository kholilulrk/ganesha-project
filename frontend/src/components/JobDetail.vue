<template>
  <transition name="modal-fade">
    <div v-if="visible" class="modal-overlay" @click.self="close">
      <div class="modal-card detail-card">
        <div class="modal-header">
          <h2>{{ job.name }}</h2>
          <button class="btn-close" @click="close">✕</button>
        </div>

        <div v-if="tabError" class="error-banner">{{ tabError }}</div>

        <div class="detail-scroll">
          <div class="detail-section">
            <label class="section-label">Deskripsi</label>
            <p class="desc-text">{{ job.description || '-' }}</p>
          </div>

          <div v-if="isAdmin" class="detail-info-grid">
            <div class="detail-info-item">
              <label>Nilai (Rp)</label>
              <span>{{ formatRupiah(job.value) }}</span>
            </div>
            <div class="detail-info-item">
              <label>Tgl Kontrak</label>
              <span>{{ formatDate(job.contract_date) }}</span>
            </div>
            <div class="detail-info-item">
              <label>Status</label>
              <span class="status-badge" :class="job.status">{{ job.status || 'pending' }}</span>
            </div>
            <div class="detail-info-item">
              <label>Dateline</label>
              <span>{{ formatDate(job.dateline) }}</span>
            </div>
            <div class="detail-info-item">
              <label>Share</label>
              <span>{{ job.share || '-' }}</span>
            </div>
          </div>

          <div v-if="job.spektek" class="detail-section">
            <label class="section-label">Referensi Dokumen</label>
            <div class="pdf-embed">
              <iframe :src="spektekUrl" class="pdf-frame"></iframe>
            </div>
          </div>

          <div v-if="allItemsDone && job.status !== 'done'" class="complete-section">
            <button class="btn-complete" @click="completeJob">Selesaikan Pekerjaan</button>
          </div>

          <div class="tabs">
            <button
              v-if="hasTeknisi"
              class="tab-btn"
              :class="{ active: activeTab === 'teknisi' }"
              @click="activeTab = 'teknisi'"
            >Tugas Teknisi</button>
            <button
              v-if="hasLogistic"
              class="tab-btn"
              :class="{ active: activeTab === 'logistic' }"
              @click="activeTab = 'logistic'"
            >Tugas Logistic</button>
            <button
              class="tab-btn"
              :class="{ active: activeTab === 'komentar' }"
              @click="activeTab = 'komentar'; onCommentTabClick()"
            >Komentar
              <span v-if="hasNewComments" class="new-comment-dot"></span>
            </button>
          </div>

          <div v-if="activeTab === 'teknisi'" class="checklist-panel">
            <div class="progress-bar-wrap">
              <div class="progress-label">{{ progress(teknisiItems).completed }}/{{ progress(teknisiItems).total }} &middot; {{ progress(teknisiItems).pct }}%</div>
              <div class="progress-track"><div class="progress-fill" :style="{ width: progress(teknisiItems).pct + '%' }"></div></div>
            </div>
            <div class="search-bar-wrap">
              <input v-model="teknisiSearch" class="search-input" placeholder="Cari tugas teknisi..." />
            </div>
            <div class="checklist-items">
              <div v-for="item in filteredTeknisi" :key="item.ID" class="checklist-row" :class="{ done: item.status === 'selesai' || item.completed }">
                <template v-if="item.status === 'selesai' || item.completed">
                  <span class="status-tag selesai">Selesai</span>
                </template>
                <template v-else-if="item.status === 'progres'">
                  <button class="status-tag selesaikan-btn" @click="selesaiItem('teknisi', item.ID)">Selesaikan</button>
                </template>
                <template v-else>
                  <button class="status-tag kerjakan-btn" @click="progresItem('teknisi', item.ID)">Kerjakan</button>
                </template>
                <template v-if="editingItemId === item.ID">
                  <input v-model="editingText" @keyup.enter="saveEdit('teknisi', item.ID)" @blur="saveEdit('teknisi', item.ID)" class="edit-input" autofocus />
                </template>
                <span v-else class="checklist-text" :class="{ strikethrough: item.status === 'selesai' || item.completed }">{{ item.item }}</span>
                <div class="item-images" v-if="getImages(item).length">
                  <div v-for="img in getImages(item)" :key="img" class="img-wrap">
                    <img :src="'/uploads/checklist/' + img" class="item-thumb" @click="openImage('/uploads/checklist/' + img)" />
                    <button v-if="canManageChecklist" class="img-delete" @click.stop="deleteImage('teknisi', item.ID, img)" title="Hapus gambar">&times;</button>
                  </div>
                </div>
                <button v-if="canManageChecklist" class="btn-icon-small" @click="startEdit(item)" title="Edit">✏️</button>
                <div class="image-upload-wrapper">
                  <button v-if="canManageChecklist" class="btn-icon-small" @click="triggerImageUpload('teknisi', item.ID)" title="Tambah gambar">🖼️</button>
                </div>
                <button v-if="canManageChecklist" class="btn-icon-small delete" @click="deleteItem('teknisi', item.ID)" title="Hapus">✕</button>
              </div>
              <div v-if="!teknisiItems.length" class="empty-checklist">Belum ada tugas</div>
            </div>
            <input ref="teknisiFileInput" type="file" accept=".jpg,.jpeg,.png,.gif,.webp" multiple @change="onFileSelected('teknisi', $event)" class="file-input-hidden" />
            <div v-if="canManageChecklist" class="add-checklist">
              <input v-model="teknisiInput" @keyup.enter="addItem('teknisi')" placeholder="Tambah tugas teknisi..." />
              <button class="btn-add-small" @click="addItem('teknisi')">+</button>
            </div>
          </div>

          <div v-if="activeTab === 'logistic'" class="checklist-panel">
            <div class="progress-bar-wrap">
              <div class="progress-label">{{ progress(logisticItems).completed }}/{{ progress(logisticItems).total }} &middot; {{ progress(logisticItems).pct }}%</div>
              <div class="progress-track"><div class="progress-fill" :style="{ width: progress(logisticItems).pct + '%' }"></div></div>
            </div>
            <div class="search-bar-wrap">
              <input v-model="logisticSearch" class="search-input" placeholder="Cari tugas logistic..." />
            </div>
            <div class="checklist-items">
              <div v-for="item in filteredLogistic" :key="item.ID" class="logistic-card" :class="{ done: item.completed }">
                <div class="logistic-header">
                  <input type="checkbox" :checked="item.completed" @change="toggleItem('logistic', item.ID)" class="checklist-check" />
                  <span class="checklist-text" :class="{ strikethrough: item.completed }">{{ item.item }}</span>
                  <div v-if="getImages(item).length" class="lg-imgs">
                    <div v-for="img in getImages(item)" :key="img" class="img-wrap">
                      <img :src="'/uploads/checklist/' + img" class="item-thumb" @click="openImage('/uploads/checklist/' + img)" />
                      <button v-if="canManageChecklist" class="img-delete" @click.stop="deleteImage('logistic', item.ID, img)" title="Hapus gambar">&times;</button>
                    </div>
                  </div>
                  <button v-if="canManageChecklist" class="btn-icon-small" @click="triggerImageUpload('logistic', item.ID)" title="Gambar">🖼️</button>
                  <button v-if="canManageChecklist" class="btn-icon-small" @click="startEdit(item)" title="Edit">✏️</button>
                  <button v-if="canManageChecklist" class="btn-icon-small delete" @click="deleteItem('logistic', item.ID)" title="Hapus">✕</button>
                </div>
                <div class="logistic-details">
                  <span class="lg-detail">{{ item.quantity || 0 }} {{ item.unit || '-' }}</span>
                  <span class="lg-dot">·</span>
                  <span class="lg-detail">{{ formatPrice(item.price) }}</span>
                  <span v-if="item.notes" class="lg-dot">·</span>
                  <span v-if="item.notes" class="lg-detail lg-note">{{ item.notes }}</span>
                </div>
                <div v-if="editingItemId === item.ID" class="logistic-edit-form">
                  <input v-model="editForm.item" @keyup.enter="saveLogisticEdit(item.ID)" placeholder="Nama barang" class="lg-input" />
                  <div class="lg-row">
                    <input v-model.number="editForm.quantity" type="number" placeholder="Jumlah barang" class="lg-input" />
                    <input v-model="editForm.unit" placeholder="Satuan" class="lg-input" />
                  </div>
                  <div class="lg-row">
                    <input v-model="editForm.notes" placeholder="Catatan" class="lg-input" />
                    <input v-model="editForm.price" type="number" placeholder="Harga barang" class="lg-input" />
                  </div>
                  <button class="btn-add-small lg-add-btn" @click="saveLogisticEdit(item.ID)">Simpan</button>
                </div>
              </div>
              <div v-if="!logisticItems.length" class="empty-checklist">Belum ada tugas</div>
            </div>
            <input ref="logisticFileInput" type="file" accept=".jpg,.jpeg,.png,.gif,.webp" @change="onFileSelected('logistic', $event)" class="file-input-hidden" />
            <div v-if="canManageChecklist" class="logistic-add-form">
              <input v-model="logisticForm.item" placeholder="Nama barang" class="lg-input"/>
              <div class="lg-row">
                <input v-model.number="logisticForm.quantity" type="number" placeholder="Jumlah barang" class="lg-input"/>
                <input v-model="logisticForm.unit" placeholder="Satuan" class="lg-input"/>
              </div>
              <div class="lg-row">
                <input v-model="logisticForm.notes" placeholder="Catatan" class="lg-input"/>
                <input v-model="logisticForm.price" type="number" placeholder="Harga barang" class="lg-input"/>
              </div>
              <button class="btn-add-small lg-add-btn" @click="addLogisticItem">+ Tambah</button>
            </div>
          </div>

          <div v-if="activeTab === 'komentar'" class="checklist-panel">
            <div class="comment-list">
              <div v-for="c in topComments" :key="c.ID" class="comment-item">
                <div class="comment-header">
                  <span class="comment-author">{{ c.name }}</span>
                  <span class="comment-time">{{ formatDate(c.CreatedAt) }}</span>
                  <button v-if="auth.user?.ID === c.user_id" class="btn-icon-small delete" @click="deleteComment(c.ID)" title="Hapus">✕</button>
                </div>
                <p class="comment-text">{{ c.text }}</p>
                <button class="btn-reply" @click="toggleReply(c.ID)">Balas</button>
                <div v-if="replyOpen === c.ID" class="reply-form">
                  <textarea v-model="replyText" placeholder="Tulis balasan..." rows="2" class="comment-textarea"></textarea>
                  <button class="btn-add-small" @click="addReply(c.ID)" :disabled="!replyText.trim()">Kirim</button>
                </div>
                <div v-if="getReplies(c.ID).length" class="replies-list">
                  <div v-for="r in getReplies(c.ID)" :key="r.ID" class="reply-item">
                    <div class="comment-header">
                      <span class="comment-author">{{ r.name }}</span>
                      <span class="comment-time">{{ formatDate(r.CreatedAt) }}</span>
                      <button v-if="auth.user?.ID === r.user_id" class="btn-icon-small delete" @click="deleteComment(r.ID)" title="Hapus">✕</button>
                    </div>
                    <p class="comment-text">{{ r.text }}</p>
                  </div>
                </div>
              </div>
              <div v-if="!topComments.length" class="empty-checklist">Belum ada komentar</div>
            </div>
            <div class="comment-form">
              <textarea v-model="commentInput" placeholder="Tulis komentar..." rows="2" class="comment-textarea"></textarea>
              <button class="btn-add-small" @click="addComment" :disabled="!commentInput.trim()">Kirim</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>

  <!-- Image Preview Modal -->
  <div v-if="previewSrc" class="preview-overlay" @click.self="closePreview">
    <div class="preview-card">
      <button class="preview-close" @click="closePreview">&times;</button>
      <img :src="previewSrc" class="preview-image" />
      <a :href="previewSrc" download class="preview-download" target="_blank">Download</a>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { checklistAPI } from '../api/checklist'
import { commentAPI } from '../api/comment'
import { jobAPI } from '../api/job'
import { useAuthStore } from '../stores/auth'
import { usePermissionStore } from '../stores/permissions'

const props = defineProps({
  visible: Boolean,
  job: Object,
})
const emit = defineEmits(['close', 'job-updated'])

const auth = useAuthStore()
const perms = usePermissionStore()
const role = computed(() => auth.user?.role || '')
const canManageChecklist = computed(() => perms.can('checklist', 'manage'))
const isAdmin = computed(() => role.value === 'Super Admin' || role.value === 'Administrasi')
const allItemsDone = computed(() => {
  const tek = teknisiItems.value
  const log = logisticItems.value
  const all = [...tek, ...log]
  return all.length > 0 && all.every(i => i.completed)
})

const tabError = ref('')
const activeTab = ref(role.value === 'Logistic' ? 'logistic' : 'teknisi')
const teknisiItems = ref([])
const logisticItems = ref([])
const teknisiSearch = ref('')
const logisticSearch = ref('')

const filteredTeknisi = computed(() => {
  const q = teknisiSearch.value.toLowerCase().trim()
  if (!q) return teknisiItems.value
  return teknisiItems.value.filter(i => i.item.toLowerCase().includes(q))
})
const filteredLogistic = computed(() => {
  const q = logisticSearch.value.toLowerCase().trim()
  if (!q) return logisticItems.value
  return logisticItems.value.filter(i => i.item.toLowerCase().includes(q))
})
const teknisiInput = ref('')
const comments = ref([])
const commentInput = ref('')
const replyOpen = ref(null)
const replyText = ref('')
const seenCommentCount = ref(0)

const storageKey = computed(() => `seen_comments_${props.job?.ID || 0}`)

function loadSeenCount() {
  const saved = localStorage.getItem(storageKey.value)
  seenCommentCount.value = saved ? parseInt(saved, 10) : 0
}

function saveSeenCount() {
  localStorage.setItem(storageKey.value, String(comments.value.length))
}

const hasNewComments = computed(() => comments.value.length > seenCommentCount.value)

function onCommentTabClick() {
  saveSeenCount()
  seenCommentCount.value = comments.value.length
}

const topComments = computed(() => comments.value.filter(c => !c.parent_id))

function getReplies(parentId) {
  return comments.value.filter(c => c.parent_id === parentId)
}

function toggleReply(commentId) {
  replyOpen.value = replyOpen.value === commentId ? null : commentId
  replyText.value = ''
}
const editingItemId = ref(null)
const editingText = ref('')
const uploadTargetItemId = ref(null)
const teknisiFileInput = ref(null)
const logisticFileInput = ref(null)

const logisticForm = ref({ item: '', quantity: null, unit: '', notes: '', price: null })
const editForm = ref({ item: '', quantity: null, unit: '', notes: '', price: null })

const spektekUrl = computed(() => {
  if (!props.job?.spektek) return ''
  const path = props.job.spektek.replace(/\\/g, '/')
  if (path.startsWith('uploads/')) return '/' + path
  return '/uploads/spektek/' + path
})

const shared = computed(() => (props.job?.share || '').split(',').filter(Boolean))
const hasTeknisi = computed(() => {
  if (role.value === 'Administrasi' || role.value === 'Super Admin') return true
  if (role.value === 'Logistic') return false
  return shared.value.includes('Teknisi')
})
const hasLogistic = computed(() => {
  if (role.value === 'Super Admin' || role.value === 'Logistic') return true
  return shared.value.includes('Logistic')
})

function formatPrice(val) {
  if (!val) return 'Rp 0'
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

function formatRupiah(val) {
  return Number(val).toLocaleString('id-ID')
}

async function addLogisticItem() {
  const f = logisticForm.value
  if (!f.item.trim()) return
  try {
    await checklistAPI.add(props.job.ID, {
      role: 'Logistic',
      item: f.item,
      quantity: f.quantity || 0,
      unit: f.unit,
      notes: f.notes,
      price: f.price || 0,
    })
    tabError.value = ''
    logisticForm.value = { item: '', quantity: null, unit: '', notes: '', price: null }
    await loadItems('logistic')
  } catch (e) {
    tabError.value = `Gagal menambah tugas: ${e.response?.data?.error || e.message}`
  }
}

async function saveLogisticEdit(itemId) {
  const f = editForm.value
  if (!f.item.trim()) {
    editingItemId.value = null
    return
  }
  try {
    await checklistAPI.update(props.job.ID, itemId, {
      item: f.item,
      quantity: f.quantity || 0,
      unit: f.unit,
      notes: f.notes,
      price: f.price || 0,
    })
    tabError.value = ''
    editingItemId.value = null
    await loadItems('logistic')
  } catch (e) {
    tabError.value = `Gagal mengedit tugas: ${e.response?.data?.error || e.message}`
  }
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

async function loadComments() {
  try {
    const res = await commentAPI.get(props.job.ID)
    comments.value = res.data.comments
    if (activeTab.value === 'komentar') {
      saveSeenCount()
      seenCommentCount.value = comments.value.length
    }
  } catch (e) {
    tabError.value = `Gagal memuat komentar: ${e.response?.data?.error || e.message}`
  }
}

async function addComment() {
  const text = commentInput.value.trim()
  if (!text) return
  try {
    await commentAPI.add(props.job.ID, text)
    commentInput.value = ''
    await loadComments()
  } catch (e) {
    tabError.value = `Gagal menambah komentar: ${e.response?.data?.error || e.message}`
  }
}

async function addReply(parentId) {
  const text = replyText.value.trim()
  if (!text) return
  try {
    await commentAPI.add(props.job.ID, text, parentId)
    replyText.value = ''
    replyOpen.value = null
    await loadComments()
  } catch (e) {
    tabError.value = `Gagal menambah balasan: ${e.response?.data?.error || e.message}`
  }
}

async function deleteComment(commentId) {
  if (!confirm('Yakin ingin menghapus komentar ini?')) return
  try {
    await commentAPI.remove(props.job.ID, commentId)
    await loadComments()
  } catch (e) {
    tabError.value = `Gagal menghapus komentar: ${e.response?.data?.error || e.message}`
  }
}

watch(() => props.visible, (v) => {
  if (v) {
    tabError.value = ''
    loadSeenCount()
    if (hasTeknisi.value) loadItems('teknisi')
    if (hasLogistic.value) loadItems('logistic')
    loadComments()
  }
})

function close() {
  emit('close')
}

function progress(items) {
  const total = items.length
  const completed = items.filter(i => i.status === 'selesai' || i.completed).length
  const pct = total ? Math.round((completed / total) * 100) : 0
  return { total, completed, pct }
}

function getImages(item) {
  return (item.images || '').split(',').filter(Boolean)
}

function startEdit(item) {
  editingItemId.value = item.ID
  editingText.value = item.item
  editForm.value = {
    item: item.item,
    quantity: item.quantity || 0,
    unit: item.unit || '',
    notes: item.notes || '',
    price: item.price || 0,
  }
}

async function saveEdit(roleKey, itemId) {
  if (!editingText.value.trim()) {
    editingItemId.value = null
    return
  }
  try {
    await checklistAPI.update(props.job.ID, itemId, { item: editingText.value })
    tabError.value = ''
    editingItemId.value = null
    await loadItems(roleKey)
  } catch (e) {
    tabError.value = `Gagal mengedit tugas: ${e.response?.data?.error || e.message}`
  }
}

async function uploadImage(roleKey, itemId, e) {
  const files = Array.from(e.target.files || [])
  if (!files.length) return
  const maxImages = roleKey === 'teknisi' ? 3 : 1
  const item = roleKey === 'teknisi'
    ? teknisiItems.value.find(i => i.ID === itemId)
    : logisticItems.value.find(i => i.ID === itemId)
  const existing = item ? getImages(item).length : 0
  const allowed = maxImages - existing
  if (allowed <= 0) {
    tabError.value = roleKey === 'teknisi' ? 'Maksimal 3 gambar untuk tugas Teknisi' : 'Maksimal 1 gambar untuk tugas Logistic'
    e.target.value = ''
    return
  }
  const toUpload = files.slice(0, allowed)
  if (files.length > allowed) {
    tabError.value = `${roleKey === 'teknisi' ? 'Maksimal 3' : 'Maksimal 1'} gambar. ${allowed} gambar akan diupload.`
  }
  const roleName = roleKey === 'teknisi' ? 'teknisi' : 'logistic'
  try {
    for (const file of toUpload) {
      const formData = new FormData()
      formData.append('file', file)
      await checklistAPI.uploadImage(props.job.ID, itemId, roleName, formData)
    }
    tabError.value = ''
    e.target.value = ''
    await loadItems(roleKey)
  } catch (err) {
    tabError.value = err.response?.data?.error || 'Gagal upload gambar'
    e.target.value = ''
  }
}

function triggerImageUpload(roleKey, itemId) {
  uploadTargetItemId.value = itemId
  if (roleKey === 'teknisi') {
    teknisiFileInput.value.value = ''
    teknisiFileInput.value?.click()
  } else {
    logisticFileInput.value.value = ''
    logisticFileInput.value?.click()
  }
}

function onFileSelected(roleKey, e) {
  const itemId = uploadTargetItemId.value
  if (!itemId) return
  uploadImage(roleKey, itemId, e)
}

const previewSrc = ref(null)

function openImage(src) {
  previewSrc.value = src
}

function closePreview() {
  previewSrc.value = null
}

async function deleteImage(roleKey, itemId, filename) {
  try {
    await checklistAPI.deleteImage(props.job.ID, itemId, filename)
    await loadItems(roleKey)
  } catch (err) {
    tabError.value = err.response?.data?.error || 'Gagal hapus gambar'
  }
}

async function loadItems(roleKey) {
  try {
    const apiRole = roleKey === 'teknisi' ? 'Teknisi' : 'Logistic'
    const res = await checklistAPI.get(props.job.ID, apiRole)
    if (roleKey === 'teknisi') teknisiItems.value = res.data.items
    else logisticItems.value = res.data.items
  } catch (e) {
    tabError.value = `Gagal memuat tugas: ${e.response?.data?.error || e.message}`
  }
}

async function addItem(roleKey) {
  const text = teknisiInput.value.trim()
  if (!text) return
  try {
    await checklistAPI.add(props.job.ID, { role: 'Teknisi', item: text })
    tabError.value = ''
    teknisiInput.value = ''
    await loadItems(roleKey)
  } catch (e) {
    tabError.value = `Gagal menambah tugas: ${e.response?.data?.error || e.message}`
  }
}

async function toggleItem(roleKey, itemId) {
  try {
    await checklistAPI.toggle(props.job.ID, itemId)
    tabError.value = ''
    await loadItems('teknisi')
    await loadItems('logistic')
    const allItems = [...teknisiItems.value, ...logisticItems.value]
    if (allItems.some(i => i.completed) && props.job.status === 'pending') {
      await jobAPI.updateStatus(props.job.ID, 'progres')
      props.job.status = 'progres'
    }
  } catch (e) {
    tabError.value = `Gagal mengubah tugas: ${e.response?.data?.error || e.message}`
  }
}

async function progresItem(roleKey, itemId) {
  try {
    await checklistAPI.progres(props.job.ID, itemId)
    tabError.value = ''
    await loadItems('teknisi')
    if (props.job.status === 'pending') {
      await jobAPI.updateStatus(props.job.ID, 'progres')
      props.job.status = 'progres'
    }
  } catch (e) {
    tabError.value = `Gagal mengubah status: ${e.response?.data?.error || e.message}`
  }
}

async function selesaiItem(roleKey, itemId) {
  try {
    await checklistAPI.selesai(props.job.ID, itemId)
    tabError.value = ''
    await loadItems('teknisi')
    await loadItems('logistic')
  } catch (e) {
    tabError.value = `Gagal mengubah status: ${e.response?.data?.error || e.message}`
  }
}

function deleteItem(roleKey, itemId) {
  const item = roleKey === 'teknisi'
    ? teknisiItems.value.find(i => i.ID === itemId)
    : logisticItems.value.find(i => i.ID === itemId)
  const label = item?.item?.substring(0, 40) || 'tugas ini'
  if (!confirm(`Yakin ingin menghapus "${label}"?`)) return
  doDelete(roleKey, itemId)
}

async function doDelete(roleKey, itemId) {
  try {
    await checklistAPI.remove(props.job.ID, itemId)
    tabError.value = ''
    await loadItems(roleKey)
  } catch (e) {
    tabError.value = `Gagal menghapus tugas: ${e.response?.data?.error || e.message}`
  }
}

async function completeJob() {
  if (!confirm('Yakin ingin menyelesaikan pekerjaan ini?')) return
  try {
    const res = await jobAPI.complete(props.job.ID)
    emit('job-updated', res.data.job)
    tabError.value = ''
  } catch (e) {
    tabError.value = `Gagal menyelesaikan pekerjaan: ${e.response?.data?.error || e.message}`
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--modal-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  backdrop-filter: blur(4px);
}

.modal-card {
  background: var(--modal-bg);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 32px;
  width: 100%;
  max-width: 640px;
  max-height: 90vh;
  overflow-y: auto;
  animation: modalIn 0.3s ease;
}

@keyframes modalIn {
  from { opacity: 0; transform: scale(0.95) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.modal-header h2 {
  color: var(--text-primary);
  font-size: 18px;
  font-weight: 600;
}

.btn-close {
  background: var(--hover-bg);
  border: none;
  color: var(--text-muted);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
}

.btn-close:hover {
  background: var(--hover-bg-strong);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.error-banner {
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 10px 14px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 13px;
}

.tabs {
  display: flex;
  gap: 4px;
  border-bottom: 1px solid var(--card-border-light);
}

.tab-btn {
  padding: 10px 18px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-size: 13px;
  font-weight: 600;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  transition: color 0.2s, border-color 0.2s;
  margin-bottom: -1px;
  position: relative;
}

.new-comment-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  background: #e74c3c;
  border-radius: 50%;
  margin-left: 6px;
  vertical-align: super;
}

.tab-btn:hover {
  color: var(--text-secondary);
}

.tab-btn.active {
  color: #667eea;
  border-bottom-color: #667eea;
}

.detail-scroll {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 16px;
}

.detail-info-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 14px 16px;
  border-radius: 12px;
  border: 1px solid;
}

.detail-info-item:nth-child(1) {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.12), rgba(99, 102, 241, 0.04));
  border-color: rgba(99, 102, 241, 0.2);
}
.detail-info-item:nth-child(2) {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.12), rgba(245, 158, 11, 0.04));
  border-color: rgba(245, 158, 11, 0.2);
}
.detail-info-item:nth-child(3) {
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.12), rgba(16, 185, 129, 0.04));
  border-color: rgba(16, 185, 129, 0.2);
}
.detail-info-item:nth-child(4) {
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.12), rgba(239, 68, 68, 0.04));
  border-color: rgba(239, 68, 68, 0.2);
}
.detail-info-item:nth-child(5) {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.12), rgba(168, 85, 247, 0.04));
  border-color: rgba(168, 85, 247, 0.2);
}

.detail-info-item label {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.detail-info-item span {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 500;
}

.detail-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid;
}

.detail-section:first-of-type {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.08), rgba(59, 130, 246, 0.03));
  border-color: rgba(59, 130, 246, 0.15);
}

.section-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.desc-text {
  font-size: 14px;
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.5;
}

.complete-section {
  display: flex;
  justify-content: center;
  padding: 20px;
  background: linear-gradient(135deg, rgba(81, 207, 102, 0.08), rgba(81, 207, 102, 0.03));
  border: 1px solid rgba(81, 207, 102, 0.15);
  border-radius: 12px;
}

.btn-complete {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  border: none;
  padding: 12px 32px;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 600;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-complete:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.checklist-panel {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.progress-bar-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
}

.progress-label {
  font-size: 11px;
  color: var(--text-muted);
  white-space: nowrap;
  min-width: 70px;
}

.progress-track {
  flex: 1;
  height: 4px;
  background: var(--hover-bg);
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  border-radius: 2px;
  transition: width 0.3s ease;
}

.search-bar-wrap {
  margin-bottom: 6px;
}
.search-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid var(--card-border-light);
  border-radius: 8px;
  background: var(--card-bg);
  color: var(--text-primary);
  font-size: 13px;
  outline: none;
  box-sizing: border-box;
}
.search-input:focus {
  border-color: #667eea;
}

.checklist-items {
  display: flex;
  flex-direction: column;
  gap: 6px;
  max-height: 300px;
  overflow-y: auto;
}

.checklist-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.06), rgba(99, 102, 241, 0.02));
  border-radius: 10px;
  border: 1px solid rgba(99, 102, 241, 0.12);
  transition: background 0.2s, transform 0.15s;
}

.checklist-row:hover {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.12), rgba(99, 102, 241, 0.04));
  transform: translateX(2px);
}

.checklist-row.done {
  background: linear-gradient(135deg, rgba(81, 207, 102, 0.08), rgba(81, 207, 102, 0.03));
  border-color: rgba(81, 207, 102, 0.15);
  opacity: 0.7;
}

.checklist-check {
  width: 18px;
  height: 18px;
  accent-color: #51cf66;
  cursor: pointer;
  flex-shrink: 0;
}
.status-tag {
  margin-right: 8px;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 14px;
  border-radius: 20px;
  white-space: nowrap;
  flex-shrink: 0;
  letter-spacing: 0.3px;
  text-transform: uppercase;
}
.status-tag.selesai {
  background: rgba(25, 135, 84, 0.12);
  color: #157347;
  border: 1px solid rgba(25, 135, 84, 0.2);
}
.kerjakan-btn {
  margin-right: 8px;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 14px;
  border-radius: 20px;
  white-space: nowrap;
  flex-shrink: 0;
  letter-spacing: 0.3px;
  text-transform: uppercase;
  background: rgba(255, 193, 7, 0.12);
  color: #e6a800;
  border: 1px solid rgba(255, 193, 7, 0.2);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
}
.kerjakan-btn:hover {
  background: rgba(255, 193, 7, 0.25);
  transform: scale(1.05);
}
.selesaikan-btn {
  margin-right: 8px;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 14px;
  border-radius: 20px;
  white-space: nowrap;
  flex-shrink: 0;
  letter-spacing: 0.3px;
  text-transform: uppercase;
  background: rgba(13, 202, 240, 0.12);
  color: #0aa2c0;
  border: 1px solid rgba(13, 202, 240, 0.2);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
}
.selesaikan-btn:hover {
  background: rgba(13, 202, 240, 0.25);
  transform: scale(1.05);
}

.checklist-text {
  flex: 1;
  font-size: 14px;
  color: var(--text-secondary);
}

.checklist-text.strikethrough {
  text-decoration: line-through;
  color: var(--text-dim);
}

.edit-input {
  flex: 1;
  padding: 6px 10px;
  border: 1px solid #667eea;
  border-radius: 6px;
  background: rgba(102, 126, 234, 0.08);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
}

.item-images {
  display: flex;
  gap: 4px;
  align-items: center;
}

.item-thumb {
  width: 36px;
  height: 36px;
  object-fit: cover;
  border-radius: 6px;
  cursor: pointer;
  border: 1px solid var(--card-border-light);
  transition: transform 0.2s;
}

.item-thumb:hover {
  transform: scale(1.15);
}

.img-wrap {
  position: relative;
  display: inline-flex;
}
.img-delete {
  position: absolute;
  top: -6px;
  right: -6px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: none;
  background: #dc3545;
  color: #fff;
  font-size: 12px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  opacity: 0;
  transition: opacity 0.2s;
}
.img-wrap:hover .img-delete {
  opacity: 1;
}

.image-upload-wrapper {
  display: inline-flex;
}

.file-input-hidden {
  display: none;
}

.btn-icon-small {
  background: var(--hover-bg);
  border: none;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 11px;
  color: var(--text-muted);
  transition: background 0.2s, color 0.2s;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-icon-small.delete:hover {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.empty-checklist {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-dim);
  font-size: 13px;
  font-style: italic;
}

.add-checklist {
  display: flex;
  gap: 8px;
}

.add-checklist input {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
}

.add-checklist input:focus {
  border-color: #667eea;
}

.add-checklist input::placeholder {
  color: var(--text-dim);
}

.btn-add-small {
  padding: 10px 16px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-add-small:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.logistic-card {
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.06), rgba(16, 185, 129, 0.02));
  border-radius: 10px;
  border: 1px solid rgba(16, 185, 129, 0.12);
  padding: 8px 10px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  transition: background 0.2s, transform 0.15s;
}

.logistic-card:hover {
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.12), rgba(16, 185, 129, 0.04));
  transform: translateX(2px);
}

.logistic-card.done {
  background: linear-gradient(135deg, rgba(81, 207, 102, 0.08), rgba(81, 207, 102, 0.03));
  border-color: rgba(81, 207, 102, 0.15);
  opacity: 0.7;
}

.logistic-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logistic-details {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: 28px;
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1;
}

.lg-dot {
  color: var(--text-dim);
}

.lg-detail {
  color: var(--text-muted);
}

.lg-note {
  color: var(--text-muted);
  font-style: italic;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 200px;
}

.lg-imgs {
  display: flex;
  gap: 3px;
  align-items: center;
}

.logistic-add-form,
.logistic-edit-form {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 6px;
}

.lg-input {
  padding: 6px 10px;
  border: 1px solid var(--input-border);
  border-radius: 6px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
}

.lg-input:focus {
  border-color: #667eea;
}

.lg-input::placeholder {
  color: var(--text-dim);
}

.lg-row {
  display: flex;
  gap: 4px;
}

.lg-row .lg-input {
  flex: 1;
  min-width: 0;
}

.lg-add-btn {
  padding: 6px 14px;
  font-size: 13px;
  align-self: flex-end;
}

.spektek-panel {
  padding: 4px 0;
}

.pdf-embed {
  border-radius: 10px;
  border: 1px solid rgba(239, 68, 68, 0.15);
  overflow: hidden;
}

.pdf-frame {
  width: 100%;
  height: 500px;
  border: none;
  border-radius: 10px;
}

.detail-section:has(.pdf-embed) {
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.06), rgba(239, 68, 68, 0.02));
  border-color: rgba(239, 68, 68, 0.12);
}

.comment-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.comment-item {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.06), rgba(236, 72, 153, 0.02));
  border: 1px solid rgba(236, 72, 153, 0.1);
  border-radius: 10px;
  padding: 12px 14px;
}

.comment-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.comment-author {
  font-weight: 600;
  font-size: 13px;
  color: var(--text-primary);
}

.comment-time {
  font-size: 11px;
  color: var(--text-dim);
  flex: 1;
}

.comment-text {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
  white-space: pre-wrap;
}

.comment-form {
  display: flex;
  gap: 8px;
  margin-top: 16px;
  align-items: flex-start;
}

.comment-textarea {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
  resize: vertical;
  transition: border-color 0.2s;
  min-height: 40px;
}

.comment-textarea:focus {
  border-color: #667eea;
}

.comment-textarea::placeholder {
  color: var(--text-dim);
}

.btn-reply {
  background: none;
  border: none;
  color: #667eea;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 4px 0;
  margin-top: 4px;
  font-family: 'Inter', sans-serif;
}

.btn-reply:hover {
  text-decoration: underline;
}

.reply-form {
  display: flex;
  gap: 8px;
  margin-top: 8px;
  align-items: flex-start;
}

.replies-list {
  margin-left: 20px;
  margin-top: 8px;
  border-left: 2px solid var(--card-border);
  padding-left: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.reply-item {
  padding: 8px 10px;
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.06), rgba(168, 85, 247, 0.02));
  border: 1px solid rgba(168, 85, 247, 0.08);
  border-radius: 8px;
}

/* Image Preview Modal */
.preview-overlay {
  position: fixed;
  inset: 0;
  z-index: 10000;
  background: rgba(0,0,0,0.6);
  display: flex;
  align-items: center;
  justify-content: center;
}
.preview-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  max-width: 90vw;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  box-shadow: 0 8px 30px rgba(0,0,0,0.25);
}
.preview-image {
  max-width: 100%;
  max-height: 70vh;
  border-radius: 8px;
  object-fit: contain;
}
.preview-close {
  align-self: flex-end;
  background: none;
  border: none;
  font-size: 28px;
  cursor: pointer;
  line-height: 1;
  color: #555;
}
.preview-download {
  background: #198754;
  color: #fff;
  padding: 8px 24px;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
  transition: background 0.2s;
}
.preview-download:hover {
  background: #157347;
}
</style>
