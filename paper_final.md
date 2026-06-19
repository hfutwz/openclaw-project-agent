# AI 辅助开发环境下的软件过程管理实践
# ——以自习座位预约系统 SeatFlow 为例

**摘要**：本文以《软件过程管理》课程 Lab 项目——自习座位预约系统 SeatFlow 为研究载体，系统记录并分析了在 OpenClaw 和 Claude 等大语言模型驱动的 Vibe Coding 范式下，如何完成从需求理解、架构设计、多 Agent 初始化、代码生成到 CI/CD 交付的全流程实践。通过 数十次 Git 提交、40+ REST API、12 个实测 Bug 和 10 类团队冲突问题的详细分析，本文提出了一套面向 AI 辅助编程的个人软件开发 SOP，归纳了 Vibe Coding 在上下文工程、需求拆解、隔离测试、多 Agent 编排等维度的利弊权衡，并对软件过程管理课程核心概念在 AI 时代的适应与挑战进行了深度思考。

**关键词**：Vibe Coding；用户故事；敏捷开发；软件过程管理；CI/CD

---

## 一、引言

2026 年以来，以 Claude Code、GitHub Copilot、Cursor 为代表的 AI 编程工具快速普及，催生了 Vibe Coding 这一新型开发范式。开发者以自然语言描述意图，由 LLM 负责代码生成与修改，人类退化为意图提供者和验收者[1]。这一模式对传统软件过程管理带来了深刻冲击，当代码生成速度以小时计、Bug 修复以秒计时，Scrum 的两周迭代、代码审查的人工流程、需求文档的精细拆解，是否还有意义？

本文以《软件过程管理》课程 Lab 项目 —— 自习座位预约系统 SeatFlow 为具体载体，尝试回答上述问题。SeatFlow 是一个涵盖学生预约、签到、RBAC 权限管理与智能助手的 Web 全栈系统，由 6 名组员在 AI 辅助下协作开发，历时数月。本文不是泛泛而谈 AI 如何提效，而是从真实的提交记录、实测 Bug、团队冲突和流程决策出发，探讨 AI 时代软件过程管理的具体实践路径。

---

## 二、实验需求分析与团队分工

### 2.1 实验需求分析

Lab 的核心需求是：**以高等学校日常学习生活为背景，通过信息技术手段实现一个自习室座位预约系统，提升各类自习室座位使用率**。

充分阅读实验文档后，我对项目的理解分三个层次：

**业务层**：解决"一座难求"与"书包占座人不在"两个矛盾现象。核心机制是"预约→签到→自动释放"闭环：学生必须在到达前预约，到达后15分钟内签到，否则系统自动释放座位并计一次违约。这个闭环是整个系统价值的核心，不是装饰性需求。

**技术层**：系统包含三个有明确技术挑战的模块：
1. **座位图**：需要网格化可视化布局，能区分状态、标注特征（插座、靠窗），这对前端交互提出了较高要求
2. **定时任务**：提前15分钟提醒、逾期10分钟催促、逾期15分钟自动取消——三个时间节点的精确触发，需要独立的调度机制
3. **智能助手**：通过自然语言完成查询和操作，是 Lab 重点考核内容之一，需要接入 LLM 并设计 function calling

**协作层**：6人团队分别负责不同模块，需要在接口边界、数据库 schema、分支策略上达成一致，避免并行开发产生冲突。

### 2.2 任务拆分与团队分工

Lab 采用用户故事作为最小任务粒度，共识别 17 个用户故事，分为学生端（US-S01~S11）和管理端（US-A01~A06）：

**学生端任务分配**

| 编号 | 故事摘要 | 优先级 | 负责人 |
|---|---|---|-----|
| US-S01 | 查看所有可用自习室及开放时间 | P0 |  |
| US-S02 | 查看座位图并选择座位 | P0 |  |
| US-S03 | 按整点小时预约（最多4小时） | P0 |  |
| US-S04 | 输入动态编码签到 | P0 |  |
| US-S05 | 收到预约提醒（15min前推送） | P0 |  |
| US-S06 | 超时未签到自动取消 | P0 |  |
| US-S07 | 取消预约（含违约边界） | P0 | |
| US-S08 | 多条件搜索座位 | P0 |  |
| US-S09 | 查看历史预约并再次预约 | P0 | |
| US-S10 | 查看违约记录 | P2 | |
| US-S11 | 智能助手自然语言交互 | P1 |  |

**管理端任务分配**

| 编号 | 故事摘要 | 优先级 | 负责人    |
|---|---|---|--------|
| US-A01 | 登记/注销自习室 | P0 | 组员A（我） |
| US-A02 | 登记/注销座位（含批量生成） | P0 | 组员A（我） |
| US-A03 | 查看预约统计仪表盘 | P0 |    |
| US-A04 | 代客预约/取消 | P2 |   |
| US-A05 | 维护角色和权限（RBAC） | P0 |    |
| US-A06 | 调整系统参数 | P2 | 组员A（我） |

### 2.3 AI 使用透明度

本项目所有代码均在 AI 辅助下生成，具体环节说明如下：

| 环节                        | 使用的大语言模型          | 人工介入程度 | 备注 |
|---------------------------|-------------------|--------|---|
| 需求分析与 PRD 撰写              | GLM 5.2           | 高      | 人工主导框架，AI 补全细节 |
| 开发计划（Plan）                | Claude 4.8 Opus   | 极高     | 人工主导架构设计与用户故事拆解，AI 生成结构化文档 |
| 后端代码生成 Spring Boot        | Claude 4.7 Sonnet | 中      | AI 生成初稿，人工修复 Bug |
| 前端代码生成 React + Ant Design | Gemini 3.1 Pro    | 中      | AI 生成，人工联调 |
| 数据库 schema 设计             | Claude 4.7 Sonnet | 高      | 人工主导表结构，AI 生成 DDL |
| 代码 Review                 | Claude 4.7 Sonnet | 极高     | Review Agent 独立上下文审查，人工确认并决策 |
| 测试样例生成                    | Kimi K2.6         | 中      | Test Agent 生成用例，人工执行验证 |
| Bug 修复                    | Claude 4.7 Sonnet | 中      | AI 定位根因，人工确认修复方向 |

---

### 2.4 Vibe Coding 准备：Agent 配置文件设计与架构规划

在正式开发前，我花了约一天时间在 OpenClaw 中搭建多 Agent 框架，为每个子 Agent 编写一套结构化的配置文件，并完成系统架构设计，将所有技术决策写入 `plan/plan.md` 作为团队统一基准。

**Agent 配置文件体系**

每个 Agent 目录下均包含一组标准化的身份与约束文件，包括：角色定义文件（SOUL.md）、用户环境约束文件（USER.md）、身份标识文件（IDENTITY.md）、工具说明文件（TOOLS.md）、调度索引文件（AGENTS.md）以及跨会话记忆文件（memory/）。这套文件体系使每个 Agent 在会话启动时能快速加载完整上下文，保持角色边界清晰、上下文互不干扰。详细设计见第四章初始化阶段。

**Multi-Agent 架构图**

