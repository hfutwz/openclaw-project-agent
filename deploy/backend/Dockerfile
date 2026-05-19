# ======================
# SeatFlow Backend Dockerfile
# ======================
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build

# 复制 pom.xml 并下载依赖（利用 Docker 层缓存）
COPY code-agent/backend/pom.xml .
RUN mvn dependency:go-offline -B

# 复制源码并打包
COPY code-agent/backend/src ./src
RUN mvn package -DskipTests -q

# 运行阶段 — 使用轻量 JRE 镜像
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/target/seatflow-api-*.jar app.jar
EXPOSE 8080
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
