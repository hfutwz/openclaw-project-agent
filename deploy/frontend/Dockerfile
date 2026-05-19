# ======================
# SeatFlow Frontend Dockerfile
# ======================
FROM node:22-alpine AS builder
WORKDIR /app

# 复制依赖文件（利用 Docker 层缓存）
COPY code-agent/frontend/package.json code-agent/frontend/pnpm-lock.yaml* ./

# 安装 pnpm 并安装依赖
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --config.onlyBuiltDependencies=esbuild || pnpm install --config.onlyBuiltDependencies=esbuild

# 复制源码并构建
COPY code-agent/frontend ./
RUN pnpm build

# 运行阶段 — Nginx 提供静态文件 + 反向代理 API
FROM nginx:alpine
COPY deploy/frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
