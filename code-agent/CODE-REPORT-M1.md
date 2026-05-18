# FIX-REPORT-M1.md — M1 修复报告

**修复日期：** 2026-05-16
**修复范围：** M1 基础框架 Review 审计修复
**分支：** `feature/M1`

---

## 修复概览

| 优先级 | 问题 | 状态 | 文件 |
|---|---|---|---|
| P0-1 | AuthServiceImpl 缺失 | ✅ 已修复 | `AuthServiceImpl.java` (新建) |
| P1-1 | useAuth.ts API 响应 `.data` 嵌套 Bug | ✅ 已修复 | `useAuth.ts` |
| P1-2 | CORS 未在 SecurityFilterChain 中显式启用 | ✅ 已修复 | `SecurityConfig.java` |
| P1-3 | UserDetailsServiceImpl 未过滤 deleted=0 | ✅ 已修复 | `UserDetailsServiceImpl.java` |
| P1-4 | JwtAuthFilter catch 未清理 SecurityContext | ✅ 已修复 | `JwtAuthFilter.java` |
| P1-5 | PermissionMapper SQL 未过滤 role 逻辑删除 | ✅ 已修复 | `PermissionMapper.java` |
| P1-6 | 管理端接口缺少权限注解保护 | ✅ 已修复 | `SecurityConfig.java` |
| P2-1 | RouteGuard 使用 window.location.href | ✅ 已修复 | `App.tsx` |
| P2-2 | AdminLayout Menu items 含非标准 show 属性 | ✅ 已修复 | `AdminLayout.tsx` |
| P2-3 | mapper-locations 指向空目录 | ✅ 已修复 | `application.yml` |
| P2-4 | SchedulingConfig 使用 Executors | ✅ 已修复 | `SchedulingConfig.java` |
| P2-5 | LoginRequest 缺少长度限制 | ✅ 已修复 | `LoginRequest.java` |
| P2-6 | SeatFlowApplication 缺少 @MapperScan | ✅ 已修复 | `SeatFlowApplication.java` |

---

## 修复详情

### P0-1: AuthServiceImpl 缺失（新建）

**文件：** `backend/src/main/java/com/seatflow/service/impl/AuthServiceImpl.java`

创建了 `AuthServiceImpl`，实现 `AuthService` 接口：
- `login()`：使用 `BCryptPasswordEncoder` 校验密码，调用 `JwtTokenProvider.generateToken()` 生成 token
- `getCurrentUserInfo()`：从 `SecurityUtils.getCurrentUserId()` 获取当前用户 ID，查询角色和权限列表
- 登录查询时已添加 `.eq(User::getDeleted, 0)` 过滤

同时修复了 `JwtTokenProvider` 签名，将 `generateToken()` 参数从 `String userType` 改为 `List<String> roles`，与 AuthServiceImpl 匹配。

### P1-1: useAuth.ts API 响应处理 Bug

**文件：** `frontend/src/hooks/useAuth.ts`

**根因：** `api.ts` 响应拦截器已返回 `response.data`（即 `{ code, message, data }`），但 `useAuth.ts` 仍访问 `res.data.code`，导致永远为 `undefined`。

**修复：** 改为直接访问 `res.code` 和 `res.data`：
```typescript
// 修复前
if (res.data.code === 200) { ... res.data.data ... }

// 修复后
if (res.code === 200) { const info = res.data as UserInfo; ... }
```

### P1-2: CORS 未在 Spring Security 中显式启用

**文件：** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`

**修复：**
1. 注入 `CorsConfigurationSource` bean
2. 在 `SecurityFilterChain` 中添加 `.cors(cors -> cors.configurationSource(corsConfigurationSource))`

### P1-3: UserDetailsServiceImpl 未过滤逻辑删除用户

**文件：** `backend/src/main/java/com/seatflow/security/UserDetailsServiceImpl.java`

**修复：** `loadUserByUsername` 中添加 `.eq(User::getDeleted, 0)` 条件：
```java
User user = userMapper.selectOne(
    new LambdaQueryWrapper<User>()
        .eq(User::getUsername, username)
        .eq(User::getDeleted, 0)  // 新增
);
```

### P1-4: JwtAuthFilter catch 未清理 SecurityContext

**文件：** `backend/src/main/java/com/seatflow/security/JwtAuthFilter.java`

**修复：** catch 块添加 `SecurityContextHolder.clearContext()`：
```java
} catch (Exception e) {
    log.error("JWT authentication failed: {}", e.getMessage());
    SecurityContextHolder.clearContext();  // 新增
}
```

### P1-5: PermissionMapper SQL 未过滤 role 逻辑删除

**文件：** `backend/src/main/java/com/seatflow/mapper/PermissionMapper.java`

**修复：** SQL 中添加 `r.deleted = 0` 条件：
```sql
SELECT DISTINCT p.* FROM t_permission p
INNER JOIN t_role_permission rp ON p.id = rp.permission_id
INNER JOIN t_user_role ur ON rp.role_id = ur.role_id
INNER JOIN t_role r ON rp.role_id = r.id
WHERE ur.user_id = #{userId} AND r.deleted = 0  -- 新增
```

### P1-6: 后端管理接口缺少权限注解保护

**文件：** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`

