# AI 辅助开发环境下的软件过程管理实践
# ——以自习座位预约系统（SeatFlow）为例

**摘要**：本文以"自习座位预约系统"（SeatFlow）Lab 项目为研究载体，系统记录并分析了在 OpenClaw + Claude 大语言模型驱动的 Vibe Coding 范式下，如何构建多 Agent 协作框架、落地用户故事驱动的敏捷开发流程、设计 CI/CD 流水线，以及在5人小组真实协作场景中发生的冲突与解法。通过 49 次 Git 提交、112 个后端 Java 文件、24 个前端组件、47 个 REST API、12 个实测 Bug 和 10 类团队冲突问题的详细分析，本文提出了一套面向 AI 辅助编程的软件过程管理 SOP，归纳了 Vibe Coding 在上下文工程、需求拆解、隔离测试、多 Agent 编排等维度的利弊权衡，并对软件过程管理课程核心概念在 AI 时代的适应与挑战进行了批判性思考。

**关键词**：Vibe Coding；大语言模型辅助编程；多 Agent 协作；用户故事；敏捷开发；上下文工程；软件过程管理；CI/CD

---

## 一、引言

2025 年以来，以 Claude Code、GitHub Copilot、Cursor 为代表的 AI 编程工具快速普及，催生了"Vibe Coding"这一新型开发范式——开发者以自然语言描述意图，由大语言模型（LLM）负责代码生成与修改，人类退化为"意图提供者"和"验收者"[1]。这一模式对传统软件过程管理带来了深刻冲击：当代码生成速度以小时计、Bug 修复以秒计时，Scrum 的两周迭代、代码审查的人工流程、需求文档的精细拆解，是否还有意义？

本文以华中科技大学2026年春季《软件过程管理》课程 Lab 项目——自习座位预约系统（SeatFlow）——为具体载体，尝试回答上述问题。SeatFlow 是一个涵盖学生预约、签到、RBAC 权限管理的 Web 全栈系统，由5名组员在 AI 辅助下协作开发，历时约一个月。本文不是泛泛而谈 AI 如何"提效"，而是从真实的提交记录、实测 Bug、团队冲突和流程决策出发，探讨 AI 时代软件过程管理的具体实践路径。

---

## 二、从0到1：基于 OpenClaw 的 Vibe Coding 初始化

### 2.1 上下文工程：让 AI 知道它是谁

Vibe Coding 最大的挑战不是模型能力，而是**上下文管理**。LLM 在每次会话中都从零开始，没有持久记忆。传统软件工程师的隐性知识（代码风格、技术选型历史、团队约定）需要显式地注入到 AI 的上下文中，才能保证输出的一致性[2]。

本项目采用 OpenClaw 平台，其核心设计理念是将 AI Agent 的身份、记忆、工具、目标等分解为结构化文件，构成完整的"上下文工程"体系：

**SOUL.md（灵魂文件）**：定义 Agent 的行为准则和风格。核心规则是"直接动手，少问废话"——避免 AI 产生过多确认性对话，降低交互摩擦。这对照了传统软件工程中"做事前先问清楚"的原则，在 AI 辅助场景下，过度确认反而会打断开发节奏。

**USER.md（用户画像）**：记录与 AI 协作的人类开发者信息，包括技术偏好（只用 pnpm、Java 路径、部署用 Podman 而非 Docker）。这些约束如果不显式记录，AI 会基于概率分布猜测，产生不符合实际环境的代码。

**AGENTS.md（Agent 框架）**：定义会话启动流程：先读 SOUL.md、USER.md、memory/ 目录，再执行任务。这相当于给 AI 设计了"上班前的晨会"——确保每次会话都有足够背景再开始工作。

**memory/YYYY-MM-DD.md（日志记忆）**：每日记录关键决策、技术踩坑、进度状态。解决了 LLM 跨会话失忆的根本问题——不是依赖模型的内置记忆，而是让 AI 主动维护外部文件作为持久化记忆。

这套机制本质上是一种**结构化 Prompt 工程**的升级版，从"每次对话写 Prompt"升级为"维护一套 AI 可读的项目知识库"[3]。Anthropic 官方将其称为"上下文工程"（Context Engineering），核心策略包括：Compaction（压缩摘要）、结构化笔记（持久化记忆）、即时检索（Just-in-time retrieval）、多 Agent 架构（Sub-agent）[4]。

### 2.2 AI 使用透明度

本项目所有代码均在 AI 辅助下生成，具体分工如下：

