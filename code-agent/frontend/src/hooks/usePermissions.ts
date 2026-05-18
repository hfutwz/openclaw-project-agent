import { useCallback } from 'react';
import type { UserInfo } from './useAuth';

function getUser(): UserInfo | null {
  const saved = localStorage.getItem('userInfo');
  return saved ? JSON.parse(saved) : null;
}

/**
 * 权限检查 hook
 */
export function usePermissions() {

  const hasPermission = useCallback((permission: string): boolean => {
    const user = getUser();
    return user?.permissions.includes(permission) ?? false;
  }, []);

  const hasAnyPermission = useCallback((permissions: string[]): boolean => {
    const user = getUser();
    if (!user) return false;
    return permissions.some((p) => user.permissions.includes(p));
  }, []);

  const hasRole = useCallback((role: string): boolean => {
    const user = getUser();
    return user?.roles.includes(role) ?? false;
  }, []);

  const isAdmin = useCallback((): boolean => {
    return getUser()?.userType === 'ADMIN';
  }, []);

  const isStudent = useCallback((): boolean => {
    return getUser()?.userType === 'STUDENT';
  }, []);

  return {
    hasPermission,
    hasAnyPermission,
    hasRole,
    isAdmin,
    isStudent,
  };
}
