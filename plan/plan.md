# Plan: 自习座位预约系统 — 开发方案

**版本：** v1.0
**日期：** 2026-05-16
**基准文档：** PRD v0.3

---

## 1. 用户故事清单

> 从 PRD 提取，作为开发验收的颗粒度依据

### 学生端

| 编号 | 用户故事 | 对应功能 | 优先级 |
|---|---|---|---|
| US-S01 | 查看所有可用自习室及开放时间 | F001 | P0 |
| US-S02 | 查看座位图并选择座位预约 | F002, F003 | P0 |
| US-S03 | 按整点小时预约座位（最多4h） | F003 | P0 |
| US-S04 | 输入教室动态编码签到 | F004, F009 | P0 |
| US-S05 | 收到预约提醒 | F005 | P0 |
| US-S06 | 超时未签到自动取消+通知 | F005, F006 | P0 |
| US-S07 | 取消预约（含违约边界） | F003 | P0 |
| US-S08 | 多条件搜索座位（含位置标记） | F007 | P0 |
| US-S09 | 查看历史预约并再次预约 | F008 | P0 |
| US-S10 | 查看违约记录 | F006 | P2 |
| US-S11 | 智能助手自然语言交互 | F013 | P1 |

### 管理端

| 编号 | 用户故事 | 对应功能 | 优先级 |
|---|---|---|---|
| US-A01 | 登记/注销自习室 | F001 | P0 |
| US-A02 | 登记/注销座位（含位置标记） | F002 | P0 |
| US-A03 | 查看预约统计 | F014, A-STAT01 | P0 |
| US-A04 | 代客预约/取消 | F003 | P2 |
| US-A05 | 维护角色和权限 | F010-F012 | P0 |
| US-A06 | 调整系统参数 | F014 | P2 |

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────┐
│                   Nginx (可选)                    │
│              反向代理 + 静态资源                    │
└───────────┬─────────────────────┬───────────────┘
            │                     │
    ┌───────▼───────┐     ┌───────▼───────┐
    │  学生端 React  │     │  管理端 React  │
    │  :5173 (dev)  │     │  :5173 (dev)  │
    │  同一SPA,路由   │     │  分区或独立部署  │
    └───────┬───────┘     └───────┬───────┘
            │  HTTP/WS            │  HTTP
            │                     │
    ┌───────▼─────────────────────▼───────┐
    │       Spring Boot 3 Backend         │
    │            :8080                     │
    │  ┌─────────────────────────────┐    │
    │  │  Controller (REST API)      │    │
    │  │  ↓                          │    │
    │  │  Service (业务逻辑)          │    │
    │  │  ↓                          │    │
    │  │  Repository (MyBatis Plus)  │    │
    │  │  ↓                          │    │
    │  │  Mapper (SQL映射)           │    │
    │  └─────────────────────────────┘    │
    │  ┌──────────┐  ┌────────────────┐  │
    │  │ Security │  │ @Scheduled     │  │
    │  │ + JWT    │  │ + ThreadPool   │  │
    │  └──────────┘  └────────────────┘  │
    │  ┌──────────┐  ┌────────────────┐  │
    │  │ WebSocket│  │ JavaMail       │  │
    │  │ + STOMP  │  │ (SMTP)         │  │
    │  └──────────┘  └────────────────┘  │
    └───────────────┬─────────────────────┘
                    │
            ┌───────▼───────┐
            │  MySQL 8.0    │
            │  :3306        │
            │  database:    │
            │  seatflow     │
            └───────────────┘
```

### 2.2 前端架构

```
src/
├── main.tsx                  # 入口
├── App.tsx                   # 根组件 + 路由
├── layouts/
│   ├── StudentLayout.tsx     # 学生端布局（顶栏+侧边栏+内容）
│   └── AdminLayout.tsx       # 管理端布局
├── pages/
│   ├── student/
│   │   ├── RoomList.tsx      # 自习室列表
│   │   ├── RoomDetail.tsx    # 自习室详情 + 座位图
│   │   ├── Reservation.tsx   # 预约确认
│   │   ├── CheckIn.tsx       # 签到
│   │   ├── MyReservations.tsx# 我的预约
│   │   ├── Search.tsx        # 座位搜索
│   │   ├── Violations.tsx    # 违约记录
│   │   └── Assistant.tsx     # 智能助手
│   └── admin/
│       ├── Dashboard.tsx     # 仪表盘
│       ├── RoomManage.tsx    # 自习室管理
│       ├── SeatManage.tsx    # 座位管理
│       ├── ReservationManage.tsx # 预约管理
│       ├── ViolationManage.tsx   # 违约管理
│       ├── UserManage.tsx    # 用户管理
│       ├── RoleManage.tsx    # 角色管理
│       ├── SystemConfig.tsx  # 系统参数
│       └── CheckInCode.tsx   # 动态编码
├── components/
│   ├── SeatMap/              # 座位图组件（核心）
│   │   ├── SeatMap.tsx       # 座位图主体
│   │   ├── Seat.tsx          # 单个座位
│   │   └── SeatLegend.tsx    # 图例
│   ├── ChatBox/              # 智能助手聊天框
│   │   ├── ChatBox.tsx
│   │   └── MessageBubble.tsx
│   └── common/               # 通用组件
│       ├── Result.tsx        # 统一结果展示
│       └── PageHeader.tsx
├── services/
│   ├── api.ts                # Axios 实例 + 拦截器
│   ├── auth.ts               # 认证接口
│   ├── room.ts               # 自习室接口
│   ├── seat.ts               # 座位接口
│   ├── reservation.ts        # 预约接口
│   ├── search.ts             # 搜索接口
│   ├── violation.ts          # 违约接口
│   ├── rbac.ts               # RBAC接口
│   ├── config.ts             # 系统参数接口
│   ├── assistant.ts          # 智能助手接口
│   └── websocket.ts          # WebSocket 连接管理
├── hooks/
│   ├── useAuth.ts            # 认证状态
│   ├── usePermissions.ts     # 权限检查
│   └── useWebSocket.ts       # WebSocket 消息
├── utils/
│   ├── constants.ts          # 常量定义
│   └── helpers.ts            # 工具函数
├── styles/
│   └── global.css            # 全局样式
└── assets/
    └── ...                   # 静态资源
