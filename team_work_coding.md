# SeatFlow 团队协作冲突问题记录

> 5人小组 Vibe Coding 协作开发过程中遇到的所有团队冲突问题、复现场景与解法。
> 目标：帮助后续类似项目避免重蹈覆辙。

---

## CONFLICT-001：本地 MySQL 配置各不相同

### 冲突现象
- 组员 A 本地 MySQL root 密码是 `root`，组员 B 是 `123456`，组员 C 没有本地 MySQL
- `application.yml` 里的 `spring.datasource.username/password` 写死了一个人的配置
- 拉取代码后直接运行报 `Access denied for user 'root'@'localhost'`

### 根因
数据库连接配置硬编码在 `application.yml`，无法适配不同本地环境。

### 我们的解法
统一用 Docker/Podman 部署 MySQL，不依赖本地 MySQL 安装：
```bash
cd deploy
podman-compose up -d mysql  # 只启动 MySQL 容器
```
`application.yml` 连接 `localhost:3307`，密码统一为 `deploy/.env` 中定义的 `MYSQL_ROOT_PASSWORD=seatflow123`。

### 更优解法
用 `application-local.yml` + `.gitignore` 隔离本地配置：
```yaml
# application.yml（提交到 git）
spring:
  datasource:
    url: ${DB_URL:jdbc:mysql://localhost:3307/seatflow}
    username: ${DB_USER:root}
    password: ${DB_PASSWORD:seatflow123}
```
每个人在本地创建 `application-local.yml` 覆盖，不提交到 git。

---

## CONFLICT-002：init.sql 数据频繁修改导致合并冲突

### 冲突现象
- 组员 A 扩充了自习室和座位数据（data.sql v2.0 → v3.0）
- 组员 B 在 data.sql 里加了 RBAC 权限初始化数据
- 两人同时修改同一文件，pull 时产生 merge conflict

### 根因
`data.sql` / `init.sql` 是单一文件，多人同时写入不同业务模块的初始数据，必然产生行级冲突。

### 我们的解法
将组员 B 的 RBAC 数据（`INSERT IGNORE`）和组员 A 的业务种子数据合并为统一的 v2.0 版本，人工审核冲突后手动合并，用 `INSERT IGNORE` 保证幂等性。

### 更优解法
按模块拆分 SQL 文件，由主库合并：
```
deploy/mysql/
  01_schema.sql        # 建表（所有人共同维护）
  02_rbac_seed.sql     # 组员 B 负责
  03_room_seat_seed.sql # 组员 A 负责
  04_reservation_seed.sql # 组员 C 负责
```
MySQL 容器 `entrypoint` 按字母顺序执行 `/docker-entrypoint-initdb.d/` 下的所有 `.sql`，天然支持拆分文件，减少冲突面。

---

## CONFLICT-003：BCrypt 密码 Hash 不一致导致登录失败

### 冲突现象
- 组员 B 写 data.sql 时用自己生成的 BCrypt hash（`$2a$10$N.zmdr9k7...`）
- 该 hash 对应的密码**不是** `admin123`，是组员 B 本人知道的密码
- 其他组员登录时一律报 `密码错误`，不知道实际密码是什么

### 根因
BCrypt hash 不可逆，注释说明 `-- admin123 ->` 是错误的，实际 hash 与密码不对应。

### 我们的解法
统一替换回项目初始验证过的 hash：
- `admin123` → `$2a$10$XiJZwcfX1LTFisLwC3LtD.vu9Q745J1dgom5nkR8CR3RQsKbUEUFK`
- `student123` → `$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G`

### 更优解法
在 data.sql 头部注释中写明密码明文，并由一人统一生成所有 hash，其他人不得修改用户表数据：
```sql
-- 测试账号（统一格式，禁止个人修改）
-- admin / admin123
-- student1~5 / student123
```

---

## CONFLICT-004：代码同步时整目录覆盖，丢失已有改动