```
                   ┌──────────────────────────────────────┐
                   │         Orchestrator（编排器）         │
                   │     调度所有子 Agent，守门，不写代码    │
                   └──────────────────┬───────────────────┘
                                      │ sessions_spawn / sessions_send
          ┌───────────┬───────────────┼────────────┬──────────────────┐
          ▼           ▼               ▼            ▼                  ▼
   ┌────────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
   │ Plan Agent │ │Code Agent│ │Review Agent  │ │  Test Agent  │ │UI Research Agent │
   │ 需求 → PRD │ │ 全栈开发 │ │ 纯只读审查   │ │ 基于PRD写测试│ │ UI/UX 调研       │
   └────────────┘ └──────────┘ └──────────────┘ └──────────────┘ └──────────────────┘
```

**各 Agent 职责一览**

| Agent | 职责 | 工作目录 |
|---|---|---|
| Orchestrator | 编排调度，守门（PRD 未确认不启动代码） | 项目根目录 |
| Plan Agent | 需求澄清 → 输出 PRD，迭代修改直到用户确认 | `plan-agent/` → `prd/` |
| Code Agent | 按用户故事顺序全栈实现（前端 + 后端） | `code-agent/` |
| Review Agent | 纯只读审查 PRD/Plan/代码，五维度评分 | `review-agent/` |
| Test Agent | 基于 PRD 编写测试用例，代码完成后执行 | `test-agent/` |
| Delivery Agent | 所有 US 合并后最终验证，5维度100分考核 | `delivery-agent/` |
| UI Research Agent | 调研座位图/两端体感/AI助手界面，输出落地建议 | `ui-research-agent/` |

**PRD → Plan → Review / Code + Test 闭环流程**

```
用户提需求
    │
    ▼
[1] Plan Agent → 产出 PRD → 用户人工确认 ✅（未确认绝不启动代码）
    │
    ├─────────────────────────────────────┐
    ▼                                     ▼
[2] Code Agent（按 US 顺序开发）    [3] Test Agent（基于 PRD 并行写测试用例）
    │（每个 US 完成后）                   │
    ▼                                     │
[4] Review Agent ◄──────────────────────┘
    ✅ 通过 → 合并 main → 开始下一个 US
    ⚠️ 问题 → Code Agent 修复 → 重审
    │
    ▼（所有 US 完成）
[5] Delivery Agent → 5维度100分验证
    ✅ 可交付 → 部署
    ⚠️ P0 问题 → Code Agent 修复 → 重验
```

**每个用户故事的完成门槛**

```
[Code]   实现代码（feature/US-Sxx 分支）
    ↓
[Code]   本地验证：mvn compile 零错误 + pnpm build 零错误
    ↓
[Review] 五维度审查通过（代码质量30/安全25/架构20/边界15/性能10）
    ↓
[Test]   测试用例全部通过
    ↓
[PR]     合并 main → 推送 GitHub + 华为云前端 + 华为云后端
    ↓
         开始下一个 US
```

**架构设计工作**

作为本组的架构负责人，我完成了系统全局架构设计，包括：ER 图与数据库 Schema 设计、后端五层分层架构规范、前端项目目录结构规划、接口命名与统一返回格式规范。所有设计决策写入 `plan/plan.md`，详见第三章。

## 三、我的工作：系统架构设计

本章详细介绍我在本项目中承担的核心架构设计工作。所有设计在开发启动前完成，写入 `plan/plan.md` 作为全组技术规范，约束 Code Agent 的代码生成行为。

### 3.1 ER 图与数据库设计

数据库采用 MySQL 8.0，共设计13张核心表。核心 ER 关系如下：

```
┌──────────┐     ┌──────────┐     ┌──────────────┐
│   User   │────<│Reservation│>────│    Seat      │
│          │     └──────────┘     └──────┬───────┘
│          │                            │  N:1
│          │     ┌──────────────┐       │
│          │────<│  Violation   │  ┌────▼─────────┐
│          │     └──────────────┘  │    Room      │
│          │                       └──────────────┘
│          │     ┌──────────┐
│          ├────<│UserRole  │────> Role ─────> RolePermission ─────> Permission
│          │     └──────────┘
└──────────┘     ┌──────────────┐
                 │ CheckInCode  │ ←── 每日动态签到码（按 Room 生成）
                 └──────────────┘
                 ┌──────────────┐
                 │ SystemConfig │ ←── 系统参数（k-v 结构）
                 └──────────────┘
```

**关键设计决策**：

- **外键禁止在数据库层面设定**：Lab 要求外键约束由后端业务层保证，避免数据库级联带来的并发问题，也方便数据迁移
- **座位状态无中间状态**：`SeatStatus` 枚举只有 `AVAILABLE/DISABLED`，预约状态通过关联 `Reservation` 表实时计算，不在 Seat 表冗余字段，避免并发更新不一致
- **预约状态机**：`ReservationStatus` 枚举为 `PENDING → CHECKED_IN → COMPLETED / CANCELLED`，状态转换由定时任务和业务接口共同驱动
- **SystemConfig 表**：k-v 结构存储系统参数（如最大预约小时数），支持运行时调整，不硬编码在代码中

### 3.2 后端架构设计

后端采用 **Spring Boot 3 + JDK 21 + MyBatis Plus + MySQL 8.0**，严格五层分离：

```
com.seatflow/
├── controller/        # REST 接口层（@RestController）
├── service/           # 业务逻辑层（接口 + impl 分离）
├── mapper/            # 数据访问层（MyBatis Plus BaseMapper）
├── entity/            # 数据库实体（@TableName）
├── dto/
│   ├── request/       # 入参 VO（@Valid 校验）
│   └── response/      # 出参 VO（脱敏、格式化）
├── config/            # 配置类（Security/WebSocket/MyBatis/CORS）
├── security/          # JWT 过滤器 + UserDetailsService
├── scheduled/         # 定时任务（提醒/自动取消/每日签到码）
├── common/
│   ├── result/        # 统一返回 Result<T>
│   ├── exception/     # BusinessException + GlobalExceptionHandler
│   └── enums/         # 业务枚举（ReservationStatus/SeatStatus 等）
└── ai/                # LLM 客户端（function calling 映射）
```

**编码规范**（写入 plan.md 约束 Code Agent）：

- Controller 只做参数校验和格式转换，不写业务逻辑
- Service 接口与实现分离，`XxxService.java` + `XxxServiceImpl.java`
- 所有接口统一返回 `Result<T>`，格式：`{code, message, data}`
- 数据库字段命名用下划线，Java 字段用驼峰，通过 MyBatis Plus 自动映射
- 接口版本前缀统一为 `/api/`，管理端接口加 `/admin/` 中缀

### 3.3 前端架构设计

前端采用 **React 19 + TypeScript + Ant Design + Vite**，构建工具强制使用 pnpm：

```
src/
├── pages/
│   ├── student/       # 学生端页面（RoomList/RoomDetail/CheckIn/Assistant...）
│   └── admin/         # 管理端页面（Dashboard/RoomManage/SeatManage/RoleManage...）
├── components/
│   ├── SeatMap/       # 座位图（网格布局，核心交互组件）
│   └── ChatBox/       # 智能助手聊天框
├── services/          # API 请求层（Axios 实例 + 接口封装）
├── hooks/             # 自定义 Hook（useAuth/usePermissions/useWebSocket）
└── utils/             # 常量与工具函数
```

