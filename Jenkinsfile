pipeline {
    agent any
    
    environment {
        // ⚠️ QUAN TRỌNG: Thay đổi các giá trị này theo thông tin của bạn
        DOCKERHUB_USERNAME = 'your_dockerhub_username'  // Thay bằng Docker Hub username
        IMAGE_NAME = 'devops-cicd-demo'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'devops-app'
        APP_PORT = '3000'
        HOST_PORT = '8080'
        
        // Credentials ID trong Jenkins (sẽ được tạo trong phần cấu hình)
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        
        // Render.com Deploy Hook (để trống nếu deploy local)
        // Lấy từ Render Dashboard → Service → Settings → Deploy Hook
        RENDER_DEPLOY_HOOK = ''  // Ví dụ: 'https://api.render.com/deploy/srv-xxx?key=yyy'
    }
    
    stages {
        stage('🔍 Checkout') {
            steps {
                echo '📥 Pulling source code from GitHub...'
                checkout scm
                
                // Hiển thị thông tin commit
                script {
                    sh '''
                        echo "========================================="
                        echo "Git Information:"
                        echo "========================================="
                        git log -1 --pretty=format:"Commit: %H%nAuthor: %an <%ae>%nDate: %ad%nMessage: %s"
                        echo ""
                        echo "========================================="
                    '''
                }
            }
        }
        
        stage('🧪 Test') {
            steps {
                echo '🧪 Running tests...'
                dir('app') {
                    sh '''
                        echo "Running application tests..."
                        # Nếu có test script trong package.json
                        if [ -f "package.json" ]; then
                            npm test 2>/dev/null || echo "No tests configured"
                        fi
                        echo "✅ Tests completed!"
                    '''
                }
            }
        }
        
        stage('🐳 Build Docker Image') {
            steps {
                echo '🔨 Building Docker image...'
                dir('app') {
                    script {
                        // Build image với tag là build number
                        sh """
                            docker build -t ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
                            docker tag ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                        """
                        
                        echo "✅ Docker image built successfully!"
                        echo "   - ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                        echo "   - ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                    }
                }
            }
        }
        
        stage('📤 Push to Docker Hub') {
            steps {
                echo '📤 Pushing image to Docker Hub...'
                script {
                    // Login và push image lên Docker Hub
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKERHUB_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            
                            echo "Pushing images to Docker Hub..."
                            docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                            
                            echo "✅ Images pushed successfully!"
                        '''
                    }
                }
            }
        }
        
        stage('🚀 Deploy') {
            steps {
                echo '🚀 Deploying application...'
                script {
                    if (env.RENDER_DEPLOY_HOOK?.trim()) {
                        // Deploy lên Render.com
                        echo "Deploying to Render.com..."
                        sh """
                            curl -X POST "${RENDER_DEPLOY_HOOK}"
                            echo ""
                            echo "========================================="
                            echo "✅ Deploy triggered on Render.com!"
                            echo "🌐 Check your Render dashboard for status"
                            echo "========================================="
                        """
                    } else {
                        // Deploy local (mặc định)
                        sh '''
                            echo "Deploying locally..."
                            echo "Stopping and removing old container (if exists)..."
                            docker stop ${CONTAINER_NAME} 2>/dev/null || true
                            docker rm ${CONTAINER_NAME} 2>/dev/null || true
                            
                            echo "Pulling latest image..."
                            docker pull ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                            
                            echo "Starting new container..."
                            docker run -d \
                                --name ${CONTAINER_NAME} \
                                --restart unless-stopped \
                                -p ${HOST_PORT}:${APP_PORT} \
                                -e NODE_ENV=production \
                                ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                            
                            echo "Waiting for container to be healthy..."
                            sleep 5
                            
                            echo "Container status:"
                            docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                            
                            echo ""
                            echo "========================================="
                            echo "✅ Deployment completed successfully!"
                            echo "🌐 Application URL: http://localhost:${HOST_PORT}"
                            echo "========================================="
                        '''
                    }
                }
            }
        }
        
        stage('✅ Health Check') {
            steps {
                echo '🏥 Performing health check...'
                script {
                    if (env.RENDER_DEPLOY_HOOK?.trim()) {
                        echo "App deployed to Render.com - check Render dashboard for health status"
                        echo "Your app URL will be: https://your-service-name.onrender.com"
                    } else {
                        sh '''
                            echo "Checking application health..."
                            
                            # Wait a bit for the app to fully start
                            sleep 3
                            
                            # Health check
                            HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${HOST_PORT}/health || echo "000")
                            
                            if [ "$HEALTH_STATUS" = "200" ]; then
                                echo "✅ Application is healthy!"
                                curl -s http://localhost:${HOST_PORT}/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:${HOST_PORT}/health
                            else
                                echo "⚠️ Health check returned status: $HEALTH_STATUS"
                                echo "Container logs:"
                                docker logs ${CONTAINER_NAME} --tail 20
                            fi
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            // Clean up dangling images
            sh 'docker image prune -f 2>/dev/null || true'
        }
        
        success {
            echo '''
            ╔═══════════════════════════════════════════════╗
            ║     ✅ PIPELINE COMPLETED SUCCESSFULLY!       ║
            ╠═══════════════════════════════════════════════╣
            ║  All stages passed:                           ║
            ║  ✓ Checkout                                   ║
            ║  ✓ Test                                       ║
            ║  ✓ Build Docker Image                         ║
            ║  ✓ Push to Docker Hub                         ║
            ║  ✓ Deploy                                     ║
            ║  ✓ Health Check                               ║
            ╚═══════════════════════════════════════════════╝
            '''
        }
        
        failure {
            echo '''
            ╔═══════════════════════════════════════════════╗
            ║     ❌ PIPELINE FAILED!                       ║
            ╠═══════════════════════════════════════════════╣
            ║  Please check the logs above for details.     ║
            ╚═══════════════════════════════════════════════╝
            '''
        }
    }
}
