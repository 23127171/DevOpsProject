# DevOps CI/CD Project - CSC11004
# Đồ án môn Mạng máy tính nâng cao
## Triển khai CI/CD sử dụng Git, Jenkins và Docker

---

## 📋 Mục lục

1. [Giới thiệu](#giới-thiệu)
2. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
3. [Cấu trúc dự án](#cấu-trúc-dự-án)
4. [Hướng dẫn cài đặt](#hướng-dẫn-cài-đặt)
5. [Cấu hình Git & GitHub](#cấu-hình-git--github)
6. [Cấu hình Jenkins](#cấu-hình-jenkins)
7. [Cấu hình Docker Hub](#cấu-hình-docker-hub)
8. [Chạy Pipeline](#chạy-pipeline)
9. [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)

---

## 📖 Giới thiệu

Dự án này triển khai một quy trình CI/CD hoàn chỉnh với các công cụ:
- **Git/GitHub**: Quản lý source code
- **Jenkins**: Automation server cho CI/CD
- **Docker**: Container platform
- **Docker Hub**: Container registry

### Pipeline Flow
```
Developer Push Code → GitHub → Jenkins Pull → Build Docker Image → Push to Docker Hub → Deploy Container
```

---

## 💻 Yêu cầu hệ thống

- **OS**: Ubuntu 20.04+ / Debian 10+ (khuyến nghị) hoặc Windows với WSL2
- **RAM**: Tối thiểu 4GB (khuyến nghị 8GB)
- **Disk**: Tối thiểu 20GB trống
- **Software**:
  - Docker Engine 20.10+
  - Docker Compose 2.0+
  - Git 2.0+

---

## 📁 Cấu trúc dự án

```
DevOpsProject/
├── app/
│   ├── index.js          # Source code ứng dụng Node.js
│   ├── package.json      # Node.js dependencies
│   └── Dockerfile        # Dockerfile để build image
├── Jenkinsfile           # Pipeline definition
├── docker-compose.jenkins.yml  # Docker Compose cho Jenkins
├── setup.sh              # Script cài đặt tự động
├── README.md             # File này
└── .gitignore           # Git ignore rules
```

---

## 🚀 Hướng dẫn cài đặt

### Bước 1: Cài đặt Docker (nếu chưa có)

```bash
# Cài đặt Docker trên Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Thêm user vào group docker (để chạy docker không cần sudo)
sudo usermod -aG docker $USER
newgrp docker

# Kiểm tra Docker
docker --version
docker run hello-world
```

### Bước 2: Clone repository và chạy setup

```bash
# Clone repo (thay YOUR_USERNAME bằng GitHub username của bạn)
git clone https://github.com/YOUR_USERNAME/DevOpsProject.git
cd DevOpsProject

# Cấp quyền thực thi cho script
chmod +x setup.sh

# Chạy script setup
./setup.sh
```

---

## 🔧 Cấu hình Git & GitHub (3 điểm)

### 1. Cấu hình Git local (2 điểm)

```bash
# ⚠️ QUAN TRỌNG: Thay MSSV bằng mã số sinh viên thực tế của bạn
git config --global user.name "MSSV"
git config --global user.email "MSSV@student.edu.vn"

# Kiểm tra cấu hình
git config --list
```

### 2. Tạo GitHub Repository (1 điểm)

1. Đăng nhập GitHub: https://github.com
2. Click **"New repository"**
3. Đặt tên repo: `DevOpsProject`
4. Chọn **Public** hoặc **Private**
5. Click **"Create repository"**

### 3. Push code lên GitHub

```bash
# Di chuyển vào thư mục dự án
cd /path/to/DevOpsProject

# Khởi tạo Git repository
git init

# Thêm tất cả files
git add .

# Commit với message
git commit -m "Initial commit - DevOps CI/CD Project"

# Thêm remote origin (thay YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/DevOpsProject.git

# Push lên GitHub
git branch -M main
git push -u origin main
```

---

## 🔧 Cấu hình Jenkins (4 điểm)

### 1. Khởi động Jenkins (đã làm trong setup.sh)

```bash
# Nếu cần khởi động lại
docker-compose -f docker-compose.jenkins.yml up -d

# Xem password admin ban đầu
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. Cấu hình ban đầu Jenkins (2 điểm)

1. Truy cập: **http://localhost:8081**
2. Nhập **Initial Admin Password**
3. Chọn **"Install suggested plugins"**
4. Tạo Admin User:
   - **Username**: `MSSV` (⚠️ BẮT BUỘC dùng MSSV)
   - **Password**: Mật khẩu của bạn
   - **Full name**: Họ tên của bạn
   - **Email**: Email của bạn

### 3. Cài đặt Plugins bổ sung

1. Vào **Manage Jenkins** → **Plugins** → **Available plugins**
2. Tìm và cài đặt:
   - ✅ Docker Pipeline
   - ✅ Docker plugin
   - ✅ Git plugin (thường đã có sẵn)
3. Click **"Install"** và restart Jenkins nếu cần

### 4. Cấu hình Docker Hub Credentials

1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **"Add Credentials"**
3. Điền thông tin:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Docker Hub username của bạn
   - **Password**: Docker Hub password hoặc Access Token
   - **ID**: `dockerhub-credentials` (⚠️ QUAN TRỌNG: phải đúng ID này)
   - **Description**: Docker Hub Credentials

---

## 🐳 Cấu hình Docker Hub (2 điểm)

### 1. Tạo tài khoản Docker Hub

1. Đăng ký tại: https://hub.docker.com
2. Xác nhận email

### 2. Tạo Access Token (khuyến nghị thay vì password)

1. Login Docker Hub → **Account Settings** → **Security**
2. Click **"New Access Token"**
3. Đặt tên: `jenkins-token`
4. Chọn quyền: **Read, Write, Delete**
5. Copy token và lưu lại (chỉ hiện 1 lần)

### 3. Cập nhật Jenkinsfile

Mở file `Jenkinsfile` và thay đổi:

```groovy
environment {
    DOCKERHUB_USERNAME = 'your_actual_dockerhub_username'  // ← Thay bằng username thực
    // ... các biến khác giữ nguyên
}
```

---

## ▶️ Chạy Pipeline (2 điểm)

### 1. Tạo Pipeline Job trong Jenkins

1. Click **"New Item"**
2. Đặt tên: `DevOps-CICD-Pipeline`
3. Chọn **"Pipeline"** → **OK**
4. Trong phần **Pipeline**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/YOUR_USERNAME/DevOpsProject.git`
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile`
5. Click **"Save"**

### 2. Chạy Pipeline

1. Click **"Build Now"**
2. Xem tiến trình trong **Build History** → Click vào build number → **Console Output**

### 3. Kiểm tra kết quả

```bash
# Kiểm tra container đang chạy
docker ps

# Kiểm tra ứng dụng
curl http://localhost:8080

# Xem logs container
docker logs devops-app
```

---

## 🐛 Xử lý lỗi thường gặp

### Lỗi 1: Permission denied khi chạy docker

```bash
# Thêm user vào group docker
sudo usermod -aG docker $USER
newgrp docker

# Hoặc chạy với sudo
sudo docker ...
```

### Lỗi 2: Jenkins không thể kết nối Docker

```bash
# Kiểm tra docker socket
ls -la /var/run/docker.sock

# Đảm bảo Jenkins container có quyền truy cập
docker exec jenkins docker ps
```

### Lỗi 3: Push image thất bại

- Kiểm tra credentials trong Jenkins
- Kiểm tra DOCKERHUB_USERNAME trong Jenkinsfile
- Thử login Docker Hub thủ công:
  ```bash
  docker login
  ```

### Lỗi 4: Container không start được

```bash
# Xem logs
docker logs devops-app

# Kiểm tra port đã được sử dụng chưa
sudo lsof -i :8080

# Dừng container khác đang dùng port
docker stop <container_id>
```

---

## 📊 Thang điểm đánh giá

| Phần | Nội dung | Điểm |
|------|----------|------|
| 1 | Cấu hình Git | 2 |
| 1 | Cấu hình Github | 1 |
| 2 | Cấu hình Jenkins | 2 |
| 2 | Cấu hình Docker | 2 |
| 3 | Kết nối Jenkins & Docker (Pipeline) | 2 |
| | **Tổng** | **9** |

---

## 📝 Ghi chú quan trọng

1. **⚠️ Username phải là MSSV**: Tất cả username (Git, Jenkins Admin) phải là mã số sinh viên
2. **Commit history**: Đảm bảo commit history hiển thị đúng MSSV
3. **Demo**: Chuẩn bị sẵn sàng để demo pipeline hoạt động
4. **Documentation**: Ghi chép lại quá trình thực hiện

---

## 🔗 Links hữu ích

- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Git Documentation](https://git-scm.com/doc)
- [Docker Hub](https://hub.docker.com/)

---

## 👥 Thông tin nhóm

- **Môn học**: CSC11004 - Mạng máy tính nâng cao
- **Đề tài**: Triển khai CI/CD sử dụng Git, Jenkins và Docker
- **Thành viên**:
  - MSSV_1 - Họ tên SV 1
  - MSSV_2 - Họ tên SV 2

---

*© 2026 - Đồ án CI/CD Pipeline*
