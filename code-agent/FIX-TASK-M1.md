# M1 修复任务

## 说明
Review Agent 已完成 M1 代码审计，发现以下问题需要修复。请严格按 Review 报告修复，完成后验证编译和启动。

## 必读文件
1. Review 报告: /Users/will/.openclaw/workspace-project/review-agent/review-M1.md
2. PRD: /Users/will/.openclaw/workspace-project/prd/prd.md
3. Plan: /Users/will/.openclaw/workspace-project/plan/plan.md

## 必须修复的问题（按优先级）

### 🔴 P0-1: AuthServiceImpl 缺失
- **文件:** 需新建 `backend/src/main/java/com/seatflow/service/impl/AuthServiceImpl.java`
- **问题:** AuthService 只有接口没有实现，Spring Boot 启动失败
- **修复:** Review 报告已提供完整代码建议，参考实现
- **关键:** 使用 `@Service` + `@RequiredArgsConstructor`，实现 login() 和 getCurrentUserInfo()
- **注意:** 查询用户时必须过滤 `deleted = 0`

### 🔴 P1-1: 前端 useAuth.ts API 响应嵌套 .data Bug
- **文件:** `frontend/src/hooks/useAuth.ts`
- **问题:** api.ts 拦截器已返回 response.data，但 useAuth.ts 仍访问 res.data.code → 永远 undefined
- **修复:** 将 `res.data.code` 改为 `res.code`，`res.data.data` 改为 `res.data`

### 🟡 P1-2: CORS 未在 Spring Security 中显式启用
- **文件:** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`
- **问题:** CorsConfig 定义了 bean 但 SecurityConfig 没调用 .cors()
- **修复:** 在 SecurityFilterChain 中添加 `.cors(cors -> cors.configurationSource(corsConfigurationSource()))`，并注入 CorsConfigurationSource

### 🟡 P1-3: UserDetailsServiceImpl 未过滤逻辑删除用户
- **文件:** `backend/src/main/java/com/seatflow/security/UserDetailsServiceImpl.java`
- **问题:** loadUserByUsername 未加 deleted=0 条件
- **修复:** LambdaQueryWrapper 添加 `.eq(User::getDeleted, 0)`

### 🟡 P1-4: JwtAuthFilter catch 后未清理 SecurityContext
- **文件:** `backend/src/main/java/com/seatflow/security/JwtAuthFilter.java`
- **问题:** catch 块只记录日志，未调用 SecurityContextHolder.clearContext()
- **修复:** catch 块添加 `SecurityContextHolder.clearContext();`

### 🟡 P1-5: PermissionMapper.selectByUserId SQL 未过滤 role 逻辑删除
- **文件:** `backend/src/main/java/com/seatflow/mapper/PermissionMapper.java`
- **问题:** SQL INNER JOIN t_role 但没加 r.deleted = 0
- **修复:** SQL 中添加 `AND r.deleted = 0`

### 🟡 P1-6: 后端管理接口缺少权限注解保护
- **文件:** `backend/src/main/java/com/seatflow/config/SecurityConfig.java`
- **问题:** 仅配置了"全部需认证"，未按角色/权限控制管理端接口
- **修复:** 在 authorizeHttpRequests 中添加 `.requestMatchers("/api/admin/**").hasAnyAuthority("room:manage", "role:manage", "system:config", "user:manage")`
  或在各 Admin Controller 方法上加 `@PreAuthorize("hasAuthority('xxx')")`

## 建议修复（可选，时间允许）

### P2-1: RouteGuard 使用整页刷新
- **文件:** `frontend/src/App.tsx`
- **修复:** 使用 `useNavigate()` 替代 `window.location.href`

### P2-2: AdminLayout Menu items 含非标准属性
- **文件:** `frontend/src/layouts/AdminLayout.tsx`
- **修复:** 构造数组时过滤，不在 item 上加 `show`

### P2-3: mapper-locations 指向空目录产生警告
- **文件:** `backend/src/main/resources/application.yml`
- **修复:** 删除 `mapper-locations: classpath:mapper/*.xml` 配置行

### P2-4: SchedulingConfig 使用 Executors
- **文件:** `backend/src/main/java/com/seatflow/config/SchedulingConfig.java`
- **修复:** 使用 `ThreadPoolTaskScheduler`

### P2-5: LoginRequest 缺少长度限制
- **文件:** `backend/src/main/java/com/seatflow/dto/request/LoginRequest.java`
- **修复:** 添加 `@Size(min = 3, max = 50)` 和 `@Size(min = 6, max = 100)`

### P2-6: SeatFlowApplication 缺少 @MapperScan
- **文件:** `backend/src/main/java/com/seatflow/SeatFlowApplication.java`
- **修复:** 添加 `@MapperScan("com.seatflow.mapper")`

## 验收标准
修复完成后必须验证：
1. 后端: `mvn compile` 通过
2. 后端: `mvn spring-boot:run` 启动成功（不报错）
3. 前端: `npm run build` 通过
4. 登录接口可调用（POST /api/auth/login 返回 200 + token）

## Git 提交
- 在 feature/M1 分支上修复
- Commit: `fix(M1): 修复 Review 审计问题 — AuthServiceImpl + useAuth + CORS + 安全加固`

## 输出
修复完成后输出修复报告到 /Users/will/.openclaw/workspace-project/code-agent/FIX-REPORT-M1.md
