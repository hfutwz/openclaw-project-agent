import api from './api';

export interface UserInfo {
  id: number;
  username: string;
  realName: string;
  email: string;
  departmentId: number | null;
  userType: string;
  roles: string[];
  permissions: string[];
}

export const authService = {
  /** GET /api/auth/me — 获取当前用户信息 */
  getCurrentUser: async (): Promise<{ code: number; data: UserInfo }> => {
    return api.get('/auth/me') as Promise<{ code: number; data: UserInfo }>;
  },

  /** 判断是否已登录 */
  isLoggedIn: (): boolean => !!localStorage.getItem('token'),

  /** 从 localStorage 读取缓存的用户信息 */
  getSavedUser: (): UserInfo | null => {
    const s = localStorage.getItem('userInfo');
    if (!s) return null;
    try { return JSON.parse(s) as UserInfo; }
    catch { return null; }
  },
};