**修复：** 在 `authorizeHttpRequests` 中为 `/api/admin/**` 添加权限要求：
```java
.requestMatchers("/api/admin/**").hasAnyAuthority(
    "room:manage", "seat:manage", "reservation:manage",
    "system:config", "role:manage", "user:manage",
    "reservation:view", "violation:view"
)
```

### P2-1: RouteGuard 使用 window.location.href

**文件：** `frontend/src/App.tsx`

**修复：** 使用 React Router 的 `useNavigate` 进行客户端导航，避免整页刷新。

### P2-2: AdminLayout Menu items 过滤

**文件：** `frontend/src/layouts/AdminLayout.tsx`

**修复：** 使用展开运算符 `...(hasPermission('xxx') ? [{...}] : [])` 替代 `show` 属性 + `.filter(Boolean)` 方式，避免 TypeScript 类型问题。

### P2-3: mapper-locations 警告

**文件：** `backend/src/main/resources/application.yml`

**修复：** 删除 `mapper-locations: classpath:mapper/*.xml` 配置行（全注解 Mapper，不需要 XML）。

### P2-4: SchedulingConfig 使用 ThreadPoolTaskScheduler

**文件：** `backend/src/main/java/com/seatflow/config/SchedulingConfig.java`

**修复：** 从 `Executors.newScheduledThreadPool(4)` 改为 Spring 管理的 `ThreadPoolTaskScheduler`，并添加 `destroyMethod = "shutdown"` 和 `setWaitForTasksToCompleteOnShutdown(true)`。

### P2-5: LoginRequest 添加长度限制

**文件：** `backend/src/main/java/com/seatflow/dto/request/LoginRequest.java`

**修复：** 添加 `@Size(min = 3, max = 50)` 和 `@Size(min = 6, max = 100)`。

### P2-6: SeatFlowApplication 添加 @MapperScan

**文件：** `backend/src/main/java/com/seatflow/SeatFlowApplication.java`

**修复：** 添加 `@MapperScan("com.seatflow.mapper")`。

---

## 验证结果

| 验证项 | 结果 |
|---|---|
| 后端 `mvn compile` | ✅ BUILD SUCCESS (49 源文件) |
| 后端 `mvn spring-boot:run` | ✅ Started SeatFlowApplication in 1.105s |
| MySQL 数据库连接 | ✅ HikariPool-1 - Start completed |
| Spring Security JWT Filter | ✅ Filter 'jwtAuthFilter' configured |
| 前端 `npm run build` | ✅ built in 1.61s |

---

## Git 提交记录

```
64c9e0b fix(M1): 修复 Review 审计问题 — AuthServiceImpl + CORS + 安全加固
1118d06 fix(M1): 前端修复 — useAuth响应处理 + RouteGuard导航 + AdminLayout菜单类型
ed49d7f feat(M1-F01): Axios实例+拦截器、登录页、路由守卫、布局组件、权限hooks
ba95953 feat(M1-B05): MyBatis Plus 分页插件配置
832730f feat: 初始化Spring Boot 3后端项目，基础结构和依赖配置完成
401ed46 Initial commit
```

---

## 遗留说明

1. **AuthenticationProvider WARN 警告：** Spring Security 提示 "Global AuthenticationManager configured with an AuthenticationProvider bean"，这是因为同时定义了 `AuthenticationProvider` bean 和 `UserDetailsService` bean。警告不影响功能，属于 Spring Security 6 的配置建议提示。如需消除，可将 `AuthenticationProvider` 改为手动实例化 `DaoAuthenticationProvider` 后注入 `UserDetailsService`。当前实现功能正确，暂不处理。

2. **前端 Chunk Size 警告：** Ant Design 打包后 JS 文件 821KB 超过 500KB 建议值。属于优化项，不影响功能，M2+ 阶段可引入代码分割。
