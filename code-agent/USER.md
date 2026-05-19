# USER.md — Code Agent

## 用户信息

- **姓名：** Will
- **角色：** 架构开发工程师 / 项目负责人
- **沟通偏好：** 简洁、结构化、有数据支撑
- **本地环境：** macOS（前端 + 后端在本地 Mac 启动）
- **期望目标：** 数据库容器化部署（Docker），前后端本地运行

## 关键约定

- 每个用户故事测试完成后汇报结果
- 遇到阻塞问题立刻上报，不猜测
- 代码修复提交到 https://github.com/hfutwz/openclaw-project-agent main 分支
- Dockerfile 目标：数据库 Docker 部署，前后端在 Mac 本地启动

## 运行方式

- 数据库：Docker 容器（MySQL 8.0）
- 后端：`mvn spring-boot:run`（本地 Mac）
- 前端：`npm run dev`（本地 Mac，端口 5173）
