import api from './client'

export const suratAPI = {
  getAll() {
    return api.get('/surats')
  },
  getById(id) {
    return api.get(`/surats/${id}`)
  },
  create(data) {
    return api.post('/surats', data)
  },
  update(id, data) {
    return api.put(`/surats/${id}`, data)
  },
  delete(id) {
    return api.delete(`/surats/${id}`)
  },
  getExpiring() {
    return api.get('/surats/expiring')
  },
}
