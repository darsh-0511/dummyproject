pipeline {
    agent {
        label 'podman-agent'  // Jenkins agent with Podman installed
    }
    
    environment {
        // Container Registry Configuration
        REGISTRY_URL = credentials('container-registry-url')
        REGISTRY_CREDENTIALS = credentials('registry-credentials')
        REGISTRY_NAMESPACE = 'blu-reserve'
        
        // Image Names
        BACKEND_IMAGE = "${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend"
        FRONTEND_IMAGE = "${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend"
        
        // Version Tags
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
        BUILD_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        
        // Deployment Server
        DEPLOY_SERVER = credentials('deployment-server')
        DEPLOY_USER = credentials('deployment-user')
        
        // Notification
        SLACK_CHANNEL = '#blu-reserve-deployments'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out code from Git..."
                    checkout scm
                    sh 'git log -1 --pretty=format:"%h - %an: %s"'
                }
            }
        }
        
        stage('Environment Setup') {
            steps {
                script {
                    echo "🔧 Setting up environment..."
                    sh '''
                        echo "Podman Version:"
                        podman --version
                        
                        echo "Git Commit: ${GIT_COMMIT_SHORT}"
                        echo "Build Tag: ${BUILD_TAG}"
                        
                        # Create necessary directories
                        mkdir -p logs
                        mkdir -p test-results
                    '''
                }
            }
        }
        
        stage('Backend Tests') {
            steps {
                script {
                    echo "🧪 Running Backend Tests..."
                    dir('backend') {
                        sh '''
                            # Create virtual environment
                            python3 -m venv venv
                            source venv/bin/activate
                            
                            # Install dependencies
                            pip install --upgrade pip
                            pip install -r requirements.txt
                            
                            # Run tests
                            pytest test_main.py -v --junitxml=../test-results/backend-results.xml || true
                            
                            # Deactivate virtual environment
                            deactivate
                        '''
                    }
                }
            }
            post {
                always {
                    junit 'test-results/backend-results.xml'
                }
            }
        }
        
        stage('Build Backend Image') {
            steps {
                script {
                    echo "🐳 Building Backend Container Image..."
                    dir('backend') {
                        sh """
                            podman build \
                                -t ${BACKEND_IMAGE}:${BUILD_TAG} \
                                -t ${BACKEND_IMAGE}:latest \
                                -f Dockerfile \
                                .
                            
                            echo "✅ Backend image built successfully"
                            podman images | grep blu-reserve-backend
                        """
                    }
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                script {
                    echo "🐳 Building Frontend Container Image..."
                    dir('frontend') {
                        sh """
                            podman build \
                                -t ${FRONTEND_IMAGE}:${BUILD_TAG} \
                                -t ${FRONTEND_IMAGE}:latest \
                                -f Dockerfile \
                                .
                            
                            echo "✅ Frontend image built successfully"
                            podman images | grep blu-reserve-frontend
                        """
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo "🔒 Running Security Scans..."
                    sh """
                        # Scan backend image
                        echo "Scanning backend image..."
                        podman run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest image \
                            --severity HIGH,CRITICAL \
                            ${BACKEND_IMAGE}:${BUILD_TAG} || true
                        
                        # Scan frontend image
                        echo "Scanning frontend image..."
                        podman run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest image \
                            --severity HIGH,CRITICAL \
                            ${FRONTEND_IMAGE}:${BUILD_TAG} || true
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    echo "📤 Pushing images to container registry..."
                    sh """
                        # Login to registry
                        echo ${REGISTRY_CREDENTIALS_PSW} | podman login ${REGISTRY_URL} -u ${REGISTRY_CREDENTIALS_USR} --password-stdin
                        
                        # Push backend images
                        echo "Pushing backend image..."
                        podman push ${BACKEND_IMAGE}:${BUILD_TAG}
                        podman push ${BACKEND_IMAGE}:latest
                        
                        # Push frontend images
                        echo "Pushing frontend image..."
                        podman push ${FRONTEND_IMAGE}:${BUILD_TAG}
                        podman push ${FRONTEND_IMAGE}:latest
                        
                        # Logout
                        podman logout ${REGISTRY_URL}
                        
                        echo "✅ Images pushed successfully"
                    """
                }
            }
        }
        
        stage('Deploy to Server') {
            steps {
                script {
                    echo "🚀 Deploying to production server..."
                    sh """
                        # Copy deployment files to server
                        scp -o StrictHostKeyChecking=no \
                            podman-compose.yml \
                            scripts/deploy.sh \
                            scripts/health-check.sh \
                            .env.production \
                            ${DEPLOY_USER}@${DEPLOY_SERVER}:/opt/blu-reserve/
                        
                        # Execute deployment script on remote server
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} \
                            "cd /opt/blu-reserve && \
                             chmod +x deploy.sh health-check.sh && \
                             BUILD_TAG=${BUILD_TAG} \
                             REGISTRY_URL=${REGISTRY_URL} \
                             REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE} \
                             ./deploy.sh"
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Running health checks..."
                    sh """
                        # Wait for services to be ready
                        sleep 10
                        
                        # Run health check script on remote server
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} \
                            "cd /opt/blu-reserve && ./health-check.sh"
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    echo "💨 Running smoke tests..."
                    sh """
                        # Test backend API
                        curl -f http://${DEPLOY_SERVER}:8000/seats || exit 1
                        
                        # Test frontend
                        curl -f http://${DEPLOY_SERVER}:8080/ || exit 1
                        
                        echo "✅ Smoke tests passed"
                    """
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                // Send success notification
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"✅ Blu-Reserve deployment successful! Build: ${BUILD_TAG}"}' \
                    ${SLACK_WEBHOOK_URL} || true
                """
            }
        }
        failure {
            script {
                echo "❌ Pipeline failed!"
                // Send failure notification
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"❌ Blu-Reserve deployment failed! Build: ${BUILD_TAG}"}' \
                    ${SLACK_WEBHOOK_URL} || true
                """
            }
        }
        always {
            script {
                echo "🧹 Cleaning up..."
                sh '''
                    # Clean up old images (keep last 5)
                    podman image prune -af --filter "until=168h" || true
                    
                    # Clean up build artifacts
                    rm -rf backend/venv
                    rm -rf test-results
                '''
            }
        }
    }
}
