import api from './client'

export const attendanceAPI = {
  getToday() { return api.get('/attendance/today') },
  hadir(location) { return api.post('/attendance/hadir', { location }) },
  tidakHadir(reason) { return api.post('/attendance/tidak-hadir', { reason }) },
  lemburStart() { return api.post('/attendance/lembur/start') },
  lemburEnd() { return api.post('/attendance/lembur/end') },
  getReport(params) { return api.get('/attendance/report', { params }) },
  update(id, data) { return api.put(`/attendance/${id}`, data) },
  delete(id) { return api.delete(`/attendance/${id}`) },
}
