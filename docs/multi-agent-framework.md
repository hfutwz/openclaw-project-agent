# Multi-Agent 全链路开发框架

> 创建时间：2026-05-16
> 最后更新：2026-05-16
> 状态：配置完成，待接收需求文档

---

## 一、架构概览

本框架采用 **1 个主 Agent（Orchestrator 编排者）+ 4 个子 Agent（通过 sessions_spawn 调度）** 的 subagent 架构。

```
                        ┌──────────────────────────────┐
                        │   Orchestrator (主 Agent)      │
                        │   volcengine-plan/glm-5.1      │
                        │   ~/workspace-project/         │
                        │   编排调度，不写代码             │
                        └──────────────┬────────────────┘
                                       │ sessions_spawn / sessions_send
               ┌───────────┬───────────┼───────────┬──────────────┐
               ▼           ▼                       ▼              ▼
        ┌────────────┐ ┌──────────────┐   ┌──────────────┐ ┌──────────────┐
        │ Plan Agent │ │  Code Agent  │   │ Review Agent │ │  Test Agent  │
        │            │ │ (前端+后端)   │   │              │ │              │
        │  glm-5.1   │ │ deepseek-v3.2│   │doubao-2.0-pro│ │doubao-2.0-   │
        │            │ │              │   │              │ │  code        │
        └────────────┘ └──────────────┘   └──────────────┘ └──────────────┘
         需求→PRD       前后端并行编码      代码审查(只读)    与Code并行写测试
```

### 核心设计原则

1. **Subagent 架构** — Orchestrator 通过 `sessions_spawn` 创建子 Agent，通过 `sessions_send` 下发指令，子 Agent 完成后自动回报
2. **PRD 守门** — 所有 Agent 都必须等用户确认 PRD 后才能启动
3. **Code/Test 并行** — Test Agent 基于 PRD 写测试，和 Code Agent 同时启动，防止测试过拟合代码
4. **Review 自动合并** — Review 通过 + Test 通过 → 自动合并 PR

---

## 二、Agent 详细配置

### 2.1 Orchestrator（主 Agent / 编排者）

| 项目 | 配置 |
|---|---|
| **Agent ID** | `project-orchestrator` |
| **模型** | `volcengine-plan/glm-5.1` |
| **工作空间** | `~/workspace-project/` |
| **Agent Dir** | `~/.openclaw/agents/project-orchestrator/agent/` |
| **工具** | read, write, edit, exec |
| **角色** | 编排调度、用户交互、进度跟踪、冲突协调 |
| **不写代码** | 仅调度子 Agent |

**Workspace 文件：**

| 文件 | 用途 |
|---|---|
| `SOUL.md` | 身份和风格 |
| `USER.md` | 用户信息和偏好 |
| `IDENTITY.md` | 角色标识 |
| `TOOLS.md` | 调度工具说明 |
| `AGENTS.md` | 子 Agent 索引和编排流程 |

---

### 2.2 Plan Agent（规划）

| 项目 | 配置 |
|---|---|
| **子 Agent 标签** | `plan-agent` |
| **模型** | `volcengine-plan/glm-5.1` |
| **工作目录** | `~/workspace-project/plan-agent/` |
| **身份文档** | `plan-agent/plan-agent.md` |
| **选模型理由** | 中文理解强，擅长结构化文档输出 |

**输入：** 用户业务需求（文本/文档/对话）
**输出：** PRD → `prd/prd.md`
**关键约束：** PRD 必须用户确认后才能推进

---

### 2.3 Code Agent（编码 — 前端+后端并行）

| 项目 | 配置 |
|---|---|
| **子 Agent 标签** | `code-agent-frontend` / `code-agent-backend` |
| **模型** | `volcengine-plan/deepseek-v3.2` |
| **工作目录** | `code-agent/frontend/` + `code-agent/backend/` |
| **身份文档** | `code-agent/code-agent.md` |
| **选模型理由** | 编程能力最强，代码生成质量最高 |

**输入：** 已确认的 PRD
**输出：** 前端/后端代码实现
**关键约束：** 前后端并行；基于 PRD 开发；feature 分支；与 Test Agent 同时启动

---

### 2.4 Review Agent（审查）

| 项目 | 配置 |
|---|---|
| **子 Agent 标签** | `review-agent` |
| **模型** | `volcengine-plan/doubao-seed-2.0-pro` |
| **工作目录** | `~/workspace-project/review-agent/` |
| **身份文档** | `review-agent/review-agent.md` |
| **选模型理由** | 综合推理强，多维度审查判断准确 |

**输入：** Code Agent 代码 + PRD
**输出：** 审查报告 → `review-agent/review-Txxx.md`
**关键约束：** 只读权限（禁止 write/edit/apply_patch）；基于 PRD 审查；通过后自动合并

---

### 2.5 Test Agent（测试）

| 项目 | 配置 |
|---|---|
| **子 Agent 标签** | `test-agent` |
| **模型** | `volcengine-plan/doubao-seed-2.0-code` |
| **工作目录** | `~/workspace-project/test-agent/` |
| **身份文档** | `test-agent/test-agent.md` |
| **选模型理由** | 编程+执行兼顾，写测试+跑测试 |