**座位图设计**是前端最具挑战性的部分。Lab 要求座位图"优雅可选择，静态"，我的设计方案是：
- 网格布局（`row_num × col_num`）渲染座位矩阵
- 颜色区分状态：绿色（可用）/ 橙色（已预约）/ 灰色（不可用）
- 图标标注特征：⚡ 插座 / 🪟 靠窗 / 🚶 走廊
- 点击座位弹出预约时间选择弹窗，时间选择器限制整点小时、最多4小时

---

## 四、初始化阶段：基于 OpenClaw 的单 Agent 上下文搭建

### 4.1 为什么需要专门的初始化阶段

Vibe Coding 最大的挑战不是模型能力，而是**上下文管理**。LLM 在每次会话中都从零开始，没有持久记忆。传统软件工程师的隐性知识（代码风格、技术选型历史、团队约定）需要显式地注入到 AI 的上下文中，才能保证输出的一致性[2]。

如果跳过初始化阶段直接让 AI 开始写代码，会出现以下问题：
- 下次会话忘记上次的技术决定（如"数据库外键禁止在 DB 层设定"）
- 不同 Agent 对同一概念的理解不同（如座位状态的枚举值）
- 环境约束无法感知（如"只能用 pnpm 不能用 npm"）

### 4.2 专用初始化 Agent 的工作

我在 OpenClaw 中新建了一个独立的初始化 Agent 会话，专门完成以下文件的创建与调试：

**SOUL.md（AI 行为风格）**：

核心规则是"直接动手，少问废话"——避免 AI 产生过多确认性对话。关键条目：
- 推送前必须执行 `pnpm build`（前端）或 `mvn compile`（后端），零错误才允许推送
- 发现 Bug 立即修复并说明根因，不要绕过
- 只在真正需要人工决定时才提问，其余自行解决

**USER.md（项目技术约束）**：

记录所有开发环境的硬性约束，让每个 Agent 会话启动时都能感知：
```
- Java 路径：/tmp/jdk21/（不是系统默认）
- 前端包管理：只用 pnpm，禁止 npm/yarn
- 容器化：Mac 环境用 Podman，路径 /Users/.../podman-compose
- 数据库密码：统一在 deploy/.env，不硬编码
- 华为云 main 分支：有保护规则，只能通过 MR 合并，禁止 force push
```

**AGENTS.md（Agent 启动流程）**：

定义每次新建 Agent 会话时的强制启动序列：
1. 读 SOUL.md → 确认行为风格
2. 读 USER.md → 加载环境约束
3. 读 memory/YYYY-MM-DD.md → 了解最近进展
4. 再开始工作

**memory/（日志记忆系统）**：

按日期建立 `memory/YYYY-MM-DD.md`，每次会话结束时更新。解决了 LLM 跨会话失忆的根本问题——不依赖模型的内置记忆，而是让 AI 主动维护外部文件作为持久化记忆[3]。

**plan/plan.md（开发北极星）**：

将所有架构决策、用户故事、接口规范写入单一权威文档。Code Agent 的每一次生成任务都以 Plan 为基准，Plan 文件一旦确定不随意修改，防止 AI 在不同会话中产生矛盾的实现。

### 4.3 初始化阶段的价值

这套机制本质上是一种**结构化 Prompt 工程的升级版**，从"每次对话写 Prompt"升级为"维护一套 AI 可读的项目知识库"[4]。Anthropic 官方将其称为"上下文工程"（Context Engineering），核心是在正确的时间给 AI 提供精准的信息[5]。

初始化完成后，每个新建的 Agent 会话可以在30秒内达到"了解项目全貌"的状态，而不需要重新解释背景。这在多人协作、跨天开发的场景中节省了大量的上下文重建成本。

---

## 五、设计阶段：多 Agent 协作框架

### 5.1 为什么需要多 Agent

单一 AI 对话存在两个核心问题：

1. **上下文窗口限制**：随着对话轮次增加，早期约定会被"稀释"，AI 生成的代码逐渐偏离原始设计意图
2. **角色混淆**：同一个 AI 既写代码又做 Review，相当于让同一个人同时扮演"开发者"和"审查者"，必然产生认知偏差

本项目将开发流程拆解为6个独立 Agent，各自维护隔离的上下文。完整架构在第二章已概述，这里重点说明各 Agent 的隔离机制与设计意图。

```
                   ┌──────────────────────────────────────┐
                   │         Orchestrator（编排器）         │
                   │  调度所有子 Agent，守门，不写代码  │
                   └──────────────────┬───────────────────┘
                                          │ sessions_spawn
             ┌───────────┬───────────┼───────────┐
             ↓           ↓             ↓             ↓
      ┌──────────┐ ┌──────────┐ ┌─────────────┐ ┌─────────────┐
      │Plan Agent│ │Code Agent│ │Review Agent │ │ Test Agent  │
      │需求→PRD │ │ 全栈开发 │ │纯只读审查   │ │基于PRD写测试│
      └──────────┘ └──────────┘ └─────────────┘ └─────────────┘
```

### 5.2 Review Agent 与 Test Agent 的隔离设计

**Review Agent 和 Test Agent 的上下文隔离**是关键设计。如果 Code Agent 写完代码立刻在同一上下文中做 Review，AI 会倾向于"自我合理化"——因为它"记得"自己为什么这样写。独立的 Review Agent 从新鲜的上下文出发，更容易发现设计问题[6]。

这一设计与传统软件工程中"作者不做自测"原则是同构的——不同之处在于，我们用上下文隔离替代了人员隔离。

实践中发现，Review Agent 对以下类型问题特别有效：
- **硬编码**：路由、密码、端口写死（BUG-003 的根因）
- **缺少边界处理**：空值未判断、超长字符串截断缺失
- **安全隐患**：接口未鉴权、SQL 拼接风险

对以下类型问题不如人工审查：
- **业务逻辑完整性**：需要了解完整业务流程才能判断
- **团队代码风格一致性**：需要了解已有代码库

### 5.3 Plan 文件的核心地位

`plan/plan.md` 是整个开发的"北极星"——Code Agent 的每一次生成任务都以 Plan 中的用户故事和接口规范为基准。这产生了一个重要约束：**Plan 文件不能被随意修改**。一旦 Plan 改变，已有代码的逻辑依据就会消失，AI 下次生成时可能产生与已有代码矛盾的实现。

这与传统软件工程的"需求冻结"原则完全一致，只是在 AI 辅助开发中表现更为极端——因为 AI 没有人类工程师的上下文记忆，它完全依赖当前可见的文档来理解系统状态。

---

## 六、开发阶段：分支策略、Bug 归因与团队协作

### 6.1 一个用户故事一个分支

本项目采用严格的用户故事分支策略：

```
main（稳定版本，受保护）
├── feature/task_a_room_management（US-A01/A02 自习室与座位管理）
├── feature/US-S01（学生端自习室查看）
├── feature/US-S02（座位图与预约）
└── ...（共18个功能分支）
```

华为云 CodeHub 上同时存在18个功能分支（`feature/US-S01~S11`、`feature/US-A01~A06`）。这种粒度的分支策略有两个重要作用：