```

### 2.3 后端架构

```
src/main/java/com/seatflow/
├── SeatFlowApplication.java          # 启动类
├── config/
│   ├── SecurityConfig.java           # Spring Security + JWT
│   ├── WebSocketConfig.java          # WebSocket + STOMP
│   ├── MyBatisPlusConfig.java        # MyBatis Plus 配置
│   ├── SchedulingConfig.java         # 定时任务线程池
│   ├── CorsConfig.java               # 跨域配置
│   └── MailConfig.java               # 邮件配置
├── security/
│   ├── JwtTokenProvider.java         # JWT 生成/验证
│   ├── JwtAuthFilter.java            # JWT 过滤器
│   ├── UserDetailsServiceImpl.java   # 用户加载
│   └── SecurityUtils.java            # 安全工具
├── controller/
│   ├── AuthController.java           # A-AUTH01, A-AUTH02
│   ├── RoomController.java           # A-ROOM01, A-ROOM02
│   ├── AdminRoomController.java      # A-ROOM03~06
│   ├── SeatController.java           # A-SEAT01, A-SEAT02
│   ├── AdminSeatController.java      # A-SEAT03~05
│   ├── ReservationController.java    # A-RES01~06
│   ├── AdminReservationController.java # A-RES07~09
│   ├── SearchController.java         # A-SCH01
│   ├── ViolationController.java      # A-VIO01, A-VIO02
│   ├── CheckInCodeController.java    # A-CODE01
│   ├── RoleController.java           # A-RBAC01~04
│   ├── UserController.java           # A-RBAC05, A-RBAC06
│   ├── SystemConfigController.java   # A-CONF01, A-CONF02
│   ├── AssistantController.java      # A-AI01
│   └── StatisticsController.java     # A-STAT01
├── service/
│   ├── AuthService.java
│   ├── RoomService.java
│   ├── SeatService.java
│   ├── ReservationService.java
│   ├── CheckInService.java
│   ├── ViolationService.java
│   ├── SearchService.java
│   ├── RoleService.java
│   ├── UserService.java
│   ├── SystemConfigService.java
│   ├── AssistantService.java
│   ├── StatisticsService.java
│   ├── NotificationService.java      # 推送（邮件+WebSocket）
│   └── impl/                         # 实现类
├── mapper/
│   ├── RoomMapper.java
│   ├── SeatMapper.java
│   ├── ReservationMapper.java
│   ├── CheckInCodeMapper.java
│   ├── ViolationMapper.java
│   ├── UserMapper.java
│   ├── RoleMapper.java
│   ├── PermissionMapper.java
│   ├── UserRoleMapper.java
│   ├── RolePermissionMapper.java
│   └── SystemConfigMapper.java
├── entity/
│   ├── Room.java
│   ├── Seat.java
│   ├── Reservation.java
│   ├── CheckInCode.java
│   ├── Violation.java
│   ├── User.java
│   ├── Role.java
│   ├── Permission.java
│   ├── UserRole.java
│   ├── RolePermission.java
│   └── SystemConfig.java
├── dto/
│   ├── request/
│   │   ├── LoginRequest.java
│   │   ├── ReservationCreateRequest.java
│   │   ├── CheckInRequest.java
│   │   ├── SeatSearchRequest.java
│   │   ├── RoomCreateRequest.java
│   │   ├── RoomUpdateRequest.java
│   │   ├── SeatCreateRequest.java
│   │   ├── SeatUpdateRequest.java
│   │   ├── RoleCreateRequest.java
│   │   ├── UserRoleRequest.java
│   │   ├── SystemConfigUpdateRequest.java
│   │   └── ChatRequest.java
│   └── response/
│       ├── LoginResponse.java
│       ├── UserInfoResponse.java
│       ├── RoomResponse.java
│       ├── RoomDetailResponse.java
│       ├── SeatResponse.java
│       ├── ReservationResponse.java
│       ├── ViolationResponse.java
│       ├── SearchResultResponse.java
│       ├── RoleResponse.java
│       ├── SystemConfigResponse.java
│       ├── DashboardResponse.java
│       └── ChatResponse.java
├── common/
│   ├── result/
│   │   └── Result.java               # 统一返回
│   ├── exception/
│   │   ├── BusinessException.java
│   │   └── GlobalExceptionHandler.java
│   └── enums/
│       ├── ReservationStatus.java     # PENDING/CHECKED_IN/COMPLETED/CANCELLED
│       ├── SeatStatus.java            # AVAILABLE/DISABLED
│       ├── RoomStatus.java            # OPEN/CLOSED
│       ├── SocketType.java            # NONE/FIXED/TRACK
│       ├── SeatPosition.java          # WINDOW/CORRIDOR/MIDDLE
│       └── ViolationType.java         # CHECK_IN_TIMEOUT
├── scheduled/
│   ├── ReservationReminderTask.java   # 提前15min + 逾期10min 提醒
│   └── ReservationExpireTask.java     # 逾期15min 自动取消
└── ai/
    └── LlmClient.java                # LLM API 调用客户端
```

---

## 3. 数据库设计

### 3.1 ER 关系图

```
┌──────────┐     ┌──────────┐     ┌──────────────┐
│   User   │────<│Reservation│>────│    Seat      │
│          │     └──────────┘     └──────┬───────┘
│          │                            │
│          │     ┌──────────────┐       │
│          │────<│  Violation   │       │
│          │     └──────────────┘       │
│          │                            │
│          │     ┌──────────┐           │
│          ├────<│UserRole  │     ┌─────▼────────┐
│          │     └────┬─────┘     │    Room      │
└────┬─────┘          │           └──────────────┘
     │                │
     │          ┌─────▼─────┐
     │          │   Role    │
     │          └─────┬─────┘
     │                │
     │          ┌─────▼──────────┐
     │          │RolePermission  │
     │          └─────┬─────────┘
     │                │
     │          ┌─────▼──────┐
     │          │ Permission │
     │          └────────────┘
     │
     │     ┌──────────────┐
     └────<│CheckInCode   │
           └──────────────┘

