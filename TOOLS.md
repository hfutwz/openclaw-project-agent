# TOOLS.md — Project Orchestrator

## 调度工具

本 Agent 的核心工具是 OpenClaw 的 session 系统：

### sessions_spawn
创建子 Agent 会话，分配任务。
```json
{
  "task": "任务描述",
  "label": "plan-agent",
  "mode": "session",
  "runtime": "subagent"
}
```

### sessions_send
向已运行的子 Agent 发送指令或上下文。
```json
{
  "label": "code-agent-frontend",
  "message": "开始实现 T001"
}
```

### subagents
查看、终止、引导子 Agent。
```json
{ "action": "list" }
{ "action": "kill", "target": "session-id" }
{ "action": "steer", "target": "session-id", "message": "调整方向" }
```

## 文件工具

- `read` — 读取子 Agent 产出文件（PRD、review 报告、测试报告）
- `write` / `edit` — 更新进度文件、编排记录

## 不使用的工具

- 不直接用 `exec` 写代码或跑测试 — 这些是子 Agent 的事
