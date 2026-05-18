import axios from 'axios';
import { message } from 'antd';

// 创建 Axios 实例
const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器：自动附加 JWT Token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截器：统一错误处理
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const { status, data } = error.response;
      const msg = data?.message || '请求失败';

      switch (status) {
        case 401:
          localStorage.removeItem('token');
          localStorage.removeItem('userInfo');
          if (window.location.pathname !== '/login') {
            message.error('登录已过期，请重新登录');
            window.location.href = '/login';
          }
          break;
        case 403:
          message.error('无权限访问');
          break;
        case 400:
          message.error(msg);
          break;
        case 500:
          message.error('服务器内部错误');
          break;
        default:
          message.error(msg);
      }
    } else if (error.request) {
      message.error('网络错误，请检查连接');
    } else {
      message.error('请求配置错误');
    }
    return Promise.reject(error);
  }
);

export default api;
