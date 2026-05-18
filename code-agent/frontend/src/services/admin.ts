import api from './api'

export interface UserItem {
  id: number
  username: string
  realName: string
  email: string
  departmentId: number | null
  departmentName: string
  userType: string
  roles: string[]
  roleIds: number[]
  permissions: string[]
  createdAt: string
}

export interface RoleItem {
  id: number
  name: string
  code: string
  description: string
  permissionIds: number[]
  permissions: { id: number; name: string; code: string }[]
}

export interface PermissionItem {
  id: number
  name: string
  code: string
}

export interface DashboardData {
  totalRooms: number
  totalSeats: number
  availableSeats: number
  todayReservations: number
  pendingReservations: number
  todayCheckIns: number
  todayViolations: number
  totalUsers: number
}

export interface SystemConfigItem {
  id: number
  configKey: string
  configValue: string
  description: string
}

export const userApi = {
  list: (params: { page?: number; size?: number; userType?: string; keyword?: string }) =>
    api.get<{ code: number; data: { records: UserItem[]; total: number } }>('/admin/users', { params }),
  get: (id: number) => api.get<{ code: number; data: UserItem }>(`/admin/users/${id}`),
  create: (data: any) => api.post('/admin/users', data),
  update: (id: number, data: any) => api.put(`/admin/users/${id}`, data),
  delete: (id: number) => api.delete(`/admin/users/${id}`),
}

export const roleApi = {
  list: () => api.get<{ code: number; data: RoleItem[] }>('/admin/roles'),
  get: (id: number) => api.get<{ code: number; data: RoleItem }>(`/admin/roles/${id}`),
  create: (data: any) => api.post('/admin/roles', data),
  update: (id: number, data: any) => api.put(`/admin/roles/${id}`, data),
  delete: (id: number) => api.delete(`/admin/roles/${id}`),
  permissions: () => api.get<{ code: number; data: PermissionItem[] }>('/admin/roles/permissions'),
}

export const dashboardApi = {
  getStats: () => api.get<{ code: number; data: DashboardData }>('/admin/dashboard'),
}

export const configApi = {
  list: () => api.get<{ code: number; data: SystemConfigItem[] }>('/admin/config'),
  batchUpdate: (data: Record<string, string>) => api.put('/admin/config', data),
  update: (key: string, value: string) => api.put(`/admin/config/${key}`, { value }),
}
