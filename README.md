# Tarefas App
Um aplicativo de tarefas para fazer uma atividade. 
Caso você seja apressado, e tenha docker no seu ambiente:
```bash
docker compose up -d
```

do contrário, abaixo estarão algumas instruções.

# Como Rodar

Se quiser rodar, basta fazer os passos abaixo

## Requisitos Obrigatórios

- [Java 17+](https://adoptopenjdk.net/)
- [MySql 8+](https://www.mysql.com/downloads/)

## Requisitos Opcionais

- [Docker](https://www.docker.com/) (opcional, para rodar via containers)
- [Nix](https://nixos.org/) (opcional, para configurar um ambiente de desenvolvimento)

### 1. Rodando normalmente

```sh
# Clone o projeto
git clone https://github.com/adnanioricce/tarefas-app.git
cd tarefas-app
# Compile
./mvnw clean install
# Rode 
java -jar target/*.jar
```

### 2. Rodando com Docker
Basta construir a imagem e executar o projeto.

```sh
docker build -t tarefas-app .
docker run -p 8080:8080 tarefas-app
```
você pode utilizar as seguintes variaveis de ambiente: 
```plaintext
SPRING_DATASOURCE_URL:  url da instância mysql
SPRING_DATASOURCE_USERNAME: nome de usuário da instância mysql
SPRING_DATASOURCE_PASSWORD: senha da instância mysql
SPRING_JPA_HIBERNATE_DDL_AUTO: DDL do Hibernate, recomendo deixar "update"
# Importante:
# DDL = Database Schema Generation => Geração de Esquema de Banco de dados
```

### 4. Rodando com Nix (opcional)

Eu só não queria instalar java só pra esse projeto, e eu estava curioso de utilizar o nix há um tempo. 
Esse é um arquivo que pode ser facilmente ignorado, mas caso esteja curioso...
```sh
nix-shell
# Depois rode os comandos Java normalmente dentro do nix-shell
```
