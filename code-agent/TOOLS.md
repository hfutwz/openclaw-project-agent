# TOOLS.md — Code Agent 工具说明

## 本地环境

### 沙箱环境（当前运行环境）
- **OS：** Debian GNU/Linux 12 (bookworm) x86_64
- **Java：** /tmp/jdk-21.0.2（已安装）
- **Maven：** /usr/bin/mvn 3.8.7
- **Node：** v22.22.0
- **MySQL：** /tmp/mysql-8.0.36-linux-glibc2.28-x86_64（已安装）
- **libaio：** /tmp/libaio-local（自编译）

### MySQL 启动命令（沙箱内）
```bash
export LD_LIBRARY_PATH=/tmp/libaio-local/lib:$LD_LIBRARY_PATH
export MYSQL_HOME=/tmp/mysql-8.0.36-linux-glibc2.28-x86_64
nohup $MYSQL_HOME/bin/mysqld --user=node \
  --basedir=$MYSQL_HOME --datadir=/tmp/mysql-data \
  --port=3306 --socket=/tmp/mysql.sock > /tmp/mysql.log 2>&1 &
```

### MySQL 客户端连接
```bash
$MYSQL_HOME/bin/mysql -u root --socket=/tmp/mysql.sock seatflow
```

### 后端启动命令（沙箱内）
```bash
export JAVA_HOME=/tmp/jdk-21.0.2
export PATH=$JAVA_HOME/bin:$PATH
cd code-agent/backend
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xmx512m"
```

### 前端启动命令
```bash
cd code-agent/frontend
npm run dev
```

## Mac 本地运行（用户 Will 的环境）

### 数据库
- 使用 Docker 运行 MySQL 8.0
- 配置文件：`deploy/docker-compose.yml`（待创建）
- 连接地址：`localhost:3306`

### 后端
- Java 21 + Maven
- `mvn spring-boot:run`

### 前端
- Node.js + npm
- `npm run dev`（端口 5173）

## GitHub
- 仓库：https://github.com/hfutwz/openclaw-project-agent
- 分支策略：直接在 main 分支开发提交
- Commit 格式：`fix(US-Sxx): 修复xxx问题`
