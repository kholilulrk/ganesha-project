import api from './client'

export const companyAPI = {
  getProfile() {
    return api.get('/company')
  },
  updateProfile(data) {
    return api.put('/company', data)
  },
  createService(data) {
    return api.post('/company/services', data)
  },
  updateService(id, data) {
    return api.put(`/company/services/${id}`, data)
  },
  deleteService(id) {
    return api.delete(`/company/services/${id}`)
  },
  createPartner(data) {
    return api.post('/company/partners', data)
  },
  updatePartner(id, data) {
    return api.put(`/company/partners/${id}`, data)
  },
  deletePartner(id) {
    return api.delete(`/company/partners/${id}`)
  },
}