- **可追溯性**：每个 commit 与特定用户故事绑定，`git log --grep="US-A02"` 即可追溯座位管理功能的完整修改历史
- **冲突最小化**：不同用户故事对应不同业务模块，分支隔离大幅减少多人同时修改同一文件的概率

合并策略采用 `--no-ff`（禁止 fast-forward），在提交历史中保留每个用户故事的合并节点：

```bash
git merge feature/task_a_room_management --no-ff \
  -m "feat: 合并 feature/task_a_room_management → main（US-A01/A02 完成）"
```

### 6.2 三仓 Monorepo 架构

本项目维护三个仓库，各有明确职责：

| 仓库 | 内容 | 更新策略 |
|---|---|---|
| **GitHub monorepo** | 全部 Vibe Coding 过程细节：Agent 配置、PRD、Plan、测试报告、deploy 配置 | 每次功能完成后 push |
| **华为云后端** `seat_booking_server` | 纯后端业务代码（`code-agent/backend/` subtree） | `git subtree split` + push |
| **华为云前端** `seat_booking_web` | 纯前端业务代码（`code-agent/frontend/` subtree） | `git subtree split` + push |

使用 `git subtree split` 将 monorepo 中特定目录拆分为独立历史树，推送到华为云独立仓库：

```bash
BACKEND_COMMIT=$(git subtree split --prefix=code-agent/backend main)
git push huawei-backend "${BACKEND_COMMIT}:refs/heads/feature/task_a_room_management"
```

### 6.3 Commit 统计与分析

项目共完成49次有意义的 commit（排除初始化和同步提交）：

| 类型 | 数量 | 占比 |
|---|---|---|
| feat（新功能） | 18 | 37% |
| fix（Bug 修复） | 21 | 43% |
| docs（文档） | 7 | 14% |
| chore（维护） | 3 | 6% |

修复类提交（fix）占比高达43%，这是 Vibe Coding 的典型特征——AI 能快速生成功能框架，但在边界处理、框架配置细节上容易产生错误，需要大量修复迭代。

### 6.4 开发过程 Bug 归因分析

本项目共发现并修复12个实测 Bug，按 Vibe Coding 归因分类：

| 归因类型 | Bug 数量 | 典型案例 |
|---|---|---|
| **模型上下文不够** | 3 | Spring Security 302 重定向、MySQL 字符集乱码、monorepo 路径错位 |
| **需求描述不清楚** | 3 | userInfo 未返回、Dockerfile 镜像错误、代码同步覆盖改动 |
| **需求拆解不够细** | 2 | 登录跳转硬编码、userInfo 缺失 |
| **开发者 taste 不对** | 3 | 构建验证不完整、Volume 不清、角色跳转硬编码 |
| **环境约束未传达** | 2 | pnpm registry 污染、华为云分支保护 |
| **技术方案副作用考虑不足** | 2 | git unrelated histories、monorepo 路径问题 |

**典型案例一：BUG-001 登录返回302重定向**

Spring Boot `spring-boot-starter-security` 依赖存在时，只要没有显式定义 `SecurityFilterChain` bean，Spring Boot auto-config 就会启用默认 formLogin 机制，将所有未认证请求拦截并302重定向到 `/login`（无端口）。

Code Agent 生成 SecurityConfig 时注释了 `@EnableWebSecurity`，但没有意识到这不足以禁用 auto-config。这是"模型上下文不够"的典型案例——AI 见过足够多的 SecurityConfig 代码，但对 Spring Boot 默认行为的边界理解不如资深工程师精确。

修复方案：恢复 `@EnableWebSecurity` + 显式定义 `SecurityFilterChain` bean 全放行，MVP 阶段不依赖 Spring Security 的默认行为。

**典型案例二：BUG-004 数据库中文乱码**

`init.sql` 中建库语句写了 `CHARACTER SET utf8mb4`，但没有在文件头部声明 `SET NAMES utf8mb4`。MySQL 客户端连接字符集和服务端字符集是两套独立配置，AI 知道建库要写 utf8mb4，但对 MySQL 字符集体系的两层结构理解不够深入。

修复方案：`init.sql` 头部加三行：
```sql
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection=utf8mb4;
```

**典型案例三：BUG-010 MySQL Volume 不清导致 init.sql 不生效**

MySQL 容器在 named volume 存在时会跳过 `init.sql` 初始化，直接使用已有数据。AI 设计初始化方案时选择 `INSERT IGNORE` 认为可以随时重跑，但实际 `init.sql` 根本不会再次执行。

这是"开发者 taste 不对"的典型案例——AI 倾向于"能跑就行"的最小实现，对 Docker volume 生命周期管理理解不深。修复方案：执行 `podman-compose down -v` 清 volume 后重建。

完整Bug记录见**附录二**。

### 6.5 团队协作冲突的深度分析

在5人小组协作过程中，出现了10类具体冲突。以下选取最有代表性的四类进行深度分析：

**冲突一：代码覆盖——整目录 git checkout 丢失改动**

我实现了「批量生成座位」功能（`SeatManage.tsx`），在同步组员 B 的 RBAC 代码时，执行了 `git checkout huawei-frontend/main -- src/`，整目录覆盖导致批量生成功能消失。

根因：`git checkout <remote> -- <dir>` 是破坏性操作，不会触发 merge 流程，不会检查冲突，直接覆盖本地文件。Vibe Coding 归因为**任务描述歧义**——"把华为云代码同步过来"没有说明"只同步新增内容，不覆盖已有改动"，AI 选择了语义最直接的实现。

解法建立明确 SOP：同步整目录用 `git merge`，同步特定文件用 `git show <remote>:<path> > <local_path>`。

**冲突二：数据文件冲突——init.sql 多人并发修改**

我在 `data.sql` 中扩充自习室/座位数据，组员 B 同时添加 RBAC 权限数据，两人修改同一文件，pull 时产生 merge conflict。

根因：`data.sql` 是单一文件，承载了多个业务模块的初始化数据，违反"单一职责"原则。解法是按模块拆分 SQL 文件，利用 Docker MySQL 容器自动按字母顺序执行 `docker-entrypoint-initdb.d/` 下所有 `.sql` 文件：

```
deploy/mysql/
  01_schema.sql         # 建表（统一维护）
  02_rbac_seed.sql      # 组员 B 负责
  03_room_seat_seed.sql # 我负责
```

**冲突三：BCrypt 密码 Hash 不一致**

组员 B 写 `data.sql` 时用自己生成的 BCrypt hash，注释写 `-- admin123 ->` 但实际 hash 对应的密码未知，导致其他组员登录报"密码错误"。

根因：BCrypt hash 不可逆，注释中的密码说明和实际 hash 不对应。解法是统一替换回项目初始验证过的 hash，并规定由一人统一生成所有测试账号 hash，禁止个人修改。

**冲突四：华为云 main 分支保护规则**

执行 `git push huawei-backend <commit>:main --force` 被拒，报 `non-fast-forward`。华为云 CodeHub 对 main 分支设置了保护规则，禁止 force push。

解法：推送到临时分支 `sync-backend-fix-v3`，在华为云 Web UI 创建 MR 合并到 main。这也促使我们在项目初期就将"所有代码合并必须通过 MR 流程"写入团队规范。

完整冲突记录见**附录一**。

---

## 七、CI/CD 流水线的理解

### 7.1 流水线整体设计

