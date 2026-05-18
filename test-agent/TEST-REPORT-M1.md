# Test Report: M1 基础框架测试

**执行日期:** 2026-05-16  
**测试环境:** Java 21 + Spring Boot 3.4.5 + JUnit 5 + Mockito  
**测试依据:** PRD v0.3 + Plan v1.2 (M1 阶段)  
**测试原则:** 严格基于 PRD 编写，不基于代码实现  

---

## 1. 结果概览

| 类型 | 文件数 | 用例数 | 覆盖 PRD 章节 |
|---|---|---|---|
| 单元测试 | 3 | 19 | A-AUTH01/02, F010-F012 |
| 集成测试 | 2 | 16 | A-AUTH01/02, F010-F012, CORS |
| 冒烟测试 | 1 | 5 | 服务可用性 |
| **合计** | **6** | **40** | — |

> 注：前端路由守卫测试（T-ROUTE-01~03）为前端行为，不在后端测试覆盖范围内，已在 PRD 验收标准中标注为前端实现约束。

---

## 2. 测试用例映射表

### 2.1 认证相关 (PRD: A-AUTH01, A-AUTH02)

| 编号 | 名称 | 类型 | 状态 | PRD 依据 |
|---|---|---|---|---|
| T-AUTH-01 | 正常登录 → 返回 token + expiresIn | 单元+集成 | 🟡 待执行 | A-AUTH01 |
| T-AUTH-02 | 错误密码登录 → 401 | 单元+集成 | 🟡 待执行 | A-AUTH01 |
| T-AUTH-03 | 不存在的用户登录 → 401 | 单元+集成 | 🟡 待执行 | A-AUTH01 |
| T-AUTH-04 | 获取当前用户信息 → 含 roles + permissions | 单元+集成 | 🟡 待执行 | A-AUTH02 |
| T-AUTH-05 | 无 token 访问受保护接口 → 401 | 集成 | 🟡 待执行 | A-AUTH02 |
| T-AUTH-06 | 过期 token 访问 → 401 | 单元+集成 | 🟡 待执行 | A-AUTH02 |
| T-AUTH-07 | 空用户名登录 → 400 | 集成 | 🟡 待执行 | A-AUTH01 |
| T-AUTH-08 | 空密码登录 → 400 | 集成 | 🟡 待执行 | A-AUTH01 |

### 2.2 RBAC 相关 (PRD: F010-F012)

| 编号 | 名称 | 类型 | 状态 | PRD 依据 |
|---|---|---|---|---|
| T-RBAC-01 | 学生角色不含 room:manage, role:manage 等管理权限 | 单元 | 🟡 待执行 | F010-F012 |
| T-RBAC-02 | super_admin 包含全部 8 个权限 | 单元+集成 | 🟡 待执行 | F010-F012 |
| T-RBAC-03 | 多角色用户权限取并集 | 单元 | 🟡 待执行 | F012 |
| T-RBAC-04 | 无角色用户 → 空权限列表 | 单元 | 🟡 待执行 | F012 |
| T-RBAC-05 | viewer 角色仅含 view 权限 | 单元 | 🟡 待执行 | F011 |
| T-RBAC-06 | super_admin 可访问 /api/admin/roles | 集成 | 🟡 待执行 | F010 |
| T-RBAC-07 | super_admin 可访问 /api/admin/users | 集成 | 🟡 待执行 | F010 |
| T-RBAC-08 | 学生访问 /api/admin/roles → 403 | 集成 | 🟡 待执行 | F011 |
| T-RBAC-09 | 学生 POST /api/admin/rooms → 403 | 集成 | 🟡 待执行 | F011 |
| T-RBAC-10 | viewer PUT /api/admin/configs → 403 | 集成 | 🟡 待执行 | F011 |
| T-RBAC-11 | 未登录访问管理接口 → 401 | 集成 | 🟡 待执行 | A-AUTH02 |

### 2.3 跨域配置

| 编号 | 名称 | 类型 | 状态 | PRD 依据 |
|---|---|---|---|---|
| T-CORS-01 | OPTIONS 预检请求返回正确 CORS 头 | 集成+冒烟 | 🟡 待执行 | Plan 2.1 |

### 2.4 冒烟测试

| 编号 | 名称 | 类型 | 状态 | PRD 依据 |
|---|---|---|---|---|
| T-SMOKE-01 | 后端服务启动检查 | 冒烟 | 🟡 待执行 | — |
| T-SMOKE-02 | 登录接口可用性 | 冒烟 | 🟡 待执行 | A-AUTH01 |
| T-SMOKE-03 | 前端服务启动检查 | 冒烟 | 🟡 待执行 | — |
| T-SMOKE-04 | CORS 预检响应检查 | 冒烟 | 🟡 待执行 | Plan 2.1 |
| T-SMOKE-05 | 统一响应格式检查 | 冒烟 | 🟡 待执行 | Plan 4.1 |

---

## 3. 测试文件清单

