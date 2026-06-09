import api from './client'

export const authAPI = {
  register(data) {
    return api.post('/auth/register', data)
  },
  login(data) {
    return api.post('/auth/login', data)
  },
  getProfile() {
    return api.get('/profile')
  },
  updateProfile(data) {
    return api.put('/profile', data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
}
