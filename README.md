# n8n 一键安装脚本

支持 Debian、Ubuntu、CentOS 等常见 Linux 系统的 n8n 自动化安装脚本，基于 Docker 安装。

## 系统要求

- Linux 系统（Debian、Ubuntu、CentOS、RHEL、Fedora 等）
- Root 权限（使用 sudo）
- 网络连接

## VPS 购买建议

### 推荐使用国外 VPS

由于 n8n 经常需要配置各种国外的 AI 服务（如 OpenAI、Anthropic、Google AI 等），建议购买国外 VPS 以获得更好的网络连接和稳定性。

### 推荐配置

**Bandwagon Host（搬瓦工）KVM VPS**

- **配置**：40G SSD / 2GB RAM / 3x CPU / 2TB 流量
- **价格**：$99.99 USD/年（约 ¥700/年）
- **优势**：
  - 多数据中心可选
  - 免费自动备份和快照
  - 支持 CentOS、Debian、Ubuntu 等系统
  - 99.95% 在线时间保证
  - 适合运行 n8n 和连接国外 AI 服务

**购买链接**：[点击购买](https://bandwagonhost.com/aff.php?aff=36396&pid=45)

> **提示**：选择 "40G KVM - PROMO VPS" 年度套餐，性价比最高。

### 其他 VPS 选择

如果你已有其他 VPS 服务商，确保满足以下最低配置要求：
- **CPU**：2 核心或以上
- **内存**：2GB 或以上
- **存储**：20GB 或以上
- **带宽**：1Gbps
- **操作系统**：Debian 11+ / Ubuntu 20.04+ / CentOS 8+

## 快速安装


### 使用说明

**安装前准备：**

1. 创建 n8n 工作目录：
```bash
mkdir -p ~/n8n
cd ~/n8n
```

2. 执行安装命令：
```bash
curl -fsSL https://raw.githubusercontent.com/xapanyun/n8n_install/main/install_n8n.sh | sudo bash
```

**安装过程：**

- 脚本会自动检测操作系统并安装 Docker（如果未安装）
- 如果当前目录包含 `docker-compose.yml`，会优先使用 Docker Compose 安装
- 否则会使用 `docker run` 方式安装
- 安装完成后，n8n 会在端口 5678 上运行

## 功能特性

- ✅ 自动检测操作系统类型
- ✅ 自动安装 Docker（如果未安装）
- ✅ 支持使用 Docker Compose 或 Docker run
- ✅ 自动创建数据卷
- ✅ 设置语言环境，避免乱码
- ✅ 自动清理旧容器

## 安装说明

脚本会自动执行以下操作：

1. 检测操作系统类型（Debian/Ubuntu/CentOS 等）
2. 检查并安装 Docker（如果未安装）
3. 检查 Docker Compose 是否可用
4. 查找并使用项目中的 `docker-compose.yml`（如果存在）
5. 创建 n8n 数据卷
6. 启动 n8n 容器

## 访问 n8n

安装完成后，访问以下地址：

- 本地访问：http://localhost:5678
- 服务器 IP：http://YOUR_SERVER_IP:5678

### 使用域名访问

如果需要使用域名访问 n8n，可以通过以下方式配置：

#### 方式一：使用 Nginx 反向代理

1. 安装 Nginx（如果未安装）：
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y nginx

# CentOS/RHEL
sudo yum install -y nginx
```

2. 创建 Nginx 配置文件：
```bash
sudo nano /etc/nginx/sites-available/n8n
```

3. 添加以下配置（将 `your-domain.com` 替换为你的域名）：
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

4. 启用配置并重启 Nginx：
```bash
# Ubuntu/Debian
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# CentOS/RHEL
sudo cp /etc/nginx/sites-available/n8n /etc/nginx/conf.d/n8n.conf
sudo nginx -t
sudo systemctl restart nginx
```

5. 配置 SSL 证书（推荐使用 Let's Encrypt）：
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

#### 方式二：使用 Cloudflare 反向代理

1. 在 Cloudflare 中添加你的域名和 DNS 记录：
   - 添加 A 记录，指向你的服务器 IP 地址 
   - 确保代理状态为"已代理"（橙色云朵图标）

2. 在服务器上配置 Nginx（监听 80 端口，不需要 SSL）：
```bash
sudo nano /etc/nginx/sites-available/n8n
```

添加以下配置：
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

启用配置并重启 Nginx：
```bash
# Ubuntu/Debian
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# CentOS/RHEL
sudo cp /etc/nginx/sites-available/n8n /etc/nginx/conf.d/n8n.conf
sudo nginx -t
sudo systemctl restart nginx
```

3. 配置 Cloudflare SSL/TLS：
   - 登录 Cloudflare 控制台
   - 进入 SSL/TLS 设置
   - 选择"灵活"模式（Flexible）
   - **注意**：由于服务器只监听 80 端口（HTTP），必须选择"灵活"模式。使用 Cloudflare 时，服务器端不需要安装 certbot，Cloudflare 会自动处理 SSL 加密


**注意事项：**
- 使用域名访问时，需要确保域名 DNS 已正确解析到服务器 IP
- 使用 Nginx 方式需要配置 SSL 证书（推荐 Let's Encrypt）
- 使用 Cloudflare 方式时，服务器只需监听 80 端口，SSL 由 Cloudflare 自动处理，无需安装 certbot
- 如果使用 Cloudflare，注意 Webhook URL 配置，确保使用正确的域名

## 常用命令

### 使用 Docker Compose（如果使用 compose 安装）

```bash
cd /path/to/docker-compose.yml
docker compose ps          # 查看容器状态
docker compose logs -f     # 查看日志
docker compose down        # 停止容器
docker compose up -d       # 启动容器
docker compose restart     # 重启容器
```

### 使用 Docker run

```bash
docker ps | grep n8n       # 查看容器状态
docker logs -f n8n         # 查看日志
docker stop n8n            # 停止容器
docker start n8n          # 启动容器
docker restart n8n         # 重启容器
docker stop n8n && docker rm n8n  # 删除容器
```

## 数据持久化

n8n 的数据存储在 Docker volume `n8n_data` 中，即使删除容器，数据也不会丢失。

查看数据卷：
```bash
docker volume inspect n8n_data
```

## 卸载

### 使用 Docker Compose

```bash
cd /path/to/docker-compose.yml
docker compose down
docker volume rm n8n_data  # 可选：删除数据卷
```

### 使用 Docker run

```bash
docker stop n8n
docker rm n8n
docker volume rm n8n_data  # 可选：删除数据卷
```

## 故障排查

如果安装失败，请检查：

1. 是否有 root 权限
2. 网络连接是否正常
3. 端口 5678 是否被占用
4. Docker 服务是否正常运行

查看容器日志：
```bash
docker logs n8n
```

## 许可证

本项目遵循与 n8n 相同的许可证。

## 相关链接

- [n8n 官方文档](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [n8n 官网](https://n8n.io/)

