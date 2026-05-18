import api from './api'

export interface Room {
  id: number
  name: string
  location: string
  departmentId: number | null
  departmentName: string
  openTime: string
  closeTime: string
  status: string
  totalSeats: number
  availableSeats: number
}

export interface Seat {
  id: number
  roomId: number
  seatNumber: string
  rowNum: number
  colNum: number
  socketType: string
  position: string
  status: string
  isAvailable: boolean
}

export interface RoomDetail extends Room {
  maxRow: number
  maxCol: number
  seats: Seat[]
}

export const roomApi = {
  // 学生端
  list: () => api.get<{ code: number; data: Room[] }>('/rooms'),
  getDetail: (id: number) => api.get<{ code: number; data: RoomDetail }>(`/rooms/${id}`),

  // 管理端
  adminList: (page = 1, size = 20, status?: string, name?: string) =>
    api.get<{ code: number; data: { records: Room[]; total: number; page: number; size: number } }>('/admin/rooms', { params: { page, size, status, name } }),
  adminCreate: (data: Partial<Room>) => api.post('/admin/rooms', data),
  adminUpdate: (id: number, data: Partial<Room>) => api.put(`/admin/rooms/${id}`, data),
  adminDelete: (id: number) => api.delete(`/admin/rooms/${id}`),
}

export const seatApi = {
  // 学生端
  listByRoom: (roomId: number) => api.get<{ code: number; data: Seat[] }>(`/rooms/${roomId}/seats`),
  getDetail: (roomId: number, seatId: number) => api.get<{ code: number; data: Seat }>(`/rooms/${roomId}/seats/${seatId}`),

  // 管理端
  adminCreate: (roomId: number, data: Partial<Seat>) => api.post(`/admin/rooms/${roomId}/seats`, data),
  adminBatchCreate: (roomId: number, data: Partial<Seat>[]) => api.post(`/admin/rooms/${roomId}/seats/batch`, data),
  adminUpdate: (roomId: number, seatId: number, data: Partial<Seat>) => api.put(`/admin/rooms/${roomId}/seats/${seatId}`, data),
  adminDelete: (roomId: number, seatId: number) => api.delete(`/admin/rooms/${roomId}/seats/${seatId}`),
}
