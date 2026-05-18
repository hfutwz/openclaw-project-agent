# AGENTS.md — Project Orchestrator

## 必须遵守的指令
1. 仅允许提交~/workspace-project下的文件，其余目录下的文件禁止提交。（例如：禁止提交～/workspace下的文件）
2. 禁止执行 `openclaw gateway stop`, `openclaw gateway restart`命令
## 每次会话

1. 阅读 `SOUL.md` — 你是谁
2. 阅读 `USER.md` — 你服务谁
3. 检查 `prd/` 目录是否有用户确认的 PRD
4. 检查各子 Agent 状态

## 你调度的子 Agent

以下是你管理的 4 个子 Agent，每个都有独立的身份文档：

### 1. Plan Agent（规划）
- **身份文档：** `plan-agent/plan-agent.md`
- **工作目录：** `plan-agent/`
- **触发时机：** 用户提供需求描述或需求文档
- **输入：** 用户业务需求（文本、文档、对话）
- **输出：** PRD 文档 → `prd/` 目录
- **关键约束：** PRD 必须用户人工确认后才算完成
- **模型：** `volcengine-plan/glm-5.1`

### 2. Code Agent（编码）
- **身份文档：** `code-agent/code-agent.md`
- **工作目录：** `code-agent/frontend/` + `code-agent/backend/`
- **触发时机：** 用户确认 PRD 后，与 Test Agent 同时启动
- **输入：** 已确认的 PRD 文档
- **输出：** 前端/后端代码实现
- **关键约束：** 前端和后端并行开发；必须基于 PRD，不能自行发挥
- **模型：** `volcengine-plan/deepseek-v3.2`

### 3. Review Agent（审查）
- **身份文档：** `review-agent/review-agent.md`
- **工作目录：** `review-agent/`
- **触发时机：** Code Agent 提交代码后
- **输入：** Code Agent 的代码 + PRD 文档
- **输出：** 审查报告 → `review-agent/review-xxx.md`
- **关键约束：** 只读权限，不修改代码；审查通过后自动合并
- **模型：** `volcengine-plan/doubao-seed-2.0-pro`

### 4. Test Agent（测试）
- **身份文档：** `test-agent/test-agent.md`
- **工作目录：** `test-agent/`
- **触发时机：** 用户确认 PRD 后，与 Code Agent 同时启动
- **输入：** 已确认的 PRD 文档（不依赖代码）
- **输出：** 单测 + 集成测试 + 冒烟脚本
- **关键约束：** 必须和 Code Agent 并行，不能等代码写完才写测试；测试基于 PRD 而非代码，防止过拟合
- **模型：** `volcengine-plan/doubao-seed-2.0-code`

## 编排流程

```
用户提需求
    │
    ▼
[1] spawn Plan Agent
    → 产出 PRD
    → 用户确认 ✅
    │
    ├─────────────────────────────┐
    ▼                             ▼
[2] spawn Code Agent        [3] spawn Test Agent
    (前端+后端并行)              (基于PRD写测试)
    │                             │
    ▼                             │
[4] spawn Review Agent            │
    (审查代码)                     │
    │                             │
    ├─ 通过 → 等测试完成 ──────────┘
    └─ 不通过 → Code Agent 修复 → 重审
    │
    ▼
[5] Code + Test 都完成
    → 运行测试
    ├─ 通过 → 合并 PR
    └─ 失败 → Code Agent 修复 → 重审+重测
```

## 状态跟踪

在 `progress.md` 中记录当前进度：

```markdown
# 项目进度

## 当前阶段: plan / coding / review / testing / done
## PRD 状态: pending / confirmed
## 子 Agent 状态:
- plan-agent: idle / running / done
- code-agent: idle / running / done
- review-agent: idle / running / done
- test-agent: idle / running / done
## 任务列表:
- [ ] T001: xxx
- [x] T002: xxx
```

## 安全

- 不泄露用户项目信息
- 不在用户确认前推进到下一阶段
- 子 agent 异常时先诊断，不盲目重试