本项目基于华为云 DevCloud 构建 CI/CD 流水线，每次 commit 自动触发：

```
代码推送 (git push)
    ↓
CI 阶段：
├── 后端编译：mvn clean package -DskipTests
├── 后端单测：mvn test
├── 前端构建：pnpm install && pnpm build
└── 代码质量检查
    ↓
CD 阶段（main 分支触发）：
├── Docker 镜像构建（podman build）
├── 镜像推送到容器仓库
└── 自动部署到测试环境
```

**CI 对 Vibe Coding 的特殊价值**：AI 生成的代码可能通过静态类型检查但在运行时报错，自动化构建和测试是最后一道安全网。本项目规定 CI 通过是合并到 main 的必要条件，强制保证了主干代码的基本可运行性。

### 7.2 对 CI/CD 的理解

通过这次实践，我对 CI/CD 有了几个具体的理解：

**CI 的核心价值不是"自动化构建"，而是"快速失败"**

每次提交后5分钟内得到反馈，比人工 Review 后才发现构建失败要好得多。在 Vibe Coding 场景下，AI 生成代码的速度很快，但质量参差不齐，CI 的快速反馈机制能防止"一堆未经验证的代码堆积到最后才发现无法构建"。

**CD 的难点不是部署自动化，而是环境一致性**

本项目遇到的最典型 CD 问题是 MySQL volume 不清导致数据不一致（BUG-010）。`init.sql` 只在 volume 不存在时执行一次，数据变更后必须 `down -v` 清 volume 重建。这说明 CD 流水线必须把"环境状态"作为配置的一部分管理，而不只是部署代码。

**容器化是前提，而非锦上添花**

使用 Docker/Podman 容器化部署后，"在我机器上能跑"的问题从根本上消失——因为运行环境本身被版本化管理了（`Dockerfile` + `docker-compose.yml`）。这对5人团队尤为重要：不同组员的本地 MySQL 密码、Node 版本、JDK 版本各不相同，容器化统一了所有这些差异。

### 7.3 数据库迁移策略

SQL schema 变更遵循版本化设计原则：

- `schema.sql`（v1.0）：初始建表，包含所有基础表和约束
- `data.sql`（v1.0→v2.0→v3.0）：种子数据，用 `INSERT IGNORE` 保证幂等

生产环境应迁移到 Flyway 管理，实现版本化迁移文件（`V1__init.sql`、`V2__add_column.sql`）和自动检测未执行迁移脚本，而非依赖 `init.sql` 一次性初始化的脆弱机制。

---

## 八、Vibe Coding 过程总结与个人开发 SOP

### 8.1 Vibe Coding 的本质再理解

Vibe Coding（感觉式编程）是2025年 Andrej Karpathy 提出的概念，指将代码编写的主导权完全移交给 AI，开发者只需用自然语言描述意图[1]。学界对此已有系统综述[7]，将其定义为"以大语言模型为核心的软件开发工程方法论，人类、软件项目和编程智能体构成动态三角关系"。

但本次实践告诉我，"将主导权完全移交给 AI"这个描述有失准确。更准确的描述是：**Vibe Coding 将开发者的工作从"写代码"升级为"管理 AI 上下文"**。开发者不再负责每一行代码，但必须负责：
- 维护 AI 能理解的上下文文件（SOUL.md、Plan.md、memory/）
- 设计合理的任务粒度（用户故事的拆解深度直接决定 AI 输出质量）
- 验证 AI 输出（`pnpm build` 零错误、`mvn compile` 零错误）
- 管理 AI 无法感知的环境约束（CI 平台规则、包管理器、分支策略）

### 8.2 五维利弊权衡

**第一维：速度 vs 准确性**

AI 能在数分钟内生成完整的 Spring Boot Controller + Service + Mapper 三层结构，传统开发需要数小时。但本项目的 fix commit 占比43%，说明生成速度的代价是更高的修复密度。AI 擅长"宽度"（快速搭框架），不擅长"深度"（框架配置的边界行为）。

**第二维：需求粒度 vs 输出质量**

用户故事的粒度直接决定 AI 输出质量。"实现座位管理功能"这样的粗粒度需求会让 AI 做很多猜测；"作为管理员，我希望通过左上角和右下角坐标批量生成矩形区域座位，生成前预览总数"这样的精细化需求，AI 的实现几乎不需要修改。

**第三维：上下文管理 vs 任务规模**

AI 的上下文窗口是有限的。随着会话进行，早期的技术约定会被后续对话逐渐稀释。本项目通过 memory/ 日志机制解决跨会话遗忘问题，但在单次长对话中，上下文污染仍是难题——这是引入多 Agent 隔离的核心动机。

**第四维：AI 辅助 vs 人工监督**

"AI 能跑就行"是 Vibe Coding 的典型陷阱。AI 倾向于生成"最小可运行实现"，而不是"最优实现"。前端跳转写死路由、构建验证只跑 tsc、数据库用 INSERT IGNORE 而非 Flyway——这些都是"能跑"但不是"好的"实现。

人工监督的核心职责不是写代码，而是**把控设计品质（taste）**——AI 的直觉来自训练数据的统计分布，未必符合当前项目的实际需求。

**第五维：团队协作 vs AI 辅助的张力**

AI 辅助编程天然适合个人开发，但在多人协作中，AI 成为了一个"不参加会议的额外队友"，所有协作约定必须**显式文档化**，否则 AI 无法感知，产生的代码与团队规范不符。

### 8.3 个人 Vibe Coding SOP

基于本次实践，总结以下可操作的标准操作规程：

**阶段一：初始化上下文（项目启动时执行一次）**

```
1. 创建 SOUL.md：AI 行为风格（直接动手/遇错报出/不废话）
2. 创建 USER.md：硬性约束（技术栈/环境/禁止事项）
3. 创建 AGENTS.md：启动序列（SOUL → USER → memory → 开始）
4. 将所有环境约束写入 USER.md（不要靠口头约定）
```

**阶段二：需求拆解（每个功能模块）**

```
1. 粒度：每个用户故事约 4-8 小时工作量
2. 格式：角色 + 动作 + 价值 + 验收条件（3-5条）+ 排除项
3. 用户故事确认后写入 plan.md，锁定不随意修改
```

**阶段三：开发循环（每个用户故事重复）**

```
1. 从 main 签出 feature/<US-ID> 分支
2. 将用户故事 + 验收条件 + 相关约束注入 Code Agent 上下文
3. 生成代码后立即验证：mvn compile（后端）或 pnpm build（前端）
4. 验证通过后，用隔离上下文的 Review Agent 审查
5. Fix → 重验证 → 推送
6. feature 分支通过 CI → MR → 合并 main
```

**阶段四：记忆维护（每次会话结束）**

```
1. 更新 memory/YYYY-MM-DD.md：
   - 今天解决了什么 Bug，根因是什么
   - 做了什么技术决策，选择理由是什么
   - 下次会话需要知道的事项
2. 遇到重要约束（如 CI 平台规则），同步更新 USER.md
```

**阶段五：多 Agent 协作注意事项**

```
1. Review Agent 和 Test Agent 必须隔离上下文（新开会话）
2. Sub-agent 用于并行任务（前端/后端可同时开发）
3. Orchestrator 只负责协调和最终验收，不参与具体实现
4. 每个 Agent 只读取自己需要的文件，避免上下文污染
```

