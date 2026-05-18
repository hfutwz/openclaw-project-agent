import api from './api'

export interface CheckInResult {
  reservationId: number
  status: string
}

export interface CheckInCode {
  code: string
}

export const checkInApi = {
  checkIn: (reservationId: number, code: string) =>
    api.post<{ code: number; data: CheckInResult }>('/check-in', { reservationId, code }),
  getTodayCode: (roomId: number) =>
    api.get<{ code: number; data: CheckInCode }>(`/check-in/code/${roomId}`),
  adminGetCode: (roomId: number) =>
    api.get<{ code: number; data: CheckInCode }>(`/admin/check-in-codes/${roomId}`),
}
