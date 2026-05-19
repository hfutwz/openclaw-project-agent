import api from './api'

export interface CheckInResult {
  reservationId: number
  status: string
  message: string
}

export interface CheckInCode {
  code: string
}

export const checkInApi = {
  /**
   * 学生签到 — 只需输入签到编码，后端自动查找对应用户的预约
   * PRD: POST /api/reservations/check-in
   */
  checkIn: (code: string) =>
    api.post<{ code: number; data: CheckInResult }>('/reservations/check-in', { code }),
  getTodayCode: (roomId: number) =>
    api.get<{ code: number; data: CheckInCode }>(`/check-in/code/${roomId}`),
  adminGetCode: (roomId: number) =>
    api.get<{ code: number; data: CheckInCode }>(`/admin/rooms/${roomId}/check-in-code`),
}