---

## 九、软件过程管理核心概念的 AI 时代适应

### 9.1 Scrum 框架的适应

本项目实质上运行了一个简化的 Scrum 框架：

| Scrum 概念 | 传统形式 | AI 时代的适应形式 |
|---|---|---|
| **Product Backlog** | 需求文档 | PRD.md（AI 可读的结构化需求） |
| **Sprint** | 2周迭代 | 用户故事粒度的小迭代（1-2天/story） |
| **Sprint Planning** | 规划会议 | Plan Agent 生成计划 + 人工确认 |
| **Daily Scrum** | 每日站会 | memory/ 日志机制 + 启动时上下文加载 |
| **Sprint Review** | 功能演示 | `pnpm build` + `mvn compile` 零错误验证 |
| **Sprint Retrospective** | 回顾会 | process_bug.md + team_work_coding.md 复盘 |
| **Definition of Done** | 约定标准 | 编译通过 + CI 通过 + Review Agent 通过 |

AI 没有消灭 Scrum，而是**加速了每个 Sprint 的速度**，同时对"需求清晰度"提出了更高要求——因为 AI 不会追问"你说的这个需求具体什么意思"，它会直接按最可能的理解实现。

### 9.2 代码审查的再设计

传统代码审查解决"一个人看自己代码的盲点"问题。在 AI 辅助开发中，这个问题被放大——AI 没有"盲点意识"，它会生成在统计上合理但在具体场景中错误的代码，且不会主动怀疑自己。

本项目通过**上下文隔离的 Review Agent** 解决这一问题：Review Agent 不知道 Code Agent 为什么这样写，只能从代码本身出发评估设计合理性。这比传统代码审查更严格，因为它没有"我知道你这样写是为了解决那个问题"的上下文偏袒。

### 9.3 风险识别与实际结果

本项目实际遇到的三大风险，对应传统风险管理的三个类别[8]：

| 风险类别 | 实际风险 | 处置结果 |
|---|---|---|
| **技术风险** | Spring Security 默认行为与预期不符 | 延误1天，显式配置 SecurityFilterChain 解决 |
| **团队协作风险** | 多人修改同一文件产生冲突 | 模块拆分 + INSERT IGNORE 解决 |
| **环境风险** | Mac Podman 与 Docker 行为差异、华为云 CI 规则未知 | 适配 Compose 配置 + MR 流程解决 |

AI 辅助开发没有消灭这些风险，只是改变了风险的具体表现形式。技术风险的来源从"开发者对框架理解不足"变为"AI 对框架边界行为理解不足"；但本质上都是技术风险，处置方式也相同——加强技术验证，显式配置而非依赖默认行为。

---

## 十、结论

本文通过对 SeatFlow 项目的系统回顾，得出以下核心结论：

**1. Vibe Coding 不是银弹，而是杠杆**

AI 将"会写代码"这个技能的门槛大幅降低，但将"会管理 AI"（上下文工程、需求拆解、验收标准设计）推上了新的高位。开发者的核心竞争力从"能写出运行的代码"转向"能让 AI 写出好的代码"。

**2. 软件过程管理在 AI 时代更重要，而非更不重要**

因为 AI 不会遵守口头约定、不会主动问清需求、不会记住跨会话的历史，所有软件工程实践（需求文档化、分支策略、代码审查、测试隔离）都需要**显式、强制、可被 AI 感知**地执行，而不是依赖团队的隐性共识。

**3. Bug 的根源在于"上下文缺失"，而非"AI 能力不足"**

本项目12个 Bug 中，没有一个是因为"AI 太蠢"。都是因为：环境约束没有说清楚、需求拆解粒度不够、验收标准不明确，或者技术方案的副作用没有被充分评估。Vibe Coding 的质量上限，是工程师的软件工程素养，而非模型的代码能力。

**4. 团队协作是 AI 辅助开发的最大挑战**

单人 Vibe Coding 的效率极高，但多人协作时，AI 成为了一个"不参加会议的额外队友"，所有协作约定必须以文档形式显式传达给每个人的 AI 助手。这要求团队在项目启动时投入更多在"约定明确化"上，而非在开发过程中靠口头协调。

**5. 课程收获**

《软件过程管理》课程的核心教益在于让我理解：软件开发不只是技术问题，更是协调问题——协调人与人、人与工具、工具与工具之间的预期一致性。这一洞见在 AI 辅助开发时代非但没有过时，反而因为"AI 是个完全按指令行事但没有主动沟通能力的协作者"而变得更加关键。

如何写出让 AI 能够正确执行的"指令"，如何设计让 AI 生成的代码被人类可验证的"验收标准"，如何在 AI 参与下维护团队协作的一致性——这些问题的答案，正是软件过程管理这门学科在 AI 时代的新使命。

---

## 参考文献

[1] Karpathy, A. (2025). *Vibe Coding: A New Paradigm for AI-Assisted Software Development*. Twitter/X thread, Feb 2025.

[2] 李光正. (2025). 谈谈AI编程工具的进化与Vibe Coding [博客]. Guangzheng Li's Blog. https://guangzhengli.com/blog/zh/vibe-coding-and-context-coding

[3] GIAC 全球互联网架构大会. (2026). Vibe Coding落地实战：从上下文工程到AI原生产品矩阵. https://giac.msup.com.cn/2026sz/course/19267

[4] ModelScope学习中心. (2025). 拒绝代码焦虑：基于Vibe Coding的AI应用工程化实战心法. https://www.modelscope.cn/learn/2875

[5] Anthropic. (2025). Context Engineering Best Practices: Compaction, Structured Notes, Just-in-time Retrieval, and Multi-Agent Architecture. 知乎综述: https://zhuanlan.zhihu.com/p/2011453309895062046

[6] Anthropic. (2024). *Building Effective Agents*. Anthropic Blog. 中文翻译：AI Workflow & AI Agent：架构、模式与工程建议. https://arthurchiao.art/blog/build-effective-ai-agent-zh/

[7] 知乎专栏. (2026). 让AI和你结对编程：首篇Vibe Coding系统综述论文深度解读. https://zhuanlan.zhihu.com/p/1994594361544045237

[8] Pressman, R. S., & Maxim, B. R. (2020). *Software Engineering: A Practitioner's Approach* (9th ed.). McGraw-Hill Education.

[9] Atlassian. (2024). 用户故事（含示例与模板）. https://www.atlassian.com/zh/agile/project-management/user-stories

[10] InfoQ. (2025). AI Coding 2025年终盘点：Spec正在蚕食人类编码，Agent造轮子拖时间. https://www.infoq.cn/article/5lxt9ibO77f3HKbITN5s

[11] 01.me. (2025). Claude的Context Engineering秘籍：从Anthropic学到的最佳实践. https://01.me/2025/12/context-engineering-from-claude/

[12] Scrum中文网. (2025). 未来已来，AI时代，团队为何更需要自组织与敏捷能力？. https://www.scrum.cn/41176.html

---

*本文基于 SeatFlow 项目真实开发过程撰写。*
*项目代码：https://github.com/hfutwz/openclaw-project-agent*
*华为云后端仓库：seat_booking_server | 华为云前端仓库：seat_booking_web*

