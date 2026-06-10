<template>
  <div class="shared-page">
    <div v-if="loading" class="loading">Memuat...</div>
    <div v-else-if="error" class="error-page">
      <h2>{{ error }}</h2>
      <p>Link tidak valid atau sudah tidak berlaku.</p>
    </div>
    <template v-else>
      <div class="shared-header">
        <h1>{{ job.name }}</h1>
        <span class="status-badge" :class="job.status">{{ job.status || 'pending' }}</span>
      </div>

      <div v-if="assignedUsers.length" class="wa-contacts">
        <div v-for="u in assignedUsers" :key="u.ID" class="wa-contact" @click="openWA(u.phone)">
          <span class="wa-icon">💬</span>
          <span class="wa-name">{{ u.name }}</span>
        </div>
      </div>

      <div class="shared-body">
        <div class="info-card">
          <label>Deskripsi</label>
          <p>{{ job.description || '-' }}</p>
        </div>

        <div class="info-card" v-if="job.spektek">
          <label>SPEKTEK</label>
          <a :href="spektekUrl" target="_blank" class="spektek-link">📄 Lihat Dokumen</a>
        </div>

        <div v-if="teknisiItems.length" class="section-card">
          <h3>Tugas Teknisi</h3>
          <div class="progress-bar-wrap">
            <div class="progress-label">{{ tekProgress.completed }}/{{ tekProgress.total }} &middot; {{ tekProgress.pct }}%</div>
            <div class="progress-track"><div class="progress-fill" :style="{ width: tekProgress.pct + '%' }"></div></div>
          </div>
          <div class="checklist-items">
            <div v-for="item in teknisiItems" :key="item.ID" class="checklist-row" :class="{ done: item.status === 'selesai' || item.completed }">
              <span class="checklist-text" :class="{ strikethrough: item.status === 'selesai' || item.completed }">{{ item.item }}</span>
              <div class="right-group">
                <div v-if="getImages(item).length" class="item-images">
                  <img v-for="img in getImages(item)" :key="img" :src="'/uploads/checklist/' + img" class="item-thumb" @click="openImage('/uploads/checklist/' + img)" />
                </div>
                <span v-if="item.status === 'selesai' || item.completed" class="status-tag selesai">Selesai</span>
                <span v-else-if="item.status === 'progres'" class="status-tag progres">Progres</span>
                <span v-else class="status-tag pending">Pending</span>
              </div>
            </div>
          </div>
        </div>

        <div class="section-card">
          <h3>Komentar ({{ comments.length }})</h3>
          <div class="comment-list">
            <div v-for="c in topComments" :key="c.ID" class="comment-item">
              <div class="comment-header">
                <span class="comment-author">{{ c.name }}</span>
                <span class="comment-time">{{ formatDate(c.CreatedAt) }}</span>
              </div>
              <p class="comment-text">{{ c.text }}</p>
              <button class="btn-reply" @click="toggleReply(c.ID)">Balas</button>
              <div v-if="replyOpen === c.ID" class="reply-form">
                <input v-model="replyName" placeholder="Nama Anda" class="comment-input" />
                <textarea v-model="replyText" placeholder="Tulis balasan..." rows="2" class="comment-textarea"></textarea>
                <button class="btn-kirim" @click="sendReply(c.ID)" :disabled="!replyName.trim() || !replyText.trim()">Kirim</button>
              </div>
              <div v-if="getReplies(c.ID).length" class="replies-list">
                <div v-for="r in getReplies(c.ID)" :key="r.ID" class="reply-item">
                  <div class="comment-header">
                    <span class="comment-author">{{ r.name }}</span>
                    <span class="comment-time">{{ formatDate(r.CreatedAt) }}</span>
                  </div>
                  <p class="comment-text">{{ r.text }}</p>
                </div>
              </div>
            </div>
            <div v-if="!topComments.length" class="empty-text">Belum ada komentar</div>
          </div>
          <div class="comment-form">
            <input v-model="visitorName" placeholder="Nama Anda" class="comment-input" />
            <textarea v-model="commentText" placeholder="Tulis komentar..." rows="2" class="comment-textarea"></textarea>
            <button class="btn-kirim" @click="addComment" :disabled="!visitorName.trim() || !commentText.trim()">Kirim</button>
          </div>
        </div>
      </div>
    </template>
  </div>

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
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useHead } from '@unhead/vue'
import { jobAPI } from '../api/job'

