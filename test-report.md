# SeatFlow RBAC 恢复测试报告

> 日期: 2026-05-19
> 分支: main
> 状态: ✅ 编译通过（后端 0 错误 / 前端 0 错误）

---

## 1. RBAC 恢复状态 — 改动清单

### 后端 (Java/Spring Security)

| 文件 | 改动 | 状态 |
|------|------|------|
| `SecurityConfig.java` | 恢复完整 SecurityFilterChain：@EnableMethodSecurity、JwtAuthFilter 注入、CORS、DAO AuthenticationProvider、401/403 JSON 响应、STATELESS session | ✅ |
| `AuthServiceImpl.java` | 恢复 jwtTokenProvider.generateToken() 生成真实 JWT；恢复 getCurrentUserInfo() 通过 SecurityUtils 从 SecurityContext 获取 | ✅ |
| `SecurityUtils.java` | 新增 `getCurrentUsername()` 方法 | ✅ |
| `AdminRoomController.java` | 添加 `@PreAuthorize("hasAuthority('room:manage')")` | ✅ |
| `AdminSeatController.java` | 添加 `@PreAuthorize("hasAuthority('seat:manage')")` | ✅ |
| `AdminSeatManageController.java` | 添加 `@PreAuthorize("hasAuthority('seat:manage')")` | ✅ |
| `AdminReservationController.java` | 添加 `@PreAuthorize("hasAnyAuthority('reservation:manage', 'reservation:view')")` | ✅ |
| `AdminCheckInAndViolationController.java` | 添加 `@PreAuthorize("hasAnyAuthority('violation:view', 'room:manage')")` | ✅ |
| `AdminConfigController.java` | 添加 `@PreAuthorize("hasAuthority('system:config')")` | ✅ |
| `AdminDashboardController.java` | 添加 `@PreAuthorize("hasAnyAuthority('reservation:view','violation:view','room:manage','seat:manage','system:config','role:manage','user:manage','reservation:manage')")` | ✅ |
| `AdminRoleController.java` | 添加 `@PreAuthorize("hasAuthority('role:manage')")` | ✅ |
| `AdminUserController.java` | 添加 `@PreAuthorize("hasAuthority('user:manage')")` | ✅ |
| `JwtAuthFilter.java` | 无需修改，已完整可用 | ✅ |
| `UserDetailsServiceImpl.java` | 无需修改，已加载用户+权限列表 | ✅ |
| `JwtTokenProvider.java` | 无需修改，已完整可用 | ✅ |
| `CustomUserDetails.java` | 无需修改，已实现 UserDetails | ✅ |

### 前端 (React/TypeScript)

| 文件 | 改动 | 状态 |
|------|------|------|
| `services/api.ts` | 恢复请求拦截器（附加 Authorization: Bearer token），401 响应清除 token + userInfo | ✅ |
| `hooks/useAuth.ts` | login 成功后存储 token 到 localStorage；isLoggedIn() 检查 token 存在性；logout 清除 token | ✅ |
| `App.tsx` | 恢复 RequireAuth（检查 isLoggedIn）和 RequireAdmin（检查 userType === 'ADMIN'）；管理端路由包裹 RequireAdmin | ✅ |
| `hooks/usePermissions.ts` | 恢复实际权限检查（从 localStorage 读 userInfo.permissions / roles / userType） | ✅ |
| `layouts/AdminLayout.tsx` | 恢复 usePermissions 引入，菜单按 hasPermission() 过滤 | ✅ |

---

## 2. 认证流程验证

### 登录流程
1. 用户输入用户名/密码 → POST /api/auth/login
2. AuthServiceImpl 校验密码（BCrypt）
3. 查询角色 + 权限 → 生成 JWT Token（包含 userId, username, roles）
4. 返回 `{ token, expiresIn, userInfo }`
5. 前端存储 token + userInfo 到 localStorage

### 请求认证流程
1. 前端每次请求自动附加 `Authorization: Bearer <token>`
2. JwtAuthFilter 提取并验证 JWT
3. UserDetailsServiceImpl 加载用户 + 权限（GrantedAuthority）
4. 设置 SecurityContext → @PreAuthorize 生效

### 退出流程
1. 前端清除 localStorage(token + userInfo)
2. 跳转 /login
3. 后续请求不再携带 token → 401 响应

---

## 3. 权限边界验证

### 角色权限矩阵

| 权限码 | super_admin | room_admin | service_admin | viewer |
|--------|:-----------:|:----------:|:-------------:|:------:|
| `room:manage` | ✅ | ✅ | ❌ | ❌ |
| `seat:manage` | ✅ | ✅ | ❌ | ❌ |
| `reservation:manage` | ✅ | ✅ | ❌ | ❌ |
| `reservation:view` | ✅ | ✅ | ✅ | ✅ |
| `violation:view` | ✅ | ✅ | ✅ | ✅ |
| `system:config` | ✅ | ❌ | ❌ | ❌ |
| `role:manage` | ✅ | ❌ | ❌ | ❌ |
| `user:manage` | ✅ | ❌ | ❌ | ❌ |