┌──────────────┐
│ SystemConfig │  (独立表，KV 结构)
└──────────────┘
```

**关系说明：**
- Room 1 : N Seat
- Seat 1 : N Reservation
- User 1 : N Reservation
- User 1 : N Violation
- User N : M Role（通过 UserRole）
- Role N : M Permission（通过 RolePermission）
- Room 1 : N CheckInCode（按日期）

### 3.2 表结构

> **约束：外键禁止在数据库层面设定，由后端业务层面约束**

#### t_user 用户表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| username | VARCHAR(50) | UNIQUE, NOT NULL | 用户名 |
| password | VARCHAR(255) | NOT NULL | BCrypt 加密 |
| real_name | VARCHAR(50) | | 真实姓名 |
| email | VARCHAR(100) | | 邮箱（推送用） |
| department_id | BIGINT | | 院系ID（为空=全校共享） |
| user_type | VARCHAR(20) | NOT NULL, DEFAULT 'STUDENT' | STUDENT / ADMIN |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除 |
| created_at | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | |

#### t_department 院系表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(100) | UNIQUE, NOT NULL | 院系名称 |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

#### t_room 自习室表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(100) | NOT NULL | 自习室名称 |
| location | VARCHAR(200) | | 位置描述 |
| department_id | BIGINT | | 所属院系（为空=全校共享） |
| open_time | TIME | NOT NULL, DEFAULT '07:00:00' | 每日开放开始时间 |
| close_time | TIME | NOT NULL, DEFAULT '22:00:00' | 每日开放结束时间 |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'OPEN' | OPEN / CLOSED |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

#### t_seat 座位表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| room_id | BIGINT | NOT NULL | 所属自习室（业务层外键） |
| seat_number | VARCHAR(20) | NOT NULL | 座位编号（自习室内唯一） |
| row_num | INT | NOT NULL | 行号 |
| col_num | INT | NOT NULL | 列号 |
| socket_type | VARCHAR(20) | NOT NULL, DEFAULT 'NONE' | NONE / FIXED / TRACK |
| position | VARCHAR(20) | NOT NULL, DEFAULT 'MIDDLE' | WINDOW / CORRIDOR / MIDDLE |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'AVAILABLE' | AVAILABLE / DISABLED |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

**唯一约束：** `UNIQUE(room_id, seat_number)` （未删除时）

#### t_reservation 预约表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL | 预约用户（业务层外键） |
| seat_id | BIGINT | NOT NULL | 预约座位（业务层外键） |
| room_id | BIGINT | NOT NULL | 所属自习室（冗余，方便查询） |
| date | DATE | NOT NULL | 预约日期 |
| start_time | TIME | NOT NULL | 开始时间（整点） |
| end_time | TIME | NOT NULL | 结束时间（整点） |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'PENDING' | PENDING / CHECKED_IN / COMPLETED / CANCELLED |
| cancelled_by | VARCHAR(20) | | STUDENT / ADMIN / SYSTEM |
| reminded_before | TINYINT | NOT NULL, DEFAULT 0 | 是否已发送提前15min提醒（0=否 1=是） |
| warned_late | TINYINT | NOT NULL, DEFAULT 0 | 是否已发送逾期10min催促（0=否 1=是） |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

**索引：**
- `INDEX(seat_id, date, start_time, end_time)` — 冲突检测
- `INDEX(user_id, date, start_time)` — 用户同时段检查
- `INDEX(status, date, start_time)` — 定时任务扫描

#### 预约冲突检测（强约束，Code Agent 必须按此实现）

**座位时段冲突检测 SQL：**
```sql
SELECT COUNT(*) FROM t_reservation
WHERE seat_id = #{seatId}
  AND date = #{date}
  AND status IN ('PENDING', 'CHECKED_IN')
  AND deleted = 0
  AND start_time < #{newEndTime}
  AND end_time > #{newStartTime}
```
> 区间重叠判断：`start_time < newEndTime AND end_time > newStartTime`，不是等值匹配

**学生同时段冲突检测 SQL：**
```sql
SELECT COUNT(*) FROM t_reservation
WHERE user_id = #{userId}
  AND date = #{date}
  AND status IN ('PENDING', 'CHECKED_IN')
  AND deleted = 0
  AND start_time < #{newEndTime}
  AND end_time > #{newStartTime}
```

**Service 层约束：** `ReservationService.create()` 方法内，在 `@Transactional` 事务中先执行两条冲突检测，通过后再插入。

#### t_check_in_code 签到编码表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| room_id | BIGINT | NOT NULL | 所属教室（业务层外键） |
| code_date | DATE | NOT NULL | 编码日期 |
| code | VARCHAR(10) | NOT NULL | 6位动态编码 |
| created_at | DATETIME | NOT NULL | |

**唯一约束：** `UNIQUE(room_id, code_date)`

#### t_violation 违约表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL | 违约用户（业务层外键） |
| reservation_id | BIGINT | NOT NULL | 关联预约（业务层外键） |
| type | VARCHAR(30) | NOT NULL | CHECK_IN_TIMEOUT |
| created_at | DATETIME | NOT NULL | |

#### t_role 角色表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(50) | UNIQUE, NOT NULL | 角色名 |
| code | VARCHAR(50) | UNIQUE, NOT NULL | 角色编码（如 super_admin） |
| description | VARCHAR(200) | | 描述 |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

#### t_permission 权限表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(100) | NOT NULL | 权限名称 |
| code | VARCHAR(50) | UNIQUE, NOT NULL | 权限编码（如 reservation:view） |
| created_at | DATETIME | NOT NULL | |

#### t_user_role 用户-角色关联表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL | 用户（业务层外键） |
| role_id | BIGINT | NOT NULL | 角色（业务层外键） |
| created_at | DATETIME | NOT NULL | |

**唯一约束：** `UNIQUE(user_id, role_id)`

#### t_role_permission 角色-权限关联表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| role_id | BIGINT | NOT NULL | 角色（业务层外键） |
| permission_id | BIGINT | NOT NULL | 权限（业务层外键） |
| created_at | DATETIME | NOT NULL | |

**唯一约束：** `UNIQUE(role_id, permission_id)`

#### t_system_config 系统参数表

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| config_key | VARCHAR(100) | UNIQUE, NOT NULL | 参数键 |
| config_value | VARCHAR(200) | NOT NULL | 参数值 |
| description | VARCHAR(200) | | 说明 |
| updated_at | DATETIME | NOT NULL | |

---

## 4. 接口定义

> 与 PRD 第5章完全对应，此处补充请求/响应格式

### 4.1 统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

### 4.2 分页请求/响应

**请求参数：** `page` (从1开始), `size` (默认20), `sort` (可选)

**响应格式：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "records": [ ... ],
    "total": 100,
    "page": 1,
    "size": 20
  }
}
```

### 4.3 核心接口详细定义

#### POST /api/auth/login
```json
// Request
{ "username": "string", "password": "string" }
// Response
{ "token": "string", "expiresIn": 86400000 }
```

#### GET /api/auth/me
```json
// Response
{
  "id": 1,
  "username": "string",
  "realName": "string",
  "email": "string",
  "departmentId": 1,
  "userType": "STUDENT",
  "roles": ["student"],
  "permissions": ["reservation:create", "seat:search"]
}
```

#### POST /api/reservations
```json
// Request
{
  "seatId": 1,
  "date": "2026-05-17",
  "startTime": "08:00",
  "endTime": "10:00"
}
// Response
{
  "id": 1,
  "seatId": 1,
  "roomName": "图书馆301",
  "seatNumber": "A12",
  "date": "2026-05-17",
  "startTime": "08:00",
  "endTime": "10:00",
  "status": "PENDING"
}
```

#### POST /api/reservations/check-in
```json
// Request
{ "code": "ABC123" }
// Response
{ "success": true, "reservationId": 1, "message": "签到成功" }
```

**签到校验链路（强约束，Code Agent 必须按此实现）：**
```
1. 根据 code 查 t_check_in_code → 得到 room_id + code_date
2. 校验 code_date = 当日（非当日编码无效）
3. 查当前用户在该 room_id + 当日 的 PENDING 状态预约
4. 校验预约存在，否则返回"您在该教室无待签到预约"
5. 校验当前时间在签到窗口内（预约开始前15min ~ 预约结束时间）
6. 更新预约状态 PENDING → CHECKED_IN
```

