# SeatFlow 本地启动指南

> 本文档指导从 **华为云 CodeHub** 拉取前端和后端代码，在本地完整启动 SeatFlow 系统。

---

## 目录

1. [前置环境要求](#1-前置环境要求)
2. [拉取代码](#2-拉取代码)
3. [数据库初始化](#3-数据库初始化)
4. [启动后端](#4-启动后端)
5. [启动前端](#5-启动前端)
6. [验证与默认账号](#6-验证与默认账号)
7. [常见问题](#7-常见问题)

---

## 1. 前置环境要求

| 工具 | 版本要求 | 说明 |
|---|---|---|
| JDK | **21**（必须） | Spring Boot 3 要求 Java 17+，推荐21 |
| Maven | 3.8+ | 后端构建工具 |
| Node.js | 18+ | 前端运行环境 |
| pnpm | 8+ | 前端包管理器（**不用 npm**） |
| MySQL | 8.0+ | 数据库 |
| Git | 任意新版 | 代码拉取 |

### 安装 pnpm（如未安装）

```bash
npm install -g pnpm
```

### 验证环境

```bash
java -version    # 应显示 openjdk 21
mvn -version     # 应显示 Maven 3.x
node -v          # 应显示 v18+
pnpm -v          # 应显示 8.x+
mysql --version  # 应显示 8.x
```

---

## 2. 拉取代码

前端和后端分属两个独立的华为云 CodeHub 仓库，分别拉取。

### 2.1 配置 SSH（首次）

如果尚未配置华为云 SSH Key，先生成并添加到华为云账号：

```bash
# 生成 SSH Key（已有可跳过）
ssh-keygen -t ed25519 -C "your-email@example.com"

# 查看公钥，复制到华为云 CodeHub → 个人设置 → SSH 公钥
cat ~/.ssh/id_ed25519.pub
```

### 2.2 拉取后端代码

```bash
# 克隆后端仓库
git clone git@codehub.devcloud.cn-east-3.huaweicloud.com:6399ad5249b844219fdf1c5db0d5b204/seat_booking_server.git

# 进入目录
cd seat_booking_server

# 切换到主开发分支（如需最新开发版）
git checkout feature/wz_dev_main

# 或使用稳定版 main
git checkout main
```

### 2.3 拉取前端代码

```bash
# 另开一个终端，克隆前端仓库
git clone git@codehub.devcloud.cn-east-3.huaweicloud.com:6399ad5249b844219fdf1c5db0d5b204/seat_booking_web.git

# 进入目录
cd seat_booking_web

# 切换分支
git checkout feature/wz_dev_main
# 或
git checkout main
```

---

## 3. 数据库初始化

### 3.1 登录 MySQL

```bash
mysql -u root -p
```

### 3.2 执行初始化 SQL

后端仓库中包含完整初始化脚本（建库 + 建表 + 种子数据）。

**方式一：命令行直接执行**

```bash
# 在 seat_booking_server 目录下
mysql -u root -p < deploy/mysql/init.sql
```

**方式二：MySQL 客户端粘贴执行**

打开 `deploy/mysql/init.sql`，全选内容，在 MySQL Workbench / DBeaver / 命令行中执行。

### 3.3 初始化内容说明

`init.sql` 包含以下内容（幂等，可重复执行）：

```
✅ 创建数据库 seatflow（utf8mb4）
✅ 创建 11 张表（用户/院系/自习室/座位/预约/签到码/违约/角色/权限/RBAC关联/系统参数）
✅ 初始化种子数据：
   - 6 个院系
   - 4 个自习室（含院系关联）
   - 74 个座位（含插座/位置标记）
   - 4 个角色 + 8 个权限 + 角色-权限映射
   - 3 个默认用户（admin / student1 / student2）
   - 今日签到编码
   - 系统参数（max_reservation_hours = 4）
```

### 3.4 验证数据库

```sql
USE seatflow;
SHOW TABLES;
-- 应显示 11 张表

SELECT username, user_type FROM t_user;
-- 应显示 admin、student1、student2
```

---

## 4. 启动后端

### 4.1 修改数据库配置

打开 `src/main/resources/application.yml`，修改数据库连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/seatflow?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false
    username: root          # ← 改为你的 MySQL 用户名
    password: yourpassword  # ← 改为你的 MySQL 密码
```

> **邮件配置（可选）：** 如不需要邮件推送，`spring.mail` 相关配置可留空，系统仅使用 WebSocket 推送。

### 4.2 编译验证

```bash
cd seat_booking_server

# 确保使用 JDK 21
export JAVA_HOME=/path/to/jdk21   # macOS 示例：/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 编译检查（不运行）
mvn compile -q
# 无任何报错输出即为通过
```

### 4.3 启动服务

```bash
mvn spring-boot:run
```

启动成功标志：

```
Started SeatflowApiApplication in X.XXX seconds
Tomcat started on port 8080
```

### 4.4 验证后端

```bash
# 测试登录接口
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 应返回包含 token 的 JSON
```

> **注意：** 后端运行在 `http://localhost:8080`，前端开发模式通过 Vite 代理透明转发 `/api` 请求，无需手动处理跨域。

---

## 5. 启动前端

### 5.1 安装依赖

```bash
cd seat_booking_web

pnpm install
```

### 5.2 启动开发服务器

```bash
pnpm dev
```

启动成功标志：

```
  VITE v6.x.x  ready in XXX ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

打开浏览器访问：**http://localhost:5173**

### 5.3 生产构建（可选）

```bash
pnpm build
# 构建产物在 dist/ 目录，可部署到 Nginx 等 Web 服务器
```

---

## 6. 验证与默认账号

### 默认账号

| 账号 | 密码 | 角色 | 登录后跳转 |
|---|---|---|---|
| `admin` | `admin123` | 超级管理员（全部权限） | 管理端仪表盘 |
| `student1` | `student123` | 学生（计算机学院） | 学生端自习室列表 |
| `student2` | `student123` | 学生（电子工程学院） | 学生端自习室列表 |

### 验证清单

登录后按以下顺序验证核心功能：

**学生端（student1 登录）**
- [ ] 能看到自习室列表（卡片展示空座数）
- [ ] 点击自习室进入座位图（绿色可选 / 灰色已占）
- [ ] 点击座位 → 弹出时间选择 → 预约成功
- [ ] 在「我的预约」页看到刚才的预约
- [ ] 在「签到」页输入当日编码（可在管理端查看）→ 签到成功

**管理端（admin 登录）**
- [ ] 仪表盘显示统计数据
- [ ] 自习室管理：可新增/编辑/停用
- [ ] 签到码管理：可查看今日各自习室编码
- [ ] 角色管理：可查看 4 个角色和 8 个权限
- [ ] 系统参数：可查看并修改 max_reservation_hours

---

## 7. 常见问题

### Q: 启动后端报错 `Access denied for user 'root'@'localhost'`
**A:** `application.yml` 中的 MySQL 密码不正确，修改 `spring.datasource.password` 后重启。

### Q: 前端页面空白或 `/api` 请求报 502
**A:** 后端未启动或端口不是 8080，确认后端已运行在 `http://localhost:8080`。

### Q: 提示 `Unknown database 'seatflow'`
**A:** 数据库未初始化，执行第 3 节的 `init.sql`。

### Q: 编译报错 `java.lang.UnsupportedClassVersionError`
**A:** JDK 版本不是 21，检查 `java -version` 并切换到 JDK 21。

### Q: `pnpm install` 失败，报网络错误
**A:** 切换 pnpm 镜像源：
```bash
pnpm config set registry https://registry.npmmirror.com
pnpm install
```

### Q: 华为云 SSH 拉取失败（Permission denied）
**A:** SSH 公钥未添加到华为云，参考第 2.1 节重新配置。

---

## 附：服务端口汇总

| 服务 | 地址 |
|---|---|
| 前端开发服务器 | http://localhost:5173 |
| 后端 API | http://localhost:8080 |
| MySQL | localhost:3306 |
