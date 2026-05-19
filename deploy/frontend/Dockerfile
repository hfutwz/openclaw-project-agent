# ======================
# SeatFlow Frontend Dockerfile
# ======================

# 构建阶段
FROM node:20-alpine AS builder
WORKDIR /app

# 先复制依赖文件
COPY code-agent/frontend/package.json code-agent/frontend/pnpm-lock.yaml* ./

# 用 pnpm 安装（npm 在内部 registry 有问题）
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile || pnpm install --registry=https://registry.npmmirror.com

# 复制源码
COPY code-agent/frontend ./

# 构建
RUN pnpm build

# 运行阶段 — Nginx 提供静态文件 + 反向代理 API
FROM nginx:alpine
COPY deploy/frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
