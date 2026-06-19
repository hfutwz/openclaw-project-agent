import api from './api'

export interface SeatSearchResult {
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

export interface SearchParams {
  date: string
  startTime: string
  endTime: string
  roomId?: number
  socketType?: string
  position?: string
  departmentId?: number
}

export const searchApi = {
  search: (params: SearchParams) =>
    api.get<{ code: number; data: SeatSearchResult[] }>('/seats/search', { params }),
}