```
test-agent/
├── unit/
│   └── backend/
│       ├── AuthServiceTest.java         # 认证服务单元测试 (8 用例)
│       ├── JwtTokenProviderTest.java    # JWT 工具单元测试 (6 用例)
│       └── RbacServiceTest.java         # RBAC 服务单元测试 (5 用例)
├── integration/
│   └── api/
│       ├── AuthApiTest.java             # 认证 API 集成测试 (8 用例)
│       └── RbacApiTest.java             # RBAC API 集成测试 (8 用例)
├── smoke/
│   └── smoke-test.sh                    # 冒烟测试脚本 (5 检查点)
└── TEST-REPORT-M1.md                    # 本报告
```

---

## 4. 单元测试详情

### 4.1 AuthServiceTest (8 用例)

**被测对象:** `AuthServiceImpl` (预期实现)  
**Mock 依赖:** `UserMapper`, `RoleMapper`, `PermissionMapper`, `UserRoleMapper`, `JwtTokenProvider`, `PasswordEncoder`

| # | 方法名 | 验证场景 |
|---|---|---|
| 1 | `shouldReturnTokenWhenLoginWithValidCredentials` | 正确用户名密码 → 返回非空 token + 正数 expiresIn |
| 2 | `shouldThrowBadCredentialsWhenPasswordIsIncorrect` | 错误密码 → `BadCredentialsException` |
| 3 | `shouldThrowBadCredentialsWhenUserDoesNotExist` | 不存在用户 → `BadCredentialsException` |
| 4 | `shouldReturnUserInfoWithRolesAndPermissions` | 有效用户 ID → 返回含 roles/permissions 的完整用户信息 |
| 5 | `shouldReturnNullWhenQueryNonExistentUser` | 查询不存在用户 → null |
| 6 | `shouldReturnFalseWhenValidatingExpiredToken` | 过期 token → validateToken 返回 false |
| 7 | `shouldThrowExceptionWhenUsernameIsBlank` | 空用户名 → `BadCredentialsException` |
| 8 | `shouldThrowExceptionWhenPasswordIsBlank` | 空密码 → `BadCredentialsException` |

### 4.2 JwtTokenProviderTest (6 用例)

**被测对象:** `JwtTokenProvider`  
**关键行为:** JWT 生成、解析、过期检测

| # | 方法名 | 验证场景 |
|---|---|---|
| 1 | `shouldGenerateNonNullTokenContainingUsername` | token 非空且为三段 JWT 结构 |
| 2 | `shouldExtractCorrectUsernameFromValidToken` | 从有效 token 正确解析用户名 |
| 3 | `shouldValidateTokenAsTrueWhenValid` | 有效未过期 token → validate = true |
| 4 | `shouldValidateExpiredTokenAsFalse` | 过期 token → validate = false |
| 5 | `shouldValidateMalformedTokenAsFalse` | 畸形 token → validate = false |
| 6 | `shouldValidateEmptyTokenAsFalse` | 空 token → validate = false |

### 4.3 RbacServiceTest (5 用例)

**被测对象:** `RoleServiceImpl` (预期实现)  
**Mock 依赖:** `RoleMapper`, `PermissionMapper`, `UserRoleMapper`

| # | 方法名 | 验证场景 |
|---|---|---|
| 1 | `shouldNotContainManagementPermissionsForStudent` | 学生不含管理类权限 |
| 2 | `shouldContainAllPermissionsForSuperAdmin` | super_admin 含全部 8 个权限 |
| 3 | `shouldReturnUnionOfPermissionsForMultipleRoles` | room_admin + service_admin → 并集 5 个权限 |
| 4 | `shouldReturnEmptyPermissionsWhenUserHasNoRoles` | 无角色用户 → 空列表 |
| 5 | `shouldOnlyContainViewPermissionsForViewer` | viewer 仅含 reservation:view + violation:view |

---

## 5. 集成测试详情

### 5.1 AuthApiTest (8 用例)

**测试方式:** `@SpringBootTest` + `MockMvc` + `@MockBean`  
**测试范围:** HTTP 层 + Spring Security 过滤器链 + Controller

| # | 场景 | 请求 | 期望状态 |
|---|---|---|---|
| 1 | 正常登录 | POST /api/auth/login | 200, token 非空, expiresIn > 0 |
| 2 | 错误密码 | POST /api/auth/login | 401 |
| 3 | 用户不存在 | POST /api/auth/login | 401 |
| 4 | 获取当前用户 | GET /api/auth/me (valid token) | 200, 含 id/username/roles/permissions |
| 5 | 无 token | GET /api/auth/me | 401 |
| 6 | 过期 token | GET /api/auth/me (expired) | 401 |
| 7 | CORS 预检 | OPTIONS /api/auth/login | 200, 含 CORS 头 |
| 8 | 空用户名 | POST /api/auth/login | 400 |

### 5.2 RbacApiTest (8 用例)

**测试方式:** `@SpringBootTest` + `MockMvc` + `@MockBean`  
**测试范围:** 管理端接口的 RBAC 鉴权拦截

