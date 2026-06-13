# SeatFlow 后端服务

> 自习座位预约系统 — 后端 API 服务

## 技术栈

| 技术 | 版本 | 说明 |
|---|---|---|
| Java | 21 | 语言运行时 |
| Spring Boot | 3.4.5 | 核心框架 |
| Spring Security | 6.x | 认证鉴权（JWT + RBAC） |
| MyBatis Plus | 3.x | ORM 持久层 |
| MySQL | 8.0 | 关系型数据库 |
| WebSocket (STOMP) | — | 实时推送通知 |
| Spring Mail | — | 邮件离线兜底通知 |
| Spring Scheduling | — | 定时任务（提醒/超时取消/签到码生成） |

## 项目结构

```
src/main/java/com/seatflow/
├── config/              # 全局配置
│   ├── SecurityConfig.java        # Spring Security + JWT 过滤器链
│   ├── WebSocketConfig.java       # STOMP WebSocket 端点配置
│   ├── CorsConfig.java            # 跨域配置
│   ├── MyBatisPlusConfig.java     # 分页插件 + 逻辑删除
│   └── AssistantProperties.java   # 智能助手 LLM 配置
│
├── controller/          # REST 接口层
│   ├── AuthController.java                  # 登录 / 当前用户信息
│   ├── RoomController.java                  # 学生端：自习室列表/详情
│   ├── SeatController.java                  # 学生端：座位查询
│   ├── SeatSearchController.java            # 多条件搜索座位
│   ├── ReservationController.java           # 学生端：预约 CRUD
│   ├── CheckInController.java               # 签到
│   ├── ViolationController.java             # 学生端：违约记录
│   ├── AssistantController.java             # 智能助手对话
│   ├── AdminRoomController.java             # 管理端：自习室管理
│   ├── AdminSeatController.java             # 管理端：座位管理
│   ├── AdminSeatManageController.java       # 管理端：座位状态管理
│   ├── AdminReservationController.java      # 管理端：预约管理/代约
│   ├── AdminCheckInAndViolationController.java # 管理端：签到码 + 违约管理
│   ├── AdminDashboardController.java        # 管理端：统计仪表盘
│   ├── AdminRoleController.java             # 管理端：RBAC 角色权限
│   ├── AdminUserController.java             # 管理端：用户管理
│   └── AdminConfigController.java           # 管理端：系统参数
│
├── service/             # 业务逻辑层
│   ├── AuthService.java / impl/AuthServiceImpl.java
│   ├── RoomService.java
│   ├── SeatService.java / SeatSearchService.java
│   ├── ReservationService.java
│   ├── CheckInService.java
│   ├── ViolationService.java
│   ├── NotificationService.java   # WebSocket + Email 双通道推送
│   ├── DashboardService.java
│   ├── SystemConfigService.java
│   ├── RoleServiceImpl.java / RoleManageService.java
│   ├── UserManageService.java
│   └── assistant/
│       ├── AssistantService.java  # 对话编排
│       ├── LlmClient.java         # OpenAI 兼容 API 调用
│       ├── AssistantToolRunner.java # function calling 执行器
│       ├── FunctionExecutor.java
│       └── KnowledgeBase.java
│
├── security/            # 安全层
│   ├── JwtTokenProvider.java      # JWT 生成/解析/校验
│   ├── JwtAuthFilter.java         # 请求过滤器（每次请求注入 SecurityContext）
│   ├── UserDetailsServiceImpl.java
│   └── SecurityUtils.java         # 获取当前登录用户工具
│
└── common/
    ├── result/Result.java          # 统一响应体 Result<T>
    ├── exception/BusinessException.java
    ├── exception/GlobalExceptionHandler.java
    └── enums/                      # 枚举：预约状态/座位状态/座位位置/插座类型/违约类型
```

## 核心功能

### 认证与权限（RBAC）
- JWT Token 认证，登录返回 token，后续请求 `Authorization: Bearer <token>`
- 4种预置角色：`SUPER_ADMIN / ADMIN / VIEWER / STUDENT`
- 8种权限粒度：`room:manage / seat:manage / reservation:manage / checkin:manage / violation:manage / user:manage / role:manage / system:config`
- 接口级鉴权：`@PreAuthorize("hasAuthority('room:manage')")`

### 定时任务
| 任务 | 触发条件 | 动作 |
|---|---|---|
| 提前提醒 | 预约开始前 15min，`reminded_before=0` | 推送提醒，标记 `reminded_before=1` |
| 逾期催促 | 预约开始后 10min 未签到，`warned_late=0` | 推送催促，标记 `warned_late=1` |
| 超时取消 | 预约开始后 15min 未签到，状态 PENDING | 取消预约，创建 Violation，推送通知 |
| 签到码生成 | 每日 00:00 | 为所有 OPEN 自习室生成当日 6 位随机编码 |

### 智能助手
- 调用 OpenAI 兼容 API（`/v1/chat/completions`），支持 function calling
- 3个工具：`search_seats`（搜索座位）/ `get_my_reservations`（查询预约）/ `cancel_reservation`（取消预约）

## 快速启动

```bash
# 前置条件：MySQL 8 运行中，数据库 seatflow 已初始化
# 或通过 docker-compose 一键启动（见 deploy/）

# 编译（使用项目 JDK 21）
JAVA_HOME=/tmp/jdk21 PATH=/tmp/jdk21/bin:$PATH mvn compile

# 运行
JAVA_HOME=/tmp/jdk21 PATH=/tmp/jdk21/bin:$PATH mvn spring-boot:run

# 服务地址：http://localhost:8081
```

## 主要接口

| 接口 | 方法 | 说明 |
|---|---|---|
| `/api/auth/login` | POST | 登录，返回 JWT |
| `/api/auth/me` | GET | 当前用户信息+权限 |
| `/api/rooms` | GET | 学生端：自习室列表 |
| `/api/rooms/{id}/seats` | GET | 座位列表+状态 |
| `/api/seats/search` | GET | 多条件搜索座位 |
| `/api/reservations` | POST | 创建预约 |
| `/api/reservations/{id}/cancel` | PUT | 取消预约 |
| `/api/reservations/check-in` | POST | 签到 |
| `/api/assistant/chat` | POST | 智能助手对话 |
| `/api/admin/rooms` | POST/PUT/DELETE | 管理端：自习室 CRUD |
| `/api/admin/statistics/dashboard` | GET | 统计仪表盘 |

## 默认账号

| 账号 | 密码 | 角色 |
|---|---|---|
| admin | admin123 | SUPER_ADMIN |
| student1 | student123 | STUDENT（计算机学院） |
| student2 | student123 | STUDENT（电子工程学院） |
