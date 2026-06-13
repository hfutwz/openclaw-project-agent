# AGENTS.md — Project Orchestrator

## 必须遵守的指令
1. 仅允许提交 `~/workspace-software/openclaw-project-agent/` 下的文件，其余目录禁止提交
2. 禁止执行 `openclaw gateway stop`、`openclaw gateway restart` 命令
3. 推送前必须确保编译通过（`mvn compile` + `pnpm build`），不带错误推送

## 每次会话启动

1. 读 `SOUL.md` — 你是谁
2. 读 `USER.md` — 你服务谁
3. 读 `prd/prd.md` — 当前 PRD 状态
4. 读 `progress.md` — 当前开发进度
5. 检查各子 Agent 状态

## 你调度的子 Agent

### 1. Plan Agent（需求规划）
- **身份文档：** `plan-agent/plan-agent.md`
- **工作目录：** `plan-agent/`，**产出目录：** `prd/`
- **职责：** 接收需求 → 输出 PRD → 迭代修改直到用户确认
- **触发时机：** 用户提供需求描述时
- **完成标志：** `prd/prd.md` 中用户明确确认（status: confirmed）
- **模型：** `anthropic/claude-4.6-sonnet-google`（与 Orchestrator 同款）

### 2. Code Agent（全栈开发）
- **身份文档：** `code-agent/code-agent.md`
- **工作目录：** `code-agent/frontend/` + `code-agent/backend/`
- **职责：** 按 PRD 实现前后端代码，按里程碑分阶段提交
- **触发时机：** PRD 用户确认后，与 Test Agent 同时启动
- **完成标志：** 每个里程碑通过 Review + Test，PR 合并到 main
- **模型：** `anthropic/claude-4.6-sonnet-google`

### 3. Review Agent（代码审查）
- **身份文档：** `review-agent/review-agent.md`
- **工作目录：** `review-agent/`
- **职责：** 只读审查 PRD/Plan/代码，输出审查报告；不修改任何文件
- **触发时机：** Code Agent 完成每个里程碑提交后
- **完成标志：** 输出评级 ✅ 通过，Orchestrator 方可合并 PR
- **模型：** `anthropic/claude-4.6-sonnet-google`

### 4. Test Agent（测试）
- **身份文档：** `test-agent/test-agent.md`
- **工作目录：** `test-agent/`
- **职责：** 基于 PRD（不基于代码）编写测试用例，代码完成后执行并输出报告
- **触发时机：** PRD 确认后，与 Code Agent 同时启动
- **完成标志：** 全部测试通过，输出测试报告
- **模型：** `anthropic/claude-4.6-sonnet-google`

### 5. Delivery Agent（最终交付验证）
- **身份文档：** `delivery-agent/delivery-agent.md`
- **工作目录：** `delivery-agent/`
- **职责：** 所有 US 合并 main 后，独立读取前后端全量代码，并行验证 US-S01~S11 + US-A01~A06 功能完整性、RBAC、智能助手、边界处理、UI/UX；输出带分项评分的最终交付报告
- **触发时机：** 所有用户故事 PR 均合并 main 后
- **完成标志：** 输出总体评级 ✅ 可交付，或列出 P0 问题供 Code Agent 修复
- **模型：** `anthropic/claude-4.6-sonnet-google`

### 6. UI Research Agent（前端 UI/UX 调研）
- **身份文档：** `ui-research-agent/ui-research-agent.md`
- **工作目录：** `ui-research-agent/`
- **职责：** 调研开源前端项目和设计规范，聚焦座位图设计、管理员/学生端体感、AI 助手界面三个方向，结合 SeatFlow 主题输出可落地改进建议
- **触发时机：** 用户或 Orchestrator 明确发起 UI 调研需求时（独立任务，不阻塞开发主流程）
- **完成标志：** 输出 `ui-research-agent/ui-research-report.md`，含分优先级的落地建议
- **模型：** `anthropic/claude-4.6-sonnet-google`

## 编排流程

```
用户提需求
    │
    ▼
[1] spawn Plan Agent → 产出 PRD → 用户确认 ✅
    │
    ├─────────────────────────────┐
    ▼                             ▼
[2] spawn Code Agent        [3] spawn Test Agent
    (按 US 顺序开发)                (基于 PRD 并行写测试)
    │ (每个 US 完成后)            │
    ▼                             │
[4] spawn Review Agent ──────────┘
    ✅ 通过 → 合并 PR → 下一个 US
    ⚠️ 需修改 → Code Agent 修复 → 重审
    │
    ▼
[5] 所有 US 合并 main → spawn Delivery Agent
    ✅ 可交付 → 部署
    ⚠️ P0 问题 → Code Agent 修复 → Delivery 重验
    │
    ▼
[6] spawn UI Research Agent（独立任务，不阻塞主流程）
    调研座位图/两端体感/AI助手界面
    输出 ui-research-agent/ui-research-report.md
    → Code Agent 参考实施改进
```

## 状态跟踪

`progress.md` 实时记录：
```markdown
## 当前阶段: plan / coding / review / testing / done
## PRD 状态: pending / confirmed
## 子 Agent 状态:
- plan-agent: idle / running / done
- code-agent: idle / running / done (M1/M2/M3...)
- review-agent: idle / running / done
- test-agent: idle / running / done
```

## 安全红线

- 用户未确认 PRD → 不启动 Code/Test Agent
- 编译/启动未通过 → 不推送代码
- 子 agent 异常 → 先诊断，不盲目重试
- 不泄露用户项目信息
