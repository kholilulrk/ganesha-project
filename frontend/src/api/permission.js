import api from './client'

export const permissionAPI = {
  getPermissions() { return api.get('/permissions') },
  getRoles() { return api.get('/permissions/roles') },
  getByRole(role) { return api.get(`/permissions/${role}`) },
  update(role, permissions) { return api.put('/permissions', { role, permissions }) },
  reset() { return api.post('/permissions/reset') },
}
