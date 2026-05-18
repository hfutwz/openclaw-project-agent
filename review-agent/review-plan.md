# Review: Plan v1.0

**审查时间：** 2026-05-16
**审查基准：** 需求文档 `26春软件过程管理lab.md` + PRD v0.3
**审查重点：** 仅分析 block 业务需求的潜在问题

## 评级: ⚠️ 需修改

---

## Block 级问题（不修复会导致核心业务不可用）

### [B01] 签到流程缺少预约-编码-教室的关联校验逻辑

**问题：** PRD F004 和需求文档明确要求"签到编码与教室+日期关联"，学生输入编码后系统需验证该编码对应的学生预约是否属于该教室。但 Plan 中 `POST /api/reservations/check-in` 的请求体只有 `{ "code": "ABC123" }`，没有说明后端如何从编码反查到教室，再校验当前用户是否有该教室的待签到预约。

**风险：** 如果编码只查 `t_check_in_code` 得到 `room_id`，但没有校验用户在该教室是否有预约，则学生可输入任意教室的编码完成签到——签到形同虚设。如果校验但编码输入错误导致 room_id 错误，合法签到会失败。

**建议修复：** 在 Plan 中明确签到校验链路：
```
1. 根据 code 查 t_check_in_code → 得到 room_id + code_date
2. 查当前用户在该 room_id + code_date 的 PENDING 预约
3. 校验预约存在 + 当前时间在签到窗口内（开始前15min ~ 结束）
4. 更新预约状态为 CHECKED_IN
```

---

### [B02] 预约冲突检测的 SQL 逻辑未定义，可能导致重复预约

**问题：** PRD F003 规定"同一时段同一座位不可重复预约"和"学生同一时段不可预约多个座位"。Plan 的 `t_reservation` 虽然设计了索引 `INDEX(seat_id, date, start_time, end_time)`，但**时间段重叠的判断逻辑不是简单的等值匹配**，需要区间重叠判断。

**风险：** Code Agent 可能写出 `WHERE seat_id=? AND date=? AND start_time=? AND end_time=?` 的等值查询，这无法检测到时段重叠（如 8:00-10:00 与 9:00-11:00 重叠但起止时间不同）。

**建议修复：** 在 Plan 中明确冲突检测的 SQL 条件：
```sql
-- 座位时段冲突
WHERE seat_id = ? AND date = ? AND status IN ('PENDING', 'CHECKED_IN')
  AND start_time < ? AND end_time > ?
-- 参数: seat_id, date, newEndTime, newStartTime

-- 学生同时段冲突
WHERE user_id = ? AND date = ? AND status IN ('PENDING', 'CHECKED_IN')
  AND start_time < ? AND end_time > ?
```
并且要求 Service 层在创建预约前先执行冲突检测，使用 `@Transactional` 保证原子性。

---

### [B03] 定时任务查询条件模糊，可能导致重复推送或遗漏

**问题：** Plan 定时任务只写了"查找 15min 后开始且未提醒的预约"，但 `t_reservation` 表中没有 `reminded_before` 和 `warned_late` 标记字段。PRD F005 明确要求三个时间节点各触发一次推送，如果没有标记位，定时任务每分钟扫描时会**重复发送**已发送过的提醒。

**风险：**
- 学生每分钟收到一条重复的提醒消息（体验极差）
- 或者开发者为避免重复自行加字段，但 Plan 未定义，可能导致与数据库设计不一致

**建议修复：** 在 `t_reservation` 表增加两个字段：

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| reminded_before | TINYINT | DEFAULT 0 | 是否已发送提前15min提醒（0=否 1=是） |
| warned_late | TINYINT | DEFAULT 0 | 是否已发送逾期10min催促（0=否 1=是） |

定时任务查询加上 `WHERE reminded_before = 0` / `WHERE warned_late = 0` 条件，发送后更新为 1。

---

### [B04] 学生端和管理端共用一个前端项目，但 RBAC 前端路由守卫逻辑未定义

