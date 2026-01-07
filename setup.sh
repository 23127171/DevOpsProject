#!/bin/bash

#===============================================================================
#  DevOps CI/CD Setup Script
#  Đồ án môn Mạng máy tính nâng cao (CSC11004)
#  Triển khai CI/CD sử dụng Git, Jenkins và Docker
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║        DevOps CI/CD Setup - CSC11004                      ║"
    echo "║   Triển khai CI/CD sử dụng Git, Jenkins và Docker         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    print_step "Checking Docker installation..."
    if command -v docker &> /dev/null; then
        print_info "Docker is installed: $(docker --version)"
        
        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            print_info "Docker daemon is running"
        else
            print_error "Docker daemon is not running. Please start Docker first."
            exit 1
        fi
    else
        print_error "Docker is not installed. Please install Docker first."
        echo ""
        echo "To install Docker on Ubuntu/Debian:"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        echo "  sudo usermod -aG docker \$USER"
        echo "  newgrp docker"
        exit 1
    fi
}

check_docker_compose() {
    print_step "Checking Docker Compose..."
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose is installed: $(docker-compose --version)"
    elif docker compose version &> /dev/null; then
        print_info "Docker Compose (plugin) is installed: $(docker compose version)"
    else
        print_warning "Docker Compose not found. Installing..."
        sudo apt-get update && sudo apt-get install -y docker-compose-plugin
    fi
}

check_git() {
    print_step "Checking Git installation..."
    if command -v git &> /dev/null; then
        print_info "Git is installed: $(git --version)"
    else
        print_warning "Git not found. Installing..."
        sudo apt-get update && sudo apt-get install -y git
    fi
}

start_jenkins() {
    print_step "Starting Jenkins container..."
    
    cd "$(dirname "$0")"
    
    # Start Jenkins using docker-compose
    if command -v docker-compose &> /dev/null; then
        docker-compose -f docker-compose.jenkins.yml up -d
    else
        docker compose -f docker-compose.jenkins.yml up -d
    fi
    
    print_info "Waiting for Jenkins to start..."
    sleep 10
    
    # Check if Jenkins is running
    if docker ps | grep -q jenkins; then
        print_info "Jenkins container is running"
    else
        print_error "Failed to start Jenkins container"
        exit 1
    fi
}

get_jenkins_password() {
    print_step "Getting Jenkins initial admin password..."
    
    # Wait for password file to be created
    print_info "Waiting for Jenkins to initialize (this may take 1-2 minutes)..."
    
    for i in {1..30}; do
        if docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
            echo ""
            break
        fi
        sleep 5
        echo -n "."
    done
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Jenkins Initial Admin Password:${NC}"
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
        print_warning "Password not yet available. Check later with: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
}

print_instructions() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    NEXT STEPS                             ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}1. Access Jenkins:${NC}"
    echo "   URL: http://localhost:8081"
    echo "   Use the initial admin password shown above"
    echo ""
    echo -e "${GREEN}2. Complete Jenkins Setup:${NC}"
    echo "   - Install suggested plugins"
    echo "   - Create Admin user with username = MSSV (Mã số sinh viên)"
    echo "   - Install additional plugins: Docker Pipeline, Docker plugin, Git plugin"
    echo ""
    echo -e "${GREEN}3. Configure Docker Hub Credentials in Jenkins:${NC}"
    echo "   - Go to: Manage Jenkins → Credentials → System → Global credentials"
    echo "   - Add credentials: Kind = Username with password"
    echo "   - ID: dockerhub-credentials"
    echo "   - Username: Your Docker Hub username"
    echo "   - Password: Your Docker Hub password/token"
    echo ""
    echo -e "${GREEN}4. Create Pipeline Job:${NC}"
    echo "   - New Item → Enter name → Select 'Pipeline'"
    echo "   - Pipeline → Definition: 'Pipeline script from SCM'"
    echo "   - SCM: Git"
    echo "   - Repository URL: Your GitHub repository URL"
    echo "   - Script Path: Jenkinsfile"
    echo ""
    echo -e "${GREEN}5. Update Jenkinsfile:${NC}"
    echo "   - Edit Jenkinsfile and change DOCKERHUB_USERNAME to your Docker Hub username"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "   - View Jenkins logs: docker logs jenkins -f"
    echo "   - Stop Jenkins: docker stop jenkins"
    echo "   - Start Jenkins: docker start jenkins"
    echo "   - Restart Jenkins: docker restart jenkins"
    echo ""
}

main() {
    print_banner
    
    check_docker
    check_docker_compose
    check_git
    start_jenkins
    get_jenkins_password
    print_instructions
    
    echo -e "${GREEN}✅ Setup completed successfully!${NC}"
}

main "$@"
