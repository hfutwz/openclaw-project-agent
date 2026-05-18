# Review: M1 基础框架

**审查日期:** 2026-05-16  
**审查依据:** PRD v0.3 + Plan v1.2  
**审查范围:** 后端 `src/main/java/com/seatflow/` + 前端 `src/` + 资源文件  
**审查人:** Review Agent

---

## 评级: ⚠️ 需修改

**判定理由:** 存在 **1 个 P0**（`AuthServiceImpl` 缺失导致启动失败），不满足 "无 P0" 的通过条件。

---

## 审查维度

### 1. 代码质量 (30%)

| 项 | 评分 | 说明 |
|---|---|---|
| 命名规范 | ✅ 良好 | Entity/Mapper/Controller/Service 命名符合 Plan 约定 |
| 分层清晰 | ✅ 良好 | Controller → Service(interface) → Mapper 分层正确 |
| DRY | ✅ 良好 | `SecurityUtils` 工具类封装了常用安全操作 |
| 前端结构 | ✅ 良好 | pages/layouts/services/hooks 目录划分清晰 |
| 代码可读性 | ⚠️ 一般 | 前端 `useAuth.ts` 存在嵌套 `.data` 访问（见 P1-2） |

**亮点:**
- `CustomUserDetails` 扩展了 Spring Security `UserDetails`，携带业务字段（id, departmentId, roles）
- `AdminLayout.tsx` 通过 `usePermissions` 动态渲染菜单，与 PRD 权限矩阵对齐
- `Login.tsx` UI 美观，使用了渐变背景和卡片布局

### 2. 安全性 (25%)

| 项 | 评分 | 说明 |
|---|---|---|
| 认证机制 | ✅ 良好 | JWT + Bearer Token + Spring Security 过滤器链完整 |
| 密码加密 | ✅ 良好 | BCryptPasswordEncoder 已配置 |
| 输入校验 | ✅ 良好 | `LoginRequest` 有 `@NotBlank` 校验 |
| JWT 伪造防护 | ⚠️ 一般 | `JwtAuthFilter` catch Exception 后未清理 SecurityContext（见 P1-5） |
| SQL 注入 | ✅ 良好 | 全部使用 MyBatis Plus LambdaQueryWrapper / `@Select` 参数化 |
| 越权防护 | ⚠️ 一般 | `SecurityConfig` 未区分 ADMIN/STUDENT 接口权限（仅做了认证，未做角色鉴权） |

**注意:**
- `SecurityConfig` 的 `authorizeHttpRequests` 仅区分了 "登录接口匿名" vs "其他全部需认证"，没有按角色/权限细粒度控制管理端接口。PRD F011 要求 `"每个角色仅可访问其权限范围内的功能"`，当前仅靠前端路由守卫 + `@PreAuthorize`（未使用）实现，后端接口层面缺少权限注解保护。

### 3. 架构一致性 (20%)

| 项 | 评分 | 说明 |
|---|---|---|
| PRD 接口对齐 | ✅ 良好 | `/api/auth/login` 和 `/api/auth/me` 路径/方法/响应格式符合 PRD 5.1 |
| 数据库设计 | ✅ 良好 | 11 张表 + 字段/索引与 Plan 3.2 一致 |
| 种子数据 | ✅ 良好 | 4 角色 + 8 权限 + admin 用户与 PRD F010/F011 一致 |
| CORS 配置 | ⚠️ 一般 | `CorsConfig` 定义了 source，但 `SecurityConfig` 未显式启用 `.cors()`（见 P1-3） |
| 分层规范 | ⚠️ 一般 | `AuthService` 仅有接口无实现（P0），`SchedulingConfig` 使用 `Executors` 而非 `ThreadPoolTaskScheduler` |

### 4. 边界情况 (15%)

| 项 | 评分 | 说明 |
|---|---|---|
| 异常处理 | ✅ 良好 | `GlobalExceptionHandler` 覆盖了 BusinessException/401/403/400/500 |
| 空指针防护 | ⚠️ 一般 | `UserDetailsServiceImpl` 未过滤 deleted=0（见 P1-4） |
| 过期 Token | ✅ 良好 | `JwtTokenProvider.validateToken` 正确捕获 `ExpiredJwtException` |
| 前端边界 | ⚠️ 一般 | `RouteGuard` 使用 `window.location.href` 整页刷新（见 P2-1） |

