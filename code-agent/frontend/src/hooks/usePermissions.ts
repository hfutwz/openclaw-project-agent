import { useCallback } from 'react';
import type { UserInfo } from './useAuth';

function getUser(): UserInfo | null {
  const saved = localStorage.getItem('userInfo');
  return saved ? JSON.parse(saved) : null;
}

/**
 * RBAC 权限检查 Hook
 * 从 localStorage 读取 userInfo，检查 permissions / roles
 */
export function usePermissions() {

  const hasPermission = useCallback((permission: string): boolean => {
    const user = getUser();
    if (!user || !user.permissions) return false;
    return user.permissions.includes(permission);
  }, []);

  const hasAnyPermission = useCallback((permissions: string[]): boolean => {
    const user = getUser();
    if (!user || !user.permissions) return false;
    return permissions.some(p => user.permissions.includes(p));
  }, []);

  const hasRole = useCallback((role: string): boolean => {
    const user = getUser();
    if (!user || !user.roles) return false;
    return user.roles.includes(role);
  }, []);

  const isAdmin = useCallback((): boolean => {
    const user = getUser();
    return user?.userType === 'ADMIN';
  }, []);

  const isStudent = useCallback((): boolean => {
    const user = getUser();
    return user?.userType === 'STUDENT';
  }, []);

  return {
    hasPermission,
    hasAnyPermission,
    hasRole,
    isAdmin,
    isStudent,
  };
}