#### GET /api/seats/search
```
// Query Params
?date=2026-05-17&startTime=08:00&endTime=10:00
&roomId=1&socketType=FIXED&position=WINDOW
&page=1&size=20
// Response
{
  "records": [
    {
      "seatId": 1,
      "seatNumber": "A12",
      "roomName": "图书馆301",
      "socketType": "FIXED",
      "position": "WINDOW",
      "availableSlots": ["08:00-09:00", "09:00-10:00"]
    }
  ],
  "total": 5,
  "page": 1,
  "size": 20
}
```

#### POST /api/assistant/chat
```json
// Request
{ "message": "今晚有靠窗的空座吗？" }
// Response
{
  "reply": "为您找到以下靠窗空座：\n1. 图书馆301 A12 (有固定插座, 19:00-22:00)\n2. 图书馆301 A15 (无插座, 19:00-22:00)",
  "action": "SEARCH",
  "data": [ ... ]
}
```

#### GET /api/admin/statistics/dashboard
```json
// Response
{
  "todayReservations": 120,
  "todayCheckInRate": 0.85,
  "todayViolationRate": 0.05,
  "weekReservations": 840,
  "weekCheckInRate": 0.82,
  "roomUtilization": [
    { "roomId": 1, "roomName": "图书馆301", "utilization": 0.75 }
  ]
}
```

---

## 5. 编码规范与边界约束

### 5.1 后端编码规范（强约束）

**分层规则：** 请求只能从 Controller → Service → Mapper，严禁跨层调用。

```
Controller  → 接收 Request DTO，返回 Response VO，不包含业务逻辑
Service     → 业务逻辑，事务管理，调用 Mapper，返回 Entity 或 VO
Mapper      → 继承 BaseMapper<Entity>，仅定义自定义 SQL
Entity      → 数据库表映射，@TableName, @TableId, @TableField
Request DTO → 入参校验 @NotBlank, @NotNull, @Size, @Min, @Max
Response VO → 出参封装，不暴露 Entity 内部字段
```

**命名规范：**

| 类型 | 命名规则 | 示例 |
|---|---|---|
| Entity | 名词，与表名对应 | `Room`, `Seat`, `Reservation` |
| Mapper | Entity + Mapper | `RoomMapper` |
| Service | Entity + Service | `RoomService` |
| ServiceImpl | Entity + ServiceImpl | `RoomServiceImpl` |
| Controller | 模块 + Controller | `RoomController`, `AdminRoomController` |
| Request DTO | 动作 + Request | `ReservationCreateRequest` |
| Response VO | Entity + Response | `RoomDetailResponse` |

**方法命名：**

| 操作 | Service 方法 | Mapper 方法 |
|---|---|---|
| 查单个 | `getById` / `getByXxx` | `selectById` |
| 查列表 | `list` / `listByXxx` | `selectList` |
| 分页 | `page` / `pageByXxx` | `selectPage` |
| 创建 | `create` | `insert` |
| 更新 | `update` | `updateById` |
| 删除 | `remove` (逻辑) | `deleteById` |

**业务层外键约束：**
- 严禁在数据库建外键（`FOREIGN KEY`）
- 所有关联关系在 Service 层校验
- 例：创建座位时 `RoomService.exists(roomId)` 校验自习室存在

**统一异常处理：**
- 业务异常抛 `BusinessException`
- 全局 `GlobalExceptionHandler` 捕获并返回 `Result.fail()`
- 禁止在 Controller 写 try-catch

**统一响应：**
- 所有 Controller 返回 `Result<T>`
- 成功：`Result.ok(data)`
- 失败：`Result.fail(code, message)`

### 5.2 前端编码规范

**目录规范：** 页面放 `pages/`，可复用组件放 `components/`，API 调用放 `services/`

**状态管理：** 使用 React Context + hooks，暂不引入 Redux

**座位图组件（核心重点）：**
- 静态网格布局，由管理员配置的行列数决定
- 每个座位显示：编号、状态颜色、插座标记（⚡）、位置标记（🪟/🚶）
- 颜色规范：可选=绿色、已占=灰色、停用=红色、当前选中=蓝色
- 交互：hover 显示详情 tooltip，点击弹出预约时间选择
- 美观要求：间距合理、对齐整齐、图例清晰

**API 调用：**
- 统一通过 `services/api.ts` 的 Axios 实例
- 请求拦截器自动附加 JWT Token
- 响应拦截器统一处理错误码（401 跳登录、403 提示无权限、500 提示服务器错误）

**WebSocket：**
- 通过 `services/websocket.ts` 管理 STOMP 连接
- 登录后自动连接，断线自动重连
- 收到推送消息时通过 Ant Design `message` 组件弹出通知

**路由守卫（强约束，RBAC 前端实现）：**
- 登录后 `GET /api/auth/me` 获取 `userType` + `permissions` 列表
- 路由配置中每个路由标注 `meta.permissions`（如 `['room:manage']`），管理端路由还需 `meta.userType: 'ADMIN'`
- 路由守卫（`beforeEach`）检查逻辑：
  1. 未登录 → 跳转 `/login`
  2. `userType = STUDENT` 访问管理端路由 → 跳转 `403`
  3. 用户 `permissions` 不包含路由所需权限 → 跳转 `403`
- `AdminLayout` 侧边菜单根据 `permissions` 动态渲染（无权限的菜单项不显示）
- 学生端布局 `StudentLayout` 不渲染管理端入口

### 5.3 数据库规范

- 表名统一 `t_` 前缀，小写+下划线
- 字段名小写+下划线
- 所有表包含 `id`(BIGINT AUTO_INCREMENT)、`created_at`、`updated_at`
- 逻辑删除字段 `deleted` (0=未删除, 1=已删除)
- **禁止外键**，业务层约束
- 字符集 `utf8mb4`，排序 `utf8mb4_unicode_ci`
- **Entity 表名映射**：MyBatis Plus 全局配置 `table-prefix: t_`，或每个 Entity 用 `@TableName("t_room")` 标注（二选一，Code Agent 统一使用 `@TableName` 标注）

---

## 6. 定时任务设计

### 6.1 线程池配置

```java
@Configuration
@EnableScheduling
public class SchedulingConfig implements SchedulingConfigurer {
    @Override
    public void configureTasks(ScheduledTaskRegistrar registrar) {
        registrar.setScheduler(scheduledTaskExecutor());
    }

    @Bean(destroyMethod = "shutdown")
    public ScheduledExecutorService scheduledTaskExecutor() {
        return Executors.newScheduledThreadPool(4);
    }
}
```

### 6.2 任务清单

| 任务 | Cron 表达式 | 说明 |
|---|---|---|
| 提前提醒 | 每分钟扫描 | 查找 15min 后开始且 `reminded_before = 0` 的 PENDING 预约，发送后更新 `reminded_before = 1` |
| 逾期警告 | 每分钟扫描 | 查找已开始 10min 且 `warned_late = 0` 的 PENDING 预约，发送后更新 `warned_late = 1` |
| 超时取消 | 每分钟扫描 | 查找已开始 15min 且未签到的 PENDING 预约，状态改为 CANCELLED + 记录违约 |
| 编码生成 | 0 0 0 * * ? | 每日 00:00 为所有开放教室生成当日签到编码 |
| 预约完成 | 每分钟扫描 | 查找已结束且状态为 CHECKED_IN 的预约，状态改为 COMPLETED |

