# Hướng dẫn Deploy lên AWS EC2
## All-in-One CI/CD Server

---

## 📋 Tổng quan

```
┌─────────────────────────────────────────────┐
│           AWS EC2 Instance                  │
│           (Ubuntu 22.04 LTS)                │
│  ┌───────────────────────────────────────┐  │
│  │  Jenkins (port 8081)                  │  │
│  │  Docker Engine                        │  │
│  │  App Container (port 8080)            │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

## 🚀 Bước 1: Tạo EC2 Instance

### 1.1 Đăng nhập AWS Console
- Vào https://console.aws.amazon.com
- Chọn region: **Asia Pacific (Singapore)** `ap-southeast-1` (gần VN nhất)

### 1.2 Launch Instance
1. **EC2** → **Launch Instance**
2. **Name**: `DevOps-CICD-Server`
3. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
4. **Instance type**: `t2.small` (2GB RAM) hoặc `t2.medium` (4GB RAM - khuyến nghị)
   - ⚠️ `t2.micro` (1GB) có thể không đủ RAM cho Jenkins
5. **Key pair**: Tạo mới hoặc chọn existing
   - Download file `.pem` và giữ an toàn
6. **Network settings** → **Edit**:
   - Auto-assign Public IP: **Enable**
   - Security Group: **Create new**
7. **Configure storage**: 20GB gp3

### 1.3 Cấu hình Security Group

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | My IP (hoặc 0.0.0.0/0) | SSH access |
| Custom TCP | 8081 | 0.0.0.0/0 | Jenkins |
| Custom TCP | 8080 | 0.0.0.0/0 | Application |
| HTTP | 80 | 0.0.0.0/0 | (Optional) |
| HTTPS | 443 | 0.0.0.0/0 | (Optional) |

### 1.4 Launch
- Click **Launch Instance**
- Đợi instance chuyển sang **Running**
- Ghi lại **Public IPv4 address**

---

## 🔑 Bước 2: SSH vào EC2

### Linux/Mac:
```bash
# Set permission cho key file
chmod 400 your-key.pem

# SSH vào EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Windows (PowerShell):
```powershell
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Windows (PuTTY):
1. Convert `.pem` to `.ppk` using PuTTYgen
2. Connect using PuTTY with the `.ppk` file

---

## ⚙️ Bước 3: Setup Server

### Option A: Tự động (Khuyến nghị)

```bash
# Clone repo
git clone https://github.com/YOUR_USERNAME/DevOpsProject.git
cd DevOpsProject

# Cấp quyền và chạy script
chmod +x deploy-ec2.sh
./deploy-ec2.sh
```

### Option B: Thủ công

```bash
# Update system
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install -y docker-compose-plugin

# Install Git
sudo apt-get install -y git

# Clone project
git clone https://github.com/YOUR_USERNAME/DevOpsProject.git
cd DevOpsProject

# Start Jenkins
sudo docker compose -f docker-compose.jenkins.yml up -d

# Get Jenkins password
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 🔧 Bước 4: Cấu hình Jenkins

1. **Truy cập Jenkins**: `http://YOUR_EC2_IP:8081`

2. **Nhập Initial Admin Password** (từ bước trên)

3. **Install Plugins**:
   - Chọn "Install suggested plugins"
   - Sau đó cài thêm: Docker Pipeline, Docker plugin

4. **Tạo Admin User**:
   - Username: `MSSV` (Mã số sinh viên)
   - Password: Mật khẩu của bạn

5. **Cấu hình Docker Hub Credentials**:
   - Manage Jenkins → Credentials → System → Global credentials
   - Add Credentials:
     - Kind: Username with password
     - ID: `dockerhub-credentials`
     - Username: Docker Hub username
     - Password: Docker Hub token

6. **Tạo Pipeline Job**:
   - New Item → Pipeline
   - Pipeline → Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/YOUR_USERNAME/DevOpsProject.git`
   - Script Path: `Jenkinsfile`

---

## 📝 Bước 5: Cập nhật Jenkinsfile cho EC2

Trước khi chạy pipeline, sửa Jenkinsfile:

```groovy
environment {
    DOCKERHUB_USERNAME = 'your_actual_dockerhub_username'  // ← Sửa
    // ... giữ nguyên các dòng khác
    RENDER_DEPLOY_HOOK = ''  // ← Để trống vì deploy local trên EC2
}
```

---

## ✅ Bước 6: Test Pipeline

1. Trong Jenkins, click **Build Now**
2. Xem Console Output
3. Sau khi hoàn thành, truy cập app: `http://YOUR_EC2_IP:8080`

---

## 💰 Chi phí ước tính

| Instance Type | RAM | Chi phí/tháng (ước tính) |
|---------------|-----|--------------------------|
| t2.micro | 1GB | ~$8 (có thể không đủ) |
| t2.small | 2GB | ~$17 |
| t2.medium | 4GB | ~$34 |

**💡 Tip tiết kiệm:**
- Dùng **Spot Instance** giảm 70% chi phí
- Tắt instance khi không dùng
- Dùng **Free Tier** nếu còn (12 tháng đầu, t2.micro)

---

## 🛠️ Commands hữu ích trên EC2

```bash
# Xem containers đang chạy
sudo docker ps

# Xem logs Jenkins
sudo docker logs jenkins -f

# Restart Jenkins
sudo docker restart jenkins

# Xem logs app
sudo docker logs devops-app -f

# Check disk space
df -h

# Check memory
free -m

# Check CPU
top
```

---

## 🔒 Bảo mật (Khuyến nghị)

1. **Giới hạn SSH access** chỉ từ IP của bạn
2. **Đổi port SSH** từ 22 sang port khác
3. **Enable Jenkins authentication** (đã có)
4. **Dùng HTTPS** cho Jenkins (cần domain + SSL cert)

---

## ❓ Troubleshooting

### Jenkins không khởi động
```bash
sudo docker logs jenkins
# Check if port 8081 is in use
sudo lsof -i :8081
```

### Không đủ RAM
```bash
# Check memory
free -m
# Consider upgrading to t2.medium
```

### Docker permission denied
```bash
# Re-login or run
newgrp docker
# Or use sudo
sudo docker ps
```

### Cannot connect to Jenkins
- Kiểm tra Security Group đã mở port 8081
- Kiểm tra instance đang Running
- Kiểm tra Public IP

---

## 📌 Checklist Deploy EC2

- [ ] Tạo EC2 instance (Ubuntu 22.04, t2.small+)
- [ ] Cấu hình Security Group (22, 8081, 8080)
- [ ] SSH vào instance
- [ ] Chạy deploy-ec2.sh
- [ ] Lấy Jenkins initial password
- [ ] Truy cập Jenkins và setup
- [ ] Cài Docker Pipeline plugin
- [ ] Thêm Docker Hub credentials
- [ ] Tạo Pipeline job
- [ ] Sửa DOCKERHUB_USERNAME trong Jenkinsfile
- [ ] Chạy Build và test

---

*Chúc bạn deploy thành công! 🚀*