| 环节 | AI 工具 | 人工介入程度 |
|---|---|---|
| 需求分析与 PRD 撰写 | Claude 3.7 Sonnet | 高（人工主导框架，AI 补全细节） |
| 后端代码生成（Spring Boot） | Claude 3.7 Sonnet | 中（AI 生成初稿，人工修复 Bug） |
| 前端代码生成（React+Ant Design） | Claude 3.7 Sonnet | 中（AI 生成，人工联调） |
| 数据库 schema 设计 | Claude 3.7 Sonnet | 高（人工主导表结构，AI 生成 DDL） |
| CI/CD 配置 | Claude 3.7 Sonnet | 低（AI 生成，轻微调整） |
| Bug 修复 | Claude 3.7 Sonnet | 中（AI 定位，人工确认修复方向） |
| 文档写作 | Claude 3.7 Sonnet | 中（AI 初稿，人工补充实际数据） |

---

## 三、设计阶段：多 Agent 协作框架

### 3.1 为什么需要多 Agent

单一 AI 对话存在两个核心问题：

1. **上下文窗口限制**：随着对话轮次增加，早期约定会被"稀释"，AI 生成的代码逐渐偏离原始设计意图
2. **角色混淆**：同一个 AI 既写代码又做 Review，相当于让同一个人同时扮演"开发者"和"审查者"，必然产生认知偏差

本项目将开发流程拆解为6个独立 Agent，各自维护隔离的上下文：

```
Orchestrator（主 Agent）
├── Plan Agent      → plan-agent/plan.md（制定开发计划）
├── Code Agent      → code-agent/（前后端代码生成）
│   ├── backend/    Spring Boot 3 + MyBatis Plus
│   └── frontend/   React 19 + Ant Design
├── Review Agent    → review-agent/（代码审查）
├── Test Agent      → test-agent/（测试用例生成与执行）
└── Delivery Agent  → delivery-agent/（最终交付验证）
```

**Review Agent 和 Test Agent 的隔离设计**是关键。如果 Code Agent 写完代码立刻在同一上下文中做 Review，AI 会倾向于"自我合理化"——因为它"记得"自己为什么这样写。独立的 Review Agent 从新鲜的上下文出发，更容易发现设计问题[5]。

这一设计与传统软件工程中"作者不做自测"原则是同构的——不同之处在于，我们用上下文隔离替代了人员隔离。

### 3.2 PRD 与用户故事驱动

Plan Agent 的核心产出是 `plan/plan.md`，其中将所有需求按用户故事（User Story）组织：

**学生端（US-S01 ~ US-S11）**：

| 编号 | 用户故事 | 验收条件 |
|---|---|---|
| US-S01 | 查看所有可用自习室及开放时间 | 首页展示全部开放自习室，含地址/时间/剩余座位 |
| US-S02 | 查看座位图并选择座位 | 网格布局，颜色区分状态，点击可预约 |
| US-S03 | 按整点小时预约（最多4小时） | 时间选择器，超出4小时报错 |
| US-S04 | 输入动态编码签到 | 每日生成随机6位码，输入后匹配有效预约 |
| US-S05 | 收到预约提醒 | 15分钟前推送 WebSocket 通知 |
| US-S06 | 超时未签到自动取消 | 定时任务：逾期15分钟后状态改 CANCELLED，记违约 |
| US-S07 | 取消预约（含违约边界） | 开始前30分钟内取消记违约 |
| US-S08 | 多条件搜索座位 | 按插座类型/位置/时间过滤 |
| US-S09 | 查看历史预约并再次预约 | 历史列表，支持一键复制条件重新预约 |
| US-S10 | 查看个人违约记录 | 违约列表含原因、时间、累计次数 |
| US-S11 | 智能助手自然语言交互 | 自然语言查询，function calling 映射系统操作 |

**管理端（US-A01 ~ US-A06）**：

| 编号 | 用户故事 | 验收条件 |
|---|---|---|
| US-A01 | 登记/注销自习室 | CRUD，支持设置开放时间段 |
| US-A02 | 登记/注销座位（含插座/位置标记） | 支持批量生成（坐标范围）、单个管理 |
| US-A03 | 查看预约统计仪表盘 | 按自习室、时段统计预约量、占用率 |
| US-A04 | 代客预约/取消 | 管理员指定用户预约，记录操作人 |
| US-A05 | 维护角色和权限（RBAC） | 4种角色，8种权限粒度，接口级 @PreAuthorize |
| US-A06 | 调整系统参数 | max_reservation_hours 等参数可配置 |

