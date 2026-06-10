<template>
  <div class="todo-page">
    <div class="page-header">
      <div>
        <h1>To-do List</h1>
        <p>Tugas untuk saya & tugas yang saya buat</p>
      </div>
    </div>

    <div class="todo-input-bar">
      <input v-model="newTask" @keyup.enter="addTodo" placeholder="Tambah tugas baru..." class="todo-input" />
      <select v-model="assignTo" class="todo-assign">
        <option value="">Untuk saya</option>
        <option v-for="u in assignableUsers" :key="u.ID" :value="u.ID">{{ u.name }}</option>
      </select>
      <button @click="addTodo" class="btn-add-todo" :disabled="!newTask.trim()">Tambah</button>
    </div>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <div class="todo-tabs">
      <button :class="{ active: filter === 'all' }" @click="filter = 'all'">Semua ({{ todos.length }})</button>
      <button :class="{ active: filter === 'pending' }" @click="filter = 'pending'">Pending ({{ pendingCount }})</button>
      <button :class="{ active: filter === 'done' }" @click="filter = 'done'">Selesai ({{ doneCount }})</button>
    </div>

    <div class="todo-list">
      <div v-for="todo in filteredTodos" :key="todo.ID" class="todo-item" :class="{ done: todo.status === 'done' }">
        <label class="todo-check-wrap">
          <input type="checkbox" :checked="todo.status === 'done'" @change="toggleTodo(todo.ID)" class="todo-check" />
          <span class="todo-checkmark"></span>
        </label>
        <div class="todo-body">
          <span class="todo-task">{{ todo.task }}</span>
          <span class="todo-meta">
            <span class="todo-creator">dari {{ userName(todo.created_by) }}</span>
            <span class="todo-divider">·</span>
            <span class="todo-assignee">untuk {{ assigneeName(todo.assigned_to) }}</span>
            <span class="todo-date">{{ formatDate(todo.CreatedAt) }}</span>
          </span>
        </div>
        <button class="btn-delete-todo" @click="deleteTodo(todo.ID)" title="Hapus">&times;</button>
      </div>
      <div v-if="!filteredTodos.length" class="empty-todo">
        <p>{{ filter === 'all' ? 'Belum ada tugas' : filter === 'pending' ? 'Semua tugas selesai' : 'Belum ada tugas selesai' }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHead } from '@unhead/vue'
import { todoAPI } from '../api/todo'
import { userAPI } from '../api/user'
import { useAuthStore } from '../stores/auth'
useHead({
  title: 'To-do List',
  meta: [
    { name: 'description', content: 'Daftar tugas Ganesha Energi' },
  ],
})

const auth = useAuthStore()
const currentUserId = computed(() => auth.user?.ID || auth.user?.id || 0)

const todos = ref([])
const allUsers = ref([])
const newTask = ref('')
const assignTo = ref('')
const filter = ref('all')
const error = ref('')

const currentRole = computed(() => auth.user?.role || '')
const assignableUsers = computed(() => {
  return allUsers.value.filter(u => u.role !== 'Super Admin')
})
const pendingCount = computed(() => todos.value.filter(t => t.status === 'pending').length)
const doneCount = computed(() => todos.value.filter(t => t.status === 'done').length)

const filteredTodos = computed(() => {
  if (filter.value === 'pending') return todos.value.filter(t => t.status === 'pending')
  if (filter.value === 'done') return todos.value.filter(t => t.status === 'done')
  return todos.value
})

function userName(id) {
  if (!id) return 'Saya'
  if (id === currentUserId.value) return 'Saya'
  const u = allUsers.value.find(u => u.ID === id || u.id === id)
  return u ? u.name : 'User #' + id
}

function assigneeName(id) {
  if (!id) return 'Saya'
  if (id === currentUserId.value) return 'saya'
  const u = allUsers.value.find(u => u.ID === id || u.id === id)
  return u ? u.name : 'User #' + id
}

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('id-ID', {
    day: 'numeric', month: 'short',
  })
}

