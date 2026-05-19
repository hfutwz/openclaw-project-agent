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

  // 登录
  const login = async (username: string, password: string) => {
    try {
      const res = await api.post('/auth/login', { username, password }) as any;
      if (res.data.code === 200) {
        // [SECURITY-DISABLED] 登录接口直接返回 userInfo
        const info = res.data.data.userInfo || res.data.data;
        if (info) {
          setUserInfo(info);
          localStorage.setItem('userInfo', JSON.stringify(info));
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
    localStorage.removeItem('userInfo');
    setUserInfo(null);
    navigate('/login');
  };

  const isLoggedIn = (): boolean => !!userInfo;
  const isAdmin = (): boolean => userInfo?.userType === 'ADMIN';
  const isStudent = (): boolean => userInfo?.userType === 'STUDENT';

  useEffect(() => {
    // MVP 阶段无需初始化 token
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
  };
};