### 5. 性能 (10%)

| 项 | 评分 | 说明 |
|---|---|---|
| N+1 查询 | ✅ 良好 | `UserDetailsServiceImpl.loadUserByUsername` 一次查询 user + 一次查询 roles + 一次查询 permissions，无 N+1 |
| 内存风险 | ✅ 良好 | 无全量加载大数据集合的迹象 |
| JWT 解析 | ✅ 良好 | `parseToken` 内部缓存 parser 未做，但每次创建 parser 开销极小，可接受 |

---

## 问题列表

### [P0] 严重

#### P0-1: `AuthServiceImpl` 缺失 — 启动失败
- **描述:** `AuthService.java` 定义了接口，但项目中不存在 `AuthServiceImpl.java`。`AuthController` 通过 `@RequiredArgsConstructor` 注入 `AuthService`，Spring Boot 启动时会抛出 `No qualifying bean of type 'com.seatflow.service.AuthService' available`。
- **文件:** `backend/src/main/java/com/seatflow/service/AuthService.java`
- **影响:** 后端完全无法启动，M1 交付物不可用。
- **修复建议:**
  ```java
  @Service
  @RequiredArgsConstructor
  public class AuthServiceImpl implements AuthService {
      private final UserMapper userMapper;
      private final RoleMapper roleMapper;
      private final PermissionMapper permissionMapper;
      private final JwtTokenProvider jwtTokenProvider;
      private final PasswordEncoder passwordEncoder;

      @Override
      public LoginResponse login(LoginRequest request) {
          User user = userMapper.selectOne(
              new LambdaQueryWrapper<User>()
                  .eq(User::getUsername, request.getUsername())
                  .eq(User::getDeleted, 0));
          if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
              throw new BadCredentialsException("用户名或密码错误");
          }
          String token = jwtTokenProvider.generateToken(
              user.getId(), user.getUsername(), user.getUserType());
          return new LoginResponse(token, jwtTokenProvider.getExpiration());
      }

      @Override
      public UserInfoResponse getCurrentUserInfo() {
          Long userId = SecurityUtils.getCurrentUserId();
          User user = userMapper.selectById(userId);
          List<Role> roles = roleMapper.selectByUserId(userId);
          List<Permission> permissions = permissionMapper.selectByUserId(userId);
          return UserInfoResponse.builder()
              .id(user.getId())
              .username(user.getUsername())
              .realName(user.getRealName())
              .email(user.getEmail())
              .departmentId(user.getDepartmentId())
              .userType(user.getUserType())
              .roles(roles.stream().map(Role::getCode).toList())
              .permissions(permissions.stream().map(Permission::getCode).distinct().toList())
              .build();
      }
  }
  ```

---

### [P1] 重要

#### P1-1: 前端 API 响应嵌套 `.data` Bug
- **描述:** `api.ts` 的响应拦截器已将 `response.data` 直接返回（`(response) => response.data`），但 `useAuth.ts` 中的 `fetchUserInfo()` 和 `login()` 仍访问 `res.data.code` 和 `res.data.data`。这导致 `res.data` 为 `undefined`，条件判断永远失败，前端无法正确处理登录成功和获取用户信息。
- **文件:** `frontend/src/hooks/useAuth.ts`（第 28 行 `res.data.code`，第 30 行 `res.data.data`，第 46 行 `res.data.code`，第 47 行 `res.data.data`）
- **修复建议:**
  ```typescript
  // fetchUserInfo 中
  if (res.code === 200) {
      const info = res.data as UserInfo;
      ...
  }
  // login 中
  if (res.code === 200) {
      const { token } = res.data;
      ...
  }
  ```

