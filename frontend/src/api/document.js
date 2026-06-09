import api from './client'

export const documentAPI = {
  getAll() {
    return api.get('/documents')
  },
  getById(id) {
    return api.get(`/documents/${id}`)
  },
  create(formData) {
    return api.post('/documents', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
  update(id, data) {
    return api.put(`/documents/${id}`, data)
  },
  delete(id) {
    return api.delete(`/documents/${id}`)
  },
}