---

## 7. 推送系统设计

### 7.1 双通道架构

```
Service 层调用 NotificationService
        │
        ├── WebSocket (在线用户)
        │   ├── STOMP 推送到 /user/{userId}/queue/notifications
        │   └── 前端订阅并弹出通知
        │
        └── Email (离线兜底)
            ├── JavaMailSender 发送
            └── 异步发送（@Async + 线程池）
```

### 7.2 推送场景

| 场景 | WebSocket | Email | 触发方 |
|---|---|---|---|
| 预约成功 | ✅ | ✅ | ReservationService |
| 提前15min提醒 | ✅ | ✅ | ScheduledTask |
| 逾期10min催促 | ✅ | ✅ | ScheduledTask |
| 逾期15min取消 | ✅ | ✅ | ScheduledTask |
| 管理员取消预约 | ✅ | ✅ | ReservationService |
| 自习室关闭通知 | ✅ | ✅ | RoomService |

---

## 8. 智能助手设计

### 8.1 架构

```
用户输入 → AssistantController → AssistantService
                                    │
                                    ├── LlmClient (调用 LLM API)
                                    │   ├── system prompt: 包含可用 API 列表和座位数据结构
                                    │   └── function calling: 映射到系统查询
                                    │
                                    └── 返回结构化结果
```

### 8.2 LLM API 集成

- **API Key：** 从 `application.yml` 或环境变量读取，配置在 openclaw.json 中
- **API 协议：** OpenAI 兼容格式（`/v1/chat/completions`），支持 function calling
- **请求格式：**
```json
{
  "model": "模型名",
  "messages": [
    {"role": "system", "content": "系统提示词（含可用功能列表）"},
    {"role": "user", "content": "用户消息"}
  ],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "search_seats",
        "description": "搜索可用座位",
        "parameters": { ... }
      }
    }
  ]
}
```
- **System Prompt：** 包含系统功能说明、可用查询类型、返回格式要求
- **意图识别 → 系统调用映射（通过 function calling）：**
  - `search_seats` → `SearchService.search()` — 查询空座、条件搜索（靠窗/有插座）
  - `get_my_reservations` → `ReservationService.listCurrent()` — 查询我的预约
  - `cancel_reservation` → `ReservationService.cancel()` — 取消预约

---

## 9. 开发阶段与细粒度任务

> **强约束（替换原 M1-M7）：开发粒度以用户故事为单位，每个 US 对应一个独立分支、独立 PR、独立验收。**
>
> 执行顺序：US-S01 → US-S02 → ... → US-S11 → US-A01 → ... → US-A06
> 每个 US 完成后：编译通过 → Review 通过 → Test 通过 → 合并 main → 才开始下一个

---

### 学生端用户故事

#### US-S01：查看所有可用自习室及开放时间

| 项 | 内容 |
|---|---|
| **验收标准** | 列表展示自习室名称、位置、开放时间段、当前空座数 |
| **分支** | `feature/US-S01` |
| **后端** | `GET /api/rooms`（仅返回有权限+开放的），含空座数统计 |
| **前端** | `pages/student/RoomList.tsx` 卡片展示 |
| **测试** | 学生登录 → 能看到开放自习室列表；关闭的自习室不可见；无权限院系的自习室不可见 |

#### US-S02：查看座位图并选择座位预约

| 项 | 内容 |
|---|---|
| **验收标准** | 展示座位布局图，可选/不可选状态清晰，点击座位可发起预约 |
| **分支** | `feature/US-S02` |
| **后端** | `GET /api/rooms/{id}`（含座位列表+状态），`GET /api/rooms/{roomId}/seats` |
| **前端** | `pages/student/RoomDetailPage.tsx` + `components/SeatMap/SeatMap.tsx` |
| **测试** | 进入自习室详情 → 座位图网格展示；已占座位灰色不可点；停用座位红色不可点；可用座位绿色可点击 |

#### US-S03：按整点小时预约座位（最多4小时）

| 项 | 内容 |
|---|---|
| **验收标准** | 时间选择器以整点为单位，上限可配置（默认4h），超限提示 |
| **分支** | `feature/US-S03` |
| **后端** | `POST /api/reservations`，冲突检测（区间重叠）+ 最大时长校验（读 SystemConfig）|
| **前端** | 预约时间选择弹窗，整点选项，≤4h 限制，确认提交 |
| **测试** | 正常预约成功；同时段同座位冲突拒绝；超过4h拒绝；非整点拒绝；学生同时段重复预约拒绝 |

#### US-S04：输入教室动态编码签到

| 项 | 内容 |
|---|---|
| **验收标准** | 签到页面输入编码，验证通过后状态变为已签到 |
| **分支** | `feature/US-S04` |
| **后端** | `POST /api/reservations/check-in`（6步校验链路：code→room→当日→预约→时间窗口→更新状态）|
| **前端** | `pages/student/CheckInPage.tsx` 输入框 + 结果反馈 |
| **测试** | 正确编码+时间窗口内签到成功；错误编码失败；超出时间窗口失败；无预约失败 |

#### US-S05：收到预约提醒

| 项 | 内容 |
|---|---|
| **验收标准** | 预约前15min推送提醒；过期10min未签到再次提醒 |
| **分支** | `feature/US-S05` |
| **后端** | 定时任务每分钟扫描：`reminded_before=0` 且15min后开始 → 推送并标记；`warned_late=0` 且开始10min → 推送并标记 |
| **前端** | WebSocket 订阅推送消息，收到后弹出 Ant Design notification |
| **测试** | 创建预约 → 验证15min提醒触发；验证10min逾期催促触发 |

#### US-S06：超时未签到自动取消+通知

| 项 | 内容 |
|---|---|
| **验收标准** | 过期15min自动取消，推送通知，记录违约 |
| **分支** | `feature/US-S06` |
| **后端** | 定时任务：开始15min且PENDING → CANCELLED + 创建 Violation + 推送通知 |
| **前端** | 接收推送通知展示；我的预约页状态自动更新 |
| **测试** | 创建预约不签到 → 15min后状态变CANCELLED → 违约记录存在 → 通知推送 |

#### US-S07：取消预约

| 项 | 内容 |
|---|---|
| **验收标准** | 取消后座位释放；预约开始前取消不记违约；超时15min已自动取消不可手动取消 |
| **分支** | `feature/US-S07` |
| **后端** | `PUT /api/reservations/{id}/cancel`，校验取消规则（时间边界 + 状态校验）|
| **前端** | 我的预约页取消按钮，CANCELLED/CHECKED_IN 状态不显示取消 |
| **测试** | 开始前取消成功不记违约；开始后15min内取消成功不记违约；已超时15min取消失败 |

