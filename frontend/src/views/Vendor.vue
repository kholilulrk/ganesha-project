<template>
  <div class="vendor-page">
    <div class="page-header">
      <div>
        <h1>Vendor</h1>
        <p>Kelola data vendor dan termin pembayaran</p>
      </div>
      <button class="btn-add" @click="openVendorForm(null)">
        <span>+</span> Tambah Vendor
      </button>
    </div>

    <transition name="modal-fade">
      <div v-if="showVendorForm" class="modal-overlay" @click.self="closeVendorForm">
        <div class="modal-card">
          <div class="modal-header">
            <h2>{{ editingVendor ? 'Edit Vendor' : 'Tambah Vendor' }}</h2>
            <button class="btn-close" @click="closeVendorForm">&times;</button>
          </div>
          <form @submit.prevent="handleVendorSubmit" class="vendor-form">
            <div class="form-group">
              <label>Nama Perusahaan <span class="required">*</span></label>
              <input v-model="vendorForm.name" type="text" placeholder="Nama vendor" required />
            </div>
            <div class="form-group">
              <label>Pekerjaan Terkait</label>
              <select v-model="vendorForm.job_id">
                <option :value="null">-- Pilih pekerjaan --</option>
                <option v-for="job in jobs" :key="job.ID" :value="job.ID">
                  {{ job.name }}
                </option>
              </select>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Kontak Person</label>
                <input v-model="vendorForm.contact_person" type="text" placeholder="Nama kontak" />
              </div>
              <div class="form-group">
                <label>Telepon</label>
                <input v-model="vendorForm.phone" type="text" placeholder="No telepon" />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Email</label>
                <input v-model="vendorForm.email" type="email" placeholder="Email" />
              </div>
            </div>
            <div class="form-group">
              <label>Alamat</label>
              <textarea v-model="vendorForm.address" placeholder="Alamat lengkap" rows="2"></textarea>
            </div>
            <div class="form-group">
              <label>Keterangan</label>
              <textarea v-model="vendorForm.description" placeholder="Catatan tambahan" rows="2"></textarea>
            </div>
            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeVendorForm">Batal</button>
              <button type="submit" class="btn-save" :disabled="vendorLoading">
                <span v-if="vendorLoading" class="spinner-sm" />
                <span v-else>{{ editingVendor ? 'Simpan' : 'Tambah' }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

    <transition name="modal-fade">
      <div v-if="showTerminModal" class="modal-overlay" @click.self="closeTerminModal">
        <div class="modal-card modal-lg">
          <div class="modal-header">
            <h2>Termin Pembayaran — {{ selectedVendor?.name }}</h2>
            <button class="btn-close" @click="closeTerminModal">&times;</button>
          </div>
          <div class="termin-section">
            <table class="vendor-table" v-if="paymentTerms.length">
              <thead>
                <tr>
                  <th class="th-sm">Termin</th>
                  <th>Persentase</th>
                  <th>Jumlah (Rp)</th>
                  <th>Jatuh Tempo</th>
                  <th>Keterangan</th>
                  <th class="th-actions">Aksi</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="term in paymentTerms" :key="term.ID">
                  <td class="text-center">Termin {{ term.term_number }}</td>
                  <td>{{ term.percentage ? term.percentage + '%' : '-' }}</td>
                  <td>{{ term.amount ? formatRupiah(term.amount) : '-' }}</td>
                  <td>{{ term.due_date || '-' }}</td>
                  <td>{{ term.description || '-' }}</td>
                  <td class="td-actions">
                    <button class="btn-icon edit" @click="editTerm(term)" title="Edit">&#9998;&#65039;</button>
                    <button class="btn-icon delete" @click="deleteTerm(term.ID)" title="Hapus">&#128465;&#65039;</button>
                  </td>
                </tr>
              </tbody>
              <tfoot v-if="paymentTerms.length">
                <tr class="total-row">
                  <td class="text-center"><strong>Total</strong></td>
                  <td><strong>{{ totalPercentage }}%</strong></td>
                  <td><strong>{{ formatRupiah(totalAmount) }}</strong></td>
                  <td></td>
                  <td></td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
            <div v-else class="empty-state">
              <p>Belum ada termin pembayaran</p>
            </div>

            <hr class="termin-divider" />

            <h3>{{ editingTerm ? 'Edit Termin' : 'Tambah Termin' }}</h3>
            <form @submit.prevent="handleTermSubmit" class="termin-form">
              <div class="form-row">
                <div class="form-group">
                  <label>Termin ke- <span class="required">*</span></label>
                  <input v-model.number="termForm.term_number" type="number" min="1" required />
                </div>
                <div class="form-group">
                  <label>Persentase (%)</label>
                  <input v-model.number="termForm.percentage" type="number" step="0.01" min="0" max="100" />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Jumlah (Rp)</label>
                  <input v-model.number="termForm.amount" type="number" step="1000" min="0" />
                </div>
                <div class="form-group">
                  <label>Jatuh Tempo</label>
                  <input v-model="termForm.due_date" type="date" />
                </div>
              </div>
              <div class="form-group">
                <label>Keterangan</label>
                <input v-model="termForm.description" type="text" placeholder="Misal: Pembayaran awal" />
              </div>
              <div class="form-actions">
                <button type="button" class="btn-cancel" @click="resetTermForm">Batal</button>
                <button type="submit" class="btn-save" :disabled="termLoading">
                  <span v-if="termLoading" class="spinner-sm" />
                  <span v-else>{{ editingTerm ? 'Simpan' : 'Tambah' }}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </transition>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <transition name="toast-fade">
      <div v-if="toast.visible" class="toast-notification">{{ toast.message }}</div>
    </transition>

    <div class="table-wrapper">
      <table class="vendor-table">
        <thead>
          <tr>
            <th>Nama Perusahaan</th>
            <th>Kontak Person</th>
            <th>Telepon</th>
            <th>Email</th>
            <th>Pekerjaan Terkait</th>
            <th class="th-actions">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="vendor in vendors" :key="vendor.ID" class="table-row">
            <td class="td-name">{{ vendor.name }}</td>
            <td>{{ vendor.contact_person || '-' }}</td>
            <td>{{ vendor.phone || '-' }}</td>
            <td>{{ vendor.email || '-' }}</td>
            <td>{{ vendor.job?.name || '-' }}</td>
            <td class="td-actions">
              <button class="btn-icon term" @click="openTerminModal(vendor)" title="Termin">&#128176;</button>
              <button class="btn-icon edit" @click="openVendorForm(vendor)" title="Edit">&#9998;&#65039;</button>
              <button class="btn-icon delete" @click="deleteVendor(vendor.ID)" title="Hapus">&#128465;&#65039;</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="!vendors.length" class="empty-state">
        <div class="empty-icon">&#127970;</div>
        <p>Belum ada vendor</p>
        <button class="btn-add" @click="openVendorForm(null)">Tambah Vendor</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { vendorAPI } from '../api/vendor'
import { jobAPI } from '../api/job'

useHead({
  title: 'Vendor',
  meta: [
    { name: 'description', content: 'Kelola vendor dan termin pembayaran' },
  ],
})

const vendors = ref([])
const jobs = ref([])
const showVendorForm = ref(false)
const editingVendor = ref(false)
const editVendorId = ref(null)
const vendorLoading = ref(false)
const error = ref('')

const showTerminModal = ref(false)
const selectedVendor = ref(null)
const paymentTerms = ref([])
const editingTerm = ref(false)
const editTermId = ref(null)
const termLoading = ref(false)

const totalAmount = computed(() => {
  return paymentTerms.value.reduce((sum, t) => sum + (t.amount || 0), 0)
})

const totalPercentage = computed(() => {
  const total = paymentTerms.value.reduce((sum, t) => sum + (t.percentage || 0), 0)
  return total
})

const toast = reactive({ visible: false, message: '' })
let toastTimer = null

function showToast(msg) {
  toast.message = msg
  toast.visible = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.visible = false }, 2000)
}

