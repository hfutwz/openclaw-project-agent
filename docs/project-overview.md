# SeatFlow 自习座位预约系统 — 项目全览

> **技术栈：** Spring Boot 3 + React 19 + MySQL 8
> **开发模式：** Vibe Coding — AI 多 Agent 协作全链路软件开发

---

## 目录

1. [Vibe Coding 架构与开发模式](#1-vibe-coding-架构与开发模式)
2. [PRD → Plan → Review / Code + Test 闭环流程](#2-prd--plan--review--code--test-闭环流程)
3. [PRD 用户故事](#3-prd-用户故事)
4. [ER 图与数据库表设计](#4-er-图与数据库表设计)
5. [Plan 接口定义](#5-plan-接口定义)
6. [Code Agent 实现：用户故事 → 代码](#6-code-agent-实现用户故事--代码)
   - [6.1 学生端（US-S01 ~ US-S11）](#61-学生端-us-s01--us-s11)
   - [6.2 管理端（US-A01 ~ US-A06）](#62-管理端-us-a01--us-a06)

---

## 1. Vibe Coding 架构与开发模式

SeatFlow 采用 **Vibe Coding** 理念：人类负责需求与方向，AI Agent 负责规划、编码、审查、测试，形成全链路自动化软件开发流水线。

### 1.1 Agent 角色分工

```
                    ┌─────────────────────────────────┐
                    │        Orchestrator（编排器）      │
                    │   调度所有子 Agent，守门，不写代码   │
                    └──────────────┬──────────────────┘
                                   │
          ┌──────────┬─────────────┼─────────────┬──────────────┐
          ▼          ▼                           ▼              ▼
    ┌──────────┐ ┌──────────┐          ┌──────────────┐ ┌──────────────┐
    │Plan Agent│ │Code Agent│          │Review Agent  │ │ Test Agent   │
    │需求→PRD  │ │全栈开发  │          │纯只读审查    │ │基于PRD写测试 │
    └──────────┘ └──────────┘          └──────────────┘ └──────────────┘
                                                ▼
                                    ┌──────────────────────┐
                                    │  Delivery Agent      │
                                    │  最终交付验证（5维度） │
                                    └──────────────────────┘
                                    ┌──────────────────────┐
                                    │  UI Research Agent   │
                                    │  前端UI/UX调研（独立）│
                                    └──────────────────────┘
```

| Agent | 职责 | 工作目录 |
|---|---|---|
| Orchestrator | 编排调度，守门（PRD 未确认不启动代码） | 项目根目录 |
| Plan Agent | 需求澄清 → 输出 PRD，迭代修改直到用户确认 | `plan-agent/` → `prd/` |
| Code Agent | 按用户故事顺序全栈实现（前端 + 后端并行） | `code-agent/` |
| Review Agent | 纯只读审查 PRD/Plan/代码，五维度评分 | `review-agent/` |
| Test Agent | 基于 PRD 编写测试用例，代码完成后执行 | `test-agent/` |
| Delivery Agent | 所有 US 合并后最终验证，5维度 100分考核 | `delivery-agent/` |
| UI Research Agent | 调研座位图/两端体感/AI助手界面，输出落地建议 | `ui-research-agent/` |

### 1.2 技术架构

```
┌──────────────────────────────────────────────┐
│              前端（React 19 + Ant Design 5）   │
│  学生端（任务导向）     管理端（数据密集型）     │
│  /student/*            /admin/*              │
└──────────────────────────────────────────────┘
                       │ REST API / WebSocket
┌──────────────────────────────────────────────┐
│         后端（Spring Boot 3 + Java 21）        │
│  Spring Security（JWT + RBAC）                │
│  MyBatis Plus（分页/逻辑删除）                 │
│  Spring Scheduling（定时任务）                 │
│  WebSocket STOMP（实时推送）                   │
│  LLM API（OpenAI 兼容，function calling）      │
└──────────────────────────────────────────────┘
                       │
┌──────────────────────────────────────────────┐
│              MySQL 8（11张表）                 │
└──────────────────────────────────────────────┘
```

---

## 2. PRD → Plan → Review / Code + Test 闭环流程

### 2.1 整体流水线

```
用户提需求
    │
    ▼
[1] Plan Agent → 产出 PRD → 用户人工确认 ✅（未确认绝不启动代码）
    │
    ├──────────────────────────────────────┐
    ▼                                      ▼
[2] Code Agent（按 US 顺序开发）      [3] Test Agent（基于 PRD 并行写测试用例）
    │（每个 US 完成后）                    │
    ▼                                      │
[4] Review Agent ◄─────────────────────────┘
    ✅ 通过 → 合并 main → 开始下一个 US
    ⚠️ 问题 → Code Agent 修复 → 重审
    │
    ▼（所有 US 完成）
[5] Delivery Agent → 5维度 100分验证
    ✅ 可交付 → 部署
    ⚠️ P0 问题 → Code Agent 修复 → 重验
```

### 2.2 每个用户故事的完成门槛

```
[Code] 实现代码（feature/US-Sxx 分支）
  ↓
[Code] 本地验证：mvn compile 零错误 + pnpm build 零错误
  ↓
[Review] 五维度审查通过（代码质量30/安全25/架构20/边界15/性能10）
  ↓
[Test] 测试用例全部通过
  ↓
[PR] 合并 main → 推送 GitHub + 华为云前端 + 华为云后端
  ↓
开始下一个 US
```

### 2.3 Review Agent 五维度评分

| 维度 | 权重 | 关注点 |
|---|---|---|
| 代码质量 | 30% | 命名、结构、可读性、DRY |
| 安全性 | 25% | SQL注入、认证鉴权、敏感数据、输入校验 |
| 架构一致性 | 20% | 与 PRD/Plan 一致性、分层正确性 |
| 边界情况 | 15% | 错误处理、异常路径、并发安全 |
| 性能 | 10% | N+1查询、全量加载、内存风险 |

---

## 3. PRD 用户故事

### 3.1 学生端（US-S01 ~ US-S11）

| 编号 | 用户故事 | 验收标准 | 优先级 |
|---|---|---|---|
| **US-S01** | 作为学生，我想查看所有可用自习室及其开放时间 | 列表展示自习室名称、位置、开放时间段、当前空座数 | P0 |
| **US-S02** | 作为学生，我想查看某个自习室的座位图并选择座位预约 | 展示座位布局图，可选/不可选状态清晰，点击座位可发起预约 | P0 |
| **US-S03** | 作为学生，我想按整点小时预约座位（最多4小时） | 时间选择器以整点为单位，上限可配置（默认4h），超限提示 | P0 |
| **US-S04** | 作为学生，我想通过输入教室动态编码签到 | 签到页面输入编码，验证通过后状态变为已签到 | P0 |
| **US-S05** | 作为学生，我想收到预约提醒，以免错过签到 | 预约前15min推送提醒；过期10min未签到再次提醒 | P0 |
| **US-S06** | 作为学生，如果超时未签到，我想知道预约被取消了 | 过期15min自动取消，推送通知，记录违约 | P0 |
| **US-S07** | 作为学生，我想取消自己的预约以释放座位 | 取消后座位释放；开始前取消不记违约；超时15min不可取消 | P0 |
| **US-S08** | 作为学生，我想多条件搜索座位 | 支持多条件组合搜索，结果含编号、可用时间、插座标记、位置标记 | P0 |
| **US-S09** | 作为学生，我想查看预约历史并快速再次预约同一座位 | 历史列表含座位信息，一键再次预约（如该时段可用） | P0 |
| **US-S10** | 作为学生，我想查看自己的违约记录 | 违约列表含时间、座位、原因 | P2 |
| **US-S11** | 作为学生，我想通过自然语言与智能助手对话来查询和预约座位 | 支持自然语言输入，返回结构化座位信息或执行预约操作 | P1 |

### 3.2 管理端（US-A01 ~ US-A06）

| 编号 | 用户故事 | 验收标准 | 优先级 |
|---|---|---|---|
| **US-A01** | 作为管理员，我想登记/注销自习室 | 登记时填写名称、位置、院系、开放时间；注销后不再对学生可见 | P0 |
| **US-A02** | 作为管理员，我想登记/注销座位（含位置标记） | 座位含唯一编号、行列、插座类型、位置标记；注销后不可预约 | P0 |
| **US-A03** | 作为管理员，我想查看预约情况统计 | 可视化图表展示预约率、使用率、违约率等 | P0 |
| **US-A04** | 作为管理员，我想为用户代约或取消预约 | 管理员可代替学生操作，操作记录标注由管理员执行 | P2 |
| **US-A05** | 作为管理员，我想维护角色和权限（RBAC） | 角色增删改、权限分配、用户-角色绑定 | P0 |
| **US-A06** | 作为管理员，我想调整系统参数 | 参数修改即时生效，修改记录可追溯 | P2 |

---

## 4. ER 图与数据库表设计

### 4.1 实体关系图（ER）

```
┌──────────┐     ┌──────────────┐     ┌──────────┐
│   User   │────<│ Reservation  │>────│   Seat   │
│          │     └──────────────┘     └────┬─────┘
│          │                               │ N:1
│          │     ┌──────────────┐     ┌────▼─────┐
│          │────<│  Violation   │     │   Room   │>──┐
│          │     └──────────────┘     └──────────┘   │ N:1
│          │                                         │
│          │     ┌──────────┐     ┌────────────┐    │
│          ├────<│UserRole  │────>│    Role    │  ┌─▼──────────┐
│          │     └──────────┘     └─────┬──────┘  │Department  │
└──────────┘                            │         └────────────┘
                               ┌────────▼──────┐
                               │RolePermission │
                               └────────┬──────┘
                                        │
                               ┌────────▼──────┐
                               │  Permission   │
                               └───────────────┘

┌──────────────┐   ┌──────────────┐
│ CheckInCode  │   │ SystemConfig │  （独立KV表）
└──────────────┘   └──────────────┘
```

### 4.2 数据库表（共 11 张）

#### t_user（用户表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| username | VARCHAR(50) UNIQUE | 用户名 |
| password | VARCHAR(255) | BCrypt 加密 |
| real_name | VARCHAR(50) | 真实姓名 |
| email | VARCHAR(100) | 邮箱（推送用） |
| department_id | BIGINT | 院系ID（空=全校共享） |
| user_type | VARCHAR(20) | STUDENT / ADMIN |
| deleted | TINYINT | 逻辑删除 |

#### t_department（院系表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| name | VARCHAR(100) UNIQUE | 院系名称 |
| deleted | TINYINT | 逻辑删除 |

#### t_room（自习室表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| name | VARCHAR(100) | 自习室名称 |
| location | VARCHAR(200) | 位置描述 |
| department_id | BIGINT | 所属院系（空=全校共享） |
| open_time | TIME | 每日开放时间（默认07:00） |
| close_time | TIME | 每日关闭时间（默认22:00） |
| status | VARCHAR(20) | OPEN / CLOSED |
| deleted | TINYINT | 逻辑删除 |

#### t_seat（座位表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| room_id | BIGINT | 所属自习室（业务层外键） |
| seat_number | VARCHAR(20) | 座位编号（自习室内唯一） |
| row_num / col_num | INT | 行列位置 |
| socket_type | VARCHAR(20) | NONE / FIXED / TRACK |
| position | VARCHAR(20) | WINDOW / CORRIDOR / MIDDLE |
| status | VARCHAR(20) | AVAILABLE / DISABLED |
| deleted | TINYINT | 逻辑删除 |

**唯一约束：** `UNIQUE(room_id, seat_number)`

#### t_reservation（预约表）⭐ 核心表
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| user_id / seat_id / room_id | BIGINT | 关联（业务层外键，room_id 冗余方便查询） |
| date | DATE | 预约日期 |
| start_time / end_time | TIME | 整点时间段 |
| status | VARCHAR(20) | PENDING / CHECKED_IN / COMPLETED / CANCELLED |
| cancelled_by | VARCHAR(20) | STUDENT / ADMIN / SYSTEM |
| reminded_before | TINYINT | 是否已发15min提醒（防重发） |
| warned_late | TINYINT | 是否已发10min催促（防重发） |

**冲突检测 SQL（强约束）：**
```sql
-- 座位时段冲突
SELECT COUNT(*) FROM t_reservation
WHERE seat_id = #{seatId} AND date = #{date}
  AND status IN ('PENDING', 'CHECKED_IN') AND deleted = 0
  AND start_time < #{newEndTime} AND end_time > #{newStartTime}
```

**索引：**
- `INDEX(seat_id, date, start_time, end_time)` — 冲突检测
- `INDEX(user_id, date, start_time)` — 用户同时段检查
- `INDEX(status, date, start_time)` — 定时任务扫描

#### t_check_in_code（签到编码表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| room_id | BIGINT | 所属教室 |
| code_date | DATE | 编码日期 |
| code | VARCHAR(10) | 6位动态编码 |

**唯一约束：** `UNIQUE(room_id, code_date)`

#### t_violation（违约表）
| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | 主键 |
| user_id / reservation_id | BIGINT | 关联用户和预约 |
| type | VARCHAR(30) | CHECK_IN_TIMEOUT |
| created_at | DATETIME | 违约时间 |

#### RBAC 三张表：t_role / t_permission / t_user_role / t_role_permission
- **t_role**：角色（SUPER_ADMIN / ADMIN / VIEWER / STUDENT）
- **t_permission**：8种权限码（room:manage / seat:manage / reservation:manage / checkin:manage / violation:manage / user:manage / role:manage / system:config）
- **t_user_role**：用户-角色 N:M，`UNIQUE(user_id, role_id)`
- **t_role_permission**：角色-权限 N:M，`UNIQUE(role_id, permission_id)`

#### t_system_config（系统参数表）
| 字段 | 类型 | 说明 |
|---|---|---|
| config_key | VARCHAR(100) UNIQUE | 参数键（如 max_reservation_hours） |
| config_value | VARCHAR(200) | 参数值 |
| description | VARCHAR(200) | 说明 |

---

## 5. Plan 接口定义

### 5.1 统一响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

### 5.2 认证接口
| 接口 | 方法 | 说明 |
|---|---|---|
| `/api/auth/login` | POST | 登录，返回 JWT token + userInfo（含 roles/permissions） |
| `/api/auth/me` | GET | 获取当前用户信息+权限列表 |

### 5.3 学生端接口
| 接口 | 方法 | 说明 | 对应 US |
|---|---|---|---|
| `/api/rooms` | GET | 有权限+开放的自习室列表（含空座数） | US-S01 |
| `/api/rooms/{id}` | GET | 自习室详情（含座位列表+状态） | US-S02 |
| `/api/rooms/{roomId}/seats` | GET | 座位列表（含当日可用状态） | US-S02 |
| `/api/reservations` | POST | 创建预约（含冲突检测+时长校验+院系权限） | US-S03 |
| `/api/reservations/check-in` | POST | 签到（6步校验链路） | US-S04 |
| `/api/reservations/current` | GET | 我的当前预约 | US-S07 |
| `/api/reservations/history` | GET | 我的历史预约（分页） | US-S09 |
| `/api/reservations/{id}/cancel` | PUT | 取消预约（含边界规则） | US-S07 |
| `/api/reservations/{id}/rebook` | POST | 再次预约同一座位 | US-S09 |
| `/api/seats/search` | GET | 多条件搜索座位 | US-S08 |
| `/api/violations/mine` | GET | 我的违约记录 | US-S10 |
| `/api/assistant/chat` | POST | 智能助手对话（LLM function calling） | US-S11 |

### 5.4 管理端接口
| 接口 | 方法 | 说明 | 对应 US |
|---|---|---|---|
| `/api/admin/rooms` | POST/PUT/DELETE | 自习室 CRUD | US-A01 |
| `/api/admin/rooms/{roomId}/seats` | POST/PUT/DELETE | 座位 CRUD | US-A02 |
| `/api/admin/statistics/dashboard` | GET | 仪表盘统计数据 | US-A03 |
| `/api/admin/reservations` | GET | 全局预约列表 | US-A04 |
| `/api/admin/reservations` | POST | 代客预约（标注 created_by=ADMIN） | US-A04 |
| `/api/admin/reservations/{id}/cancel` | PUT | 代客取消 | US-A04 |
| `/api/admin/roles` | GET/POST/PUT/DELETE | 角色 CRUD | US-A05 |
| `/api/admin/users/{id}/roles` | PUT | 用户-角色绑定 | US-A05 |
| `/api/admin/users` | GET | 用户列表 | US-A05 |
| `/api/admin/configs` | GET/PUT | 系统参数读取/更新 | US-A06 |

### 5.5 定时任务
| 任务 | 触发条件 | 动作 |
|---|---|---|
| 提前提醒 | 预约开始前15min，`reminded_before=0` | 推送 + 标记 `reminded_before=1` |
| 逾期催促 | 开始后10min未签到，`warned_late=0` | 推送 + 标记 `warned_late=1` |
| 超时取消 | 开始后15min，状态 PENDING | 取消 + 创建 Violation + 推送通知 |
| 签到码生成 | 每日 00:00 | 所有 OPEN 自习室生成6位随机编码 |

---

## 6. Code Agent 实现：用户故事 → 代码

> **开发强约束：** 每个 US 独立分支（`feature/US-Sxx`），通过 Review + Test 合并 main 后才开始下一个。

### 6.1 学生端（US-S01 ~ US-S11）

#### US-S01：查看所有可用自习室及开放时间

**后端实现**
- `RoomController.GET /api/rooms` → `RoomService.listAvailableForStudent(userId)`
- 查询条件：`status=OPEN AND deleted=0 AND (department_id IS NULL OR department_id=user.department_id)`
- 响应含：自习室信息 + 空座数（子查询统计 `status=AVAILABLE` 的座位数）

**前端实现**
- `pages/student/RoomList.tsx`
- Ant Design Card 组件卡片布局，展示：名称、位置、开放时间、空座/总座数 badge

---

#### US-S02：查看座位图并选择座位预约

**后端实现**
- `RoomController.GET /api/rooms/{id}` — 自习室详情
- `SeatController.GET /api/rooms/{roomId}/seats` — 座位列表（含当日预约状态计算）

**前端实现**
- `pages/student/RoomDetailPage.tsx` + `components/SeatMap/SeatMap.tsx`
- 座位图网格布局（按 row_num/col_num 排列）
- 状态颜色：🟢可选 / ⬜已占 / 🔴停用 / 🔵我的预约
- 属性图标：⚡有插座 / 🪟靠窗 / 🚶靠走廊
- Hover tooltip 显示座位编号和属性

---

#### US-S03：按整点小时预约座位（最多4小时）

**后端实现**
- `ReservationController.POST /api/reservations`
- `ReservationService.create()` 内 `@Transactional` 执行：
  1. 院系权限校验
  2. 自习室开放时间校验
  3. 预约时长校验（读 SystemConfig.max_reservation_hours）
  4. 座位冲突检测（区间重叠 SQL）
  5. 学生同时段冲突检测
  6. 插入预约记录

**前端实现**
- 点击座位图 → 弹出时间选择 Modal
- 整点小时下拉（08:00~22:00）+ 结束时间自动计算
- 超过4小时禁用确认按钮

---

#### US-S04：输入教室动态编码签到

**后端实现**
- `CheckInController.POST /api/reservations/check-in`
- `CheckInService.checkIn()` 6步校验链路：
  1. 查询 code → 验证编码存在
  2. code → 获取 room_id
  3. 验证 code_date = 今日
  4. 查询用户在该自习室的 PENDING 预约
  5. 验证当前时间在签到窗口内（开始前15min ~ 结束时间）
  6. 更新预约状态为 CHECKED_IN

**前端实现**
- `pages/student/CheckInPage.tsx`
- 6位编码输入框，提交后显示成功/失败结果 + 对应图标

---

#### US-S05：收到预约提醒（15min前 / 逾期10min）

**后端实现**
- `@Scheduled` 每分钟扫描
- 提前提醒：`WHERE status=PENDING AND reminded_before=0 AND (date+start_time - NOW()) BETWEEN 0 AND 15min`
- 逾期催促：`WHERE status=PENDING AND warned_late=0 AND (NOW() - date+start_time) BETWEEN 10 AND 15min`
- `NotificationService.push()` — WebSocket 在线推送 + 邮件离线兜底（`@Async`）

**前端实现**
- `services/websocket.ts` — STOMP 连接，登录后建立，断线重连
- 收到推送消息 → Ant Design `notification.open()` 弹出提醒

---

#### US-S06：超时未签到自动取消 + 通知

**后端实现**
- `@Scheduled` 每分钟扫描
- 条件：`status=PENDING AND (NOW() - date+start_time) > 15min`
- 动作：`status → CANCELLED`，`cancelled_by = SYSTEM`，创建 `t_violation`，推送通知

**前端实现**
- 接收 WebSocket 推送通知展示
- 我的预约页状态实时更新（轮询或 WS 事件触发刷新）

---

#### US-S07：取消预约

**后端实现**
- `ReservationController.PUT /api/reservations/{id}/cancel`
- 取消规则校验：
  - `status=PENDING` 才可取消
  - `NOW() - start_time ≤ 15min` 则允许（不记违约）
  - 超过15min则系统已自动取消，返回错误

**前端实现**
- `pages/student/MyReservations.tsx` 当前预约列表
- 取消按钮仅在 `status=PENDING` 时显示

---

#### US-S08：多条件搜索座位

**后端实现**
- `SeatSearchController.GET /api/seats/search`
- 参数：`date / startTime / endTime / roomId / socketType / position`
- `SeatSearchService` 动态拼接 SQL：查询在该时段无 PENDING/CHECKED_IN 预约的座位

**前端实现**
- `pages/student/Search.tsx`
- Ant Design Form 多条件筛选（日期选择/时间段/自习室/插座类型/位置）
- 结果列表卡片，点击可直接进入预约流程

---

#### US-S09：查看历史预约并再次预约

**后端实现**
- `ReservationController.GET /api/reservations/history` — 分页，按 date DESC
- `ReservationController.POST /api/reservations/{id}/rebook` — 复用历史预约的 seat_id，重新走 create 逻辑（含冲突检测）

**前端实现**
- `pages/student/MyReservations.tsx` — Tab 切换：当前预约 / 历史预约
- 历史列表每条显示"再次预约"按钮

---

#### US-S10：查看违约记录

**后端实现**
- `ViolationController.GET /api/violations/mine`
- 返回：违约时间、座位编号、自习室名称、违约类型

**前端实现**
- `pages/student/MyViolations.tsx`
- Ant Design Table 展示，无记录时显示友好空状态

---

#### US-S11：智能助手自然语言交互

**后端实现**
- `AssistantController.POST /api/assistant/chat`
- `LlmClient` 调用 OpenAI 兼容 `/v1/chat/completions`（function calling 模式）
- 3个工具函数：
  - `search_seats` → `SeatSearchService.search()`
  - `get_my_reservations` → `ReservationService.listCurrent()`
  - `cancel_reservation` → `ReservationService.cancel()`

**前端实现**
- `pages/student/Assistant.tsx`
- 聊天框：用户气泡（右侧）/ AI 气泡（左侧）/ 打字机动效
- 快捷 chip：「找靠窗有插座的座位」「我今天的预约」「取消预约」

---

### 6.2 管理端（US-A01 ~ US-A06）

#### US-A01：登记/注销自习室

**后端实现**
- `AdminRoomController` — CRUD 接口，权限：`@PreAuthorize("hasAuthority('room:manage')")`
- 注销 = 逻辑删除（`deleted=1`，`status=CLOSED`）

**前端实现**
- `pages/admin/RoomManage.tsx`
- Ant Design Table + 新增/编辑 Modal（表单：名称/位置/院系/开放时间）+ 启停/删除操作列

---

#### US-A02：登记/注销座位（含位置标记）

**后端实现**
- `AdminSeatController` — CRUD，权限：`seat:manage`
- 创建时校验：`seat_number` 在同 room 下唯一

**前端实现**
- `pages/admin/SeatManage.tsx`
- 按自习室筛选座位列表，新增时填写编号/行列/插座类型/位置标记

---

#### US-A03：查看预约统计仪表盘

**后端实现**
- `AdminDashboardController.GET /api/admin/statistics/dashboard`
- `DashboardService` 聚合查询：今日预约总数、签到率、违约率、各自习室利用率

**前端实现**
- `pages/admin/Dashboard.tsx`
- Ant Design 统计卡片（数字大字展示）+ 折线图/柱状图（使用 Ant Design Charts 或 ECharts）

---

#### US-A04：代客预约/取消

**后端实现**
- `AdminReservationController.POST /api/admin/reservations` — 代客预约，`created_by = ADMIN`
- `AdminReservationController.PUT /api/admin/reservations/{id}/cancel` — 代客取消，`cancelled_by = ADMIN`

**前端实现**
- `pages/admin/ReservationManage.tsx`
- 全局预约列表 + 筛选（用户/日期/状态）+ 代客预约弹窗 + 取消按钮

---

#### US-A05：维护角色和权限（RBAC）

**后端实现**
- `AdminRoleController` — 角色 CRUD，权限分配
- `AdminUserController` — 用户列表，用户-角色绑定
- 4种预置角色：`SUPER_ADMIN / ADMIN / VIEWER / STUDENT`
- 8种权限粒度：`room:manage / seat:manage / reservation:manage / checkin:manage / violation:manage / user:manage / role:manage / system:config`

**前端实现**
- `pages/admin/RoleManage.tsx` — 角色列表 + 权限勾选 Checkbox
- `pages/admin/UserManage.tsx` — 用户列表 + 角色分配 Select
- 管理端侧边栏按用户权限动态渲染（无权限项灰化隐藏）

---

#### US-A06：调整系统参数

**后端实现**
- `AdminConfigController.GET /api/admin/configs` — 参数列表
- `AdminConfigController.PUT /api/admin/configs` — 批量更新（修改即时生效，`SystemConfigService` 内存缓存刷新）

**前端实现**
- `pages/admin/SystemConfigPage.tsx`
- 参数列表（key / value / 说明）+ 行内编辑 + 保存

---

## 附录

### 默认账号
| 账号 | 密码 | 角色 |
|---|---|---|
| admin | admin123 | SUPER_ADMIN |
| student1 | student123 | STUDENT（计算机学院） |
| student2 | student123 | STUDENT（电子工程学院） |

### 分支规范
| 分支 | 用途 |
|---|---|
| `main` | 稳定版本，经过 Review + Test |
| `feature/wz_dev_main` | 当前主开发分支 |
| `feature/US-S01` ~ `feature/US-S11` | 各用户故事开发分支 |
| `feature/US-A01` ~ `feature/US-A06` | 各管理端用户故事开发分支 |

### 仓库地址
| 仓库 | 地址 |
|---|---|
| GitHub（monorepo） | `git@github.com:hfutwz/openclaw-project-agent.git` |
| 华为云后端 | `seat_booking_server.git`（subtree: `code-agent/backend/`） |
| 华为云前端 | `seat_booking_web.git`（subtree: `code-agent/frontend/`） |