#### US-S08：多条件搜索座位

| 项 | 内容 |
|---|---|
| **验收标准** | 支持多条件组合搜索，结果含座位编号、可用时间、教室、插座标记、位置标记 |
| **分支** | `feature/US-S08` |
| **后端** | `GET /api/seats/search`（参数：日期、时段、自习室、socketType、position）|
| **前端** | `pages/student/Search.tsx` 多条件表单 + 结果列表 + 点击可预约 |
| **测试** | 各条件单独搜索返回正确结果；组合条件过滤正确；无匹配返回空列表 |

#### US-S09：查看历史预约并再次预约

| 项 | 内容 |
|---|---|
| **验收标准** | 历史列表含座位信息，一键再次预约（如该时段可用）|
| **分支** | `feature/US-S09` |
| **后端** | `GET /api/reservations/history`（分页），`POST /api/reservations/{id}/rebook` |
| **前端** | 我的预约页历史 Tab，再次预约按钮（时段可用则成功，否则提示冲突）|
| **测试** | 历史列表正确展示；再次预约同时段可用时成功；时段已被占用时提示冲突 |

#### US-S10：查看违约记录

| 项 | 内容 |
|---|---|
| **验收标准** | 违约列表含时间、座位、原因 |
| **分支** | `feature/US-S10` |
| **后端** | `GET /api/violations/mine` |
| **前端** | `pages/student/MyViolations.tsx` 列表展示 |
| **测试** | 有违约记录时正确展示；无违约记录时展示空状态 |

#### US-S11：智能助手自然语言交互

| 项 | 内容 |
|---|---|
| **验收标准** | 支持自然语言输入，返回结构化座位信息或执行预约操作 |
| **分支** | `feature/US-S11` |
| **后端** | `POST /api/assistant/chat`，LLM function calling 映射 search_seats / get_my_reservations / cancel_reservation |
| **前端** | `pages/student/Assistant.tsx` 聊天框 + 气泡展示 |
| **测试** | 自然语言查询座位返回结果；查询我的预约返回当前预约；取消预约指令执行成功 |

---

### 管理端用户故事

#### US-A01：登记/注销自习室

| 项 | 内容 |
|---|---|
| **验收标准** | 登记时填写名称、位置、所属院系、开放时间；注销后不再对学生可见 |
| **分支** | `feature/US-A01` |
| **后端** | `POST/PUT/DELETE /api/admin/rooms`，权限：`room:manage` |
| **前端** | `pages/admin/RoomManage.tsx` 表格+新增/编辑弹窗+启停/删除 |
| **测试** | 创建自习室学生端可见；注销后学生端不可见；无权限用户返回403 |

#### US-A02：登记/注销座位

| 项 | 内容 |
|---|---|
| **验收标准** | 座位含唯一编号、位置（行列）、插座类型标记、位置标记（靠窗/靠走廊/中间）；注销后不可预约 |
| **分支** | `feature/US-A02` |
| **后端** | `POST/PUT/DELETE /api/admin/rooms/{roomId}/seats`，权限：`seat:manage` |
| **前端** | `pages/admin/SeatManage.tsx` 座位列表+新增/编辑/停用 |
| **测试** | 创建座位座位图展示；停用座位不可预约；自习室内座位编号唯一 |

#### US-A03：查看预约统计

| 项 | 内容 |
|---|---|
| **验收标准** | 可视化图表展示预约率、使用率、违约率等 |
| **分支** | `feature/US-A03` |
| **后端** | `GET /api/admin/statistics/dashboard`，权限：任意管理员权限 |
| **前端** | `pages/admin/Dashboard.tsx` 图表展示（预约率/签到率/违约率/自习室利用率）|
| **测试** | 仪表盘返回数据结构完整；无预约时率为0不报错 |

#### US-A04：代客预约/取消

| 项 | 内容 |
|---|---|
| **验收标准** | 管理员可代替学生操作，操作记录标注由管理员执行 |
| **分支** | `feature/US-A04` |
| **后端** | `POST /api/admin/reservations`，`PUT /api/admin/reservations/{id}/cancel`，权限：`reservation:manage`，created_by字段标注ADMIN |
| **前端** | 预约管理页代客预约弹窗 + 取消按钮 |
| **测试** | 代客预约成功并标注created_by=ADMIN；无权限用户403 |

#### US-A05：维护角色和权限（RBAC）

| 项 | 内容 |
|---|---|
| **验收标准** | 角色增删改、权限分配、用户-角色绑定 |
| **分支** | `feature/US-A05` |
| **后端** | `/api/admin/roles` CRUD + `/api/admin/users/{id}/roles`，权限：`role:manage`、`user:manage` |
| **前端** | `pages/admin/RoleManage.tsx` + `pages/admin/UserManage.tsx` |
| **测试** | 不同角色登录菜单/接口按权限显示；超权限访问返回403 |

#### US-A06：调整系统参数

| 项 | 内容 |
|---|---|
| **验收标准** | 参数修改即时生效，修改记录可追溯 |
| **分支** | `feature/US-A06` |
| **后端** | `GET/PUT /api/admin/configs`，权限：`system:config` |
| **前端** | `pages/admin/SystemConfigPage.tsx` 参数列表+修改+保存 |
| **测试** | 修改max_reservation_hours=2 → 预约超过2h拒绝；无权限用户403 |

---

## 10. 开发流程强约束（替换原 M1-M7）

### 分支命名
```
feature/US-S01 ... feature/US-S11
feature/US-A01 ... feature/US-A06
```

### 每个 US 完成阈唃
```
[Code] 实现代码
  ↓
[Code] 本地验证：mvn compile 零错 + pnpm build 零错
  ↓
[Review] 审查通过 (✅) — 否则 Code 修复 → 重审
  ↓
[Test] 测试通过 (✅) — 否则 Code 修复 → 重测
  ↓
[PR] 合并 main → 才开始下一个 US
```

### 禁止行为
- ✖ 跳过 Review/Test 直接合并
- ✖ 一个 US 的代码混入另一个 US 的 PR
- ✖ 未编译/未构建通过就推送
- ✖ 跳过用户故事顺序

---

## Changelog