const headTitle = ref('Bagikan Pekerjaan')
const headDesc = ref('Lihat progres pekerjaan Anda di Ganesha Energi')
const headImage = ref('')

const route = useRoute()
const job = ref({})

useHead({
  title: headTitle,
  meta: [
    { name: 'description', content: headDesc },
    { property: 'og:title', content: headTitle },
    { property: 'og:description', content: headDesc },
    { property: 'og:image', content: headImage },
    { property: 'og:type', content: 'website' },
    { name: 'twitter:card', content: 'summary_large_image' },
  ],
})

watch(job, (val) => {
  if (val?.name) {
    headTitle.value = `${val.name} | Ganesha Energi`
    headDesc.value = `Lihat progres pekerjaan: ${val.name}`
  }
})
const teknisiItems = ref([])
const comments = ref([])
const assignedUsers = ref([])
const loading = ref(true)
const error = ref('')
const visitorName = ref('')
const commentText = ref('')
const replyOpen = ref(null)
const replyText = ref('')
const replyName = ref('')

const topComments = computed(() => comments.value.filter(c => !c.parent_id))

function getReplies(parentId) {
  return comments.value.filter(c => c.parent_id === parentId)
}

function toggleReply(commentId) {
  replyOpen.value = replyOpen.value === commentId ? null : commentId
  replyText.value = ''
  replyName.value = ''
}

const spektekUrl = computed(() => {
  if (!job.value?.spektek) return ''
  const path = job.value.spektek.replace(/\\/g, '/')
  if (path.startsWith('uploads/')) return '/' + path
  return '/uploads/spektek/' + path
})

const tekProgress = computed(() => progress(teknisiItems.value))
function progress(items) {
  const total = items.length
  const completed = items.filter(i => i.status === 'selesai' || i.completed).length
  const pct = total ? Math.round((completed / total) * 100) : 0
  return { total, completed, pct }
}

function getImages(item) {
  return (item.images || '').split(',').filter(Boolean)
}

