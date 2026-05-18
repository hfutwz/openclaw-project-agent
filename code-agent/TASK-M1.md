# M1 任务: 基础框架搭建

## 说明
你是 Code Agent，负责根据 PRD 和 Plan 实现 M1 阶段的所有后端和前端代码。

## 必读文件
1. PRD: `~/workspace-project/prd/prd.md`
2. Plan (重点看第3章数据库设计、第5章编码规范、第9章M1任务): `~/workspace-project/plan/plan.md`
3. 身份文档: `~/workspace-project/code-agent/code-agent.md`

## 工作目录
- 后端: `~/workspace-project/code-agent/backend/`
- 前端: `~/workspace-project/code-agent/frontend/`

## 后端已有代码
Spring Boot 3 项目已初始化，已有:
- `SeatFlowApplication.java` — 启动类
- `Result.java` — 统一返回类
- `BusinessException.java` + `GlobalExceptionHandler.java` — 异常处理

## M1-B 后端任务（按顺序执行）

### M1-B01: 数据库 DDL
- 在 `src/main/resources/schema.sql` 创建所有11张表的DDL
- 表结构严格按 Plan 第3.2节定义
- 字符集 utf8mb4，排序 utf8mb4_unicode_ci
- 禁止外键，业务层约束

### M1-B02: 种子数据
- 在 `src/main/resources/data.sql` 插入种子数据
- admin账号(username: admin, password: admin123, BCrypt加密)
- 4个默认角色(super_admin, room_admin, service_admin, viewer)
- 8个权限项(reservation:view, violation:view, reservation:manage, seat:manage, room:manage, system:config, role:manage, user:manage)
- 角色-权限映射
- 系统参数默认值(max_reservation_hours=4等)
- 2个院系(计算机学院, 电子工程学院)
- 2个自习室 + 若干座位

### M1-B03: 统一返回类 ✅ 已完成
Result.java 已存在，检查是否符合 Plan 规范

### M1-B04: 异常处理 ✅ 已完成
BusinessException + GlobalExceptionHandler 已存在，检查是否符合 Plan 规范

### M1-B05: MyBatis Plus 配置
- `MyBatisPlusConfig.java` — 分页插件 + 逻辑删除全局配置
- application.yml 配置 MyBatis Plus

### M1-B06: JWT 工具类
- `JwtTokenProvider.java` — 生成/解析/验证token
- 密钥和过期时间从 application.yml 读取

### M1-B07: Spring Security 配置
- `SecurityConfig.java` — SecurityFilterChain 配置
- `JwtAuthFilter.java` — JWT 认证过滤器
- `UserDetailsServiceImpl.java` — 加载用户+权限
- `SecurityUtils.java` — 获取当前登录用户
- 登录接口匿名访问，其他需JWT

### M1-B08: 登录接口
- `AuthController.java` — POST /api/auth/login + GET /api/auth/me
- `AuthService.java` — 登录验证 + 返回token + 获取用户信息+权限
- 登录响应含 token + expiresIn
- /api/auth/me 返回 id, username, realName, email, departmentId, userType, roles, permissions

### M1-B09: 跨域配置
- `CorsConfig.java` — 允许前端 5173 端口跨域访问

## M1-F 前端任务（可与后端并行）

### M1-F01: Axios 实例 + 拦截器
- `services/api.ts` — Axios 实例
- 请求拦截器自动附 JWT Token
- 响应拦截器: 401跳登录, 403提示无权限, 500提示服务器错误

### M1-F02: 登录页
- `pages/Login.tsx` — 用户名密码表单 → 调用登录API → 存token → 跳转首页

### M1-F03: 路由配置 + 路由守卫
- `App.tsx` — React Router 配置
- 路由守卫: 未登录→跳登录, STUDENT不可访问管理端, 权限不足→403
- 每个路由 meta.permissions 和 meta.userType

### M1-F04: 学生端布局
- `layouts/StudentLayout.tsx` — 顶栏(logo+用户名+退出)+内容区，无管理端入口

### M1-F05: 管理端布局
- `layouts/AdminLayout.tsx` — 顶栏+侧边栏(按权限动态渲染)+内容区

### M1-F06: useAuth + usePermissions hooks
- `hooks/useAuth.ts` — 获取当前用户信息
- `hooks/usePermissions.ts` — 判断权限

## 编码规范（强约束）
- 后端分层: Controller → Service → Mapper，严禁跨层
- 表名 @TableName("t_room") 标注
- 统一返回 Result<T>，Controller 无 try-catch
- Entity 字段命名与数据库一致(下划线→驼峰由MyBatis Plus自动映射)
- 前端用 React Context + hooks，暂不引入 Redux
- UI 框架: Ant Design

## 验收标准
每完成一个子任务后:
1. 后端: `mvn compile` 通过
2. 前端: `npm run build` 通过
3. 完成所有 M1 任务后: 后端 `mvn spring-boot:run` 启动成功，前端 `npm run dev` 启动成功
4. 登录接口可调用并返回正确数据

## Git 提交规范
- 分支: `feature/M1`
- Commit: `feat(M1-B01): 数据库DDL创建` 格式
- 每个子任务独立 commit

## 注意事项
- 严格按 Plan 的数据库表结构实现，不要自行发挥
- 种子数据中的 admin 密码用 BCrypt 加密
- JWT 密钥在 application.yml 中配置，不要硬编码
- 先完成所有后端任务，再完成前端任务
- 完成后通知 Orchestrator