**问题：** Plan 架构图中学生端和管理端写的是"同一SPA, 路由分区"，但 PRD F011 明确要求"管理界面根据用户角色仅展示其被授权的功能"。Plan 的前端架构没有定义：
1. 如何根据用户角色（STUDENT/ADMIN）区分路由
2. 管理端页面如何根据 permissions 列表动态渲染菜单
3. 直接访问管理端 URL 时如何拦截

**风险：** Code Agent 可能写出所有人都能访问所有页面的前端，学生可以直接通过 URL 访问管理端，违反 RBAC 需求。

**建议修复：** 在 Plan 前端规范中补充路由守卫设计：
```
1. 登录后获取 permissions 列表（GET /api/auth/me 已返回）
2. 路由配置中标注每个路由所需权限（meta.permissions）
3. 路由守卫（beforeEach）检查：无权限则重定向到 403 页面
4. 管理端布局（AdminLayout）根据 permissions 动态渲染侧边菜单
5. 用户类型为 STUDENT 时，管理端路由不可访问
```

---

### [B05] 缺少初始数据（种子数据）方案

**问题：** Plan 里程碑 M1 提到"数据库建表 + 初始数据"，但没有定义初始数据内容。RBAC 系统需要至少预置：
- 默认角色（super_admin, room_admin, service_admin, viewer）
- 权限项（8个 permission_code）
- 角色-权限对应关系
- 至少一个 super_admin 用户

**风险：** 没有 super_admin 账号，第一次启动后无法登录管理端，整个系统不可用。没有预置角色和权限，RBAC 无法初始化。

**建议修复：** 在 Plan 中增加种子数据清单：
```sql
-- 1. 预置权限
INSERT INTO t_permission (name, code) VALUES
('查看预约记录', 'reservation:view'),
('查看违约记录', 'violation:view'),
('代客预约/取消', 'reservation:manage'),
('座位管理', 'seat:manage'),
('自习室管理', 'room:manage'),
('系统参数配置', 'system:config'),
('角色权限管理', 'role:manage'),
('用户角色分配', 'user:manage');

-- 2. 预置角色
INSERT INTO t_role (name, code, description) VALUES
('超级管理员', 'super_admin', '全部权限'),
('自习室管理员', 'room_admin', '自习室/座位管理'),
('业务管理员', 'service_admin', '预约/违约查看及代客操作'),
('只读查看', 'viewer', '仅查看预约/违约记录');

-- 3. 角色-权限映射（super_admin 全部权限，其他按需）

-- 4. 预置超级管理员
INSERT INTO t_user (username, password, real_name, user_type)
VALUES ('admin', '$2a$10$...（BCrypt加密）', '系统管理员', 'ADMIN');

-- 5. 预置系统参数
INSERT INTO t_system_config (config_key, config_value, description) VALUES
('max_reservation_hours', '4', '单次最大预约小时数'),
('check_in_remind_before_min', '15', '签到提前提醒分钟数'),
('check_in_warn_after_min', '10', '签到逾期警告分钟数'),
('check_in_cancel_after_min', '15', '签到逾期取消分钟数');
```

---

## 非 Block 级问题（不影响核心业务，但值得关注）

### [NB01] 后端 Entity 名与表名映射关系未明确

Plan 表名用 `t_` 前缀（如 `t_room`），但 Entity 类名是 `Room`。需要 MyBatis Plus 配置表名映射 `@TableName("t_room")` 或全局配置 `tablePrefix: t_`。建议在编码规范中明确。

### [NB02] 智能助手 LLM API 的调用方式过于笼统

Plan 只写了"function calling: 映射到系统查询"，但没有说明 LLM API 的具体协议（OpenAI 兼容？自定义？）。建议在 Plan 中明确 API 格式，方便 Code Agent 实现。

---

## 总结

Plan v1.0 整体架构合理、分层清晰、编码规范详尽。但有 **5 个 Block 级问题**必须在交给 Code Agent 之前修复，否则会导致核心功能（签到校验、预约冲突、重复推送、RBAC 路由、系统初始化）不可用。建议修复后重新评审。