const vendorForm = reactive({
  name: '',
  contact_person: '',
  phone: '',
  email: '',
  address: '',
  description: '',
  job_id: null,
})

const termForm = reactive({
  term_number: 1,
  percentage: null,
  amount: null,
  due_date: '',
  description: '',
})

function openVendorForm(vendor) {
  if (vendor) {
    editingVendor.value = true
    editVendorId.value = vendor.ID
    vendorForm.name = vendor.name
    vendorForm.contact_person = vendor.contact_person || ''
    vendorForm.phone = vendor.phone || ''
    vendorForm.email = vendor.email || ''
    vendorForm.address = vendor.address || ''
    vendorForm.description = vendor.description || ''
    vendorForm.job_id = vendor.job_id
  } else {
    editingVendor.value = false
    editVendorId.value = null
    vendorForm.name = ''
    vendorForm.contact_person = ''
    vendorForm.phone = ''
    vendorForm.email = ''
    vendorForm.address = ''
    vendorForm.description = ''
    vendorForm.job_id = null
  }
  showVendorForm.value = true
}

function closeVendorForm() {
  showVendorForm.value = false
}

function resetTermForm() {
  editingTerm.value = false
  editTermId.value = null
  termForm.term_number = (paymentTerms.value.length || 0) + 1
  termForm.percentage = null
  termForm.amount = null
  termForm.due_date = ''
  termForm.description = ''
}