### 冲突现象
- 组员 A 实现了「批量生成座位」功能（`SeatManage.tsx`）
- 同步组员 B 的华为云 main 代码时，用 `git checkout huawei-frontend/main -- src/` 整目录覆盖
- 组员 A 的改动被组员 B 的旧版本覆盖，功能消失

### 根因
`git checkout <remote> -- <dir>` 是破坏性操作，会无条件覆盖本地文件，不会合并，不会报冲突。

### 我们的解法
从自己的历史分支恢复被覆盖的文件：
```bash
git show huawei-frontend/feature/task_a_room_management:src/pages/admin/SeatManage.tsx \
  > code-agent/frontend/src/pages/admin/SeatManage.tsx
```

### 更优解法
同步他人代码时**永远用 `git merge`，不用 `git checkout -- <dir>`**：
```bash
git fetch huawei-frontend
git merge huawei-frontend/main --no-ff
# 手动解决冲突后提交
```
或者明确只同步对方新增的文件，不动自己修改过的文件：
```bash
# 查看对方新增了哪些文件
git diff HEAD huawei-frontend/main --name-only --diff-filter=A
```

---

## CONFLICT-005：monorepo 路径导致文件放错位置

### 冲突现象
- 用 `git checkout huawei-backend/main -- src/` 同步华为云后端代码
- `src/` 目录直接出现在 monorepo 根目录（应在 `code-agent/backend/src/`）
- `data.sql`、`schema.sql` 等也跑到了根目录

### 根因
华为云后端仓库的 `src/` 在其根目录，checkout 到 monorepo 时按原路径存放，导致路径错位。monorepo 中后端代码应在 `code-agent/backend/` 下。

### 我们的解法
用 `git show` 指定输出路径：
```bash
git show huawei-backend/main:src/main/resources/data.sql \
  > code-agent/backend/src/main/resources/data.sql
```
并用 `git rm -r --cached` 清理误放的文件。

### 更优解法
建立明确的"同步操作 SOP"，每次同步前先检查目标路径：
```bash
# 同步单个文件，路径明确
git show huawei-backend/main:<源路径> > code-agent/backend/<目标路径>

# 或使用 git subtree pull 保持路径映射
git subtree pull --prefix=code-agent/backend huawei-backend main
```

---

## CONFLICT-006：RBAC 表结构与权限数据由多人维护，接口定义冲突

### 冲突现象
- 组员 B 负责 RBAC，定义了 `t_role`、`t_permission`、`t_role_permission`、`t_user_role` 等表
- 组员 A 在自己的 schema.sql 里也定义了部分相关表（早期未协调）
- 合并时出现表重复定义、字段名不一致（如 `role_name` vs `name`）

### 根因
多人分头开发，没有在开发前对表结构做统一评审。各人按自己理解建表，合并时冲突。

### 我们的解法
以组员 B 的 RBAC 设计为准，组员 A 的相关表定义全部删除，使用 `INSERT IGNORE` + `SELECT JOIN` 的方式插入权限关联数据，避免硬编码 ID。

### 更优解法
开发前召开"表结构评审会"，确定所有表的字段名、类型、枚举值，写入统一的 `schema.sql`，每个人只负责自己模块的 `data_*.sql`，**不允许修改 schema.sql 未分配给自己的表**。

---

## CONFLICT-007：华为云 main 分支有保护规则，强推失败

### 冲突现象
- 组员 A 完成合并后，执行 `git push huawei-backend <commit>:refs/heads/main --force`
- 华为云 CodeHub 报错，拒绝 force push
- 报错：`non-fast-forward`，无法强制推送

### 根因
华为云 CodeHub 对 `main` 分支设置了保护规则，禁止 force push，要求通过 Merge Request 合并。

### 我们的解法
推送到临时分支（`sync-main-task-a`），在华为云 Web UI 创建 MR 合并到 main；或直接 fast-forward 推送（确保本地 main 包含远端所有提交）。

### 更优解法
所有人统一通过 feature 分支 → MR → main 的标准 GitFlow，不依赖直接推 main。在项目初期就在 CodeHub 上设置好分支保护和 MR 审核规则，形成规范。

---

