import api from './client'

export const announcementAPI = {
  getAll() { return api.get('/announcements') },
  getActive() { return api.get('/announcements/active') },
  create(data) { return api.post('/announcements', data) },
  update(id, data) { return api.put(`/announcements/${id}`, data) },
  toggle(id) { return api.put(`/announcements/${id}/toggle`) },
  delete(id) { return api.delete(`/announcements/${id}`) },
}
