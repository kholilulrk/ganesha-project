import api from './client'

export const dashboardAPI = {
  getStats() { return api.get('/dashboard') },
}