| 日期 | 版本 | 变更 |
|---|---|---|
| 2026-05-16 | v1.0 | Plan 初版，基于 PRD v0.3 产出 |
| 2026-05-16 | v1.1 | Review Agent 审查修复：B01签到校验链路、B02预约冲突区间重叠SQL、B03定时任务推送标记位、B04前端路由守卫RBAC、B05种子数据方案；补充Entity表名映射规则、LLM API协议定义 |
| 2026-06-13 | v2.0 | 强约束：开发粒度由 M1-M7 替换为用户故事（US-S01~S11、US-A01~A06），每个 US 独立分支+PR+验收 |

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M1-B01 | 创建所有数据库表 DDL | `schema.sql` | 11张表全部创建成功，字段/索引/约束符合第3章定义 |
| M1-B02 | 执行种子数据 | `data.sql` | admin账号可登录；4个角色+8个权限+映射+系统参数均已初始化 |
| M1-B03 | 统一返回类 Result<T> | `Result.java` | `Result.ok(data)` / `Result.fail(code, msg)` 可用 |
| M1-B04 | BusinessException + GlobalExceptionHandler | `BusinessException.java`, `GlobalExceptionHandler.java` | 抛出异常后返回标准 JSON，Controller 无 try-catch |
| M1-B05 | MyBatis Plus 配置 | `MyBatisPlusConfig.java` | 分页插件+逻辑删除全局配置生效 |
| M1-B06 | JWT 工具类 | `JwtTokenProvider.java` | 生成token / 解析token / 验证过期 |
| M1-B07 | Spring Security 配置 | `SecurityConfig.java`, `JwtAuthFilter.java`, `UserDetailsServiceImpl.java` | 登录接口匿名访问，其他接口需 JWT；token无效返回401 |
| M1-B08 | 登录接口 | `AuthController.java` + `AuthService.java` | POST /api/auth/login 返回token；GET /api/auth/me 返回用户信息+权限 |
| M1-B09 | 跨域配置 | `CorsConfig.java` | 前端 5173 端口可跨域访问后端 8080 |

#### M1-F: 前端基础

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M1-F01 | Axios 实例 + 拦截器 | `services/api.ts` | 请求自动附 JWT；401跳登录；403/500弹出提示 |
| M1-F02 | 登录页 | `pages/Login.tsx` | 输入用户名密码 → 调用登录接口 → 存储 token → 跳转首页 |
| M1-F03 | 路由配置 + 路由守卫 | `App.tsx` | 未登录→跳登录；STUDENT不可访问管理端；权限不足→403 |
| M1-F04 | 学生端布局 | `layouts/StudentLayout.tsx` | 顶栏(logo+用户名+退出)+内容区，无管理端入口 |
| M1-F05 | 管理端布局 | `layouts/AdminLayout.tsx` | 顶栏+侧边栏(按权限动态渲染)+内容区 |
| M1-F06 | useAuth + usePermissions hooks | `hooks/useAuth.ts`, `hooks/usePermissions.ts` | 获取当前用户信息、判断权限 |

---

### M2: 自习室+座位 (Day 2)

#### M2-B: 后端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M2-B01 | 自习室 Entity + Mapper | `Room.java`, `RoomMapper.java` | MyBatis Plus CRUD 可用 |
| M2-B02 | 院系 Entity + Mapper | `Department.java`, `DepartmentMapper.java` | CRUD 可用 |
| M2-B03 | 自习室 Service（学生端） | `RoomService.java` | 学生端列表仅返回有权限+开放的；详情含座位概览 |
| M2-B04 | 自习室 Service（管理端） | `RoomService.java` | 管理端全量列表+CRUD；注销后逻辑删除 |
| M2-B05 | 自习室 Controller | `RoomController.java`, `AdminRoomController.java` | 6个接口(A-ROOM01~06)全部可用 |
| M2-B06 | 座位 Entity + Mapper | `Seat.java`, `SeatMapper.java` | CRUD 可用；唯一约束(room_id, seat_number) |
| M2-B07 | 座位 Service | `SeatService.java` | 创建时校验自习室存在；学生端返回可用状态；管理端CRUD |
| M2-B08 | 座位 Controller | `SeatController.java`, `AdminSeatController.java` | 5个接口(A-SEAT01~05)全部可用；支持批量创建 |

#### M2-F: 前端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M2-F01 | 自习室列表页(学生) | `pages/student/RoomList.tsx` | 卡片展示：名称、位置、开放时间、空座数/总数 |
| M2-F02 | 自习室详情页(学生) | `pages/student/RoomDetail.tsx` | 展示自习室信息 + 座位图区域（占位，M2-F03接入） |
| M2-F03 | 座位图组件 | `components/SeatMap/SeatMap.tsx`, `Seat.tsx`, `SeatLegend.tsx` | 网格布局展示行列；颜色区分可选/已占/停用；⚡插座/🪟靠窗/🚶靠走廊标记；hover详情tooltip；美观大方整洁 |
| M2-F04 | 自习室管理页(管理) | `pages/admin/RoomManage.tsx` | 表格+新增/编辑弹窗+启停/删除 |
| M2-F05 | 座位管理页(管理) | `pages/admin/SeatManage.tsx` | 按自习室查看座位列表+新增/编辑/停用；座位图编辑模式 |

---

### M3: 预约核心 (Day 3)

#### M3-B: 后端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M3-B01 | 预约 Entity + Mapper | `Reservation.java`, `ReservationMapper.java` | 含 reminded_before/warned_late 字段；3个索引创建 |
| M3-B02 | 预约 Service — 创建 | `ReservationService.create()` | 冲突检测(区间重叠SQL)+开放时间校验+院系权限校验+最大时长校验；@Transactional |
| M3-B03 | 预约 Service — 取消 | `ReservationService.cancel()` | 预约开始前/后15min内取消不记违约；超15min系统已取消不可手动取消 |
| M3-B04 | 预约 Service — 查询 | `ReservationService` | 我的当前预约/历史预约(分页)/再次预约 |
| M3-B05 | 预约 Controller（学生端） | `ReservationController.java` | A-RES01~06 全部可用 |
| M3-B06 | 预约 Controller（管理端） | `AdminReservationController.java` | A-RES07~09 全部可用；代客预约标注created_by |

#### M3-F: 前端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M3-F01 | 预约时间选择 + 确认页 | `pages/student/Reservation.tsx` | 点击座位→弹出时间选择(整点、≤4h)→确认→调用创建接口 |
| M3-F02 | 我的预约页 | `pages/student/MyReservations.tsx` | 当前预约(可签到/取消)+历史预约(可再次预约) |
| M3-F03 | 预约管理页(管理) | `pages/admin/ReservationManage.tsx` | 全局预约列表+筛选+代客预约/取消入口 |

---

### M4: 签到+提醒+推送 (Day 4)

