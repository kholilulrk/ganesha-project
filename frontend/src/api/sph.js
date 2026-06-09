import api from './client'

export const sphAPI = {
  getAll() {
    return api.get('/sph')
  },
  getById(id) {
    return api.get(`/sph/${id}`)
  },
  create(data) {
    return api.post('/sph', data)
  },
  update(id, data) {
    return api.put(`/sph/${id}`, data)
  },
  delete(id) {
    return api.delete(`/sph/${id}`)
  },
}