function formatNumber(val) {
  if (!val) return '0'
  return Number(val).toLocaleString('id-ID')
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

const previewSrc = ref(null)

function openImage(src) {
  previewSrc.value = src
}

function closePreview() {
  previewSrc.value = null
}

function openWA(phone) {
  if (!phone) return
  const num = phone.replace(/[^0-9]/g, '')
  if (num.startsWith('0')) {
    window.open('https://wa.me/62' + num.slice(1), '_blank')
  } else {
    window.open('https://wa.me/' + num, '_blank')
  }
}

async function addComment() {
  const name = visitorName.value.trim()
  const text = commentText.value.trim()
  if (!name || !text) return
  try {
    await jobAPI.addSharedComment(route.params.token, { name, text })
    visitorName.value = ''
    commentText.value = ''
    const res = await jobAPI.getShared(route.params.token)
    comments.value = res.data.comments
  } catch (e) {
    error.value = 'Gagal mengirim komentar'
  }
}

async function sendReply(parentId) {
  const name = replyName.value.trim()
  const text = replyText.value.trim()
  if (!name || !text) return
  try {
    await jobAPI.addSharedComment(route.params.token, { name, text, parent_id: parentId })
    replyName.value = ''
    replyText.value = ''
    replyOpen.value = null
    const res = await jobAPI.getShared(route.params.token)
    comments.value = res.data.comments
  } catch (e) {
    error.value = 'Gagal mengirim balasan'
  }
}

onMounted(async () => {
  try {
    const res = await jobAPI.getShared(route.params.token)
    job.value = res.data.job
    teknisiItems.value = res.data.teknisi_items || []
    comments.value = res.data.comments || []
    assignedUsers.value = res.data.assigned_users || []
  } catch (e) {
    error.value = 'Link tidak valid'
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.shared-page {
  max-width: 720px;
  margin: 0 auto;
  padding: 32px 20px;
}

.loading {
  text-align: center;
  padding: 80px 20px;
  color: var(--text-muted);
  font-size: 15px;
}

.error-page {
  text-align: center;
  padding: 80px 20px;
}

.error-page h2 {
  color: #ff6b6b;
  margin-bottom: 8px;
}

.shared-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

.shared-header h1 {
  font-size: 22px;
  font-weight: 700;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: capitalize;
}

.status-badge.pending { background: rgba(255, 193, 7, 0.15); color: #ffc107; }
.status-badge.progres { background: rgba(13, 202, 240, 0.15); color: #0dcaf0; }
.status-badge.done { background: rgba(25, 135, 84, 0.15); color: #198754; }

.wa-contacts {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}

.wa-contact {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: rgba(37, 211, 102, 0.1);
  border: 1px solid rgba(37, 211, 102, 0.25);
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.wa-contact:hover {
  background: rgba(37, 211, 102, 0.2);
}

.wa-icon {
  font-size: 18px;
}

.wa-name {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.shared-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.info-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 16px 20px;
}

.info-card label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.info-card p {
  font-size: 14px;
  color: var(--text-primary);
}

.section-card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 20px;
}

.section-card h3 {
  font-size: 15px;
  font-weight: 600;
  margin-bottom: 12px;
}

.progress-bar-wrap {
  margin-bottom: 12px;
}

.progress-label {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.progress-track {
  height: 6px;
  background: var(--hover-bg);
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  border-radius: 4px;
  transition: width 0.3s;
}

.checklist-items {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.checklist-text {
  flex-shrink: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 14px;
  color: var(--text-secondary);
}
.checklist-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 10px;
}
.checklist-row.done {
  opacity: 0.6;
}
.status-tag {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 14px;
  border-radius: 20px;
  white-space: nowrap;
  flex-shrink: 0;
  letter-spacing: 0.3px;
  text-transform: uppercase;
}
.status-tag.pending {
  background: rgba(255, 193, 7, 0.12);
  color: #e6a800;
  border: 1px solid rgba(255, 193, 7, 0.2);
}
.status-tag.progres {
  background: rgba(13, 202, 240, 0.12);
  color: #0aa2c0;
  border: 1px solid rgba(13, 202, 240, 0.2);
}
.status-tag.selesai {
  background: rgba(25, 135, 84, 0.12);
  color: #157347;
  border: 1px solid rgba(25, 135, 84, 0.2);
}
.right-group {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;
}
.item-images {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.item-thumb {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  object-fit: cover;
  cursor: pointer;
  border: 1px solid var(--card-border-light, #e0e0e0);
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  transition: transform 0.2s, box-shadow 0.2s;
}
.item-thumb:hover {
  transform: scale(1.15);
  box-shadow: 0 2px 8px rgba(0,0,0,0.12);
}

.logistic-card {
  padding: 10px 12px;
  background: var(--hover-bg);
  border-radius: 8px;
}

.logistic-card.done {
  opacity: 0.6;
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
  margin-top: 4px;
}

.comment-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 16px;
}

.comment-item {
  padding: 10px 14px;
  background: var(--hover-bg);
  border-radius: 8px;
}

.comment-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.comment-author {
  font-weight: 600;
  font-size: 13px;
  color: var(--text-primary);
}

.comment-time {
  font-size: 11px;
  color: var(--text-dim);
}

.comment-text {
  font-size: 13px;
  color: var(--text-primary);
  white-space: pre-wrap;
}

.empty-text {
  text-align: center;
  padding: 24px;
  color: var(--text-dim);
  font-size: 13px;
  font-style: italic;
}

.comment-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.comment-input {
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
}

.comment-input:focus {
  border-color: #667eea;
}

.comment-textarea {
  padding: 10px 14px;
  border: 1px solid var(--input-border);
  border-radius: 8px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  outline: none;
  resize: vertical;
}

.comment-textarea:focus {
  border-color: #667eea;
}

.btn-kirim {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  align-self: flex-end;
  font-family: 'Inter', sans-serif;
}

.btn-kirim:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-kirim:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.spektek-link {
  color: #667eea;
  font-size: 14px;
  text-decoration: none;
}

.spektek-link:hover {
  text-decoration: underline;
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
  flex-direction: column;
  gap: 8px;
  margin-top: 8px;
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
  background: var(--hover-bg);
  border-radius: 6px;
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
