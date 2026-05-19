import axios from 'axios';
import { Modal } from 'antd';

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

// 响应拦截器：统一错误处理，使用弹窗提示
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const { status, data } = error.response;
      const msg = data?.message || '请求失败';

      switch (status) {
        case 401:
          localStorage.removeItem('userInfo');
          // 使用 pathname 保留端口号，不强制跳转（避免无限重定向）
          if (window.location.pathname !== '/login') {
            Modal.error({
              title: '登录已过期',
              content: '请重新登录',
            });
          }
          break;
        case 403:
          Modal.error({
            title: '访问被拒绝',
            content: '您没有权限执行此操作，请联系管理员',
          });
          break;
        case 404:
          Modal.error({
            title: '资源不存在',
            content: msg || '请求的资源不存在',
          });
          break;
        case 500:
          Modal.error({
            title: '服务器错误',
            content: '服务器内部错误，请稍后重试',
          });
          break;
        case 502:
        case 503:
        case 504:
          Modal.error({
            title: '服务不可用',
            content: '后端服务未启动或不可用，请检查服务状态',
          });
          break;
        default:
          Modal.error({
            title: '请求失败',
            content: `${msg} (错误码: ${status})`,
          });
      }
    } else if (error.request) {
      // 请求已发出但没有收到响应
      Modal.error({
        title: '网络错误',
        content: '无法连接到服务器，请检查：\n1. 后端服务是否正常运行\n2. 网络连接是否正常',
      });
    } else {
      Modal.error({
        title: '请求配置错误',
        content: error.message,
      });
    }
    return Promise.reject(error);
  }
);

export default api;
