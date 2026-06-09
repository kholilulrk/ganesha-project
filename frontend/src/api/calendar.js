import api from './client'

export const calendarAPI = {
  getAll() {
    return api.get('/calendar-events')
  },
  create(data) {
    return api.post('/calendar-events', data)
  },
  update(id, data) {
    return api.put(`/calendar-events/${id}`, data)
  },
  delete(id) {
    return api.delete(`/calendar-events/${id}`)
  },
}
