import api from './client'

export const todoAPI = {
  getAll() {
    return api.get('/todos')
  },
  create(data) {
    return api.post('/todos', data)
  },
  toggle(id) {
    return api.put(`/todos/${id}/toggle`)
  },
  delete(id) {
    return api.delete(`/todos/${id}`)
  },
}
