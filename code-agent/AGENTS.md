# AGENTS.md — Code Agent 工作规范

## 角色定位

我是 **Code Agent**，SeatFlow 项目的全栈开发工程师。
当前任务：对已开发完成的代码进行交互测试，发现 bug 立刻修复，直到所有用户故事通过。

## 执行阶段（严格顺序，禁止跳阶段）

### 阶段 0：准备工作 ✅（已完成基础环境）
- [x] 读取 PRD、Plan、现有代码
- [x] 编写 SOUL.md / IDENTITY.md / USER.md / TOOLS.md / AGENTS.md
- [x] 沙箱安装 Java 21 + MySQL 8.0

### 阶段 1：创建数据库 + 导入 SQL 🔄（进行中）
- [ ] 确认 MySQL 在沙箱内正常运行
- [ ] 导入 schema.sql（12张表）
- [ ] 导入 data.sql（初始数据：用户/角色/权限/自习室/座位）
- [ ] 验证数据完整性

### 阶段 2：启动前后端 + 逐条用户故事测试修复
- [ ] 后端编译 + 启动（端口 8080）
- [ ] 前端启动（端口 5173）
- **学生端用户故事（按顺序，逐条测试）：**
  - [ ] US-S01: 查看所有可用自习室及其开放时间
  - [ ] US-S02: 查看座位图并选择座位
  - [ ] US-S03: 按整点小时预约座位（最多4小时）
  - [ ] US-S04: 通过动态编码签到
  - [ ] US-S05: 收到预约提醒
  - [ ] US-S06: 超时未签到自动取消+通知
  - [ ] US-S07: 取消预约（含违约边界）
  - [ ] US-S08: 多条件搜索座位
  - [ ] US-S09: 查看历史预约并再次预约
  - [ ] US-S10: 查看违约记录
  - [ ] US-S11: 智能助手自然语言交互
- **管理端用户故事（学生端全部通过后）：**
  - [ ] US-A01: 登记/注销自习室
  - [ ] US-A02: 登记/注销座位
  - [ ] US-A03: 查看预约统计
  - [ ] US-A04: 代客预约/取消
  - [ ] US-A05: 维护角色和权限
  - [ ] US-A06: 调整系统参数

### 阶段 3：Dockerfile 容器化（数据库）
- [ ] 创建 `deploy/docker-compose.yml`（MySQL 8.0）
- [ ] 创建 `deploy/Dockerfile.db`（如需自定义初始化）
- [ ] 验证：Mac 本地前后端 + Docker 数据库联调可行

## 每个用户故事的测试流程

1. **按 PRD 验收标准**进行 API 测试（curl / 浏览器）
2. 发现问题 → 定位根因 → 修复代码
3. 重新测试直到通过
4. **提交 PR** 到 main 分支（commit: `fix(US-Sxx): 描述`）
5. 进入下一个用户故事

## 已发现的 Bug 清单（待修复）

| Bug ID | 位置 | 描述 | 状态 |
|---|---|---|---|
| BUG-01 | pom.xml | 缺少 spring-boot-starter-websocket | ✅ 已修复 |
| BUG-02 | CheckInService / CheckInController | 签到接口路径错误（/api/check-in），签到逻辑需要 reservationId 违反 PRD | ✅ 已修复 |
| BUG-03 | Reservation entity | 缺少 created_by 字段（代客预约标注） | ✅ 已修复 |
| BUG-04 | AdminCheckInAndViolationController | 签到编码接口路径错误 | ✅ 已修复 |
| BUG-05 | ReservationService | max_reservation_hours 硬编码为 4，应从 SystemConfig 读取 | 🔄 修复中 |
| BUG-06 | ReservationService.adminCreate | 代客预约未使用 forUserId | 🔄 修复中 |
| BUG-07 | frontend/services/checkin.ts | 签到 API 路径和参数不符合后端 | 待修复 |
| BUG-08 | t_reservation schema | 缺少 created_by 字段 | 待修复 |
| BUG-09 | CheckInService.autoCancelTimeout | 只检查当天，未处理跨天场景 | 待修复 |
| BUG-10 | NotificationService | 完全未实现，影响 US-S05/S06 | 待修复 |

## Git 规范

- 仓库：https://github.com/hfutwz/openclaw-project-agent
- 分支：直接在 main 开发
- Commit：`fix(US-Sxx): 修复xxx` / `fix(BUG-xx): 修复xxx`
- 每个用户故事修复完成后推送一次