用户故事的核心价值在于**将需求转换为 AI 可验证的验收条件**。传统需求文档对人类有效，但对 AI 而言，越具体的约束越能产生更准确的代码。"作为管理员，我希望能批量生成座位"这种叙述方式，比"实现座位批量创建功能"更容易让 AI 理解"谁在用、怎么用、边界是什么"[6]。

### 3.3 Plan 文件的核心地位

`plan/plan.md` 是整个开发的"北极星"——Code Agent 的每一次生成任务都以 Plan 中的用户故事为基准。这产生了一个重要约束：**Plan 文件不能被随意修改**。一旦 Plan 改变，已有代码的逻辑依据就会消失，AI 下次生成时可能产生与已有代码矛盾的实现。

这与传统软件工程的"需求冻结"原则完全一致，只是在 AI 辅助开发中表现更为极端——因为 AI 没有人类工程师的上下文记忆，它完全依赖当前可见的文档来理解系统状态。

---

## 四、开发阶段：用户故事分支策略与 Git 实践

### 4.1 一个用户故事一个分支

本项目采用严格的用户故事分支策略：

```
main（稳定版本）
├── feature/task_a_room_management（组员A：US-A01/A02/A05/A06）
├── feature/US-S01（学生端自习室查看）
├── feature/US-S02（座位图与预约）
├── feature/US-A03（预约统计仪表盘）
└── ...
```

华为云 CodeHub 上同时存在18个功能分支（`feature/US-S01` ~ `feature/US-S11`，`feature/US-A01` ~ `feature/US-A06`）。这种粒度的分支策略有两个重要作用：

**可追溯性**：每个 commit 与特定用户故事绑定，`git log --grep="US-A02"` 即可追溯座位管理功能的完整修改历史。这在传统 monorepo 开发中依赖 commit message 规范，而在 AI 辅助开发中，分支隔离提供了更强的保障。

**冲突最小化**：不同用户故事对应不同业务模块，分支隔离大幅减少了多人同时修改同一文件的概率。

合并策略采用 `--no-ff`（禁止 fast-forward），在提交历史中保留每个用户故事的合并节点，使历史图谱清晰可读：

```bash
git merge feature/task_a_room_management --no-ff \
  -m "feat: 合并 feature/task_a_room_management → main（US-A01/A02/A05/A06 完成）"
```

### 4.2 三仓 monorepo 架构

本项目维护三个仓库，各有明确职责：

| 仓库 | 内容 | 更新策略 |
|---|---|---|
| **GitHub monorepo** | 全部 Vibe Coding 过程细节：Agent 配置、PRD、Plan、测试报告、deploy 配置 | 每次功能完成后 push |
| **华为云后端** `seat_booking_server` | 纯后端业务代码（`code-agent/backend/` subtree）| `git subtree split` + push |
| **华为云前端** `seat_booking_web` | 纯前端业务代码（`code-agent/frontend/` subtree） | `git subtree split` + push |

使用 `git subtree split` 将 monorepo 中特定目录拆分为独立历史树，推送到华为云独立仓库：

```bash
# 推送后端到华为云
BACKEND_COMMIT=$(git subtree split --prefix=code-agent/backend main)
git push huawei-backend "${BACKEND_COMMIT}:refs/heads/feature/task_a_room_management"
```

这一架构的优势是**全过程可审计**：GitHub 保留所有决策痕迹，华为云呈现干净的业务代码，互不干扰。

### 4.3 Commit Message 规范

所有提交遵循 Conventional Commits 规范：

```
<type>(<scope>): <description>

类型：feat（新功能）| fix（修复）| docs（文档）| chore（维护）| refactor（重构）
范围：task-a | frontend | backend | docker | db
```

项目共完成 49 次有意义的 commit（排除初始化和同步提交），分布如下：

| 类型 | 数量 | 说明 |
|---|---|---|
| feat | 18 | 新功能（用户故事实现） |
| fix | 21 | Bug 修复（包括部署修复） |
| docs | 7 | 文档（PRD/Plan/README） |
| chore | 3 | 维护（agent 配置更新） |

修复类提交（fix）占比高达43%，这是 Vibe Coding 的典型特征——AI 能快速生成功能框架，但在边界处理、框架配置细节上容易产生错误，需要大量修复迭代。

---

## 五、团队协作冲突的深度分析

在5人小组协作过程中，出现了10类具体冲突。以下选取最有代表性的四类进行深度分析：

### 5.1 环境配置冲突：数据库密码各不相同

**现象**：组员 A 本地 MySQL root 密码是 `root`，组员 B 是 `123456`，组员 C 没有安装本地 MySQL。`application.yml` 写死了一个人的配置，导致其他人拉代码后无法直接运行。