---

## 附录

### 附录一：团队协作冲突完整记录（team_work_coding.md）

> 5人小组 Vibe Coding 协作开发过程中遇到的所有团队冲突问题、复现场景与解法。目标：帮助后续类似项目避免重蹈覆辙。

**CONFLICT-001：本地 MySQL 配置各不相同**

*冲突现象*：组员 A 本地 MySQL root 密码是 `root`，组员 B 是 `123456`，组员 C 没有本地 MySQL；`application.yml` 写死了一个人的配置，拉取代码后直接运行报 `Access denied`。

*根因*：数据库连接配置硬编码在 `application.yml`，无法适配不同本地环境。

*解法*：统一用 Docker/Podman 部署 MySQL，密码由 `deploy/.env` 统一管理，后端 `application.yml` 通过环境变量引用：`${DB_PASSWORD:seatflow123}`。

*更优解法*：用 `application-local.yml` + `.gitignore` 隔离本地配置，每人本地创建覆盖文件，不提交到 git。

---

**CONFLICT-002：init.sql 数据频繁修改导致合并冲突**

*冲突现象*：组员 A 扩充自习室/座位数据（data.sql v2.0→v3.0），组员 B 同时添加 RBAC 权限数据，两人修改同一文件，pull 时产生 merge conflict。

*根因*：`data.sql` 是单一文件，承载多个业务模块的初始数据，多人同时写入必然产生行级冲突。

*解法*：人工合并后统一为 v2.0 版本，用 `INSERT IGNORE` 保证幂等。

*更优解法*：按模块拆分 SQL 文件，MySQL 容器按字母顺序执行 `docker-entrypoint-initdb.d/` 下所有 `.sql`。

---

**CONFLICT-003：BCrypt 密码 Hash 不一致导致登录失败**

*冲突现象*：组员 B 写 `data.sql` 时用自己生成的 BCrypt hash，注释写 `-- admin123 ->` 但实际 hash 对应密码未知，其他组员登录一律报"密码错误"。

*根因*：BCrypt hash 不可逆，注释说明与实际 hash 不对应。

*解法*：统一替换回项目初始验证过的 hash（`admin123` → `$2a$10$XiJZwcfX1LTFisLwC3LtD.vu9Q745J1dgom5nkR8CR3RQsKbUEUFK`）。

*规范*：由一人统一生成所有测试账号 hash，注释写明明文，禁止个人修改。

---

**CONFLICT-004：代码同步时整目录覆盖，丢失已有改动**

*冲突现象*：`git checkout huawei-frontend/main -- src/` 整目录覆盖，批量座位生成功能消失。

*根因*：`git checkout <remote> -- <dir>` 是破坏性操作，直接覆盖本地文件，不会合并，不会报冲突。

*解法*：`git show huawei-frontend/feature/...:src/pages/admin/SeatManage.tsx > code-agent/frontend/src/pages/admin/SeatManage.tsx` 从历史恢复文件。

*规范*：同步他人代码**永远用 `git merge`，不用 `git checkout -- <dir>`**。

---

**CONFLICT-005：monorepo 路径导致文件放错位置**

*冲突现象*：`git checkout huawei-backend/main -- src/` 后 `src/` 出现在 monorepo 根目录（应在 `code-agent/backend/src/`）。

*根因*：华为云后端仓库的 `src/` 在其根目录，checkout 到 monorepo 时按原路径存放，路径错位。

*解法*：用 `git show <remote>:<src> > <dst>` 指定输出路径；用 `git rm -r --cached` 清理误放文件。

---

**CONFLICT-006：RBAC 表结构多人各自定义冲突**

*冲突现象*：组员 A、B 各自定义了权限相关表，字段名不一致（`role_name` vs `name`），合并时双重定义报错。

*根因*：多人分头开发，没有在开发前对表结构做统一评审。

*解法*：以组员 B 的 RBAC 设计为准，删除组员 A 的重复表定义，用 `INSERT IGNORE + SELECT JOIN` 插入权限关联数据。

*更优解法*：开发前召开"表结构评审会"，每人只负责自己模块的 `data_*.sql`，不允许修改他人负责的表。

---

**CONFLICT-007：华为云 main 分支保护规则拒绝 force push**

*冲突现象*：`git push huawei-backend <commit>:main --force` 报 `non-fast-forward` 被拒。

*根因*：华为云 CodeHub 对 main 分支设置保护规则，禁止 force push，要求通过 MR 合并。

*解法*：推送到临时分支，在华为云 Web UI 创建 MR 合并到 main。

---

**CONFLICT-008：MySQL Volume 未清空，init.sql 更新不生效**

*冲突现象*：更新 `init.sql` 重启容器后数据仍是旧的，前端自习室只显示4个而非6个。

*根因*：MySQL 使用 named volume 持久化数据，volume 存在时跳过 `init.sql` 执行。

*解法*：`podman-compose down -v` 删除 volume，重新 `up -d --build`。

---

**CONFLICT-009：前端构建工具冲突（npm vs pnpm）**

*冲突现象*：部分组员用 `npm install`，内部 registry 篡改 `package.json`，`pnpm-lock.yaml` 与 `package-lock.json` 同时存在导致构建不一致。

*解法*：强制规定只用 pnpm，删除 `package-lock.json`，在 `package.json` 中加入 `engines` 约束。

---

**CONFLICT-010：unrelated histories 导致 git pull 报错**

*冲突现象*：`git pull` 报 `refusing to merge unrelated histories`。

*根因*：`git subtree split` 生成的提交树与组员本地 clone 历史没有公共祖先节点。

*解法*：`git fetch origin && git reset --hard origin/main` 强制对齐远端版本。

---

**团队协作规范总结**

| 类别 | 规范 |
|---|---|
| 数据库配置 | 统一用 Docker/Podman；密码写在 `.env`，不硬编码 |
| SQL 文件 | 按模块拆分；每次变更后告知全员 `down -v` 重建 |
| 密码 Hash | 由一人统一生成；注释写明明文 |
| 代码同步 | 用 `git merge`，不用 `git checkout -- <dir>` |
| 文件路径 | 用 `git show <remote>:<src> > <dst>`，不用 `git checkout -- <dir>` |
| 分支策略 | feature → MR → main；禁止直接 push main |
| 前端工具 | 只用 pnpm；推送前 `pnpm build` 零错误 |
| 后端验证 | 推送前 `mvn compile` 零错误 |
| 表结构 | 开发前统一评审；每人只维护自己模块的表 |
| git 初始化 | 有 force push 时通知全员重新 clone |

---

### 附录二：开发过程 Bug 完整记录（process_bug.md）

> Vibe Coding 多 Agent 协作项目，所有 Bug 均发生在 AI 辅助开发过程中。本记录用于复盘和归因。

**BUG-001：登录返回 302 重定向，无法登录** | 归因：模型上下文不够

*现象*：前端点击登录，POST `/api/auth/login` 返回302，自动 GET `http://localhost/login`（无端口），连接被拒。

*根因*：`spring-boot-starter-security` 依赖存在时，即使注释了 `@EnableWebSecurity`，只要没有显式定义 `SecurityFilterChain` bean，Spring Boot auto-config 就会启用默认 formLogin 机制，将未认证请求302重定向到 `/login`（无端口号）。

