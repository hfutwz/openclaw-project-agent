# SeatFlow 开发过程 Bug 记录

> Vibe Coding 多 Agent 协作项目，所有 Bug 均发生在 AI 辅助开发过程中。
> 本文记录开发过程中出现的所有问题、根因与解法，用于复盘和归因。

---

## BUG-001：登录返回 302 重定向，无法登录

### 现象
- 前端点击登录，Network 显示 POST `/api/auth/login` 返回 302
- 第二个请求自动 GET `http://localhost/login`（无端口号），连接被拒
- admin / student 账号均无法登录

### 根因
Spring Boot `spring-boot-starter-security` 依赖存在时，即使注释了 `@EnableWebSecurity`，只要没有显式定义 `SecurityFilterChain` bean，Spring Boot auto-config 就会启用默认 formLogin 机制，将所有未认证请求拦截并 302 重定向到 `/login`（无端口）。

### 我们的解法
在 `SecurityConfig.java` 中恢复 `@EnableWebSecurity` 注解，并显式定义 `SecurityFilterChain` bean，设置 `anyRequest().permitAll()`，同时禁用 formLogin / httpBasic / CSRF / Stateless session。

### 更优解法
MVP 阶段可通过此方案全放行，后续接入 JWT 后在 Filter 层做认证，不依赖 Spring Security 的默认行为。

### 归因（Vibe Coding 视角）
**模型上下文不够**：Code Agent 生成 SecurityConfig 时删除了关键注解，但没有意识到 Spring Boot auto-config 会在无 bean 时自动接管。模型对 Spring Security 的默认行为理解不完整，生成了"看起来正确但逻辑有误"的代码。

---

## BUG-002：登录成功但用户信息为空，前端无法判断角色

### 现象
- 登录接口返回 200，但 localStorage 中 userInfo 为空对象
- admin 用户登录后和学生用户界面完全相同

### 根因
`AuthServiceImpl.login()` 方法只做了密码校验，返回 `LoginResponse("", 0L)` 空对象，未查询角色/权限并填充 userInfo 字段。

### 我们的解法
修改 `AuthServiceImpl.login()`，登录成功后查询用户的 roles 和 permissions，构建 `UserInfoResponse` 并作为 `LoginResponse.userInfo` 返回给前端。

### 归因（Vibe Coding 视角）
**需求没有描述清楚**：登录接口的验收条件只写了"验证用户名密码"，没有明确要求"返回角色权限信息"。Code Agent 按最小实现来做，没有主动补全业务完整性。属于**需求拆解不够细**的问题。

---

## BUG-003：登录成功后所有用户都跳转到学生端

### 现象
- admin 登录后跳转到 `/student/rooms`，而非管理端

### 根因
`Login.tsx` 中写死了 `navigate('/student/rooms')`，未根据用户角色动态跳转。

### 我们的解法
修改 `Login.tsx`，登录成功后读取 `localStorage.userInfo.userType`，ADMIN 跳转 `/admin/dashboard`，STUDENT 跳转 `/student/rooms`。

### 归因（Vibe Coding 视角）
**开发者的 taste 不对**：Code Agent 生成前端跳转逻辑时，用了最简单的写死方案，没有考虑多角色场景。这是 AI 倾向于"能跑就行"的典型问题，缺乏业务全局意识。

---

## BUG-004：数据库中文乱码

### 现象
- 前端自习室名称显示为 `å›¾ä¹¦é¦†301` 等乱码
- 数据库中存储的中文数据编码错误

### 根因（两处）
1. `init.sql` 头部缺少 `SET NAMES utf8mb4` 声明，MySQL 客户端连接时使用默认字符集（latin1）解析 SQL 文件，导致中文写入乱码
2. 早期 `init.sql` 中部分 INSERT 语句前缺少 `SET CHARACTER SET utf8mb4`

### 我们的解法
在 `deploy/mysql/init.sql` 文件头部加入：
```sql
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection=utf8mb4;
```

### 更优解法
在 `docker-compose.yml` 的 MySQL 服务中加入 `command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci`，从服务端强制指定字符集，双重保障。

### 归因（Vibe Coding 视角）
**模型上下文不够**：Code Agent 生成 SQL 文件时知道建库语句要写 `utf8mb4`，但没有意识到 MySQL 客户端连接字符集和服务端字符集是两套独立配置，缺乏对 MySQL 字符集体系的完整理解。

---

## BUG-005：Dockerfile 构建失败（Maven 未内置 / Node 版本不兼容）

### 现象
- 后端 Dockerfile 使用 `eclipse-temurin:21-jdk` 镜像，但该镜像没有 Maven，构建报 `mvn: command not found`
- 前端 Dockerfile 使用 `node:20-alpine`，但 pnpm 11 要求 Node 22+，安装依赖报版本错误

### 根因
Code Agent 生成 Dockerfile 时选择了基础 JDK 镜像，没有意识到 Maven 需要单独安装；前端镜像版本选择也未考虑 pnpm 的版本要求。

