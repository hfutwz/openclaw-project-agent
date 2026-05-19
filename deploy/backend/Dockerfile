# ======================
# SeatFlow Backend Dockerfile
# ======================
# 需要先在本机编译：cd code-agent/backend && mvn package -DskipTests
# 或者使用多阶段构建（需要完整源码）
# ======================

# 多阶段构建 — 先编译再打包
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build
COPY code-agent/backend/pom.xml .
RUN mvn dependency:go-offline -B || true
COPY code-agent/backend/src ./src
RUN mvn package -DskipTests -q

# 运行阶段
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/target/seatflow-api-*.jar app.jar
EXPOSE 8080
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
