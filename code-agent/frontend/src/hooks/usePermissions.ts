import { useCallback } from 'react';
import type { UserInfo } from './useAuth';

function getUser(): UserInfo | null {
  const saved = localStorage.getItem('userInfo');
  return saved ? JSON.parse(saved) : null;
}

/**
 * [SECURITY-DISABLED] MVP 阶段：所有权限检查返回 true
 * 恢复 RBAC 时取消注释原逻辑
 */
export function usePermissions() {

  const hasPermission = useCallback((_permission: string): boolean => {
    // [SECURITY-DISABLED] 原逻辑：检查 user.permissions
    return true;
  }, []);

  const hasAnyPermission = useCallback((_permissions: string[]): boolean => {
    // [SECURITY-DISABLED] 原逻辑：检查任意权限
    return true;
  }, []);

  const hasRole = useCallback((_role: string): boolean => {
    // [SECURITY-DISABLED] 原逻辑：检查 user.roles
    return true;
  }, []);

  const isAdmin = useCallback((): boolean => {
    // [SECURITY-DISABLED] 原逻辑：检查 userType === 'ADMIN'
    return true;
  }, []);

  const isStudent = useCallback((): boolean => {
    // [SECURITY-DISABLED] 原逻辑：检查 userType === 'STUDENT'
    return true;
  }, []);

  return {
    hasPermission,
    hasAnyPermission,
    hasRole,
    isAdmin,
    isStudent,
  };
}