## CONFLICT-008：MySQL Volume 未清空，init.sql 更新不生效

### 冲突现象
- 更新了 `init.sql`（新增自习室/座位），重启容器后数据仍是旧的
- 其他组员 pull 最新代码，重跑 `docker-compose up -d` 后问题依旧

### 根因
MySQL 使用 named volume 持久化数据。volume 已存在时，MySQL 不会重新执行 `init.sql`，直接复用旧数据。`INSERT IGNORE` 只防止报错，不会更新已存在的记录。

### 我们的解法
```bash
podman-compose down -v   # -v 参数强制删除 volume
podman-compose up -d --build
```

### 注意事项
- 告知所有组员：**每次 init.sql 有变更，必须 `down -v` 清库重建**
- 或者在 init.sql 中用 `DELETE FROM t_xxx WHERE ...` 显式清理旧数据再插入
- 生产环境应迁移到 Flyway/Liquibase 做版本化管理

---

## CONFLICT-009：前端构建工具冲突（npm vs pnpm）

### 冲突现象
- 部分组员用 `npm install`，内部 npm registry 包不全，且会篡改 `package.json` 写入内部源地址
- `package-lock.json` 和 `pnpm-lock.yaml` 同时存在，导致两个 lockfile 冲突
- `npm install` 后部分组员的构建比其他人多出警告，甚至报错

### 根因
内部 npm registry（`npm.devops.xiaohongshu.com:7001`）镜像不完整，且会修改配置文件污染仓库。

### 我们的解法
- 强制规定：**前端只用 pnpm，禁止使用 npm/yarn**
- `.npmrc` 中配置公共源
- 删除仓库中的 `package-lock.json`，只保留 `pnpm-lock.yaml`
- 加入 `README.md` 开发规范说明

### 更优解法
在 `package.json` 中加入 `engines` 约束：
```json
{
  "engines": {
    "node": ">=22.0.0",
    "pnpm": ">=9.0.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

---

## CONFLICT-010：unrelated histories 导致 git pull 报错

### 冲突现象
- 我们用 `git subtree split` 生成纯后端/前端分支，force push 到华为云
- 其他组员之前 clone 了华为云仓库，再 `git pull` 时报 `refusing to merge unrelated histories`
- 提交历史不连续，无法正常合并

### 根因
`git subtree split` 生成的提交树与组员本地 clone 的历史没有公共祖先节点，Git 拒绝合并不相关的历史。

### 我们的解法
```bash
git fetch origin
git reset --hard origin/main
```
放弃本地历史，强制对齐远端版本。

### 更优解法
初始建仓时统一通过 `git clone` 从华为云 clone，不做多次 force push；或在第一次 push 后明确告知所有组员重新 clone：
```bash
git clone git@codehub...seat_booking_server.git
```

---

## 团队协作规范总结（防止冲突清单）

| 类别 | 规范 |
|---|---|
| **数据库配置** | 统一用 Docker/Podman，不依赖本地 MySQL；密码写在 `.env`，不硬编码到 `application.yml` |
| **SQL 文件** | 按模块拆分 `data_xxx.sql`，避免多人同改一文件；每次变更后告知全员 `down -v` 重建 |
| **密码 Hash** | 由一人统一生成所有测试账号 hash，注释写明明文密码，禁止个人修改 |
| **代码同步** | 用 `git merge` 而非 `git checkout -- <dir>`；同步前先 `git diff` 确认变更范围 |
| **文件路径** | monorepo 同步用 `git show <remote>:<src> > <dst>`，不用 `git checkout -- <dir>` |
| **分支策略** | feature 分支开发 → MR → main，禁止直接 push main；team 主库不做 force push |
| **前端工具** | 只用 pnpm；推送前必须 `pnpm build` 零错误 |
| **后端验证** | 推送前必须 `mvn compile` 零错误 |
| **表结构** | 开发前统一评审 schema，每人只维护自己模块的表 |
| **git 初始化** | 建仓后统一 clone，不做破坏性 force push；有 force push 时通知全员重新 clone |
