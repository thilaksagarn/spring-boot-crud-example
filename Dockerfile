# ------------ Stage 1: Build ------------ #
FROM maven:3.8.6-eclipse-temurin-17-alpine AS builder

# Set working directory inside the container
WORKDIR /app

# Copy pom.xml and download dependencies (leverages Docker caching)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code and package the application
COPY src ./src
RUN mvn clean package -DskipTests

# ------------ Stage 2: Runtime ------------ #
FROM eclipse-temurin:17-jre-alpine

# Set environment variables (for secrets use Docker Secrets or .env in compose/k8s)
ENV JAVA_OPTS="-Xms256m -Xmx512m"

# Create a user (optional security enhancement)
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Set working directory
WORKDIR /app

# Copy built jar from Stage 1
COPY --from=builder /app/target/spring-boot-crud-example-2-0.0.1-SNAPSHOT.jar app.jar

# Healthcheck (Kubernetes can also manage readiness/liveness probes)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Expose application port
EXPOSE 8081

# Default command
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
