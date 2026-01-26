# n8n One-Click Installation Script

[中文](README_cn.md) | [English](README.md)

Automated installation script for n8n on common Linux systems (Debian, Ubuntu, CentOS, etc.), based on Docker installation.

## System Requirements

- Linux system (Debian, Ubuntu, CentOS, RHEL, Fedora, etc.)
- Root privileges (using sudo)
- Network connection

## VPS Purchase Recommendations

### Recommended: Use Overseas VPS

Since n8n often needs to configure various overseas AI services (such as OpenAI, Anthropic, Google AI, etc.), it is recommended to purchase an overseas VPS for better network connectivity and stability.

### Recommended Configuration

**Bandwagon Host KVM VPS**

- **Configuration**: 40G SSD / 2GB RAM / 3x CPU / 2TB Traffic
- **Price**: $99.99 USD/year (approximately ¥700/year)
- **Advantages**:
  - Multiple data centers available
  - Free automatic backup and snapshots
  - Supports CentOS, Debian, Ubuntu, and other systems
  - 99.95% uptime guarantee
  - Suitable for running n8n and connecting to overseas AI services

**Purchase Link**: [Click to Purchase](https://bandwagonhost.com/aff.php?aff=36396&pid=45)

> **Tip**: Choose the "40G KVM - PROMO VPS" annual plan for the best value.

### Other VPS Options

If you already have another VPS provider, ensure it meets the following minimum configuration requirements:
- **CPU**: 2 cores or more
- **Memory**: 2GB or more
- **Storage**: 20GB or more
- **Bandwidth**: 1Gbps
- **Operating System**: Debian 11+ / Ubuntu 20.04+ / CentOS 8+

## Quick Installation

### Usage Instructions

**Pre-installation Preparation:**

1. Create n8n working directory:
```bash
mkdir -p ~/n8n
cd ~/n8n
```

2. Execute installation command:
```bash
curl -fsSL https://raw.githubusercontent.com/xapanyun/n8n_install/main/install_n8n.sh | sudo bash
```

**Installation Process:**

- The script will automatically detect the operating system and install Docker (if not installed)
- If the current directory contains `docker-compose.yml`, it will prioritize using Docker Compose for installation
- Otherwise, it will use `docker run` for installation
- After installation, n8n will run on port 5678

## Features

- ✅ Automatic operating system detection
- ✅ Automatic Docker installation (if not installed)
- ✅ Support for Docker Compose or Docker run
- ✅ Automatic data volume creation
- ✅ Locale settings to avoid encoding issues
- ✅ Automatic cleanup of old containers

## Installation Instructions

The script will automatically perform the following operations:

1. Detect operating system type (Debian/Ubuntu/CentOS, etc.)
2. Check and install Docker (if not installed)
3. Check if Docker Compose is available
4. Find and use the `docker-compose.yml` in the project (if it exists)
5. Create n8n data volume
6. Start n8n container

## Accessing n8n

After installation, access n8n at the following addresses:

- Local access: http://localhost:5678
- Server IP: http://YOUR_SERVER_IP:5678

### Using Domain Name Access

If you need to access n8n using a domain name, you can configure it in the following ways:

#### Method 1: Using Nginx Reverse Proxy

1. Install Nginx (if not installed):
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y nginx

# CentOS/RHEL
sudo yum install -y nginx
```

2. Create Nginx configuration file:
```bash
sudo nano /etc/nginx/sites-available/n8n
```

3. Add the following configuration (replace `your-domain.com` with your domain):
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

4. Enable configuration and restart Nginx:
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

5. Configure SSL certificate (recommended: Let's Encrypt):
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

#### Method 2: Using Cloudflare Reverse Proxy

1. Add your domain and DNS records in Cloudflare:
   - Add an A record pointing to your server IP address
   - Ensure the proxy status is "Proxied" (orange cloud icon)

2. Configure Nginx on the server (listen on port 80, no SSL needed):
```bash
sudo nano /etc/nginx/sites-available/n8n
```

Add the following configuration:
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

Enable configuration and restart Nginx:
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

3. Configure Cloudflare SSL/TLS:
   - Log in to Cloudflare dashboard
   - Go to SSL/TLS settings
   - Select "Flexible" mode
   - **Note**: Since the server only listens on port 80 (HTTP), you must select "Flexible" mode. When using Cloudflare, you don't need to install certbot on the server side, as Cloudflare will automatically handle SSL encryption

**Notes:**
- When using domain name access, ensure the domain DNS is correctly resolved to the server IP
- Using the Nginx method requires configuring an SSL certificate (recommended: Let's Encrypt)
- When using the Cloudflare method, the server only needs to listen on port 80, SSL is automatically handled by Cloudflare, no need to install certbot
- If using Cloudflare, pay attention to Webhook URL configuration to ensure the correct domain is used

## Common Commands

### Using Docker Compose (if installed with compose)

```bash
cd /path/to/docker-compose.yml
docker compose ps          # View container status
docker compose logs -f     # View logs
docker compose down        # Stop containers
docker compose up -d       # Start containers
docker compose restart     # Restart containers
```

### Using Docker run

```bash
docker ps | grep n8n       # View container status
docker logs -f n8n         # View logs
docker stop n8n            # Stop container
docker start n8n          # Start container
docker restart n8n         # Restart container
docker stop n8n && docker rm n8n  # Remove container
```

## Data Persistence

n8n data is stored in the Docker volume `n8n_data`, so data will not be lost even if the container is deleted.

View data volume:
```bash
docker volume inspect n8n_data
```

## Uninstallation

### Using Docker Compose

```bash
cd /path/to/docker-compose.yml
docker compose down
docker volume rm n8n_data  # Optional: remove data volume
```

### Using Docker run

```bash
docker stop n8n
docker rm n8n
docker volume rm n8n_data  # Optional: remove data volume
```

## Troubleshooting

If installation fails, please check:

1. Whether you have root privileges
2. Whether the network connection is normal
3. Whether port 5678 is occupied
4. Whether the Docker service is running normally

View container logs:
```bash
docker logs n8n
```

## License

This project follows the same license as n8n.

## Related Links

- [n8n Official Documentation](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [n8n Official Website](https://n8n.io/)

