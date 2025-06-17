{
  description = "Ambiente de desenvolvimento para API de Tarefas Spring Boot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Versões específicas para consistência
        jdk = pkgs.openjdk17;
        maven = pkgs.maven;
        
        # Script para inicializar o banco MySQL
        mysql-init-script = pkgs.writeScriptBin "mysql-init" ''
          #!/bin/bash
          echo "🗄️  Iniciando MySQL..."
          
          # Criar diretório para dados MySQL se não existir
          mkdir -p .devenv/mysql
          
          # Inicializar MySQL se necessário
          if [ ! -d ".devenv/mysql/mysql" ]; then
            echo "📦 Inicializando banco de dados MySQL..."
            ${pkgs.mysql80}/bin/mysqld --initialize-insecure \
              --datadir=.devenv/mysql \
              --basedir=${pkgs.mysql80}
          fi
          
          # Iniciar servidor MySQL
          echo "🚀 Iniciando servidor MySQL..."
          ${pkgs.mysql80}/bin/mysqld \
            --datadir=.devenv/mysql \
            --socket=.devenv/mysql.sock \
            --port=3306 \
            --bind-address=127.0.0.1 \
            --skip-networking=false &
          
          # Aguardar MySQL inicializar
          sleep 5
          
          # Criar banco e usuário
          echo "👤 Configurando banco e usuário..."
          ${pkgs.mysql80}/bin/mysql \
            --socket=.devenv/mysql.sock \
            -u root \
            -e "CREATE DATABASE IF NOT EXISTS tarefas_db;"
          
          ${pkgs.mysql80}/bin/mysql \
            --socket=.devenv/mysql.sock \
            -u root \
            -e "CREATE USER IF NOT EXISTS 'tarefas_user'@'localhost' IDENTIFIED BY 'senha123';"
          
          ${pkgs.mysql80}/bin/mysql \
            --socket=.devenv/mysql.sock \
            -u root \
            -e "GRANT ALL PRIVILEGES ON tarefas_db.* TO 'tarefas_user'@'localhost';"
          
          ${pkgs.mysql80}/bin/mysql \
            --socket=.devenv/mysql.sock \
            -u root \
            -e "FLUSH PRIVILEGES;"
          
          echo "✅ MySQL configurado com sucesso!"
        '';
        
        # Script para executar a aplicação
        run-app-script = pkgs.writeScriptBin "run-app" ''
          #!/bin/bash
          echo "🚀 Executando aplicação Spring Boot..."
          
          # Verificar se MySQL está rodando
          if ! pgrep -f mysqld > /dev/null; then
            echo "❌ MySQL não está rodando. Execute 'mysql-init' primeiro."
            exit 1
          fi
          
          # Executar aplicação
          ${maven}/bin/mvn spring-boot:run \
            -Dspring-boot.run.profiles=dev
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Java e Maven
            jdk
            maven
            
            # Banco de dados
            mysql80
            
            # Scripts customizados
            mysql-init-script
            run-app-script
            
            # Ferramentas
            curl
            docker
            kubectl
          ];
          
          shellHook = ''
            echo "🚀 Ambiente de desenvolvimento Spring Boot"
            echo "Execute 'mysql-init' para configurar MySQL"
            echo "Execute 'run-app' para iniciar a aplicação"
            
            export JAVA_HOME="${jdk}"
            export PATH="${jdk}/bin:${maven}/bin:$PATH"
          '';
        };
      });
}