#### P1-2: CORS 未在 Spring Security 中显式启用
- **描述:** `CorsConfig` 定义了 `CorsConfigurationSource` bean，但 `SecurityConfig` 没有调用 `.cors()` 方法将其接入 Security 过滤器链。在 Spring Security 6 中，OPTIONS 预检请求可能先被 Security 过滤器拦截并返回 401，而不是由 CORS 处理器正确响应。
- **文件:** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`
- **修复建议:**
  ```java
  .cors(cors -> cors.configurationSource(corsConfigurationSource()))
  ```
  并注入 `CorsConfigurationSource` bean：
  ```java
  private final CorsConfigurationSource corsConfigurationSource;
  ```

#### P1-3: `UserDetailsServiceImpl` 未过滤逻辑删除用户
- **描述:** `loadUserByUsername` 使用 `selectOne` 查询时未加 `deleted = 0` 条件。如果同名用户被逻辑删除后重新注册，可能加载到已删除用户的旧数据（尽管 username 有唯一约束，但逻辑删除后唯一约束仍可能生效取决于数据库实现）。
- **文件:** `backend/src/main/java/com/seatflow/security/UserDetailsServiceImpl.java`
- **修复建议:**
  ```java
  User user = userMapper.selectOne(
      new LambdaQueryWrapper<User>()
          .eq(User::getUsername, username)
          .eq(User::getDeleted, 0));
  ```

#### P1-4: `JwtAuthFilter` catch Exception 后未清理 SecurityContext
- **描述:** `doFilterInternal` 的 catch 块仅记录日志，未调用 `SecurityContextHolder.clearContext()`。如果前一个请求在 SecurityContext 中留下了认证信息（虽然 `OncePerRequestFilter` 每次请求都会新建上下文），在极端并发场景下可能存在残留认证风险。
- **文件:** `backend/src/main/java/com/seatflow/security/JwtAuthFilter.java`
- **修复建议:** 在 catch 块中添加 `SecurityContextHolder.clearContext();`

#### P1-5: `PermissionMapper.selectByUserId` SQL 未过滤 role 逻辑删除
- **描述:** SQL 中 INNER JOIN `t_role` 但没有加 `r.deleted = 0` 条件（`RoleMapper.selectByUserId` 已加）。已逻辑删除的角色关联的权限仍会被查询出来。
- **文件:** `backend/src/main/java/com/seatflow/mapper/PermissionMapper.java`
- **修复建议:**
  ```sql
  SELECT DISTINCT p.* FROM t_permission p
  INNER JOIN t_role_permission rp ON p.id = rp.permission_id
  INNER JOIN t_user_role ur ON rp.role_id = ur.role_id
  INNER JOIN t_role r ON rp.role_id = r.id
  WHERE ur.user_id = #{userId} AND r.deleted = 0
  ```

#### P1-6: 后端缺少细粒度权限注解保护
- **描述:** `SecurityConfig` 仅配置了 "全部需认证"，没有使用 `@PreAuthorize` 或 `hasAuthority` 对管理端接口（`/api/admin/**`）进行权限控制。当前仅靠前端路由守卫限制，存在接口越权风险（已认证学生可直接调用管理 API）。
- **文件:** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`
- **修复建议:**
  ```java
  .requestMatchers("/api/admin/**").hasAuthority("room:manage") // 至少限制管理端
  ```
  或更细粒度地在各 Controller 方法上使用 `@PreAuthorize("hasAuthority('room:manage')")`。

---

### [P2] 建议

#### P2-1: 前端 `RouteGuard` 使用整页刷新跳转
- **描述:** `RouteGuard` 使用 `window.location.href = '/login'` 和 `window.location.href = '/403'` 进行跳转，导致 SPA 整页刷新，用户体验差。
- **文件:** `frontend/src/App.tsx`
- **修复建议:** 使用 React Router 的 `useNavigate` 进行客户端导航：
  ```typescript
  const navigate = useNavigate();
  // ...
  navigate('/login');
  ```

#### P2-2: `AdminLayout` Menu items 含非标准属性
- **描述:** 菜单项数组中使用了 `show` 属性，然后 `.filter(item => item.show !== false)`。这不是 Ant Design Menu `ItemType` 的正式属性，依赖运行时过滤。
- **文件:** `frontend/src/layouts/AdminLayout.tsx`
- **修复建议:** 直接在构造数组时过滤，不在 item 上加 `show`：
  ```typescript
  const menuItems = [
      { key: '/admin', icon: ..., label: ... },
      hasPermission('room:manage') && { key: '/admin/rooms', ... },
      ...
  ].filter(Boolean);
  ```

#### P2-3: `mapper-locations` 指向空目录产生启动警告
- **描述:** `application.yml` 配置了 `mapper-locations: classpath:mapper/*.xml`，但 `resources/mapper/` 目录为空（全注解 Mapper）。启动时会打印 "Property 'mapperLocations' was not specified or no MyBatis mapper was found" 警告。
- **文件:** `backend/src/main/resources/application.yml`
- **修复建议:** 删除该配置行，或添加一个占位 XML 文件。

#### P2-4: `SchedulingConfig` 未使用 Spring 管理的线程池
- **描述:** Plan 第 6 章建议使用 `ThreadPoolTaskScheduler`，当前实现使用 `Executors.newScheduledThreadPool(4)`。功能等价，但后者不由 Spring 管理生命周期。
- **文件:** `backend/src/main/java/com/seatflow/config/SchedulingConfig.java`
- **修复建议:**
  ```java
  @Bean(destroyMethod = "shutdown")
  public ThreadPoolTaskScheduler scheduledTaskExecutor() {
      ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
      scheduler.setPoolSize(4);
      scheduler.setThreadNamePrefix("scheduled-");
      return scheduler;
  }
  ```

#### P2-5: `LoginRequest` 缺少长度限制
- **描述:** 仅有 `@NotBlank`，没有 `@Size` 限制用户名/密码长度，可能导致超长输入。
- **文件:** `backend/src/main/java/com/seatflow/dto/request/LoginRequest.java`
- **修复建议:**
  ```java
  @NotBlank @Size(min = 3, max = 50) private String username;
  @NotBlank @Size(min = 6, max = 100) private String password;
  ```

#### P2-6: `SeatFlowApplication` 缺少 `@MapperScan`
- **描述:** 虽然每个 Mapper 都有 `@Mapper` 注解，但加上 `@MapperScan("com.seatflow.mapper")` 可以统一扫描，减少遗漏风险。
- **文件:** `backend/src/main/java/com/seatflow/SeatFlowApplication.java`
- **修复建议:** 添加 `@MapperScan("com.seatflow.mapper")`。

---

## PRD / Plan 一致性核对

| PRD 要求 | 实现状态 | 备注 |
|---|---|---|
| A-AUTH01: POST /api/auth/login | ✅ 已实现 | `AuthController.login` |
| A-AUTH02: GET /api/auth/me | ✅ 已实现 | `AuthController.getCurrentUser` |
| F010: 4 个默认角色 | ✅ 已实现 | data.sql 已初始化 |
| F011: 8 个权限项 | ✅ 已实现 | data.sql 已初始化 |
| F012: 用户-角色多对多 | ✅ 已实现 | `UserRole` Entity + Mapper |
| CORS: 前端 5173 可访问 | ⚠️ 部分实现 | `CorsConfig` 有配置，但 Security 未显式启用 |
| 路由守卫: 未登录→登录页 | ✅ 已实现 | `RouteGuard` |
| 路由守卫: 学生不可访问管理端 | ✅ 已实现 | `RouteGuard` |
| 路由守卫: 无权限→403 | ⚠️ 前端实现 | 后端接口缺少权限注解保护 |
| Plan M1-B01~09: 后端基础 | ⚠️ 大部分完成 | 缺少 `AuthServiceImpl` (M1-B08) |
| Plan M1-F01~06: 前端基础 | ✅ 已实现 | Axios、Login、路由守卫、布局、hooks |

---

## 总结

M1 阶段代码整体结构清晰，分层规范，前后端基础框架搭建良好。**但存在一个阻塞性 P0 问题（`AuthServiceImpl` 缺失）导致后端无法启动**，必须优先修复。此外前端 `useAuth.ts` 中的 API 响应处理存在逻辑错误，会导致登录和信息获取功能失效。

**建议修复优先级:**
1. 🔴 **立即:** 创建 `AuthServiceImpl.java`（P0-1）
2. 🔴 **立即:** 修复 `useAuth.ts` 的 `res.data` 嵌套访问（P1-1）
3. 🟡 **高:** 在 `SecurityConfig` 中启用 CORS（P1-2）
4. 🟡 **高:** 为 `UserDetailsServiceImpl` 加 deleted=0 过滤（P1-3）
5. 🟢 **中:** 后端管理接口增加 `@PreAuthorize` 权限保护（P1-6）
6. 🟢 **低:** 其他 P2 建议项

修复后建议由 **Test Agent** 执行测试用例验证。

---

*Review Agent 产出 | 2026-05-16*
