import { useState } from 'react';
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
  const navigate = useNavigate();

  // 登录
  const login = async (username: string, password: string) => {
    try {
      const res = await api.post('/auth/login', { username, password }) as any;
      if (res.data.code === 200) {
        const data = res.data.data;
        const info = data.userInfo || data;
        if (info) {
          setUserInfo(info);
          localStorage.setItem('userInfo', JSON.stringify(info));
        }
        // 存储 JWT Token
        if (data.token) {
          localStorage.setItem('token', data.token);
        }
        return { success: true };
      }
      return { success: false, message: res.data.message };
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

  // MVP 阶段无需初始化

  return {
    user: userInfo,
    userInfo,
    login,
    logout,
    isLoggedIn,
    isAdmin,
    isStudent,
  };
};
