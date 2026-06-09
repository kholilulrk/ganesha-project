import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'
import { permissionAPI } from '../api/permission'

export const usePermissionStore = defineStore('permissions', () => {
  const permissions = ref([])
  const loaded = ref(false)
  const previewRole = ref(null)
  const previewPermissions = ref([])

  const permissionSet = computed(() => new Set(permissions.value))
  const previewPermissionSet = computed(() => new Set(previewPermissions.value))

  function can(resource, action) {
    const auth = useAuthStore()
    if (previewRole.value) {
      if (previewRole.value === 'Super Admin') return true
      return previewPermissionSet.value.has(`${resource}.${action}`)
    }
    if (auth.user?.role === 'Super Admin') return true
    return permissionSet.value.has(`${resource}.${action}`)
  }

  async function load() {
    try {
      const res = await permissionAPI.getPermissions()
      permissions.value = (res.data.permissions || []).map(p => {
        const resource = p.resource || p.Resource
        const action = p.action || p.Action
        return resource && action ? `${resource}.${action}` : null
      }).filter(Boolean)
      loaded.value = true
    } catch {
      permissions.value = []
      loaded.value = true
    }
  }

  async function setPreview(role) {
    previewRole.value = role
    if (!role) {
      previewPermissions.value = []
      return
    }
    try {
      const res = await permissionAPI.getByRole(role)
      previewPermissions.value = (res.data.permissions || []).map(p => {
        const resource = p.resource || p.Resource
        const action = p.action || p.Action
        return resource && action ? `${resource}.${action}` : null
      }).filter(Boolean)
    } catch {
      previewPermissions.value = []
    }
  }

  function clearPreview() {
    previewRole.value = null
    previewPermissions.value = []
  }

  function reset() {
    permissions.value = []
    loaded.value = false
    previewRole.value = null
    previewPermissions.value = []
  }

  return { permissions, loaded, previewRole, can, load, setPreview, clearPreview, reset }
})
