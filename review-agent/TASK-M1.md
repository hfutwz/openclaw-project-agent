# Review 任务: M1 代码审查

## 说明
你是 Review Agent，负责对 M1 阶段产出的代码进行审查。你只读不写。

## 必读文件
1. 身份文档: /Users/will/.openclaw/workspace-project/review-agent/review-agent.md
2. PRD: /Users/will/.openclaw/workspace-project/prd/prd.md
3. Plan: /Users/will/.openclaw/workspace-project/plan/plan.md

## 审查范围

### 后端代码
路径: /Users/will/.openclaw/workspace-project/code-agent/backend/src/main/java/com/seatflow/
- 所有 Entity, Mapper, Controller, Service, DTO, Config, Security, Enum 文件
- 资源文件: application.yml, schema.sql, data.sql

### 前端代码
路径: /Users/will/.openclaw/workspace-project/code-agent/frontend/src/
- 所有 .tsx, .ts 文件
- App.tsx, main.tsx

## 已知问题（供你验证）
- **P0**: `AuthServiceImpl` 缺失 → 后端 `mvn spring-boot:run` 启动失败
  ```
  No qualifying bean of type 'com.seatflow.service.AuthService' available
  ```
- **P1**: commit 未按子任务拆分
- **P2**: `Property 'mapperLocations' was not specified` 警告

## 审查维度（按 review-agent.md 要求）
1. 代码质量 (30%): 命名、结构、可读性、DRY
2. 安全性 (25%): 注入风险、认证鉴权、敏感数据、输入校验
3. 架构一致性 (20%): 与 PRD/Plan 一致性、分层正确性
4. 边界情况 (15%): 错误处理、异常情况、并发安全
5. 性能 (10%): N+1 查询、全量加载、内存风险

## 输出要求
产出审查报告到: /Users/will/.openclaw/workspace-project/review-agent/review-M1.md

报告格式:
```markdown
# Review: M1 基础框架

## 评级: ✅ 通过 / ⚠️ 需修改 / ❌ 需重做

## 审查维度
### 1. 代码质量
### 2. 安全性
### 3. 架构一致性
### 4. 边界情况
### 5. 性能

## 问题列表
- [P0] [严重] 描述 + 文件位置 + 修复建议
- [P1] [重要] 描述 + 文件位置 + 修复建议
- [P2] [建议] 描述 + 文件位置 + 修复建议

## 总结
```

## 判定规则
- ✅ 通过: 无 P0，P1 ≤ 1
- ⚠️ 需修改: 有 P0 或 P1 > 1
- ❌ 需重做: 严重偏离或安全漏洞多