async function addTodo() {
  if (!newTask.value.trim()) return
  error.value = ''
  try {
    const data = { task: newTask.value.trim() }
    if (assignTo.value) data.assigned_to = Number(assignTo.value)
    await todoAPI.create(data)
    newTask.value = ''
    assignTo.value = ''
    await loadTodos()
  } catch (e) {
    error.value = 'Gagal menambah tugas'
  }
}

async function toggleTodo(id) {
  try {
    await todoAPI.toggle(id)
    await loadTodos()
  } catch (e) {
    error.value = 'Gagal mengubah status'
  }
}

async function deleteTodo(id) {
  if (!confirm('Hapus tugas ini?')) return
  try {
    await todoAPI.delete(id)
    await loadTodos()
  } catch (e) {
    error.value = 'Gagal menghapus tugas'
  }
}

async function loadTodos() {
  try {
    const res = await todoAPI.getAll()
    todos.value = res.data.todos
  } catch (e) {
    error.value = 'Gagal memuat data'
  }
}

onMounted(async () => {
  loadTodos()
  try {
    const res = await userAPI.getAll()
    allUsers.value = res.data.users
  } catch { /* ignore */ }
})
</script>

<style scoped>
.todo-page {
  padding: 24px;
  max-width: 700px;
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

.todo-input-bar {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.todo-input {
  flex: 1;
  padding: 12px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  transition: border-color 0.2s;
}

.todo-input:focus {
  border-color: #667eea;
}

.todo-assign {
  padding: 12px 14px;
  border: 1px solid var(--input-border);
  border-radius: 10px;
  background: var(--input-bg);
  color: var(--text-primary);
  font-size: 14px;
  font-family: 'Inter', sans-serif;
  outline: none;
  cursor: pointer;
  min-width: 140px;
}

.todo-assign:focus {
  border-color: #667eea;
}

.todo-assign option {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.btn-add-todo {
  padding: 12px 20px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  white-space: nowrap;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-add-todo:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.btn-add-todo:disabled {
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

.todo-tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.todo-tabs button {
  padding: 8px 16px;
  border: 1px solid var(--card-border-light);
  border-radius: 8px;
  background: transparent;
  color: var(--text-secondary);
  font-size: 13px;
  font-family: 'Inter', sans-serif;
  cursor: pointer;
  transition: all 0.2s;
}

.todo-tabs button.active {
  background: rgba(102, 126, 234, 0.15);
  color: #667eea;
  border-color: rgba(102, 126, 234, 0.3);
}

.todo-tabs button:hover:not(.active) {
  background: var(--hover-bg);
}

.todo-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.todo-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: var(--card-bg);
  border: 1px solid var(--card-border-light);
  border-radius: 12px;
  transition: all 0.2s;
}

.todo-item:hover {
  border-color: var(--card-border);
}

.todo-item.done {
  opacity: 0.6;
}

.todo-check-wrap {
  position: relative;
  width: 22px;
  height: 22px;
  flex-shrink: 0;
  cursor: pointer;
}

.todo-check {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  width: 100%;
  height: 100%;
}

.todo-checkmark {
  position: absolute;
  inset: 0;
  border: 2px solid var(--card-border);
  border-radius: 6px;
  transition: all 0.2s;
}

.todo-check:checked + .todo-checkmark {
  background: #51cf66;
  border-color: #51cf66;
}

.todo-check:checked + .todo-checkmark::after {
  content: '';
  position: absolute;
  left: 6px;
  top: 2px;
  width: 6px;
  height: 10px;
  border: solid #fff;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

.todo-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.todo-task {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  word-break: break-word;
}

.todo-item.done .todo-task {
  text-decoration: line-through;
}

.todo-meta {
  display: flex;
  gap: 8px;
  font-size: 11px;
  color: var(--text-muted);
  flex-wrap: wrap;
}

.todo-divider {
  color: var(--text-dim);
}

.todo-assignee {
  font-weight: 600;
  color: #667eea;
}

.btn-delete-todo {
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: var(--text-muted);
  font-size: 18px;
  cursor: pointer;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-delete-todo:hover {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.empty-todo {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-dim);
  font-size: 14px;
}
</style>
