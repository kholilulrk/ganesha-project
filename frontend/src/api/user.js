import api from './client'

export const userAPI = {
  getAll(params) {
    return api.get('/users', { params })
  },
  create(data) {
    return api.post('/users', data)
  },
  update(id, data) {
    return api.put(`/users/${id}`, data)
  },
  delete(id) {
    return api.delete(`/users/${id}`)
  },
}
