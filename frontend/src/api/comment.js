import api from './client'

export const commentAPI = {
  get(jobId) {
    return api.get(`/jobs/${jobId}/comments`)
  },
  add(jobId, text, parentId) {
    const data = { text }
    if (parentId) data.parent_id = parentId
    return api.post(`/jobs/${jobId}/comments`, data)
  },
  remove(jobId, commentId) {
    return api.delete(`/jobs/${jobId}/comments/${commentId}`)
  },
}