**输入：** 已确认的 PRD（不依赖代码）
**输出：** 单测 + 集成测试 + 冒烟脚本 → `test-agent/`
**关键约束：** 必须和 Code Agent 同时启动；基于 PRD 写测试而非代码；包含单测/集成/冒烟三类

---

## 三、执行流程

```
用户提交需求
       │
       ▼
┌──────────────────────┐
│ [1] spawn Plan Agent │
│     → 产出 PRD       │
│     → 多轮迭代修改    │
│     → 用户确认 ✅    │
└──────────┬───────────┘
           │ 用户确认 PRD
           ▼
┌──────────────────────────────────────────────┐
│ [2] 同时 spawn                               │
│     ┌────────────────┐ ┌──────────────────┐  │
│     │ Code Agent     │ │  Test Agent      │  │
│     │ (前端+后端并行)│ │  (基于PRD写测试)  │  │
│     └───────┬────────┘ └────────┬─────────┘  │
│             │                   │            │
│             │  Code完成         │ 测试写完    │
│             ▼                   │            │
│     ┌────────────────┐         │            │
│     │ Review Agent   │         │            │
│     │ (审查代码)     │         │            │
│     └───────┬────────┘         │            │
│             │ 通过             │            │
│             ├──────────────────┘            │
│             ▼                               │
│     执行测试                                │
│     ├─ ✅ 通过 → 合并 PR                    │
│     └─ ❌ 失败 → Code修复 → 重审+重测       │
└──────────────────────────────────────────────┘
```

---

## 四、并行策略

| 阶段 | 并行方式 |
|---|---|
| **Plan** | 串行（必须先出 PRD 且用户确认） |
| **Code + Test** | **必须并行**（Test 基于 PRD 写测试，防过拟合） |
| **Code 内部** | 前端 + 后端并行 |
| **Review** | Code Agent 提交后启动，可前后端分别 Review |
| **Test 执行** | Code 完成 + Review 通过后执行 |

---

## 五、模型选型

| Agent | 模型 | 选型理由 |
|---|---|---|
| Orchestrator | `glm-5.1` | 中文指令遵循好，编排逻辑不需要强编程 |
| Plan Agent | `glm-5.1` | 中文理解强，结构化文档输出好 |
| Code Agent | `deepseek-v3.2` | 编程能力最强，代码生成质量最高 |
| Review Agent | `doubao-seed-2.0-pro` | 综合推理强，多维度判断准确 |
| Test Agent | `doubao-seed-2.0-code` | 编程+执行兼顾，写测试+跑测试 |

---

## 六、目录结构

```
~/workspace-project/                    # Orchestrator 工作空间
├── SOUL.md                             # 编排者身份
├── USER.md                             # 用户信息
├── IDENTITY.md                         # 角色标识
├── TOOLS.md                            # 调度工具说明
├── AGENTS.md                           # 子 Agent 索引 + 编排流程
├── progress.md                         # 项目进度跟踪（运行时生成）
├── prd/                                # PRD 产出目录
│   └── prd.md                          # Plan Agent 产出
├── plan-agent/                         # Plan Agent 工作目录
│   └── plan-agent.md                   # 身份文档
├── code-agent/                         # Code Agent 工作目录
│   ├── code-agent.md                   # 身份文档
│   ├── frontend/                       # 前端代码
│   └── backend/                        # 后端代码
├── review-agent/                       # Review Agent 工作目录
│   ├── review-agent.md                 # 身份文档
│   └── review-Txxx.md                  # 审查报告（运行时生成）
├── test-agent/                         # Test Agent 工作目录
│   ├── test-agent.md                   # 身份文档
│   ├── unit/                           # 单元测试（运行时生成）
│   ├── integration/                    # 集成测试（运行时生成）
│   ├── smoke/                          # 冒烟测试（运行时生成）
│   └── reports/                        # 测试报告（运行时生成）
└── docs/                               # 框架文档
    └── multi-agent-framework.md        # 本文件
```

---

## 七、关键设计决策

| 决策 | 选择 | 理由 |
|---|---|---|
| Code/Test 是否并行 | ✅ 并行 | 防止测试过拟合代码；基于 PRD 写测试才能验证需求是否被正确实现 |
| Review 后是否自动合并 | ✅ 自动 | Review 通过 + Test 通过 = 质量达标，无需人工再确认合并 |
| Test 基于 PRD 还是代码 | **PRD** | 基于代码写测试会"适应"实现，失去验证需求的价值 |
| 子 Agent 生命周期 | `mode: session` | 持久会话，可多次交互（修改 PRD、修复代码后重新 review/test） |
| 前后端 Code Agent | 合为一个 Agent，内部并行 | 共享 PRD 上下文，减少通信开销；实际 spawn 时用不同 label 区分 |

---

## 八、当前状态

- [x] 工作空间目录创建
- [x] Orchestrator 完整配置（SOUL/USER/IDENTITY/TOOLS/AGENTS）
- [x] 4 个子 Agent 身份文档
- [x] openclaw.json 注册 project-orchestrator
- [x] 框架文档输出
- [ ] 重启 Gateway 使配置生效
- [ ] 接收需求文档，启动 Plan Agent