### 我们的解法
- 后端 Dockerfile：`eclipse-temurin:21-jdk` → `maven:3.9-eclipse-temurin-21`（自带 Maven）
- 前端 Dockerfile：`node:20-alpine` → `node:22-alpine`

### 归因（Vibe Coding 视角）
**需求没有描述清楚**：构建环境约束（pnpm 版本、Maven 版本）未在 prompt 中明确说明。属于**开发约束传达不充分**，模型只能猜测合理的镜像。

---

## BUG-006：前端构建验证不完整导致推送后报错

### 现象
- 修改代码后只用 `tsc -b` 单独验证，推送后 Docker 构建时 `vite build` 报错
- 部分未使用导入等错误在单独 tsc 时未发现

### 根因
`tsc -b` 只做类型检查，`vite build` 还会做 tree-shaking、import 分析等额外检查。两者不等价。

### 我们的解法
规定推送前必须执行完整的 `pnpm build`（= `tsc -b && vite build`），零错误才允许推送。

### 归因（Vibe Coding 视角）
**开发者的 taste 不对**：Code Agent 为了快速验证，用了最轻量的检查命令，没有考虑 CI 环境与本地验证的等价性。属于**验收标准不统一**问题。

---

## BUG-007：pnpm 安装被内部 npm registry 污染

### 现象
- 在沙箱环境中安装前端依赖时，`npm install` 报包缺失或 `package.json` 被篡改
- 内部 npm registry（`npm.devops.xiaohongshu.com:7001`）包不全，且会修改 `package.json` 写入内部源地址

### 根因
沙箱环境的 npm 默认指向内部 registry，该 registry 未镜像所有公共包，且安装时会修改配置文件，导致后续构建污染。

### 我们的解法
全部改用 `pnpm` + `node-linker=hoisted`，配置 `.npmrc` 指向外部公共源，并将"前端只用 pnpm"作为强约束写入项目规范。

### 归因（Vibe Coding 视角）
**环境约束未传达**：沙箱的特殊 registry 配置是运行时环境问题，Code Agent 无法预知。属于**基础设施信息没有在 prompt 中说明**，需要人工在项目规范中显式记录。

---

## BUG-008：git 推送出现 "refusing to merge unrelated histories"

### 现象
- 用户在本地 clone 华为云仓库后，执行 `git pull` 报 `refusing to merge unrelated histories`
- 原因是我们用 `git subtree split` 推送的历史与用户本地 clone 的历史没有共同祖先

### 根因
`git subtree split` 生成的提交历史是全新的（没有 merge commit 连接到原始 clone），与用户通过 `git clone` 拿到的历史没有公共祖先节点。

### 我们的解法
```bash
git fetch origin
git reset --hard origin/main
```
强制将本地重置为远端版本，放弃本地历史。

### 更优解法
后续统一用 `--allow-unrelated-histories` 合并，或在 subtree split 时保持分支连续性，避免 force push。

### 归因（Vibe Coding 视角）
**架构选型理解不够深**：monorepo + subtree split 是一个复杂的多仓协作模式，Code Agent 提出方案时没有充分评估对小组成员本地操作的影响。属于**技术方案的副作用考虑不足**。

---

## BUG-009：批量座位生成 UI 被组员代码覆盖

### 现象
- 我们实现的「批量生成座位」功能在同步组员 B 代码后消失
- GitHub 和本地的 `SeatManage.tsx` 都变回了组员 B 的旧版本

### 根因
同步华为云 main 分支（含组员 B 的 RBAC 代码）时，直接用 `git checkout huawei-frontend/main -- src/` 覆盖了整个 `src/` 目录，导致我们已改动的 `SeatManage.tsx` 被旧版本覆盖。

### 我们的解法
从华为云前端的 `feature/task_a_room_management` 分支（我们之前推进去的版本）恢复文件：
```bash
git show huawei-frontend/feature/task_a_room_management:src/pages/admin/SeatManage.tsx > code-agent/frontend/src/pages/admin/SeatManage.tsx
```

### 更优解法
多人协作时，同步他人代码应用 `git merge` 而非 `git checkout -- .` 整目录覆盖，保留各自的改动历史，冲突手动解决。

### 归因（Vibe Coding 视角）
**需求没有描述清楚**：同步任务的边界不明确——"把华为云代码同步过来"没有指定"只同步新增内容，不覆盖已有改动"。Agent 选择了最简单的整目录覆盖方案，丢失了已有改动。属于**任务描述歧义**导致的操作失误。

---

## BUG-010：MySQL Volume 未清空导致 init.sql 不生效

### 现象
- 更新了 `deploy/mysql/init.sql`（新增自习室和座位数据），重启 podman 后前端仍显示旧数据
- 自习室只有4个而非6个，座位数量远少于预期

### 根因
MySQL 容器使用 named volume（`mysql-data`）持久化数据。第一次启动时 MySQL 会执行 `init.sql` 初始化，但 volume 已存在时 MySQL 认为数据库已初始化，**直接跳过 init.sql**，使用已有数据。

