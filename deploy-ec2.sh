#!/bin/bash

#===============================================================================
#  AWS EC2 Setup Script - All-in-One CI/CD Server
#  Đồ án môn Mạng máy tính nâng cao (CSC11004)
#  
#  Script này chạy TRÊN EC2 instance sau khi SSH vào
#===============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     AWS EC2 All-in-One CI/CD Server Setup                 ║"
    echo "║     Jenkins + Docker + App Deployment                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Update system
update_system() {
    print_step "Updating system packages..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

# Install Docker
install_docker() {
    print_step "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        print_info "Docker already installed: $(docker --version)"
        return
    fi
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_info "Docker installed: $(docker --version)"
}

# Install Docker Compose
install_docker_compose() {
    print_step "Installing Docker Compose..."
    
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        print_info "Docker Compose already installed"
        return
    fi
    
    sudo apt-get install -y docker-compose-plugin
    print_info "Docker Compose installed"
}

# Install Git
install_git() {
    print_step "Installing Git..."
    
    if command -v git &> /dev/null; then
        print_info "Git already installed: $(git --version)"
        return
    fi
    
    sudo apt-get install -y git
    print_info "Git installed: $(git --version)"
}

# Setup firewall
setup_firewall() {
    print_step "Configuring firewall..."
    
    # Allow SSH
    sudo ufw allow 22/tcp
    # Allow Jenkins
    sudo ufw allow 8081/tcp
    # Allow App
    sudo ufw allow 8080/tcp
    # Allow HTTP/HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable firewall (non-interactive)
    echo "y" | sudo ufw enable || true
    
    print_info "Firewall configured"
}

# Clone project
clone_project() {
    print_step "Setting up project..."
    
    PROJECT_DIR="/home/$USER/DevOpsProject"
    
    if [ -d "$PROJECT_DIR" ]; then
        print_info "Project directory exists, pulling latest..."
        cd "$PROJECT_DIR"
        git pull origin main || true
    else
        echo ""
        echo -e "${YELLOW}Enter your GitHub repository URL:${NC}"
        echo "Example: https://github.com/YOUR_USERNAME/DevOpsProject.git"
        read -p "URL: " REPO_URL
        
        if [ -z "$REPO_URL" ]; then
            print_info "No URL provided, creating empty project directory..."
            mkdir -p "$PROJECT_DIR"
        else
            git clone "$REPO_URL" "$PROJECT_DIR"
        fi
    fi
    
    cd "$PROJECT_DIR"
    print_info "Project directory: $PROJECT_DIR"
}

# Start Jenkins
start_jenkins() {
    print_step "Starting Jenkins..."
    
    cd /home/$USER/DevOpsProject
    
    # Need to use newgrp or re-login for docker group
    # Using sudo as workaround
    sudo docker compose -f docker-compose.jenkins.yml up -d || \
    sudo docker-compose -f docker-compose.jenkins.yml up -d
    
    print_info "Waiting for Jenkins to start..."
    sleep 15
    
    # Get initial password
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Jenkins Initial Admin Password:${NC}"
    sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
        echo "Password not ready yet. Run: sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
}

# Print final instructions
print_instructions() {
    # Get public IP
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_EC2_PUBLIC_IP")
    
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🎉 SETUP COMPLETED!                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}📍 Your EC2 Public IP: ${PUBLIC_IP}${NC}"
    echo ""
    echo -e "${GREEN}🔗 Access URLs:${NC}"
    echo "   Jenkins:  http://${PUBLIC_IP}:8081"
    echo "   App:      http://${PUBLIC_IP}:8080 (after deployment)"
    echo ""
    echo -e "${GREEN}📋 Next Steps:${NC}"
    echo "   1. Open Jenkins URL in browser"
    echo "   2. Enter the initial admin password shown above"
    echo "   3. Install suggested plugins"
    echo "   4. Create admin user (username = MSSV)"
    echo "   5. Install Docker Pipeline & Docker plugins"
    echo "   6. Add Docker Hub credentials"
    echo "   7. Create Pipeline job pointing to your GitHub repo"
    echo ""
    echo -e "${GREEN}🔧 Useful Commands:${NC}"
    echo "   View Jenkins logs:    sudo docker logs jenkins -f"
    echo "   Restart Jenkins:      sudo docker restart jenkins"
    echo "   View running containers: sudo docker ps"
    echo "   Get Jenkins password: sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    echo ""
    echo -e "${YELLOW}⚠️  Remember to configure AWS Security Group:${NC}"
    echo "   - Port 22 (SSH)"
    echo "   - Port 8081 (Jenkins)"
    echo "   - Port 8080 (App)"
    echo ""
}

# Main
main() {
    print_banner
    
    update_system
    install_docker
    install_docker_compose
    install_git
    setup_firewall
    clone_project
    start_jenkins
    print_instructions
    
    echo -e "${GREEN}✅ All done! Please re-login or run 'newgrp docker' to use docker without sudo.${NC}"
}

main "$@"