**根因分析**：传统开发中，团队通常维护一份"环境搭建文档"，每个人手动对齐本地环境。这种方式在小团队中勉强可行，但脆弱——文档一旦过时，新成员上手成本极高。

**解法对比**：

| 方案 | 描述 | 优劣 |
|---|---|---|
| 文档约定 | 统一规定密码为 `root`，人工对齐 | 脆弱，文档更新不及时 |
| 环境变量 + .gitignore | `${DB_PASSWORD:default}`，本地 `.env` 不提交 | 规范，但需每人手动创建 |
| **Docker/Podman 统一部署** | 所有人用容器 MySQL，密码由 `.env` 统一管理 | **最强一致性**，本次采用方案 |

我们最终方案是容器化 MySQL，密码定义在 `deploy/.env`（不提交 git），后端 `application.yml` 连接 `localhost:3307`。这实际上是将"环境一致性"从"约定"升级为"强制"——容器本质上是可重复的环境规格说明书。

### 5.2 数据文件冲突：init.sql 多人并发修改

**现象**：组员 A 在 `data.sql` 中添加自习室和座位数据（v2.0），组员 B 同时添加 RBAC 权限数据，两人修改同一文件，pull 时产生 merge conflict。

**根因分析**：`data.sql` 是一个单一文件，承载了多个业务模块的初始化数据。这违反了"单一职责"原则——一个文件的内容应该只因一个原因而改变。多人同时修改同一文件，冲突是必然结果，与 AI 辅助开发无关，是架构设计问题。

**解法**：按模块拆分 SQL 文件，利用 Docker MySQL 容器自动按字母顺序执行 `docker-entrypoint-initdb.d/` 下所有 `.sql` 文件的特性：

```
deploy/mysql/
  01_schema.sql         # 建表（统一维护）
  02_rbac_seed.sql      # 组员 B 负责
  03_room_seat_seed.sql # 组员 A 负责
  04_reservation_seed.sql # 组员 C 负责
```

这一方案将"文件层面的冲突"转变为"目录层面的分工"，每个组员只拥有自己文件的所有权，冲突面从 O(n²) 降为 O(1)。

### 5.3 代码覆盖：整目录 git checkout 丢失改动

**现象**：组员 A 实现了「批量生成座位」功能（`SeatManage.tsx`）。在同步组员 B 的 RBAC 代码时，执行了 `git checkout huawei-frontend/main -- src/`，整目录覆盖导致批量生成功能消失。

**根因分析**：`git checkout <remote> -- <dir>` 是破坏性操作，不会触发 merge 流程，不会检查冲突，直接覆盖本地文件。这是一个典型的"工具使用错误"——在 AI 辅助场景下，Agent 倾向于选择最简单的命令，而最简单的命令不一定是最安全的。

这个 Bug 的 Vibe Coding 归因是**任务描述歧义**：用户说"把华为云代码同步过来"，没有说明"只同步新增内容，不覆盖已有改动"。AI 选择了语义最直接的实现，却忽略了隐含的约束。

**解法**：建立明确的同步 SOP：
- 同步整个目录：用 `git merge`，不用 `git checkout -- <dir>`
- 同步特定文件：用 `git show <remote>:<path> > <local_path>`

### 5.4 RBAC 表结构冲突：多人各自建表

**现象**：组员 B 负责 RBAC，定义了 `t_role`、`t_permission` 等4张表。组员 A 在早期开发中也定义了部分权限相关表，字段名不一致（`role_name` vs `name`），合并时双重定义报错。

**根因分析**：这是一个架构协商缺失的问题。传统软件工程中，数据库 schema 是团队的"公共契约"，需要在开发前统一设计并锁定。在 AI 辅助开发中，这个问题被放大——AI 会基于用户描述"合理推测"字段名，不同组员的 AI 会产生不同的合理推测。

**解法**：在开发启动阶段组织"表结构评审会"，将所有表的字段名、类型、枚举值写入统一 `schema.sql`，每人只维护自己模块的 `data_*.sql`，不允许修改他人负责的表定义。这与传统软件工程的"接口先行"原则一致，只是在 AI 时代需要更严格地执行，因为 AI 不会主动遵守口头约定。

---

以下为完整团队协作冲突记录（引自项目 `team_work_coding.md`）：
团队协作冲突完整记录详见文末附录一。

---

## 六、开发过程 Bug 分析与 Vibe Coding 归因

本项目共发现并修复12个实测 Bug。以下从 Vibe Coding 视角进行深度归因分析：

### 6.1 Bug 分类统计

