# Dockerfile multi-stage para otimizar o tamanho da imagem
# FROM openjdk:26-jdk-slim AS builder
FROM openjdk:26-jdk-slim

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Dar permissão de execução ao mvnw
RUN chmod +x mvnw

# Baixar dependências (cache layer)
RUN ./mvnw dependency:go-offline -B

# Copiar código fonte
COPY src src

# Compilar aplicação
RUN ./mvnw clean package -DskipTests

# Stage final com imagem otimizada
# FROM openjdk:26-jre-slim

# Instalar curl para health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Criar usuário não-root para segurança
RUN groupadd -r spring && useradd -r -g spring spring

# Definir diretório de trabalho
WORKDIR /app

# Copiar JAR da aplicação do stage anterior
# COPY --from=builder /app/target/*.jar app.jar
COPY /app/target/*.jar app.jar

# Definir propriedades do usuário
RUN chown spring:spring app.jar
USER spring:spring

# Expor porta da aplicação
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# Comando para executar a aplicação
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