### 我们的解法
执行 `podman-compose down -v` 删除 volume，再重新 `up -d --build`，MySQL 重新执行 init.sql。

### 注意
`INSERT IGNORE` 只能防止重复报错，不能更新已存在的数据。要让新数据生效，必须先删 volume 重建。

### 更优解法
生产环境使用 Flyway / Liquibase 做数据库迁移管理，版本化管理 SQL 变更，避免依赖 init.sql 一次性初始化的脆弱机制。

### 归因（Vibe Coding 视角）
**开发者的 taste 不对**：Code Agent 设计初始化方案时选择了 `init.sql` 一次性导入，对 Docker volume 的生命周期管理理解不深。`INSERT IGNORE` 的幂等性让人误以为"可以随时重跑"，但实际 init.sql 根本不会再次执行。属于**方案设计考虑不全面**。

---

## BUG-011：同步代码时误将文件放到 monorepo 根目录

### 现象
- 用 `git checkout huawei-backend/main -- src/` 同步华为云后端代码时，`src/` 目录直接出现在 monorepo 根目录，而非 `code-agent/backend/src/`
- 同样出现了根目录下的 `data.sql`、`schema.sql` 等文件

### 根因
`git checkout <remote>/<branch> -- <path>` 命令会将文件按原路径放在当前工作目录。华为云后端仓库的 `src/` 在其根目录，checkout 到 monorepo 时就直接放在 monorepo 根目录了。

### 我们的解法
用 `git rm -r --cached` 从索引中移除误放的文件，再 `rm -rf` 删除物理文件，单独提交清理。

### 更优解法
同步时应先 `git show <remote>/<branch>:<file>` 输出到目标路径，而非直接 `git checkout`：
```bash
git show huawei-backend/main:src/main/resources/data.sql > code-agent/backend/src/main/resources/data.sql
```

### 归因（Vibe Coding 视角）
**模型上下文不够**：Agent 对 monorepo + subtree 的路径映射关系理解不到位，执行 checkout 时没有考虑目标路径偏移问题。属于**多仓架构理解不完整**导致的操作失误。

---

## BUG-012：华为云后端 main 分支有保护规则，不允许 force push

### 现象
- 执行 `git push huawei-backend <commit>:refs/heads/main --force` 报错被拒
- 错误：`non-fast-forward`，无法强制推送

### 根因
华为云 CodeHub 对 `main` 分支设置了分支保护规则，禁止 force push，需要通过 MR（Merge Request）合并。

### 我们的解法
推送到临时分支（如 `sync-main-task-a`），在华为云平台创建 MR 合并到 main；或推送到临时分支后从该分支 fast-forward 合并。

### 更优解法
提前了解 CI/CD 平台的分支保护策略，将 main 保护纳入开发规范，统一使用 MR 流程合并，不依赖 force push。

### 归因（Vibe Coding 视角）
**环境约束未传达**：华为云的分支保护配置属于平台运维信息，Agent 无法预知。但在第一次遇到后，应将此约束写入项目规范，避免后续重复踩坑。属于**平台信息传达不足**。

---

## 归因总结

| 归因类型 | 涉及 Bug | 说明 |
|---|---|---|
| **模型上下文不够** | BUG-001、BUG-004、BUG-011 | 模型对框架/工具的边界行为、底层机制理解不完整，生成了"看起来对但逻辑有误"的代码或操作 |
| **需求描述不清楚** | BUG-002、BUG-005、BUG-009 | 任务描述缺少关键约束或边界定义，Agent 按最简路径实现，遗漏了业务完整性 |
| **需求拆解不够细** | BUG-002、BUG-003 | 用户故事粒度太粗，验收条件不够具体，导致实现只满足表面功能而非完整业务链路 |
| **开发者 taste 不对** | BUG-003、BUG-006、BUG-010 | Agent 倾向于"能跑就行"的最简实现，缺乏对可维护性、健壮性、全局一致性的自发追求 |
| **环境约束未传达** | BUG-007、BUG-012 | 基础设施、平台规则等运行时信息没有在 prompt 或项目规范中显式说明，Agent 无法感知 |
| **技术方案副作用考虑不足** | BUG-008、BUG-011 | 选型时只关注主路径，忽略了方案对多人协作、路径结构、历史连续性的影响 |

---

## 经验教训

1. **每次推送前必须 `pnpm build` 零错误**，不能只跑 `tsc -b`
2. **MySQL 数据变更后必须 `down -v` 清 volume**，`INSERT IGNORE` 不能更新已有数据
3. **多人代码同步用 `git show` 输出到目标路径**，不要 `git checkout -- .` 整目录覆盖
4. **Spring Security 必须显式定义 `SecurityFilterChain` bean**，不能依赖注释注解来禁用
5. **SQL 文件头部必须有 `SET NAMES utf8mb4`**，字符集声明不能省略
6. **华为云 main 分支有保护，只能通过 MR 合并**，不要尝试 force push
7. **Vibe Coding 的 prompt 要包含环境约束**：Node 版本、包管理器、CI 平台规则、分支策略等