async function openTerminModal(vendor) {
  selectedVendor.value = vendor
  paymentTerms.value = []
  resetTermForm()
  showTerminModal.value = true
  await loadPaymentTerms(vendor.ID)
}

function closeTerminModal() {
  showTerminModal.value = false
  selectedVendor.value = null
}

function editTerm(term) {
  editingTerm.value = true
  editTermId.value = term.ID
  termForm.term_number = term.term_number
  termForm.percentage = term.percentage
  termForm.amount = term.amount
  termForm.due_date = term.due_date || ''
  termForm.description = term.description || ''
}

async function handleVendorSubmit() {
  vendorLoading.value = true
  error.value = ''
  try {
    const data = {
      name: vendorForm.name,
      contact_person: vendorForm.contact_person || null,
      phone: vendorForm.phone || null,
      email: vendorForm.email || null,
      address: vendorForm.address || null,
      description: vendorForm.description || null,
      job_id: vendorForm.job_id || null,
    }
    if (editingVendor.value) {
      await vendorAPI.update(editVendorId.value, data)
      showToast('Vendor berhasil diperbarui')
    } else {
      await vendorAPI.create(data)
      showToast('Vendor berhasil ditambahkan')
    }
    closeVendorForm()
    await loadVendors()
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan data'
  } finally {
    vendorLoading.value = false
  }
}

async function deleteVendor(id) {
  if (!confirm('Yakin ingin menghapus vendor ini?')) return
  try {
    await vendorAPI.delete(id)
    showToast('Vendor berhasil dihapus')
    await loadVendors()
  } catch (err) {
    error.value = 'Gagal menghapus data'
  }
}

async function handleTermSubmit() {
  if (!selectedVendor.value) return
  termLoading.value = true
  error.value = ''
  try {
    const data = {
      term_number: termForm.term_number,
      percentage: termForm.percentage || null,
      amount: termForm.amount || null,
      due_date: termForm.due_date || null,
      description: termForm.description || null,
    }
    if (editingTerm.value) {
      await vendorAPI.updatePaymentTerm(selectedVendor.value.ID, editTermId.value, data)
      showToast('Termin berhasil diperbarui')
    } else {
      await vendorAPI.createPaymentTerm(selectedVendor.value.ID, data)
      showToast('Termin berhasil ditambahkan')
    }
    resetTermForm()
    await loadPaymentTerms(selectedVendor.value.ID)
  } catch (err) {
    error.value = err.response?.data?.error || 'Gagal menyimpan termin'
  } finally {
    termLoading.value = false
  }
}

async function deleteTerm(termId) {
  if (!selectedVendor.value) return
  if (!confirm('Yakin ingin menghapus termin ini?')) return
  try {
    await vendorAPI.deletePaymentTerm(selectedVendor.value.ID, termId)
    showToast('Termin berhasil dihapus')
    await loadPaymentTerms(selectedVendor.value.ID)
  } catch (err) {
    error.value = 'Gagal menghapus termin'
  }
}

async function loadVendors() {
  try {
    const res = await vendorAPI.getAll()
    vendors.value = res.data.vendors
  } catch (err) {
    error.value = 'Gagal memuat data vendor'
  }
}

async function loadJobs() {
  try {
    const res = await jobAPI.getAll()
    jobs.value = res.data.jobs || []
  } catch {
    // jobs opsional
  }
}

