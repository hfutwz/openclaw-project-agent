import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';

export interface UserInfo {
  id: number;
  username: string;
  realName: string;
  email: string;
  departmentId: number | null;
  userType: 'STUDENT' | 'ADMIN';
  roles: string[];
  permissions: string[];
}

export const useAuth = () => {
  const [userInfo, setUserInfo] = useState<UserInfo | null>(() => {
    const saved = localStorage.getItem('userInfo');
    return saved ? JSON.parse(saved) : null;
  });
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  // 获取当前用户信息（从后端同步）
  // 注意：api.ts 拦截器已返回 response.data，所以 res 本身就是 { code, message, data }
  const fetchUserInfo = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const res = await api.get('/auth/me') as any;
      if (res.code === 200) {
        const info = res.data as UserInfo;
        setUserInfo(info);
        localStorage.setItem('userInfo', JSON.stringify(info));
      }
    } catch {
      localStorage.removeItem('token');
      localStorage.removeItem('userInfo');
      setUserInfo(null);
    } finally {
      setLoading(false);
    }
  };

  // 登录
  const login = async (username: string, password: string) => {
    try {
      const res = await api.post('/auth/login', { username, password }) as any;
      if (res.code === 200) {
        const { token } = res.data as { token: string; expiresIn: number };
        localStorage.setItem('token', token);
        await fetchUserInfo();
        return { success: true };
      }
      return { success: false, message: res.message };
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || '登录失败',
      };
    }
  };

  // 登出
  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('userInfo');
    setUserInfo(null);
    navigate('/login');
  };

  const isLoggedIn = (): boolean => !!localStorage.getItem('token');
  const isAdmin = (): boolean => userInfo?.userType === 'ADMIN';
  const isStudent = (): boolean => userInfo?.userType === 'STUDENT';

  // 初始化时同步用户信息
  useEffect(() => {
    if (localStorage.getItem('token') && !userInfo) {
      fetchUserInfo();
    }
  }, []);

  return {
    user: userInfo,
    userInfo,
    loading,
    login,
    logout,
    isLoggedIn,
    isAdmin,
    isStudent,
    fetchUserInfo,
  };
};