| 归因类型 | Bug 数量 | 典型案例 |
|---|---|---|
| **模型上下文不够** | 3 | Spring Security 302 重定向、MySQL 字符集乱码、monorepo 路径错位 |
| **需求描述不清楚** | 3 | userInfo 未返回、Dockerfile 镜像选择错误、代码同步覆盖改动 |
| **需求拆解不够细** | 2 | 登录跳转硬编码、userInfo 缺失 |
| **开发者 taste 不对** | 3 | 前端构建验证不完整、MySQL Volume 不清、角色跳转硬编码 |
| **环境约束未传达** | 2 | pnpm registry 污染、华为云分支保护 |
| **技术方案副作用考虑不足** | 2 | git unrelated histories、monorepo 路径问题 |

### 6.2 典型 Bug 深度分析

**BUG-001：登录返回 302 重定向**

这是本项目最典型的"模型上下文不够"案例。Spring Boot 的 Security auto-configuration 机制是：只要 `spring-boot-starter-security` 依赖存在，若无 `SecurityFilterChain` bean，自动启用 formLogin + 302 重定向。AI 生成 SecurityConfig 时注释了 `@EnableWebSecurity` 注解，但没有意识到这不足以禁用 auto-config，导致登录 POST 请求被拦截并 302 到 `http://localhost/login`（无端口号），前端无法跟随。

修复方案：恢复 `@EnableWebSecurity`，显式定义 `SecurityFilterChain` bean 全放行。这是一个需要对 Spring Boot 自动配置机制有深度理解才能避免的错误，对于 AI 而言，它见过足够多的 SecurityConfig 代码，但对框架的默认行为边界理解不如资深 Java 工程师精确。

**BUG-004：数据库中文乱码**

`init.sql` 中建库语句写了 `CHARACTER SET utf8mb4`，但没有在文件头部声明 `SET NAMES utf8mb4`。MySQL 客户端连接字符集和服务端字符集是两套独立配置，前者控制"写入时用什么编码"，后者控制"存储时用什么编码"。AI 知道建库要写 utf8mb4，但对 MySQL 字符集体系的两层结构理解不够深入，导致遗漏了客户端字符集声明。

修复方案：在 `init.sql` 头部加入三行声明：
```sql
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection=utf8mb4;
```

**BUG-010：MySQL Volume 不清，init.sql 不生效**

这是"开发者 taste 不对"的典型案例。AI 选择 `init.sql` + `INSERT IGNORE` 作为数据初始化方案，认为 `IGNORE` 关键字能保证幂等性，可以随时重跑。但实际上，MySQL 容器在 volume 存在时会跳过 `init.sql` 执行，`INSERT IGNORE` 根本没有机会运行。

这个错误暴露了 AI 对 Docker volume 生命周期的理解盲点：它能正确生成 `docker-compose.yml` 中 volume 的配置语法，但对 volume 在 MySQL 初始化流程中的角色理解不够准确。更好的解法是 Flyway/Liquibase 版本化迁移管理，但这超出了 MVP 阶段的范围。

以下为完整 Bug 记录详见文末附录二。

---

## 七、CI/CD 流水线设计

### 7.1 华为云 DevCloud 流水线

本项目基于华为云 DevCloud 构建 CI/CD 流水线，每次 commit 自动触发：

```
代码推送 (git push)
    ↓
CI 阶段：
├── 后端构建 (mvn clean package -DskipTests)
├── 后端单元测试 (mvn test)
├── 前端构建 (pnpm install && pnpm build)
└── 代码质量检查 (SonarQube / 华为云代码检查)
    ↓
CD 阶段（main 分支触发）：
├── Docker 镜像构建 (podman build)
├── 镜像推送到容器仓库
└── 自动部署到测试环境
```

每次 CI 通过是合并到 main 的必要条件，这在 AI 辅助开发中尤为重要——AI 生成的代码可能通过静态类型检查但在运行时报错，CI 的自动化测试是最后一道安全网。

### 7.2 数据库迁移策略

SQL schema 变更遵循版本化设计原则：

- `schema.sql`（v1.0）：初始建表，包含所有基础表和约束
- `data.sql`（v1.0→v2.0→v3.0）：种子数据，用 `INSERT IGNORE` 保证幂等
- 每次迭代的 schema 变更通过新增 `ALTER TABLE` 语句追加，不修改已有建表语句

生产环境应迁移到 Flyway 管理，实现：
- 版本化迁移文件（`V1__init.sql`、`V2__add_column.sql`）
- 自动检测未执行的迁移脚本
- 回滚支持（`U1__rollback.sql`）