async function loadPaymentTerms(vendorId) {
  try {
    const res = await vendorAPI.getPaymentTerms(vendorId)
    paymentTerms.value = res.data.payment_terms
  } catch {
    error.value = 'Gagal memuat termin pembayaran'
  }
}

function formatRupiah(val) {
  return new Intl.NumberFormat('id-ID').format(val)
}

onMounted(() => {
  loadVendors()
  loadJobs()
})
</script>

<style scoped>
.vendor-page {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-header h1 {
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 700;
  margin: 0;
}

.page-header p {
  color: var(--text-muted);
  font-size: 14px;
  margin: 4px 0 0 0;
}

.btn-add {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-family: 'Inter', sans-serif;
}

.btn-add:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  padding: 20px;
}

.modal-card {
  background: var(--card-bg);
  border-radius: 16px;
  width: 100%;
  max-width: 520px;
  max-height: 90vh;
  overflow-y: auto;
  padding: 28px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-card.modal-lg {
  max-width: 700px;
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
  font-weight: 700;
  margin: 0;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  color: var(--text-muted);
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.btn-close:hover {
  background: var(--hover-bg);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.vendor-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row {
  display: flex;
  gap: 16px;
}

.form-row .form-group {
  flex: 1;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 600;
}

.form-group .required {
  color: #ef4444;
}

.form-group input,
.form-group select,
.form-group textarea {
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid var(--card-border-light);
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  transition: border-color 0.2s;
  outline: none;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  border-color: #667eea;
}

.form-group textarea {
  resize: vertical;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

.btn-cancel {
  padding: 10px 20px;
  background: var(--hover-bg);
  color: var(--text-primary);
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: background 0.2s;
}

.btn-cancel:hover {
  background: var(--hover-bg-strong);
}

.btn-save {
  padding: 10px 24px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  transition: opacity 0.2s;
}

.btn-save:hover {
  opacity: 0.9;
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner-sm {
  display: inline-block;
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
  padding: 12px 16px;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  color: #ef4444;
  border-radius: 10px;
  margin-bottom: 16px;
  font-size: 14px;
}

.toast-notification {
  position: fixed;
  top: 20px;
  right: 20px;
  padding: 12px 24px;
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 12px;
  color: var(--text-primary);
  font-size: 14px;
  font-weight: 500;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  z-index: 400;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.3s ease;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.table-wrapper {
  background: var(--card-bg);
  border-radius: 16px;
  border: 1px solid var(--card-border-light);
  overflow: hidden;
}

.vendor-table {
  width: 100%;
  border-collapse: collapse;
}

.vendor-table thead {
  background: var(--hover-bg);
}

.vendor-table th {
  padding: 14px 16px;
  text-align: left;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 1px solid var(--card-border-light);
}

.vendor-table td {
  padding: 14px 16px;
  color: var(--text-primary);
  font-size: 14px;
  border-bottom: 1px solid var(--card-border-light);
}

.vendor-table .table-row:hover {
  background: var(--hover-bg);
}

.vendor-table .td-name {
  font-weight: 600;
}

.vendor-table .total-row td {
  border-top: 2px solid var(--card-border-light);
  background: var(--hover-bg);
  font-weight: 600;
}

.vendor-table .th-sm {
  width: 80px;
}

.text-center {
  text-align: center;
}

.th-actions {
  width: 140px;
  text-align: center;
}

.td-actions {
  text-align: center;
  white-space: nowrap;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  padding: 6px 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.btn-icon:hover {
  background: var(--hover-bg);
}

.btn-icon.term:hover {
  background: rgba(16, 185, 129, 0.15);
}

.btn-icon.edit:hover {
  background: rgba(102, 126, 234, 0.15);
}

.btn-icon.delete:hover {
  background: rgba(239, 68, 68, 0.15);
}

.empty-state {
  padding: 60px 20px;
  text-align: center;
  color: var(--text-muted);
}

.empty-state .empty-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.empty-state p {
  font-size: 16px;
  margin-bottom: 16px;
}

.termin-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.termin-divider {
  border: none;
  border-top: 1px solid var(--card-border-light);
  margin: 8px 0;
}

.termin-section h3 {
  color: var(--text-primary);
  font-size: 15px;
  font-weight: 600;
  margin: 0;
}

.termin-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
</style>