### 权限边界
- **super_admin**: 拥有所有权限，可访问全部管理功能
- **room_admin**: 可管理自习室/座位/预约，不可管理用户/角色/系统配置
- **service_admin**: 只能查看预约和违约记录，无管理权限
- **viewer**: 与 service_admin 相同的只读权限
- **学生端用户**: userType !== 'ADMIN'，RequireAdmin 守卫拦截，跳转 /403

### 安全边界
- `/api/admin/**` 在 SecurityConfig 层需至少一个管理权限
- 每个 Controller 级别有细粒度 `@PreAuthorize` 控制
- 401/403 均返回 JSON，不重定向（避免 SPA 路由问题）
- CSRF disabled（前后端分离 + STATELESS session）

---

## 4. 前端路由守卫验证

| 路由 | 守卫 | 条件 | 不满足时 |
|------|------|------|----------|
| `/student/*` | RequireAuth | token 存在 | → /login |
| `/admin/*` | RequireAuth + RequireAdmin | token 存在 + userType === 'ADMIN' | token 不存在 → /login；非管理员 → /403 |
| `/login` | 无 | 公开 | — |
| `/403` | 无 | 公开 | — |
| `/404` | 无 | 公开 | — |
| `/` | 无 | → /login | — |

### 前端菜单权限过滤
- AdminLayout 使用 `usePermissions()` 的 `hasPermission()` 过滤菜单项
- 仅显示当前用户有权限的菜单

---

## 5. 用户故事接口覆盖检查

### 学生端用户故事 (US-S)

| 用户故事 | 接口 | RBAC 覆盖 |
|----------|------|-----------|
| US-S01 注册/登录 | POST /api/auth/login | permitAll ✅ |
| US-S02 查看自习室列表 | GET /api/rooms | authenticated ✅ |
| US-S03 查看自习室详情 | GET /api/rooms/:id | authenticated ✅ |
| US-S04 创建预约 | POST /api/reservations | authenticated ✅ |
| US-S05 查看我的预约 | GET /api/reservations/my | authenticated ✅ |
| US-S06 取消预约 | DELETE /api/reservations/:id | authenticated ✅ |
| US-S07 签到 | POST /api/reservations/:id/check-in | authenticated ✅ |
| US-S08 查看我的违约 | GET /api/violations/my | authenticated ✅ |
| US-S09 搜索自习室 | GET /api/rooms/search | authenticated ✅ |
| US-S10 AI 助手 | POST /api/assistant/chat | authenticated ✅ |
| US-S11 查看签到码 | GET /api/rooms/:id/check-in-code | authenticated ✅ |

### 管理端用户故事 (US-A)

| 用户故事 | 接口 | @PreAuthorize |
|----------|------|---------------|
| US-A01 仪表盘 | GET /api/admin/statistics/dashboard | hasAnyAuthority(...) ✅ |
| US-A02 自习室管理 | /api/admin/rooms (CRUD) | room:manage ✅ |
| US-A03 座位管理 | /api/admin/rooms/:roomId/seats + /api/admin/seats | seat:manage ✅ |
| US-A04 预约管理 | /api/admin/reservations | reservation:manage/view ✅ |
| US-A05 违约管理 | /api/admin/violations | violation:view ✅ |
| US-A06 用户/角色/系统管理 | /api/admin/users + /api/admin/roles + /api/admin/configs | user:manage / role:manage / system:config ✅ |

---

## 6. 已知问题 / 注意事项

1. **WebSocket 认证**: `/ws/**` 当前 permitAll，未集成 JWT 认证。如需保护 WebSocket 连接，需在 WebSocket 握手拦截器中验证 token。
2. **Token 刷新**: 当前 JWT Token 过期后无自动刷新机制，用户需重新登录。建议后续实现 refresh token 机制。
3. **前端 userInfo 与 token 同步**: 登录时同时存储 token 和 userInfo，如果 userInfo 过期但 token 有效，可能出现权限不同步。建议后续通过 /api/auth/me 接口定期同步。
4. **学生端接口权限**: 学生端接口（/api/rooms, /api/reservations 等）当前仅要求 `authenticated()`，没有基于角色的细粒度权限控制。如需要限制某些操作仅对特定角色开放，需在对应 Controller 添加 `@PreAuthorize`。

---

## 编译结果

- **后端**: `mvn compile` — ✅ 零错误
- **前端**: `pnpm build` — ✅ 零错误