#### M4-B: 后端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M4-B01 | 签到编码 Entity + Mapper | `CheckInCode.java`, `CheckInCodeMapper.java` | CRUD可用；唯一约束(room_id, code_date) |
| M4-B02 | 签到编码生成 | `CheckInService.generateDailyCodes()` | 每日00:00为所有OPEN教室生成6位随机编码 |
| M4-B03 | 签到功能 | `CheckInService.checkIn()` | 按签到校验链路(6步)执行；校验窗口+预约存在性 |
| M4-B04 | 签到编码 Controller | `CheckInCodeController.java` | A-CODE01 管理端查看当日编码 |
| M4-B05 | WebSocket 配置 | `WebSocketConfig.java` | STOMP端点配置；前端可连接 |
| M4-B06 | NotificationService | `NotificationService.java` | 双通道推送：WebSocket(在线)+Email(离线兜底)；@Async邮件发送 |
| M4-B07 | 定时任务 — 提前提醒 | `ReservationReminderTask.remindBefore()` | 扫描15min后开始+reminded_before=0→推送+更新为1 |
| M4-B08 | 定时任务 — 逾期催促 | `ReservationReminderTask.warnLate()` | 扫描开始10min+warned_late=0→推送+更新为1 |
| M4-B09 | 定时任务 — 超时取消 | `ReservationExpireTask.expireAndCancel()` | 扫描开始15min+PENDING→CANCELLED+记违约+推送+释放座位 |
| M4-B10 | 定时任务 — 预约完成 | `ReservationExpireTask.completeReservation()` | 扫描已结束+CHECKED_IN→COMPLETED |
| M4-B11 | 违约 Entity + Mapper + Service | `Violation.java`, `ViolationMapper.java`, `ViolationService.java` | 自动记录+查询(我的/全局) |
| M4-B12 | 违约 Controller | `ViolationController.java` | A-VIO01~02 可用 |

#### M4-F: 前端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M4-F01 | 签到页 | `pages/student/CheckIn.tsx` | 输入编码→调用签到接口→成功/失败反馈 |
| M4-F02 | WebSocket 连接管理 | `services/websocket.ts`, `hooks/useWebSocket.ts` | 登录后连接；断线重连；收到消息弹出 Ant Design 通知 |
| M4-F03 | 签到编码查看页(管理) | `pages/admin/CheckInCode.tsx` | 按教室查看当日编码 |
| M4-F04 | 违约记录页(学生) | `pages/student/Violations.tsx` | 个人违约列表 |
| M4-F05 | 违约管理页(管理) | `pages/admin/ViolationManage.tsx` | 全局违约列表+筛选 |

---

### M5: RBAC+搜索+管理端 (Day 5)

#### M5-B: 后端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M5-B01 | 角色 Entity + Mapper | `Role.java`, `RoleMapper.java` | CRUD可用 |
| M5-B02 | 权限 Entity + Mapper | `Permission.java`, `PermissionMapper.java` | 查询可用 |
| M5-B03 | 用户角色关联 | `UserRole.java`, `UserRoleMapper.java` | 绑定/解绑 |
| M5-B04 | 角色权限关联 | `RolePermission.java`, `RolePermissionMapper.java` | 绑定/解绑 |
| M5-B05 | RoleService | `RoleService.java` | 角色CRUD+权限分配；获取用户权限列表(多角色取并集) |
| M5-B06 | RBAC Controller | `RoleController.java`, `UserController.java` | A-RBAC01~06 可用 |
| M5-B07 | 搜索 Service | `SearchService.java` | 多条件组合查询(日期/时段/自习室/插座/位置/院系) |
| M5-B08 | 搜索 Controller | `SearchController.java` | A-SCH01 可用，返回座位+可用时段 |
| M5-B09 | 系统参数 Service | `SystemConfigService.java` | KV读取+批量更新；修改即时生效 |
| M5-B10 | 系统参数 Controller | `SystemConfigController.java` | A-CONF01~02 可用 |
| M5-B11 | 统计 Service | `StatisticsService.java` | 今日/本周预约率/签到率/违约率/自习室利用率 |
| M5-B12 | 统计 Controller | `StatisticsController.java` | A-STAT01 可用 |

#### M5-F: 前端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M5-F01 | 搜索页(学生) | `pages/student/Search.tsx` | 多条件表单(日期/时段/插座/位置/自习室)→结果列表→点击可预约 |
| M5-F02 | 角色管理页(管理) | `pages/admin/RoleManage.tsx` | 角色列表+新增/编辑+勾选权限 |
| M5-F03 | 用户管理页(管理) | `pages/admin/UserManage.tsx` | 用户列表+分配/移除角色 |
| M5-F04 | 系统参数页(管理) | `pages/admin/SystemConfig.tsx` | 参数列表+修改+保存 |
| M5-F05 | 仪表盘(管理) | `pages/admin/Dashboard.tsx` | 统计图表(预约率/签到率/违约率/自习室利用率) |

---

### M6: 智能助手 (Day 6)

#### M6-B: 后端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M6-B01 | LlmClient | `ai/LlmClient.java` | 可调用 OpenAI 兼容 /v1/chat/completions；支持 function calling |
| M6-B02 | System Prompt 设计 | — | 包含功能说明+可用工具列表+返回格式 |
| M6-B03 | function calling — search_seats | `AssistantService.java` | LLM返回search_seats → 调用SearchService.search() → 返回结果给LLM |
| M6-B04 | function calling — get_my_reservations | `AssistantService.java` | LLM返回get_my_reservations → 调用ReservationService.listCurrent() |
| M6-B05 | function calling — cancel_reservation | `AssistantService.java` | LLM返回cancel_reservation → 调用ReservationService.cancel() |
| M6-B06 | 对话接口 | `AssistantController.java` | POST /api/assistant/chat → 返回自然语言回复+结构化数据 |

#### M6-F: 前端

| 编号 | 任务 | 产出 | 验收标准 |
|---|---|---|---|
| M6-F01 | 聊天框组件 | `components/ChatBox/ChatBox.tsx`, `MessageBubble.tsx` | 消息输入框+对话气泡(用户/AI) |
| M6-F02 | 智能助手页 | `pages/student/Assistant.tsx` | 嵌入ChatBox→调用对话接口→展示结果 |

---

### M7: 联调+交付 (Day 7)

| 编号 | 任务 | 验收标准 |
|---|---|---|
| M7-01 | 前后端全流程联调 | 学生端：登录→查看自习室→选座预约→签到→查看预约→搜索→智能助手；管理端：登录→仪表盘→CRUD→RBAC |
| M7-02 | 定时任务验证 | 创建预约→等待提醒推送→超时自动取消+违约记录 |
| M7-03 | RBAC 验证 | 不同角色登录→菜单/页面/接口均符合权限 |
| M7-04 | Bug 修复 | 所有发现的 Bug 修复完成 |
| M7-05 | 部署验证 | 本地启动前后端，全流程可走通 |
| M7-06 | 代码提交+推送 | 前后端代码提交到 GitHub，编译通过+启动成功 |

---

## Changelog

| 日期 | 版本 | 变更 |
|---|---|---|
| 2026-05-16 | v1.0 | Plan 初版，基于 PRD v0.3 产出 |
| 2026-05-16 | v1.1 | Review Agent 审查修复：B01签到校验链路、B02预约冲突区间重叠SQL、B03定时任务推送标记位(reminded_before/warned_late)、B04前端路由守卫RBAC、B05种子数据方案；补充Entity表名映射规则、LLM API协议定义 |
| 2026-05-16 | v1.2 | 里程碑细粒度拆分：7个阶段(M1-M7)、62个原子任务，每个任务含编号/产出/验收标准 |