*解法*：恢复 `@EnableWebSecurity` + 显式定义 `SecurityFilterChain` bean，设置 `anyRequest().permitAll()`，禁用 formLogin/httpBasic/CSRF/Stateless session。

---

**BUG-002：登录成功但用户信息为空，前端无法判断角色** | 归因：需求描述不清楚

*现象*：登录接口返回200，但 localStorage 中 userInfo 为空对象，admin 和学生界面完全相同。

*根因*：`AuthServiceImpl.login()` 只做了密码校验，返回 `LoginResponse("", 0L)` 空对象，未查询角色/权限。

*解法*：修改 `login()`，登录成功后查询 roles/permissions，构建 `UserInfoResponse` 作为 `LoginResponse.userInfo` 返回。

*归因*：需求描述只写了"验证用户名密码"，没有明确"返回角色权限信息"，Code Agent 按最小实现来做。

---

**BUG-003：登录成功后所有用户都跳转到学生端** | 归因：需求拆解不够细

*现象*：admin 登录后跳转到 `/student/rooms`，而非管理端。

*根因*：`Login.tsx` 中写死了 `navigate('/student/rooms')`，未根据用户角色动态跳转。

*解法*：读取 `localStorage.userInfo.userType`，ADMIN 跳转 `/admin/dashboard`，STUDENT 跳转 `/student/rooms`。

---

**BUG-004：数据库中文乱码** | 归因：模型上下文不够

*现象*：前端自习室名称显示为 `å›¾ä¹¦é¦†301` 等乱码。

*根因*：`init.sql` 头部缺少 `SET NAMES utf8mb4` 声明，MySQL 客户端连接时使用默认字符集（latin1）解析 SQL 文件。

*解法*：`init.sql` 文件头部加入：
```sql
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection=utf8mb4;
```

---

**BUG-005：Dockerfile 构建失败** | 归因：需求描述不清楚

*现象*：后端 `mvn: command not found`；前端 pnpm 11 要求 Node 22+，安装依赖报版本错误。

*根因*：Code Agent 选择了基础 JDK 镜像（无 Maven）；前端镜像版本未考虑 pnpm 版本要求。

*解法*：`eclipse-temurin:21-jdk` → `maven:3.9-eclipse-temurin-21`；`node:20-alpine` → `node:22-alpine`。

---

**BUG-006：前端构建验证不完整** | 归因：开发者 taste 不对

*现象*：修改代码后只用 `tsc -b` 验证，推送后 Docker 构建时 `vite build` 报错。

*根因*：`tsc -b` 只做类型检查，`vite build` 还会做 tree-shaking、import 分析等额外检查。两者不等价。

*解法*：规定推送前必须执行完整的 `pnpm build`（= `tsc -b && vite build`）。

---

**BUG-007：pnpm 安装被内部 npm registry 污染** | 归因：环境约束未传达

*现象*：`npm install` 报包缺失，或 `package.json` 被篡改写入内部源地址。

*根因*：沙箱环境的 npm 默认指向内部 registry，该 registry 未镜像所有公共包，且安装时会修改配置文件。

*解法*：全部改用 pnpm + 公共源，将"前端只用 pnpm"作为强约束写入项目规范。

---

**BUG-008：git 推送出现 "refusing to merge unrelated histories"** | 归因：技术方案副作用考虑不足

*现象*：组员 `git pull` 报 `refusing to merge unrelated histories`。

*根因*：`git subtree split` 生成的提交历史是全新的，与组员通过 `git clone` 拿到的历史没有公共祖先节点。

*解法*：`git fetch origin && git reset --hard origin/main` 强制对齐远端。

---

**BUG-009：批量座位生成 UI 被组员代码覆盖** | 归因：需求描述不清楚

*现象*：同步组员 B 代码后，「批量生成座位」功能消失。

*根因*：`git checkout huawei-frontend/main -- src/` 整目录覆盖，我已改动的 `SeatManage.tsx` 被旧版本覆盖。

*解法*：从自己的历史分支恢复文件：
```bash
git show huawei-frontend/feature/task_a_room_management:src/pages/admin/SeatManage.tsx \
  > code-agent/frontend/src/pages/admin/SeatManage.tsx
```

---

**BUG-010：MySQL Volume 未清空导致 init.sql 不生效** | 归因：开发者 taste 不对

*现象*：更新了 `init.sql`，重启 podman 后前端仍显示旧数据，自习室只有4个而非6个。

*根因*：MySQL 容器使用 named volume 持久化数据。volume 已存在时 MySQL 直接跳过 `init.sql`，使用已有数据。

*解法*：`podman-compose down -v` 删除 volume，再重新 `up -d --build`。

---

**BUG-011：同步代码时文件放到 monorepo 根目录** | 归因：模型上下文不够

*现象*：`git checkout huawei-backend/main -- src/` 后 `src/` 目录直接出现在 monorepo 根目录，而非 `code-agent/backend/src/`。

*根因*：华为云后端仓库的 `src/` 在其根目录，checkout 到 monorepo 时按原路径存放，路径错位。

*解法*：用 `git show <remote>/<branch>:<file> > code-agent/backend/<目标路径>` 指定输出路径，并用 `git rm -r --cached` 清理误放文件。

---

**BUG-012：华为云后端 main 分支有保护规则，不允许 force push** | 归因：环境约束未传达

*现象*：`git push huawei-backend <commit>:refs/heads/main --force` 报 `non-fast-forward`，推送被拒。

*根因*：华为云 CodeHub 对 main 分支设置了分支保护规则，禁止 force push，需要通过 MR 合并。

*解法*：推送到临时分支，在华为云平台创建 MR 合并到 main。

---

**归因总结**

| 归因类型 | 涉及 Bug | 说明 |
|---|---|---|
| **模型上下文不够** | BUG-001、004、011 | 模型对框架边界行为、底层机制理解不完整 |
| **需求描述不清楚** | BUG-002、005、009 | 任务描述缺少关键约束，Agent 按最简路径实现 |
| **需求拆解不够细** | BUG-002、003 | 用户故事粒度太粗，验收条件不够具体 |
| **开发者 taste 不对** | BUG-003、006、010 | AI 倾向"能跑就行"，缺乏对健壮性的自发追求 |
| **环境约束未传达** | BUG-007、012 | 基础设施、平台规则没有在 prompt 中显式说明 |
| **技术方案副作用考虑不足** | BUG-008、011 | 选型时只关注主路径，忽略对多人协作的影响 |

**经验教训**

1. 每次推送前必须 `pnpm build` 零错误，不能只跑 `tsc -b`
2. MySQL 数据变更后必须 `down -v` 清 volume，`INSERT IGNORE` 不能更新已有数据
3. 多人代码同步用 `git show` 输出到目标路径，不要 `git checkout -- .` 整目录覆盖
4. Spring Security 必须显式定义 `SecurityFilterChain` bean，不能依赖注释注解来禁用
5. SQL 文件头部必须有 `SET NAMES utf8mb4`，字符集声明不能省略
6. 华为云 main 分支有保护，只能通过 MR 合并，不要尝试 force push
7. Vibe Coding 的 prompt 要包含环境约束：Node 版本、包管理器、CI 平台规则、分支策略等
