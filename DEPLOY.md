# SeatFlow 部署指南

## 前置条件
- Docker Desktop (Mac)
- Java 21 (本地运行后端)
- Node.js 22+ & npm (本地运行前端)

## 方案 A：Docker MySQL + 本地前后端（推荐）

### 1. 启动 MySQL 容器
```bash
cd openclaw-project-agent
docker compose up -d mysql
```

### 2. 启动后端
```bash
cd code-agent/backend
# 修改 application.yml 中的数据库连接
# 或者使用 Docker profile：
export JAVA_HOME=/path/to/jdk-21
mvn spring-boot:run
# 后端默认端口 8080
```

### 3. 启动前端
```bash
cd code-agent/frontend
npm install
npm run dev
# 前端默认端口 5173
```

### 4. 访问
- 前端: http://localhost:5173
- 后端 API: http://localhost:8080
- API 文档: http://localhost:8080/api-docs

## 方案 B：全容器化部署

### 1. 构建并启动所有服务
```bash
cd openclaw-project-agent
docker compose up -d
```

### 2. 访问
- 后端 API: http://localhost:8080
- MySQL: localhost:3306

## 默认账号

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 管理员 | admin | admin123 |
| 学生1 | student1 | student123 |
| 学生2 | student2 | student123 |

## 端口说明
- 8080: 后端 API
- 5173: 前端 Vite Dev Server
- 3306: MySQL
