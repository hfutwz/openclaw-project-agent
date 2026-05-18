# M1 测试兼容性修复任务

## 说明
Test Agent 编写的测试文件已复制到后端项目，但编译失败。需要修复代码使其通过测试。

## 测试文件位置
已复制到 `backend/src/test/java/` 下：
- `com/seatflow/service/AuthServiceTest.java`
- `com/seatflow/service/RbacServiceTest.java`
- `com/seatflow/security/JwtTokenProviderTest.java`
- `com/seatflow/integration/api/AuthApiTest.java`
- `com/seatflow/integration/api/RbacApiTest.java`

## 编译错误

### 错误1: AuthServiceImpl 包路径
- 测试导入: `com.seatflow.service.AuthServiceImpl`
- 实际位置: `com.seatflow.service.impl.AuthServiceImpl`
- **修复方案:** 将 `AuthServiceImpl` 移动到 `com.seatflow.service` 包下（或创建子包但测试需要相应调整）

### 错误2: RoleServiceImpl 缺失
- 测试使用: `@InjectMocks private RoleServiceImpl roleService`
- 实际: `RoleServiceImpl` 不存在
- **修复方案:** 新建 `com/seatflow/service/impl/RoleServiceImpl.java`（或 `service/RoleServiceImpl.java`），实现 `getUserPermissions(Long userId)` 方法

### 错误3: Mapper 方法缺失（需验证）
测试引用了以下方法，请检查并在 Mapper 中添加：
- `UserMapper.selectByUsername(String username)` — 如不存在，添加 `@Select("SELECT * FROM t_user WHERE username = #{username} AND deleted = 0")`
- `RoleMapper.selectRolesByUserId(Long userId)` — 如不存在，添加联表查询
- `PermissionMapper.selectPermissionsByRoleIds(List<Long> roleIds)` — 如不存在，添加 IN 查询

### 错误4: AuthService 接口方法不匹配
- 测试调用: `authService.getCurrentUser(1L)`（带 userId 参数）
- 实际接口: `getCurrentUserInfo()`（无参数）
- **修复方案:** 在 AuthService 接口和 AuthServiceImpl 中添加 `UserInfoResponse getCurrentUser(Long userId)` 方法（用于测试和Service层调用），原有 `getCurrentUserInfo()` 内部调用 `getCurrentUser(SecurityUtils.getCurrentUserId())`

### 错误5: AuthServiceImpl.login 参数不匹配
- 测试 mock: `jwtTokenProvider.generateToken("admin")`（传入 username）
- 实际实现: 检查 `generateToken` 方法签名，确保与测试 mock 兼容

## 验收标准
修复后执行以下命令必须全部通过：
1. `mvn test-compile` — 测试代码编译通过
2. `mvn test` — 单元测试全部通过
3. `mvn spring-boot:run` — 应用启动成功
4. `npm run build`（frontend）— 前端打包成功

## Git
- 在 feature/M1 分支上提交
- Commit: `fix(M1): 适配 Test Agent 测试 — 补齐ServiceImpl和Mapper方法`
