import api from './client'

export const vendorAPI = {
  getAll() {
    return api.get('/vendors')
  },
  getById(id) {
    return api.get(`/vendors/${id}`)
  },
  create(data) {
    return api.post('/vendors', data)
  },
  update(id, data) {
    return api.put(`/vendors/${id}`, data)
  },
  delete(id) {
    return api.delete(`/vendors/${id}`)
  },
  getPaymentTerms(vendorId) {
    return api.get(`/vendors/${vendorId}/payment-terms`)
  },
  createPaymentTerm(vendorId, data) {
    return api.post(`/vendors/${vendorId}/payment-terms`, data)
  },
  updatePaymentTerm(vendorId, termId, data) {
    return api.put(`/vendors/${vendorId}/payment-terms/${termId}`, data)
  },
  deletePaymentTerm(vendorId, termId) {
    return api.delete(`/vendors/${vendorId}/payment-terms/${termId}`)
  },
}