### 7.3 可用性保障

`docker-compose.yml` 配置 health check 和 restart 策略：

```yaml
backend:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
    interval: 30s
    timeout: 10s
    retries: 3
  restart: always
  depends_on:
    mysql:
      condition: service_started   # 不依赖 healthy，由 HikariCP 内置重试处理
```

Podman 环境下移除了 `condition: service_healthy` 以避免 Podman 不支持 healthcheck condition 的兼容问题，改为后端 HikariCP 连接池内置重试机制（`HIKARI_INITIALIZATION_FAIL_TIMEOUT=60`）。

---

## 八、对 Vibe Coding 的批判性思考与 SOP

### 8.1 Vibe Coding 的定义与本质

Vibe Coding（感觉式编程）是2025年 Andrej Karpathy 提出的概念，指将代码编写的主导权完全移交给 AI，开发者只需用自然语言描述意图，AI 负责生成和迭代代码[1]。学界对此已有系统综述[7]，将其定义为"以大语言模型为核心的软件开发工程方法论，人类、软件项目和编程智能体构成动态三角关系"。

但本次实践告诉我，"将主导权完全移交给 AI"这个描述有失准确。更准确的描述是：**Vibe Coding 将开发者的工作从"写代码"升级为"管理 AI 上下文"**。开发者不再负责每一行代码，但必须负责：
- 维护 AI 能理解的上下文文件（SOUL.md、Plan.md、memory/）
- 设计合理的任务粒度（用户故事的拆解深度直接决定 AI 输出质量）
- 验证 AI 输出（pnpm build 零错误、mvn compile 零错误）
- 管理 AI 无法感知的环境约束（CI 平台规则、包管理器、分支策略）

### 8.2 Vibe Coding 的五维利弊权衡

**第一维：速度 vs 准确性**

AI 能在数分钟内生成一个完整的 Spring Boot Controller + Service + Mapper 三层结构，这在传统开发中需要数小时。但本项目的 fix commit 占比 43%，说明生成速度的代价是更高的修复密度。AI 擅长"宽度"（快速搭框架），不擅长"深度"（框架配置的边界行为）。

**第二维：需求粒度 vs 输出质量**

实践发现，用户故事的粒度直接决定 AI 输出质量。"实现座位管理功能"这样的粗粒度需求会让 AI 做很多猜测，产生大量偏差；"作为管理员，我希望通过左上角和右下角坐标批量生成矩形区域座位，生成前预览总数"这样的精细化需求，AI 的实现几乎不需要修改。

**粗粒度需求的代价**：AI 需要在"什么是合理实现"上做概率猜测，猜错了就是 Bug。

**精细化需求的代价**：需求分析阶段需要更多人工投入，但可以减少后期修复成本。

总体来看，"前期多投入需求拆解，后期少投入 Bug 修复"是 Vibe Coding 的最佳实践。

**第三维：上下文管理 vs 任务规模**

AI 的上下文窗口是有限的。随着会话进行，早期的技术约定（数据库字段名、接口规范）会被后续对话逐渐稀释。本项目通过 memory/ 日志机制解决了跨会话遗忘问题，但在单次长对话中，上下文污染仍是难题——这也是引入多 Agent 隔离的核心动机。

**第四维：AI 辅助 vs 人工监督**

"AI 能跑就行"（BUG-003、BUG-006、BUG-010 的共同归因）是 Vibe Coding 的典型陷阱。AI 倾向于生成"最小可运行实现"，而不是"最优实现"。前端跳转写死路由、构建验证只跑 tsc、数据库用 INSERT IGNORE 而非 Flyway——这些都是"能跑"但不是"好的"实现。

人工监督的核心职责不是写代码，而是**把控设计品质（taste）**——什么叫"合适的抽象层次"，什么叫"合理的错误处理"，AI 的直觉来自训练数据的统计分布，未必符合当前项目的实际需求。

**第五维：团队协作 vs AI 辅助的张力**

AI 辅助编程天然适合个人开发——单人上下文完整、决策路径清晰。但在多人协作中，AI 成为了"额外的队友"——它不参与团队会议，不了解他人的改动，不理解口头约定。这意味着所有团队约定必须**显式文档化**，否则 AI 无法感知，产生的代码与团队规范不符。

本项目将这一点具体化为："所有约束必须写入项目文件（AGENTS.md、USER.md、Plan.md），口头约定不算约定"。

### 8.3 个人 Vibe Coding SOP

基于本次实践，总结以下可操作的 Vibe Coding 标准操作规程：

**阶段一：初始化上下文（项目启动时执行一次）**

