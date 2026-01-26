# n8n 一键安装脚本

[中文](README_cn.md) | [English](README.md)

支持 Debian、Ubuntu、CentOS 等常见 Linux 系统的 n8n 自动化安装脚本，基于 Docker 安装。

**现在包含集成的 PostgreSQL 数据库、Baserow 和 ngrok，用于安全的 webhook 访问！**

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
- 脚本会提示输入你的 ngrok authtoken（从 [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken) 获取）
- 安装完成后，以下服务将可用：
  - **n8n**: http://localhost:5678（也可通过 ngrok 访问）
  - **Baserow**: http://localhost:5080
  - **PostgreSQL**: n8n 的内部数据库
  - **ngrok Dashboard**: http://localhost:4040

## 功能特性

- ✅ 自动检测操作系统类型
- ✅ 自动安装 Docker（如果未安装）
- ✅ 支持使用 Docker Compose 或 Docker run
- ✅ 自动创建数据卷
- ✅ 设置语言环境，避免乱码
- ✅ 自动清理旧容器
- ✅ **集成的 PostgreSQL 数据库**，用于 n8n 数据持久化
- ✅ **集成的 Baserow** - Airtable 替代品，用于数据库管理
- ✅ **集成的 ngrok** - 安全隧道，用于从任何地方访问 webhook
- ✅ **自动配置 ngrok URL** - n8n 自动获取 ngrok URL 用于 webhook

## 安装说明

脚本会自动执行以下操作：

1. 检测操作系统类型（Debian/Ubuntu/CentOS 等）
2. 检查并安装 Docker（如果未安装）
3. 检查 Docker Compose 是否可用
4. 查找并使用项目中的 `docker-compose.yml`（如果存在）
5. 设置 ngrok 配置（提示输入 authtoken）
6. 创建包含默认密码的 `.env` 文件
7. 为所有服务创建 Docker 卷
8. 启动所有服务：PostgreSQL、Baserow、n8n 和 ngrok
9. 自动检测 ngrok URL 并配置 n8n webhook

## 集成服务

此安装包含以下集成服务：

### PostgreSQL 数据库
- **用途**：存储 n8n 工作流数据、凭证和执行历史
- **访问**：仅内部访问（在 Docker 网络内）
- **数据库**：`n8n`
- **凭证**：存储在 `.env` 文件中（默认密码：`n8n`）

