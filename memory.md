# Memory — 项目记忆

## 必须遵守的指令
1. 仅允许提交~/workspace-project下的文件，其余目录下的文件禁止提交。（例如：禁止提交～/workspace下的文件）
2. 禁止执行 `openclaw gateway stop`, `openclaw gateway restart`命令

## 开发规则（强约束）
- **直接在 main 分支开发**，前后端都一样，有错直接改，不需要 feature 分支
- 实现仅需要 MVP，将用户故事实现就好，不要过度设计

## 开发闭环工作流（强约束，持续执行至 M7 完成）

```
循环：M1 → M2 → M3 → M4 → M5 → M6 → M7
每个里程碑内：
  Step 1: Code开发 + Test用例开发（并行）
  Step 2: Code完成 → Review审计 → Code修复
  Step 3: 修复后 → 执行Test用例
    - 失败 → Code修复 → Review回归审计 → 重测
    - 通过 → Step 4
  Step 4: 提交PR → Review通过 → Merge到main分支
    - 后端：feature/Mx 分支 → PR → merge 到 main
    - 前端：feature/Mx 分支 → PR → merge 到 main
    - 必须先在本地验证：编译通过 + 启动成功 + 基本功能可用
    - PR合并后才算该里程碑真正完成，才能进入下一个M
每次完成一步骤都必须在 progress.md 中记录当前状态
```

## PR/合并规则（强约束）

- **每个M阶段闭环自验证通过后，必须提交PR并合并到main**
- **未合并 = 未完成**，不能进入下一个M
- PR流程：`git checkout -b feature/Mx` → 开发 → `git add/commit` → `git push origin feature/Mx` → 创建PR → 合并
- 推送前必须：`mvn compile` + `mvn spring-boot:run`（后端）/ `npm run build` + `npm run dev`（前端）验证通过

## 仓库地址

| 项目 | GitHub 仓库 | 本地路径 |
|---|---|---|
| 后端 (SeatFlow-API) | https://github.com/hfutwz/SeatFlow-API | `code-agent/backend/` |
| 前端 (SeatFlow-UI) | https://github.com/hfutwz/SeatFlow-UI | `code-agent/frontend/` |
| 开发过程记录仓库 | https://github.com/hfutwz/openclaw-project-agent | `code-agent/process/` |


## 关键规则

- **推送红线**：本地编译通过 + 启动成功 + 能运行，才能推送到远程，否则自行修复直到成功
- **PRD 守门**：PRD 必须用户确认后才能启动 Code/Test Agent
- **Plan 在 PRD 之后**：Plan 文档在 PRD 人工 review 完成后再写

## 环境信息

| 工具 | 版本 | 路径 |
|---|---|---|
| JDK | 21.0.11 | `/opt/homebrew/opt/openjdk@21/` |
| Maven | 3.9.15 | brew 安装 |
| MySQL | 8.0.46 | `/opt/homebrew/opt/mysql@8.0/`，root 无密码，数据库 `seatflow` |
| Node.js | 24.14.0 | nvm |
| GitHub 账号 | willwang2528 | 已加入 hfutwz 组织协作者，两个仓库均有 WRITE 权限 |
| Git 代理 | http://127.0.0.1:7897 | 访问 GitHub 必须走代理 |

## 项目状态

- **当前阶段**：✅ 全部开发完成，M1~M7 已交付
- **PRD 状态**：v0.3 已确认
- **Plan 状态**：v1.2 已确认
- **PR 合并**：12个PR全部合并（后端6个 + 前端6个）
- **待办**：无，等待用户新需求