```
1. 创建 SOUL.md（AI 行为风格）
2. 创建 USER.md（人类开发者偏好：技术栈、环境约束、禁止事项）
3. 创建 AGENTS.md（启动流程：先读 SOUL.md → USER.md → memory/ → 再开始工作）
4. 将所有环境约束写入 USER.md：
   - Java 路径、Node 版本、包管理器（只用 pnpm）
   - CI 平台规则（main 分支保护、MR 流程）
   - 数据库密码管理方式（.env 文件）
5. 选择合适的 AI 模型（长上下文任务用 Claude，代码生成用 Sonnet）
```

**阶段二：需求拆解（每个功能模块执行）**

```
1. 将需求拆解为用户故事（粒度：每个故事约 4-8 小时工作量）
2. 每个用户故事写明：
   - 角色（作为 X）+ 动作（我希望能 Y）+ 价值（以便 Z）
   - 验收条件（3-5 条具体可测试的条件）
   - 排除项（明确说明哪些不做）
3. 用户故事通过 Plan Agent 审核后锁定，不随意修改
```

**阶段三：开发循环（每个用户故事重复）**

```
1. 从 main 签出 feature/<US-ID> 分支
2. 将用户故事 + 验收条件 + 相关约束注入 Code Agent 上下文
3. 生成代码后立即验证：mvn compile（后端）或 pnpm build（前端）
4. 验证通过后，用隔离上下文的 Review Agent 审查
5. Fix → 重验证 → 推送
6. feature 分支通过 CI → MR → Review → 合并 main
```

**阶段四：记忆维护（每次会话结束时）**

