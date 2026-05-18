import api from './api'

export interface ViolationRecord {
  id: number
  userId: number
  reservationId: number
  type: string
  createdAt: string
}

export const violationApi = {
  listMy: () => api.get<{ code: number; data: ViolationRecord[] }>('/violations/my'),
  adminList: (params: { page?: number; size?: number; userId?: number; type?: string }) =>
    api.get<{ code: number; data: { records: ViolationRecord[]; total: number } }>('/admin/violations', { params }),
}
