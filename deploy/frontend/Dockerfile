# ======================
# SeatFlow Frontend Dockerfile
# ======================
FROM node:22-alpine AS builder
WORKDIR /app

# 复制依赖文件（利用 Docker 层缓存）
COPY code-agent/frontend/package.json code-agent/frontend/pnpm-lock.yaml* ./

# 安装 pnpm（使用 npm 安装，兼容 podman 离线/受限网络环境）
RUN npm install -g pnpm@9
RUN pnpm install --frozen-lockfile || pnpm install

# 复制源码并构建（排除无效的 pnpm-workspace.yaml）
COPY code-agent/frontend/src ./src
COPY code-agent/frontend/index.html ./
COPY code-agent/frontend/tsconfig*.json ./
COPY code-agent/frontend/vite.config.ts ./
COPY code-agent/frontend/.npmrc ./
RUN pnpm build

# 运行阶段 — Nginx 提供静态文件 + 反向代理 API
FROM nginx:alpine
COPY deploy/frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