```
1. 更新 memory/YYYY-MM-DD.md：
   - 今天解决了什么 Bug，根因是什么
   - 做了什么技术决策，选择理由是什么
   - 下次会话需要知道的事项
2. 遇到重要约束（如 CI 平台规则），同步更新 USER.md
3. 遇到新工具/命令，更新 TOOLS.md
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
| **Daily Scrum** | 每日站会 | memory/ 日志机制 + 会话启动时的上下文加载 |
| **Sprint Review** | 功能演示 | pnpm build + mvn compile 零错误验证 |
| **Sprint Retrospective** | 回顾会 | process_bug.md + team_work_coding.md 复盘 |
| **Definition of Done** | 约定标准 | 编译通过 + CI 通过 + Review Agent 通过 |

AI 没有消灭 Scrum，而是**加速了每个 Sprint 的速度**，同时对"需求清晰度"提出了更高要求——因为 AI 不会追问"你说的这个需求具体什么意思"，它会直接按最可能的理解实现。

### 9.2 代码审查的再设计

传统代码审查解决"一个人看自己代码的盲点"问题。在 AI 辅助开发中，这个问题被放大——AI 没有"盲点意识"，它会生成在统计上合理但在具体场景中错误的代码，且不会主动怀疑自己。

本项目通过**上下文隔离的 Review Agent** 解决这一问题：Review Agent 不知道 Code Agent 为什么这样写，它只能从代码本身出发评估设计合理性。这比传统代码审查更严格，因为它没有"我知道你这样写是为了解决那个问题"的上下文偏袒。

实践中发现，Review Agent 对以下类型问题特别有效：
- 硬编码（路由、密码、端口）
- 缺少边界处理（空值、超长字符串）
- 安全隐患（SQL 拼接、未鉴权接口）

对以下类型问题不如人工审查：
- 业务逻辑完整性（需要了解完整业务流程）
- 性能优化（需要了解实际数据规模）
- 团队代码风格一致性（需要了解已有代码库）

### 9.3 风险识别

本项目实际遇到的三大风险：

**技术风险**：Spring Security 默认行为与预期不符 → 实际发生，延误1天，通过显式配置 SecurityFilterChain 解决

**团队协作风险**：多人修改同一文件产生冲突 → 实际发生，通过模块拆分 + `INSERT IGNORE` 解决

**环境风险**：Mac 用户 Podman 与 Docker 行为差异、华为云 CI 平台规则未知 → 实际发生，通过适配 Compose 配置 + MR 流程解决

这与传统风险管理理论完全一致：技术风险、人员/协作风险、环境风险是软件项目三大风险类别[8]。AI 辅助开发没有消灭这些风险，只是改变了风险的具体表现形式。

---

## 十、结论

本文通过对 SeatFlow 项目的系统回顾，得出以下核心结论：

**1. Vibe Coding 不是银弹，而是杠杆**

AI 将"会写代码"这个技能的门槛大幅降低，但将"会管理 AI"（上下文工程、需求拆解、验收标准设计）推上了新的高位。开发者的核心竞争力从"能写出运行的代码"转向"能让 AI 写出好的代码"。

**2. 软件过程管理在 AI 时代更重要，而非更不重要**

因为 AI 不会遵守口头约定、不会主动问清需求、不会记住跨会话的历史，所有软件工程实践（需求文档化、分支策略、代码审查、测试隔离）都需要**显式、强制、可被 AI 感知**地执行，而不是依赖团队的隐性共识。

**3. Bug 的根源在于"上下文缺失"，而非"AI 能力不足"**

本项目12个 Bug 中，没有一个是因为"AI 太蠢"。都是因为：环境约束没有说清楚、需求拆解粒度不够、验收标准不明确，或者技术方案的副作用没有被充分评估。这指向一个结论：**Vibe Coding 的质量上限，是工程师的软件工程素养，而非模型的代码能力**。

**4. 团队协作是 AI 辅助开发的最大挑战**

单人 Vibe Coding 的效率极高，但多人协作时，AI 成为了一个"不参加会议的额外队友"，所有协作约定必须以文档形式显式传达给每个人的 AI 助手。这要求团队在项目启动时投入更多在"约定明确化"上，而非在开发过程中靠口头协调。

**5. 本课程收获**

《软件过程管理》课程的核心教益，在于让我理解：软件开发不只是技术问题，更是协调问题——协调人与人、人与工具、工具与工具之间的预期一致性。这一洞见在 AI 辅助开发时代非但没有过时，反而因为"AI 是个完全按指令行事但没有主动沟通能力的协作者"而变得更加关键。

如何写出让 AI 能够正确执行的"指令"，如何设计让 AI 生成的代码被人类可验证的"验收标准"，如何在 AI 参与下维护团队协作的一致性——这些问题的答案，正是软件过程管理这门学科在 AI 时代的新使命。

---

## 参考文献

[1] Karpathy, A. (2025). *Vibe Coding: A New Paradigm for AI-Assisted Software Development*. Twitter/X thread, Feb 2025.

[2] 李光正. (2025). 谈谈AI编程工具的进化与Vibe Coding [博客]. Guangzheng Li's Blog. https://guangzhengli.com/blog/zh/vibe-coding-and-context-coding

[3] GIAC 全球互联网架构大会. (2026). Vibe Coding落地实战：从上下文工程到AI原生产品矩阵. https://giac.msup.com.cn/2026sz/course/19267

[4] Anthropic. (2025). Context Engineering Best Practices: Compaction, Structured Notes, Just-in-time Retrieval, and Multi-Agent Architecture. 知乎综述: https://zhuanlan.zhihu.com/p/2011453309895062046

[5] Anthropic. (2024). *Building Effective Agents*. Anthropic Blog. 中文翻译：AI Workflow & AI Agent：架构、模式与工程建议. https://arthurchiao.art/blog/build-effective-ai-agent-zh/

[6] Atlassian. (2024). 用户故事（含示例与模板）. https://www.atlassian.com/zh/agile/project-management/user-stories

[7] 知乎专栏. (2026). 让AI和你结对编程：首篇Vibe Coding系统综述论文深度解读. https://zhuanlan.zhihu.com/p/1994594361544045237

[8] Pressman, R. S., & Maxim, B. R. (2020). *Software Engineering: A Practitioner's Approach* (9th ed.). McGraw-Hill Education.

[9] InfoQ. (2025). AI Coding 2025年终盘点：Spec正在蚕食人类编码，Agent造轮子拖时间. https://www.infoq.cn/article/5lxt9ibO77f3HKbITN5s

[10] Scrum中文网. (2025). 未来已来，AI时代，团队为何更需要自组织与敏捷能力？. https://www.scrum.cn/41176.html

[11] 01.me. (2025). Claude的Context Engineering秘籍：从Anthropic学到的最佳实践. https://01.me/2025/12/context-engineering-from-claude/

[12] ModelScope学习中心. (2025). 拒绝代码焦虑：基于Vibe Coding的AI应用工程化实战心法. https://www.modelscope.cn/learn/2875

---

*本文基于 SeatFlow 项目真实开发过程撰写。项目代码：https://github.com/hfutwz/openclaw-project-agent*
*华为云后端仓库：seat_booking_server | 华为云前端仓库：seat_booking_web*

---

## 附录

### 附录一：团队协作冲突完整记录（team_work_coding.md）

> 详见正文第五章，已完整收录。

---

### 附录二：开发过程 Bug 完整记录（process_bug.md）