| # | 场景 | 请求 | 身份 | 期望状态 |
|---|---|---|---|---|
| 1 | super_admin 访问角色列表 | GET /api/admin/roles | super_admin | 200 |
| 2 | super_admin 访问用户列表 | GET /api/admin/users | super_admin | 200 |
| 3 | 学生访问角色列表 | GET /api/admin/roles | student | 403 |
| 4 | 学生创建自习室 | POST /api/admin/rooms | student | 403 |
| 5 | viewer 修改系统参数 | PUT /api/admin/configs | viewer | 403 |
| 6 | 未登录访问角色列表 | GET /api/admin/roles | — | 401 |
| 7 | 未登录删除自习室 | DELETE /api/admin/rooms/1 | — | 401 |

---

## 6. 冒烟测试详情

**运行方式:** `bash smoke/smoke-test.sh`

| # | 检查点 | 验证内容 | 通过标准 |
|---|---|---|---|
| 1 | 后端服务启动 | GET /api/auth/me | HTTP 401（服务已启动） |
| 2 | 登录接口可用 | POST /api/auth/login | HTTP 200 或 401（接口可达） |
| 3 | 前端服务启动 | GET / | HTTP 200/304 |
| 4 | CORS 预检 | OPTIONS /api/auth/login | 响应头含 Access-Control-Allow-Origin |
| 5 | 统一响应格式 | POST /api/auth/login | JSON 含 code, message, data |

---

## 7. 与代码的集成说明

### 7.1 文件放置

将以下测试文件复制到后端项目的 `src/test/java` 对应包路径下：

```bash
cp test-agent/unit/backend/AuthServiceTest.java     code-agent/backend/src/test/java/com/seatflow/service/
cp test-agent/unit/backend/JwtTokenProviderTest.java code-agent/backend/src/test/java/com/seatflow/security/
cp test-agent/unit/backend/RbacServiceTest.java      code-agent/backend/src/test/java/com/seatflow/service/
cp test-agent/integration/api/AuthApiTest.java       code-agent/backend/src/test/java/com/seatflow/controller/
cp test-agent/integration/api/RbacApiTest.java       code-agent/backend/src/test/java/com/seatflow/controller/
```

### 7.2 编译依赖

测试基于以下 PRD/Plan 定义的类（Code Agent 需实现）：

| 类/接口 | 所在包 | PRD/Plan 依据 |
|---|---|---|
| `AuthService` / `AuthServiceImpl` | `com.seatflow.service` | Plan 2.3 |
| `RoleService` / `RoleServiceImpl` | `com.seatflow.service` | Plan 2.3 |
| `JwtTokenProvider` | `com.seatflow.security` | Plan 2.3 |
| `AuthController` | `com.seatflow.controller` | Plan 2.3, PRD 5.1 |
| `LoginRequest` | `com.seatflow.dto.request` | Plan 4.3 |
| `LoginResponse` | `com.seatflow.dto.response` | Plan 4.3 |
| `UserInfoResponse` | `com.seatflow.dto.response` | Plan 4.3 |
| `User`, `Role`, `Permission` | `com.seatflow.entity` | Plan 3.2 |
| `UserMapper`, `RoleMapper`, `PermissionMapper` | `com.seatflow.mapper` | Plan 2.3 |

### 7.3 运行命令

```bash
# 后端项目目录
cd code-agent/backend

# 运行全部测试
mvn test

# 运行单元测试
mvn test -Dtest="AuthServiceTest,JwtTokenProviderTest,RbacServiceTest"

# 运行集成测试
mvn test -Dtest="AuthApiTest,RbacApiTest"

# 运行冒烟测试（需先启动前后端服务）
bash ../../test-agent/smoke/smoke-test.sh
```

---

## 8. 前端路由守卫约束（T-ROUTE-01~03）

前端路由守卫为前端实现行为，不在后端测试覆盖。依据 PRD 和 Plan，Code Agent 需确保：

| 编号 | 场景 | 期望行为 | 实现位置 |
|---|---|---|---|
| T-ROUTE-01 | 未登录访问任何页面 | 跳转 `/login` | `App.tsx` 路由守卫 |
| T-ROUTE-02 | STUDENT 访问管理端路由 | 跳转 `403` | `App.tsx` 路由守卫 |
| T-ROUTE-03 | 无权限用户访问需权限页面 | 跳转 `403` | `App.tsx` 路由守卫 |

---

## 9. 结论

**M1 阶段测试用例已按 PRD 全部编写完成。**

- ✅ 认证模块：8 单元 + 8 集成 = 16 用例，覆盖 A-AUTH01/A-AUTH02
- ✅ RBAC 模块：5 单元 + 8 集成 = 13 用例，覆盖 F010-F012
- ✅ CORS 配置：1 集成 + 1 冒烟 = 2 检查点
- ✅ 冒烟脚本：5 检查点，覆盖服务可用性和核心 API 可达性
- ✅ 前端路由守卫：3 验收项已明确为前端实现约束

**下一步：**
1. Code Agent 完成 M1 后端代码实现
2. 将测试文件集成到 `code-agent/backend/src/test/java`
3. 执行 `mvn test` 验证
4. 如有失败，通知 Code Agent 修复并重新测试

---

*报告生成时间: 2026-05-16*  
*Test Agent 基于 PRD v0.3 / Plan v1.2 产出*
