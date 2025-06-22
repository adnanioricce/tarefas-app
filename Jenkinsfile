pipeline {
    agent any
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'ref', value: '$.ref'],
                [key: 'repository_name', value: '$.repository.name'],
                [key: 'pusher_name', value: '$.pusher.name']
            ],
            causeString: 'Triggered by Gitea push from $pusher_name',
            token: 'DEFAULT_API_TOKEN',
            tokenCredentialId: '',
            printContributedVariables: true,
            printPostContent: true,
            silentResponse: false,
            regexpFilterText: '$ref',
            regexpFilterExpression: 'refs/heads/(main|develop)'
        )
    }
    environment {
        // Container registry configuration
        CONTAINER_REGISTRY = 'homelab-dev:3030'
        CONTAINER_REGISTRY_USERNAME = 'adnangonzaga'
        PROJECT_NAME = 'tarefas-app'
        APP_NAME = 'tarefas-api'
        
        // Kubernetes configuration
        KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-credential'
        NAMESPACE = 'default'
        
        // Docker configuration
        DOCKER_CREDENTIAL_ID = 'docker-registry-credential'
        
        // Generated variables (will be set during pipeline execution)
        APP_VERSION = ''
        IMAGE_TAG = ''
        FULL_IMAGE_NAME = ''
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Set App Version') {
            steps {
                script {
                    // Generate app version based on commit hash and timestamp
                    def gitCommit = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    
                    def timestamp = sh(
                        script: 'date +%Y%m%d-%H%M%S',
                        returnStdout: true
                    ).trim()
                    
                    APP_VERSION = "${timestamp}-${gitCommit}"
                    IMAGE_TAG = "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USERNAME}/${PROJECT_NAME}/${APP_NAME}:${APP_VERSION}"
                    FULL_IMAGE_NAME = IMAGE_TAG
                    
                    echo "App Version: ${APP_VERSION}"
                    echo "Full Image Name: ${FULL_IMAGE_NAME}"
                }
            }
        }
        
        stage('Build Application') {
            steps {
                echo 'Building Spring Boot application...'
                script {
                    // Build the Spring Boot application
                    sh '''
                        if [ -f "./gradlew" ]; then
                            echo "Building with Gradle..."
                            ./gradlew clean build -x test
                        elif [ -f "./mvnw" ]; then
                            echo "Building with Maven..."
                            ./mvnw clean package -DskipTests
                        elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
                            echo "Building with system Gradle..."
                            gradle clean build -x test
                        elif [ -f "pom.xml" ]; then
                            echo "Building with system Maven..."
                            mvn clean package -DskipTests
                        else
                            echo "No recognized build tool found!"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    // Build Docker image
                    sh "docker build -t ${FULL_IMAGE_NAME} ."
                    
                    // Also tag as latest for local use
                    sh "docker tag ${FULL_IMAGE_NAME} ${APP_NAME}:latest"
                }
            }
        }
        
        stage('Export and Push Image') {
            steps {
                echo 'Exporting and pushing Docker image...'
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIAL_ID}",
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        // Login to container registry
                        sh "echo \$DOCKER_PASSWORD | docker login ${CONTAINER_REGISTRY} -u \$DOCKER_USERNAME --password-stdin"
                        
                        // Push the image
                        sh "docker push ${FULL_IMAGE_NAME}"
                        
                        echo "Image pushed successfully: ${FULL_IMAGE_NAME}"
                    }
                }
            }
        }
        
        stage('Import and Tag Image on Target Server') {
            steps {
                echo 'Importing and tagging image on deployment server...'
                script {
                    // Pull the image on the deployment server (assuming same server for simplicity)
                    // In a real scenario, you might need to SSH to a different server
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIAL_ID}",
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh "docker pull ${FULL_IMAGE_NAME}"
                        
                        // Additional tagging if needed
                        sh "docker tag ${FULL_IMAGE_NAME} ${APP_NAME}:deployed-${APP_VERSION}"
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifest') {
            steps {
                echo 'Updating Kubernetes deployment manifest...'
                script {
                    // Update the image in the Kubernetes deployment manifest
                    sh """
                        # Backup original file
                        cp k8s/app-deployment.yaml k8s/app-deployment.yaml.backup
                        
                        # Update the image tag in the deployment manifest
                        sed -i 's|image: .*|image: ${FULL_IMAGE_NAME}|g' k8s/app-deployment.yaml
                        
                        # Verify the change
                        echo "Updated deployment manifest:"
                        grep -n "image:" k8s/app-deployment.yaml || echo "No image field found in manifest"
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                script {
                    withCredentials([kubeconfigFile(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG'
                    )]) {
                        // Apply the updated manifest
                        sh """
                            # Apply the deployment manifest
                            kubectl apply -f k8s/app-deployment.yaml -n ${NAMESPACE}
                            
                            # Wait for rollout to complete
                            kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=300s
                            
                            # Verify deployment
                            kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME}
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    withCredentials([kubeconfigFile(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG'
                    )]) {
                        // Check deployment status
                        sh """
                            echo "Deployment Status:"
                            kubectl get deployment ${APP_NAME} -n ${NAMESPACE}
                            
                            echo "Pod Status:"
                            kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME}
                            
                            echo "Service Status:"
                            kubectl get svc -n ${NAMESPACE} -l app=${APP_NAME}
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
            
            // Clean up local Docker images to save space
            script {
                sh """
                    docker rmi ${FULL_IMAGE_NAME} || true
                    docker rmi ${APP_NAME}:latest || true
                    docker rmi ${APP_NAME}:deployed-${APP_VERSION} || true
                """
            }
        }
        
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🚀 Application ${APP_NAME}:${APP_VERSION} deployed to Kubernetes"
            
            // Send success notification (optional)
            // You can add Slack, email, or other notification methods here
        }
        
        failure {
            echo "❌ Pipeline failed!"
            
            // Restore backup if deployment manifest was modified
            script {
                sh """
                    if [ -f k8s/app-deployment.yaml.backup ]; then
                        echo "Restoring original deployment manifest..."
                        mv k8s/app-deployment.yaml.backup k8s/app-deployment.yaml
                    fi
                """
            }
            
            // Send failure notification (optional)
        }
        
        cleanup {
            // Clean up workspace if needed
            echo 'Cleaning up...'
        }
    }
}
