export interface RbacUser {
  userType?: string
  permissions?: string[]
  roles?: string[]
}

export const ADMIN_PERMISSIONS = [
  'reservation:view',
  'violation:view',
  'reservation:manage',
  'seat:manage',
  'room:manage',
  'system:config',
  'role:manage',
  'user:manage',
]

export const ADMIN_ROUTE_RULES = [
  { prefix: '/admin/dashboard', permissions: ADMIN_PERMISSIONS },
  { prefix: '/admin/rooms', permissions: ['room:manage'] },
  { prefix: '/admin/seats', permissions: ['seat:manage'] },
  { prefix: '/admin/reservations', permissions: ['reservation:view', 'reservation:manage'] },
  { prefix: '/admin/violations', permissions: ['violation:view'] },
  { prefix: '/admin/users', permissions: ['user:manage'] },
  { prefix: '/admin/roles', permissions: ['role:manage'] },
  { prefix: '/admin/config', permissions: ['system:config'] },
  { prefix: '/admin/check-in-codes', permissions: ['room:manage'] },
]

export function hasAnyPermission(user: RbacUser | null | undefined, permissions: string[]): boolean {
  if (!user?.permissions?.length) return false
  return permissions.some(permission => user.permissions?.includes(permission))
}

export function isAdminUser(user: RbacUser | null | undefined): boolean {
  return user?.userType === 'ADMIN' && hasAnyPermission(user, ADMIN_PERMISSIONS)
}

export function canAccessAdminPath(user: RbacUser | null | undefined, pathname: string): boolean {
  if (!isAdminUser(user)) return false
  const rule = ADMIN_ROUTE_RULES
    .filter(item => pathname === item.prefix || pathname.startsWith(`${item.prefix}/`))
    .sort((a, b) => b.prefix.length - a.prefix.length)[0]
  return rule ? hasAnyPermission(user, rule.permissions) : true
}

export function getDefaultAdminPath(user: RbacUser | null | undefined): string {
  if (!isAdminUser(user)) return '/403'
  const firstAllowed = ADMIN_ROUTE_RULES.find(rule => hasAnyPermission(user, rule.permissions))
  return firstAllowed?.prefix || '/403'
}
