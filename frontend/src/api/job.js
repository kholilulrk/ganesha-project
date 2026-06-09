import api from './client'

export const jobAPI = {
  getAll(params) {
    return api.get('/jobs', { params })
  },
  getById(id) {
    return api.get(`/jobs/${id}`)
  },
  create(data) {
    return api.post('/jobs', data)
  },
  update(id, data) {
    return api.put(`/jobs/${id}`, data)
  },
  delete(id) {
    return api.delete(`/jobs/${id}`)
  },
  generateShareLink(id) {
    return api.post(`/jobs/${id}/share-link`)
  },
  complete(id) {
    return api.put(`/jobs/${id}/complete`)
  },
  updateStatus(id, status) {
    return api.patch(`/jobs/${id}/status`, { status })
  },
  getShared(token) {
    return api.get(`/jobs/shared/${token}`)
  },
  addSharedComment(token, data) {
    return api.post(`/jobs/shared/${token}/comments`, data)
  },
  progresShared(token, itemId) {
    return api.put(`/jobs/shared/${token}/checklist/${itemId}/progres`)
  },
  selesaiShared(token, itemId) {
    return api.put(`/jobs/shared/${token}/checklist/${itemId}/selesai`)
  },
}
