import api from './api'

export interface Reservation {
  id: number
  seatId: number
  roomName: string
  seatNumber: string
  date: string
  startTime: string
  endTime: string
  status: string
  cancelledBy: string | null
}

export const reservationApi = {
  // 学生端
  create: (data: { seatId: number; date: string; startTime: string; endTime: string }) =>
    api.post<{ code: number; data: Reservation }>('/reservations', data),
  cancel: (id: number) => api.put<{ code: number; data: Reservation }>(`/reservations/${id}/cancel`),
  listCurrent: () => api.get<{ code: number; data: Reservation[] }>('/reservations/current'),
  listHistory: (page = 1, size = 20) =>
    api.get<{ code: number; data: { records: Reservation[]; total: number } }>('/reservations/history', { params: { page, size } }),
  rebook: (id: number) => api.post<{ code: number; data: Reservation }>(`/reservations/${id}/rebook`),

  // 管理端
  adminList: (params: { page?: number; size?: number; status?: string; userId?: number; date?: string }) =>
    api.get<{ code: number; data: { records: Reservation[]; total: number } }>('/admin/reservations', { params }),
  adminCancel: (id: number) => api.put<{ code: number; data: Reservation }>(`/admin/reservations/${id}/cancel`),
}
