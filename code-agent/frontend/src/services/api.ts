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

// [SECURITY-DISABLED] MVP 阶段：不再附加 JWT Token
// 原请求拦截器已移除，直接放行所有请求

// 响应拦截器：统一错误处理
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const { status, data } = error.response;
      const msg = data?.message || '请求失败';

      switch (status) {
        case 401:
          // [SECURITY-DISABLED] 清除本地用户信息
          localStorage.removeItem('userInfo');
          if (window.location.pathname !== '/login') {
            message.error('登录已过期，请重新登录');
            window.location.href = '/login';
          }
          break;
        // [SECURITY-DISABLED] 原 403 拦截改为普通错误提示
        // case 403:
        //   message.error('无权限访问');
        //   break;
        case 400:
          message.error(msg);
          break;
        case 500:
          message.error('服务器内部错误');
          break;
        default:
          message.error(`请求失败 (${status})`);
      }
    } else if (error.request) {
      message.error('网络错误，请检查服务是否正常运行');
    } else {
      message.error('请求配置错误');
    }
    return Promise.reject(error);
  }
);

export default api;
