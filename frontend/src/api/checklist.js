import api from './client'

export const checklistAPI = {
  get(jobId, role) {
    return api.get(`/jobs/${jobId}/checklist`, { params: { role } })
  },
  add(jobId, data) {
    return api.post(`/jobs/${jobId}/checklist`, data)
  },
  toggle(jobId, itemId) {
    return api.put(`/jobs/${jobId}/checklist/${itemId}`)
  },
  update(jobId, itemId, data) {
    return api.patch(`/jobs/${jobId}/checklist/${itemId}`, data)
  },
  progres(jobId, itemId) {
    return api.put(`/jobs/${jobId}/checklist/${itemId}/progres`)
  },
  selesai(jobId, itemId) {
    return api.put(`/jobs/${jobId}/checklist/${itemId}/selesai`)
  },
  uploadImage(jobId, itemId, role, formData) {
    return api.post(`/jobs/${jobId}/checklist/${itemId}/images?role=${role}`, formData)
  },
  deleteImage(jobId, itemId, filename) {
    return api.delete(`/jobs/${jobId}/checklist/${itemId}/images?filename=${filename}`)
  },
  remove(jobId, itemId) {
    return api.delete(`/jobs/${jobId}/checklist/${itemId}`)
  },
}