### Baserow
- **用途**：开源的 Airtable 替代品，用于数据库管理
- **访问**：http://localhost:5080
- **集成**：可通过内部 Docker 网络在 n8n 工作流中使用（参见[在 n8n 中使用 Baserow](#在-n8n-中使用-baserow)部分）
- **数据库**：Baserow 数据的独立 PostgreSQL 实例
- **模板同步**：默认禁用（`BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false`）以加快启动速度。如果需要 Baserow 模板，可以在 docker-compose.yml 中启用

### ngrok
- **用途**：创建安全隧道以公开暴露 n8n webhook
- **仪表板**：http://localhost:4040
- **配置**：需要 ngrok authtoken（在 [ngrok.com](https://ngrok.com) 免费获取）
- **自动配置**：自动更新 n8n 的 `WEBHOOK_URL` 和 `N8N_EDITOR_BASE_URL`

### 服务通信
所有服务都配置为高效通信：
- **n8n webhook**：自动使用 n8n ngrok URL 进行外部 webhook 访问
- **Baserow 访问**：使用本地 URL（http://localhost:5080）或服务器 IP
- **n8n ↔ Baserow 通信**：使用内部 Docker 网络地址 `http://baserow:80`（参见[在 n8n 中使用 Baserow](#在-n8n-中使用-baserow)部分）
- **PostgreSQL**：n8n 内部使用，用于数据持久化（仅内部网络）

## 访问服务

安装完成后，通过以下地址访问服务：

### n8n
- **本地访问**：http://localhost:5678
- **服务器 IP**：http://YOUR_SERVER_IP:5678
- **Ngrok URL**：查看 http://localhost:4040 或你的 `.env` 文件以获取公共 ngrok URL
  - 此 URL 自动配置用于 webhook
  - 使用此 URL 可以从任何地方安全访问 n8n

### Baserow
- **本地访问**：http://localhost:5080
- **服务器 IP**：http://YOUR_SERVER_IP:5080
- **首次设置**：访问上述任一 URL 完成 Baserow 初始设置

**重要**：Baserow 需要将 `BASEROW_PUBLIC_URL` 设置为实际可访问的 URL。安装脚本会自动检测你的服务器 IP 并自动设置。

**配置选项**：

**选项 1（自动检测）**：安装脚本自动检测你的服务器 IP 并将 `BASEROW_PUBLIC_URL` 设置为 `http://YOUR_IP:5080`

**选项 2（手动）**：如果需要通过特定 IP 或域名访问，更新 `.env`：
```bash
BASEROW_PUBLIC_URL=http://192.168.31.10:5080
```

**选项 3（多个 URL）**：使用 `BASEROW_EXTRA_PUBLIC_URLS` 允许从多个 URL 访问：
```bash
BASEROW_PUBLIC_URL=http://localhost:5080
BASEROW_EXTRA_PUBLIC_URLS=http://192.168.31.10:5080,http://192.168.1.100:5080
```

然后重启 Baserow：`docker compose restart baserow`

根据 [Baserow 文档](https://baserow.io/docs/installation/configuration)：
- 如果通过非标准端口访问，必须在 `BASEROW_PUBLIC_URL` 后附加端口号
- `BASEROW_EXTRA_PUBLIC_URLS` 允许额外的 URL，这些 URL 不会被当作已发布的应用程序域
- 不在 `BASEROW_PUBLIC_URL` 或 `BASEROW_EXTRA_PUBLIC_URLS` 中的 URL 将被视为已发布的应用程序构建器域，这会导致"未找到"错误
- `0.0.0.0` 不是有效的公共 URL - 使用实际的 IP 地址或域名

## 在 n8n 中使用 Baserow

由于 n8n 和 Baserow 在同一个 Docker Compose 设置中运行，它们可以通过内部 Docker 网络直接通信。**你应该使用内部 Docker 网络地址，而不是 ngrok URL。**

### 推荐：使用内部 Docker 网络地址

**对于需要访问 Baserow 的 n8n 工作流**，使用**内部 Docker 网络地址**：

1. **在 n8n Baserow 节点配置中**：
   - **Base URL**：`http://baserow:80`
     - `baserow` 是 docker-compose.yml 中的服务名称
     - `80` 是内部端口（不是外部端口 5080）
   - **认证**：根据需要配置你的 Baserow API token

### 为什么使用内部 Docker 网络地址？

- ✅ **直接通信**：无需通过外部网络
- ✅ **更快**：延迟更低，无外部路由
- ✅ **更安全**：服务在 Docker 网络内通信
- ✅ **更简单**：无需管理 ngrok URL
- ✅ **推荐**：同一 Docker Compose 中服务的最佳实践

### 外部访问 Baserow

如果需要从服务器外部访问 Baserow：
- **使用服务器 IP**：http://YOUR_SERVER_IP:5080
- **配置防火墙**：如果从外部网络访问，确保端口 5080 已开放
- **对于 n8n 工作流**：始终使用 `http://baserow:80`（内部 Docker 网络地址）

### 配置示例

在你的 n8n Baserow 节点中：
```
Base URL: http://baserow:80
API Token: [你的 Baserow API Token]
```

获取你的 Baserow API token：
1. 访问 http://localhost:5080（或服务器 IP:5080）的 Baserow
2. 转到设置 → API Tokens
3. 创建新的 API token
4. 在你的 n8n Baserow 节点配置中使用此 token

**注意**：对于生产工作流，始终在 n8n Baserow 节点中使用 `http://baserow:80` 作为 Base URL。

### ngrok 仪表板
- **本地访问**：http://localhost:4040
- 在此处查看隧道状态、请求和公共 URL

### 获取你的 Ngrok URL

安装后，n8n 的 ngrok URL 会自动检测并配置。你可以通过以下方式找到它：

1. **检查安装输出** - 脚本在找到 ngrok URL 时会显示它
2. **检查 ngrok 仪表板**：http://localhost:4040（显示活动隧道及其域名）
3. **检查 `.env` 文件**：查找：
   - `NGROK_URL=https://xxxxx.ngrok.io`（n8n 的 ngrok 域名）

**注意**：只有 n8n 使用 ngrok 进行 webhook 访问。Baserow 通过本地 URL 或服务器 IP 访问。

如果 ngrok URL 更改（例如，重启后），在你的 `.env` 文件中更新它并重启 n8n：
```bash
cd ~/n8n
docker compose restart n8n
```

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

### 使用 ngrok（推荐用于 Webhook）

此安装包含 ngrok 集成，为 n8n 和 Baserow 提供安全隧道：

1. **获取你的 ngrok authtoken**（免费）：
   - 在 [ngrok.com](https://ngrok.com) 注册（提供免费账户）
   - 从[仪表板](https://dashboard.ngrok.com/get-started/your-authtoken)获取你的 authtoken

2. **安装期间**，脚本会提示输入你的 authtoken。在询问时输入它。

3. **如果你跳过了它**，编辑 `ngrok.yml` 并添加你的 authtoken：
   ```bash
   cd ~/n8n
   nano ngrok.yml
   # 将 YOUR_NGROK_AUTHTOKEN_HERE 替换为你的实际 token
   ```

4. **更新后重启 ngrok**：
   ```bash
   docker compose restart ngrok
   ```

5. **检查你的 ngrok URL**：
   - 访问 http://localhost:4040（ngrok 仪表板 - 显示两个隧道）
   - 或检查你的 `.env` 文件：
     - `NGROK_URL`（n8n 隧道）
     - `BASEROW_NGROK_URL`（Baserow 隧道）

**使用 ngrok 的好处：**
- ✅ 为 n8n 和 Baserow 提供安全的 HTTPS 隧道（无需配置 SSL 证书）
- ✅ 用于 webhook 的公共 URL，无需暴露你的服务器
- ✅ 在 n8n 中自动配置 URL
- ✅ 通过 ngrok 仪表板检查请求
- ✅ 提供免费套餐

**重要提示：**
- **免费 ngrok 账户**：提供基本功能
- **付费计划**：支持额外功能和更高限制
- **检查隧道状态**：访问 http://localhost:4040 查看活动隧道及其域名

## 常用命令

### 使用 Docker Compose（如果使用 compose 安装）

```bash
cd ~/n8n
docker compose ps                    # 查看所有服务状态
docker compose logs -f               # 查看所有日志
docker compose logs -f n8n           # 仅查看 n8n 日志
docker compose logs -f baserow       # 仅查看 Baserow 日志
docker compose logs -f ngrok         # 仅查看 ngrok 日志
docker compose down                  # 停止所有容器
docker compose up -d                 # 启动所有容器
docker compose restart               # 重启所有容器
docker compose restart n8n          # 仅重启 n8n
docker compose restart ngrok        # 仅重启 ngrok
```

### 查看服务信息

```bash
cd ~/n8n

# 查看 ngrok URL
cat .env | grep NGROK_URL

# 查看数据库密码（保持安全！）
cat .env

# 检查 ngrok 仪表板
# 在浏览器中打开 http://localhost:4040

# 查看 PostgreSQL 连接信息
docker compose exec postgres psql -U n8n -d n8n -c "\l"
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

所有服务的数据都存储在 Docker 卷中，因此即使删除容器，数据也不会丢失：

- **n8n_data**：n8n 工作流、凭证和执行历史
- **postgres_data**：n8n 的 PostgreSQL 数据库
- **baserow_data**：Baserow 应用程序数据和文件
- **baserow_db_data**：Baserow 的 PostgreSQL 数据库
- **baserow_redis_data**：Baserow 的 Redis 缓存

查看卷：
```bash
docker volume ls | grep n8n
docker volume inspect n8n_data
docker volume inspect postgres_data
docker volume inspect baserow_data
docker volume inspect baserow_db_data
```

## 环境配置

安装会在你的 n8n 目录中创建一个 `.env` 文件，包含以下变量：

```bash
# PostgreSQL 配置
POSTGRES_PASSWORD=n8n

# Baserow 数据库配置
BASEROW_DB_PASSWORD=baserow
BASEROW_PUBLIC_URL=http://localhost:5080

# Redis 配置
REDIS_PASSWORD=baserow_redis_password

# Ngrok 配置
NGROK_URL=https://xxxxx.ngrok.io
BASEROW_NGROK_URL=https://xxxxx.ngrok.io
```

**重要提示：**
- 保持你的 `.env` 文件安全 - 它包含数据库密码
- 如果 ngrok URL 更改，更新 `.env` 中的 `NGROK_URL` 并重启 n8n 服务
- 使用默认密码（可在 `.env` 文件中更改用于生产环境）

## 卸载

### 使用 Docker Compose

```bash
cd ~/n8n
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
docker logs n8n_baserow
```

### Baserow 启动时间

**问：Baserow 启动时间很长，显示"正在同步 Baserow 模板"**

**答：** 这是正常行为。默认情况下，我们已禁用模板同步（`BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false`）以加快启动速度。

- **首次启动**：数据库初始化可能需要 2-5 分钟
- **后续启动**：通常更快（30 秒到 2 分钟）
- **模板同步**：默认禁用。如果需要 Baserow 的预构建模板，可以通过以下方式启用：
  1. 编辑 `docker-compose.yml`
  2. 将 `BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false` 更改为 `true`
  3. 重启：`docker compose restart baserow`

**注意**：模板同步在首次运行时可能需要 10 分钟以上，只有在需要使用 Baserow 的预构建模板时才需要。对于大多数只需要数据库的用户来说，这不是必需的。

## 许可证

本项目遵循与 n8n 相同的许可证。

## 相关链接

- [n8n 官方文档](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [n8n 官网](https://n8n.io/)

