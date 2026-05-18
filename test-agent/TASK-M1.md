# M1 测试任务: 基础框架测试用例

## 说明
你是 Test Agent，负责根据 PRD 编写 M1 阶段的测试用例。**测试必须基于 PRD，不基于代码。**

## 必读文件
1. PRD: `~/workspace-project/prd/prd.md`
2. Plan (重点看 M1 阶段的任务定义): `~/workspace-project/plan/plan.md`
3. 身份文档: `~/workspace-project/test-agent/test-agent.md`

## 工作目录
- `~/workspace-project/test-agent/`

## M1 需要测试的功能

根据 PRD 和 Plan，M1 阶段需要覆盖以下验收标准:

### 1. 认证相关 (PRD: A-AUTH01, A-AUTH02)

**测试用例:**

#### T-AUTH-01: 正常登录
- POST /api/auth/login 正确用户名密码 → 返回200 + token + expiresIn
- token 非空，expiresIn > 0

#### T-AUTH-02: 错误密码登录
- POST /api/auth/login 错误密码 → 返回401

#### T-AUTH-03: 不存在的用户登录
- POST /api/auth/login 不存在的用户名 → 返回401

#### T-AUTH-04: 获取当前用户信息
- GET /api/auth/me 携带有效token → 返回用户信息+roles+permissions
- 验证返回字段: id, username, realName, email, departmentId, userType, roles, permissions

#### T-AUTH-05: 无token访问受保护接口
- GET /api/auth/me 无token → 返回401

#### T-AUTH-06: 过期token访问
- GET /api/auth/me 过期token → 返回401

### 2. RBAC 相关 (PRD: F010-F012)

#### T-RBAC-01: 学生角色权限
- 学生登录后 permissions 不含 room:manage, role:manage 等管理权限

#### T-RBAC-02: 管理员角色权限
- super_admin 登录后 permissions 包含所有权限

#### T-RBAC-03: 多角色用户权限取并集
- 用户同时有 room_admin 和 service_admin 角色 → permissions 为两者并集

### 3. 跨域配置

#### T-CORS-01: 前端跨域访问
- OPTIONS 预检请求返回正确 CORS 头
- Access-Control-Allow-Origin 包含前端地址

### 4. 前端路由守卫

#### T-ROUTE-01: 未登录访问任何页面 → 跳转登录页
#### T-ROUTE-02: 学生访问管理端路由 → 跳转403
#### T-ROUTE-03: 无权限用户访问需权限页面 → 跳转403

## 测试代码结构

```
test-agent/
├── unit/
│   └── backend/
│       └── AuthServiceTest.java      — 认证服务单测
├── integration/
│   └── api/
│       └── AuthApiTest.java          — 认证API集成测试
├── smoke/
│   └── smoke-test.sh                 — 冒烟测试脚本
└── reports/
    └── (测试报告将在此生成)
```

## 编写要求

1. **后端单测**: 使用 JUnit 5 + Mockito，放在 `unit/backend/` 目录
2. **后端集成测试**: 使用 Spring Boot Test + MockMvc，放在 `integration/api/` 目录
3. **冒烟测试**: Shell 脚本，使用 curl 测试核心API可达性，放在 `smoke/` 目录
4. 前端测试暂不编写（M1前端页面较少，后续M2补充）

## 冒烟测试脚本要求

`smoke/smoke-test.sh` 应包含:
- 检查后端服务启动 (curl http://localhost:8080/api/auth/me → 401)
- 检查登录接口可用 (POST /api/auth/login)
- 检查前端服务启动 (curl http://localhost:5173 → 200)

## 注意事项
- 测试严格基于 PRD 的验收标准，不看代码写测试
- 每个验收标准至少1个测试用例
- 正常路径 + 至少2个异常路径
- 命名: `should [expected] when [condition]`
- 完成后通知 Orchestrator
