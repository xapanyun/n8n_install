# n8n One-Click Installation Script

[中文](README_cn.md) | [English](README.md)

Automated installation script for n8n on common Linux systems (Debian, Ubuntu, CentOS, etc.), based on Docker installation.

**Now includes integrated PostgreSQL database, Baserow, and ngrok for secure webhook access!**

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
- The script will prompt for your ngrok authtoken (get it from [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken))
- After installation, the following services will be available:
  - **n8n**: http://localhost:5678 (also accessible via ngrok)
  - **Baserow**: http://localhost:5080
  - **PostgreSQL**: Internal database for n8n
  - **ngrok Dashboard**: http://localhost:4040

## Features

- ✅ Automatic operating system detection
- ✅ Automatic Docker installation (if not installed)
- ✅ Support for Docker Compose or Docker run
- ✅ Automatic data volume creation
- ✅ Locale settings to avoid encoding issues
- ✅ Automatic cleanup of old containers
- ✅ **Integrated PostgreSQL database** for n8n data persistence
- ✅ **Integrated Baserow** - Airtable alternative for database management
- ✅ **Integrated ngrok** - Secure tunnel for webhook access from anywhere
- ✅ **Automatic ngrok URL configuration** - n8n gets ngrok URL automatically for webhooks

## Installation Instructions

The script will automatically perform the following operations:

1. Detect operating system type (Debian/Ubuntu/CentOS, etc.)
2. Check and install Docker (if not installed)
3. Check if Docker Compose is available
4. Find and use the `docker-compose.yml` in the project (if it exists)
5. Setup ngrok configuration (prompts for authtoken)
6. Create `.env` file with default passwords
7. Create Docker volumes for all services
8. Start all services: PostgreSQL, Baserow, n8n, and ngrok
9. Automatically detect ngrok URL and configure n8n webhooks

## Integrated Services

This installation includes the following integrated services:

### PostgreSQL Database
- **Purpose**: Stores n8n workflow data, credentials, and execution history
- **Access**: Internal only (within Docker network)
- **Database**: `n8n`
- **Credentials**: Stored in `.env` file (default password: `n8n`)

### Baserow
- **Purpose**: Open-source Airtable alternative for database management
- **Access**: http://localhost:5080
- **Integration**: Can be used in n8n workflows via internal Docker network (see [Using Baserow in n8n](#using-baserow-in-n8n) section)
- **Database**: Separate PostgreSQL instance for Baserow data
- **Template Sync**: Disabled by default (`BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false`) to speed up startup. If you need Baserow templates, you can enable it in docker-compose.yml

### ngrok
- **Purpose**: Creates secure tunnel to expose n8n webhooks publicly
- **Dashboard**: http://localhost:4040
- **Configuration**: Requires ngrok authtoken (free at [ngrok.com](https://ngrok.com))
- **Auto-configuration**: Automatically updates n8n's `WEBHOOK_URL` and `N8N_EDITOR_BASE_URL`

### Service Communication
All services are configured to communicate efficiently:
- **n8n webhooks**: Use the n8n ngrok URL automatically for external webhook access
- **Baserow access**: Use local URL (http://localhost:5080) or server IP
- **n8n ↔ Baserow communication**: Use internal Docker network address `http://baserow:80` (see [Using Baserow in n8n](#using-baserow-in-n8n) section)
- **PostgreSQL**: Used internally by n8n for data persistence (internal network only)

## Accessing Services

After installation, access the services at the following addresses:

### n8n
- **Local access**: http://localhost:5678
- **Server IP**: http://YOUR_SERVER_IP:5678
- **Ngrok URL**: Check http://localhost:4040 or your `.env` file for the public ngrok URL
  - This URL is automatically configured for webhooks
  - Use this URL to access n8n from anywhere securely

### Baserow
- **Local access**: http://localhost:5080
- **Server IP**: http://YOUR_SERVER_IP:5080
- **First-time setup**: Access any of the URLs above to complete Baserow initial setup

**Important**: Baserow requires `BASEROW_PUBLIC_URL` to be set to an actual accessible URL. The installation script will auto-detect your server IP and set it automatically.

**Configuration Options**:

**Option 1 (Auto-detected)**: The installation script automatically detects your server IP and sets `BASEROW_PUBLIC_URL` to `http://YOUR_IP:5080`

**Option 2 (Manual)**: If you need to access via a specific IP or domain, update `.env`:
```bash
BASEROW_PUBLIC_URL=http://192.168.31.10:5080
```

**Option 3 (Multiple URLs)**: Use `BASEROW_EXTRA_PUBLIC_URLS` to allow access from multiple URLs:
```bash
BASEROW_PUBLIC_URL=http://localhost:5080
BASEROW_EXTRA_PUBLIC_URLS=http://192.168.31.10:5080,http://192.168.1.100:5080
```

Then restart Baserow: `docker compose restart baserow`

According to [Baserow documentation](https://baserow.io/docs/installation/configuration):
- If accessing over a non-standard port, you must append the port number to `BASEROW_PUBLIC_URL`
- `BASEROW_EXTRA_PUBLIC_URLS` allows additional URLs that won't be treated as published application domains
- URLs not in `BASEROW_PUBLIC_URL` or `BASEROW_EXTRA_PUBLIC_URLS` will be treated as published application builder domains, which causes the "Not Found" error
- `0.0.0.0` is not a valid public URL - use actual IP addresses or domain names

## Using Baserow in n8n

Since n8n and Baserow are running in the same Docker Compose setup, they can communicate directly through the internal Docker network. **You should use the internal Docker network address, not the ngrok URL.**

### Recommended: Use Internal Docker Network Address

**For n8n workflows that need to access Baserow**, use the **internal Docker network address**:

1. **In n8n Baserow node configuration**:
   - **Base URL**: `http://baserow:80`
     - `baserow` is the service name in docker-compose.yml
     - `80` is the internal port (not the external port 5080)
   - **Authentication**: Configure your Baserow API token as needed

### Why Use Internal Docker Network Address?

- ✅ **Direct communication**: No need to go through external network
- ✅ **Faster**: Lower latency, no external routing
- ✅ **More secure**: Services communicate within Docker network
- ✅ **Simpler**: No need to manage ngrok URLs
- ✅ **Recommended**: Best practice for services in the same Docker Compose

### External Access to Baserow

If you need to access Baserow from outside the server:
- **Use server IP**: http://YOUR_SERVER_IP:5080
- **Configure firewall**: Ensure port 5080 is open if accessing from external networks
- **For n8n workflows**: Always use `http://baserow:80` (internal Docker network address)

### Example Configuration

In your n8n Baserow node:
```
Base URL: http://baserow:80
API Token: [Your Baserow API Token]
```

To get your Baserow API token:
1. Access Baserow at http://localhost:5080 (or server IP:5080)
2. Go to Settings → API Tokens
3. Create a new API token
4. Use this token in your n8n Baserow node configuration

**Note**: For production workflows, always use `http://baserow:80` as the Base URL in n8n Baserow nodes.

### ngrok Dashboard
- **Local access**: http://localhost:4040
- View tunnel status, requests, and public URLs here

### Getting Your Ngrok URL

After installation, n8n's ngrok URL is automatically detected and configured. You can find it by:

1. **Check the installation output** - The script displays the ngrok URL when found
2. **Check ngrok dashboard**: http://localhost:4040 (shows active tunnel with its domain)
3. **Check `.env` file**: Look for:
   - `NGROK_URL=https://xxxxx.ngrok.io` (n8n's ngrok domain)

**Note**: Only n8n uses ngrok for webhook access. Baserow is accessed via local URL or server IP.

If the ngrok URL changes (e.g., after restart), update it in your `.env` file and restart n8n:
```bash
cd ~/n8n
docker compose restart n8n
```

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

### Using ngrok (Recommended for Webhooks)

This installation includes ngrok integration, which provides secure tunnels for both n8n and Baserow:

1. **Get your ngrok authtoken** (free):
   - Sign up at [ngrok.com](https://ngrok.com) (free account available)
   - Get your authtoken from [dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)

2. **During installation**, the script will prompt for your authtoken. Enter it when asked.

3. **If you skipped it**, edit `ngrok.yml` and add your authtoken:
   ```bash
   cd ~/n8n
   nano ngrok.yml
   # Replace YOUR_NGROK_AUTHTOKEN_HERE with your actual token
   ```

4. **Restart ngrok** after updating:
   ```bash
   docker compose restart ngrok
   ```

5. **Check your ngrok URLs**:
   - Visit http://localhost:4040 (ngrok dashboard - shows both tunnels)
   - Or check your `.env` file for:
     - `NGROK_URL` (n8n tunnel)
     - `BASEROW_NGROK_URL` (Baserow tunnel)

**Benefits of using ngrok:**
- ✅ Secure HTTPS tunnels for both n8n and Baserow (no need to configure SSL certificates)
- ✅ Public URLs for webhooks without exposing your server
- ✅ Automatic URL configuration in n8n
- ✅ Request inspection via ngrok dashboard
- ✅ Free tier available

**Important Notes:**
- **Free ngrok accounts**: Available with basic features
- **Paid plans**: Support additional features and higher limits
- **Check tunnel status**: Visit http://localhost:4040 to see the active tunnel and its domain

## Common Commands

### Using Docker Compose (if installed with compose)

```bash
cd ~/n8n
docker compose ps                    # View all services status
docker compose logs -f               # View all logs
docker compose logs -f n8n           # View n8n logs only
docker compose logs -f baserow       # View Baserow logs only
docker compose logs -f ngrok         # View ngrok logs only
docker compose down                  # Stop all containers
docker compose up -d                 # Start all containers
docker compose restart               # Restart all containers
docker compose restart n8n          # Restart only n8n
docker compose restart ngrok        # Restart only ngrok
```

### Viewing Service Information

```bash
cd ~/n8n

# View ngrok URL
cat .env | grep NGROK_URL

# View database passwords (keep secure!)
cat .env

# Check ngrok dashboard
# Open browser to http://localhost:4040

# View PostgreSQL connection info
docker compose exec postgres psql -U n8n -d n8n -c "\l"
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

All service data is stored in Docker volumes, so data will not be lost even if containers are deleted:

- **n8n_data**: n8n workflows, credentials, and execution history
- **postgres_data**: PostgreSQL database for n8n
- **baserow_data**: Baserow application data and files
- **baserow_db_data**: PostgreSQL database for Baserow
- **baserow_redis_data**: Redis cache for Baserow

View volumes:
```bash
docker volume ls | grep n8n
docker volume inspect n8n_data
docker volume inspect postgres_data
docker volume inspect baserow_data
docker volume inspect baserow_db_data
```

## Environment Configuration

The installation creates a `.env` file in your n8n directory with the following variables:

```bash
# PostgreSQL Configuration
POSTGRES_PASSWORD=n8n

# Baserow Database Configuration
BASEROW_DB_PASSWORD=baserow
BASEROW_PUBLIC_URL=http://localhost:5080

# Redis Configuration
REDIS_PASSWORD=baserow_redis_password

# Ngrok Configuration
NGROK_URL=https://xxxxx.ngrok.io
BASEROW_NGROK_URL=https://xxxxx.ngrok.io
```

**Important:**
- Keep your `.env` file secure - it contains database passwords
- If ngrok URL changes, update `NGROK_URL` in `.env` and restart n8n service
- Default passwords are used (can be changed in `.env` file for production)

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
docker logs n8n_baserow
```

### Baserow Startup Time

**Q: Baserow takes a long time to start, showing "Syncing Baserow templates"**

**A:** This is normal behavior. By default, we've disabled template syncing (`BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false`) to speed up startup. 

- **First startup**: May take 2-5 minutes for database initialization
- **Subsequent startups**: Usually faster (30 seconds to 2 minutes)
- **Template sync**: Disabled by default. If you need Baserow's pre-built templates, you can enable it by:
  1. Edit `docker-compose.yml`
  2. Change `BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false` to `true`
  3. Restart: `docker compose restart baserow`

**Note**: Template syncing can take 10+ minutes on first run and is only needed if you want to use Baserow's pre-built templates. For most users who just need a database, it's not necessary.

## License

This project follows the same license as n8n.

## Related Links

- [n8n Official Documentation](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [n8n Official Website](https://n8n.io/)

