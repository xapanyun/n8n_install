#!/bin/bash

# n8n One-Click Installation Script
# Supports common Linux systems like Debian, Ubuntu, CentOS, etc.
# Based on Docker installation

# Set locale to avoid encoding issues
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root user
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run this script with root privileges (use sudo)"
        exit 1
    fi
}

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    else
        log_error "Unable to detect operating system type"
        exit 1
    fi
    
    log_info "Detected operating system: $OS $OS_VERSION"
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker is installed: $DOCKER_VERSION"
        return 0
    else
        log_warning "Docker is not installed, will install automatically"
        return 1
    fi
}

# Fix CentOS repository address (official support ended, switch to vault repository)
fix_centos_repo() {
    log_info "Detecting CentOS version and fixing repository address..."
    
    # Detect CentOS version
    if [ "$OS" != "centos" ]; then
        return 0
    fi
    
    local centos_version=$(echo $OS_VERSION | cut -d. -f1)
    
    # CentOS 8 (including 8-stream)
    if [ "$centos_version" = "8" ]; then
        log_warning "Detected CentOS 8, official support has ended, switching to vault repository..."
        
        # Backup existing repositories
        if [ ! -d /etc/yum.repos.d/backup ]; then
            mkdir -p /etc/yum.repos.d/backup
            cp -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
        fi
        
        # Replace with vault repository
        sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
        sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
        
        log_success "CentOS 8 repository address has been switched to vault.centos.org"
        
    # CentOS 7
    elif [ "$centos_version" = "7" ]; then
        log_warning "Detected CentOS 7, official support has ended, switching to vault repository..."
        
        # Backup existing repositories
        if [ ! -d /etc/yum.repos.d/backup ]; then
            mkdir -p /etc/yum.repos.d/backup
            cp -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
        fi
        
        # Replace with vault repository
        sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
        sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
        
        log_success "CentOS 7 repository address has been switched to vault.centos.org"
    else
        log_info "CentOS $centos_version repository address does not need fixing"
    fi
    
    # Clean cache
    if command -v dnf &> /dev/null; then
        dnf clean all -q 2>/dev/null || true
    else
        yum clean all -q 2>/dev/null || true
    fi
}

# Install Docker
install_docker() {
    log_info "Starting Docker installation..."
    
    case $OS in
        ubuntu|debian)
            # Update package index
            log_info "Updating package index..."
            apt-get update -qq
            
            # Install necessary dependencies
            log_info "Installing necessary dependencies..."
            apt-get install -y -qq \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker official GPG key
            log_info "Adding Docker official GPG key..."
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${OS}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            
            # Set up Docker repository
            log_info "Setting up Docker repository..."
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} \
              $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            log_info "Installing Docker Engine..."
            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            ;;
        centos|rhel|fedora)
            # Fix CentOS repository address (if needed)
            fix_centos_repo
            
            # Detect package manager
            if command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
            else
                PKG_MANAGER="yum"
            fi
            
            # Install necessary dependencies
            log_info "Installing necessary dependencies..."
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $PKG_MANAGER install -y -q dnf-plugins-core
            else
                $PKG_MANAGER install -y -q yum-utils
            fi
            
            # Add Docker repository
            log_info "Adding Docker repository..."
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $PKG_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            else
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            fi
            
            # Install Docker
            log_info "Installing Docker Engine..."
            $PKG_MANAGER install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    # Start Docker service
    log_info "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
    
    # Verify Docker installation
    if docker --version &> /dev/null; then
        log_success "Docker installed successfully: $(docker --version)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_success "Docker Compose is available (new version)"
        return 0
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        log_success "Docker Compose is available (old version)"
        return 0
    else
        log_warning "Docker Compose is not available, will use docker run"
        COMPOSE_CMD=""
        return 1
    fi
}

# Download docker-compose.yml file
download_docker_compose_file() {
    local current_dir=$(pwd)
    local compose_file="$current_dir/docker-compose.yml"
    
    log_info "Downloading docker-compose.yml file..." >&2
    
    if curl -fsSL https://raw.githubusercontent.com/xapanyun/n8n_install/main/docker-compose.yml -o "$compose_file"; then

        
        log_success "docker-compose.yml downloaded successfully: $compose_file" >&2
        echo "$compose_file"
        return 0
    else
        log_error "Failed to download docker-compose.yml" >&2
        return 1
    fi
}

# Find docker-compose.yml file
find_docker_compose_file() {
    # First check current directory
    local current_dir=$(pwd)
    if [ -f "$current_dir/docker-compose.yml" ]; then
        echo "$current_dir/docker-compose.yml"
        return 0
    fi
    
    # Check script directory
    local script_path="$0"
    # Try to get absolute path
    if [ -L "$script_path" ]; then
        script_path=$(readlink "$script_path" 2>/dev/null || echo "$script_path")
    fi
    local script_dir=$(cd "$(dirname "$script_path")" 2>/dev/null && pwd || dirname "$script_path")
    
    if [ -f "$script_dir/docker-compose.yml" ]; then
        echo "$script_dir/docker-compose.yml"
        return 0
    fi
    
    return 1
}

# Download ngrok.yml.template file
download_ngrok_template() {
    local compose_dir=$1
    local template_file="$compose_dir/ngrok.yml.template"
    
    log_info "Downloading ngrok.yml.template file..." >&2
    
    if curl -fsSL https://raw.githubusercontent.com/xapanyun/n8n_install/main/ngrok.yml.template -o "$template_file"; then
        log_success "ngrok.yml.template downloaded successfully: $template_file" >&2
        echo "$template_file"
        return 0
    else
        log_warning "Failed to download ngrok.yml.template, will create ngrok.yml directly" >&2
        return 1
    fi
}

# Setup ngrok configuration
setup_ngrok() {
    local compose_dir=$1
    local ngrok_file="$compose_dir/ngrok.yml"
    local ngrok_template="$compose_dir/ngrok.yml.template"
    
    # Check if ngrok.yml already exists
    if [ -f "$ngrok_file" ]; then
        log_info "ngrok.yml already exists, skipping setup"
        return 0
    fi
    
    # Try to find template in script directory
    local script_path="$0"
    if [ -L "$script_path" ]; then
        script_path=$(readlink "$script_path" 2>/dev/null || echo "$script_path")
    fi
    local script_dir=$(cd "$(dirname "$script_path")" 2>/dev/null && pwd || dirname "$script_path")
    
    # Try to use template from script directory
    if [ -f "$script_dir/ngrok.yml.template" ]; then
        cp "$script_dir/ngrok.yml.template" "$ngrok_file"
        log_info "Using ngrok.yml.template from script directory"
    # Try to use template from compose directory
    elif [ -f "$ngrok_template" ]; then
        cp "$ngrok_template" "$ngrok_file"
        log_info "Using ngrok.yml.template from compose directory"
    # Try to download template from GitHub
    elif download_ngrok_template "$compose_dir" > /dev/null 2>&1 && [ -f "$ngrok_template" ]; then
        cp "$ngrok_template" "$ngrok_file"
        log_info "Using downloaded ngrok.yml.template"
    else
        # Create ngrok.yml from scratch
        log_info "Creating ngrok.yml from default configuration"
        cat > "$ngrok_file" <<EOF
version: "2"
authtoken: YOUR_NGROK_AUTHTOKEN_HERE
tunnels:
  n8n:
    proto: http
    addr: n8n:5678
    inspect: true
EOF
    fi
    
    log_info "Please enter your ngrok authtoken (get it from https://dashboard.ngrok.com/get-started/your-authtoken)"
    log_info "You can also skip this step and edit ngrok.yml manually later"
    echo ""
    read -p "Enter ngrok authtoken (or press Enter to skip): " ngrok_token
    
    if [ -n "$ngrok_token" ]; then
        # Replace authtoken in ngrok.yml
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/YOUR_NGROK_AUTHTOKEN_HERE/$ngrok_token/" "$ngrok_file"
        else
            sed -i "s/YOUR_NGROK_AUTHTOKEN_HERE/$ngrok_token/" "$ngrok_file"
        fi
        log_success "ngrok authtoken configured"
    else
        log_warning "ngrok authtoken not set. Please edit $ngrok_file and add your authtoken before starting services"
    fi
}

# Create .env file for environment variables
create_env_file() {
    local compose_dir=$1
    local env_file="$compose_dir/.env"
    
    if [ -f "$env_file" ]; then
        log_info ".env file already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating .env file for environment variables..."
    
    # Use fixed default passwords (can be changed in .env file if needed)
    local postgres_password="n8n"
    local baserow_db_password="baserow"
    local redis_password="baserow_redis_password"
    
    # Auto-detect server IP for Baserow public URL
    local server_ip=""
    if command -v hostname &> /dev/null; then
        server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
    fi
    
    # Set Baserow public URL - use server IP if available, otherwise localhost
    local baserow_public_url="http://localhost:5080"
    if [ -n "$server_ip" ] && [ "$server_ip" != "127.0.0.1" ]; then
        baserow_public_url="http://${server_ip}:5080"
        log_info "Auto-detected server IP: $server_ip, setting BASEROW_PUBLIC_URL to $baserow_public_url"
    else
        log_info "Using localhost for BASEROW_PUBLIC_URL. You can update it in .env file if accessing via IP address."
    fi
    
    cat > "$env_file" <<EOF
# PostgreSQL Configuration
POSTGRES_PASSWORD=$postgres_password

# Baserow Database Configuration
BASEROW_DB_PASSWORD=$baserow_db_password
# BASEROW_PUBLIC_URL: Set to your actual access URL (IP or domain)
# If accessing via IP, update this to: http://YOUR_IP:5080
BASEROW_PUBLIC_URL=$baserow_public_url
# BASEROW_EXTRA_PUBLIC_URLS: Allow internal Docker network access
# This allows n8n to access Baserow via http://baserow:80
BASEROW_EXTRA_PUBLIC_URLS=http://baserow:80

# Redis Configuration
REDIS_PASSWORD=$redis_password

# Ngrok Configuration (will be updated after ngrok starts)
NGROK_URL=http://localhost:5678
EOF
    
    log_success ".env file created at $env_file"
    log_warning "Please keep your .env file secure. It contains database passwords."
}

# Get ngrok URL and update configuration
get_ngrok_url() {
    local compose_dir=$1
    local env_file="$compose_dir/.env"
    local ngrok_file="$compose_dir/ngrok.yml"
    
    # Check if ngrok authtoken is configured
    if [ ! -f "$ngrok_file" ]; then
        log_warning "ngrok.yml not found, skipping ngrok URL detection"
        return 0
    fi
    
    # Check if authtoken is still the placeholder or empty
    if grep -q "YOUR_NGROK_AUTHTOKEN_HERE" "$ngrok_file"; then
        log_warning "ngrok authtoken not configured (still using placeholder), skipping ngrok URL detection"
        log_info "To enable ngrok, edit $ngrok_file and add your authtoken, then restart services"
        return 0
    fi
    
    # Check if authtoken line exists and has a value
    local authtoken_line=$(grep "^authtoken:" "$ngrok_file" 2>/dev/null)
    if [ -z "$authtoken_line" ]; then
        log_warning "ngrok authtoken not found in ngrok.yml, skipping ngrok URL detection"
        return 0
    fi
    
    # Extract authtoken value (remove "authtoken: " prefix and trim whitespace)
    local authtoken_value=$(echo "$authtoken_line" | sed 's/^authtoken:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    if [ -z "$authtoken_value" ]; then
        log_warning "ngrok authtoken is empty, skipping ngrok URL detection"
        log_info "To enable ngrok, edit $ngrok_file and add your authtoken, then restart services"
        return 0
    fi
    
    # Check if ngrok container is running
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^n8n_ngrok$"; then
        log_warning "ngrok container is not running, skipping ngrok URL detection"
        return 0
    fi
    
    log_info "Waiting for ngrok to start and get public URL..."
    
    local max_attempts=30
    local attempt=0
    local n8n_ngrok_url=""
    
    while [ $attempt -lt $max_attempts ]; do
        sleep 2
        attempt=$((attempt + 1))
        
        # Try to get ngrok URL from ngrok API
        local tunnels_json=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
        
        if [ -n "$tunnels_json" ]; then
            # Parse JSON to get URL by tunnel name
            # Use Python or jq if available for better JSON parsing, otherwise use grep
            if command -v python3 &> /dev/null || command -v python &> /dev/null; then
                # Use Python for reliable JSON parsing
                local python_cmd="python3"
                if ! command -v python3 &> /dev/null; then
                    python_cmd="python"
                fi
                n8n_ngrok_url=$(echo "$tunnels_json" | $python_cmd -c "import sys, json; data=json.load(sys.stdin); [print(t['public_url']) for t in data.get('tunnels', []) if t.get('name') == 'n8n']" 2>/dev/null | head -1)
            elif command -v jq &> /dev/null; then
                # Use jq for JSON parsing
                n8n_ngrok_url=$(echo "$tunnels_json" | jq -r '.tunnels[] | select(.name=="n8n") | .public_url' 2>/dev/null | head -1)
            else
                # Fallback: use grep with more context
                n8n_ngrok_url=$(echo "$tunnels_json" | grep -A 15 '"name":"n8n"' | grep '"public_url"' | head -1 | sed 's/.*"public_url":"\([^"]*\)".*/\1/')
            fi
            
            # Fallback: if parsing by name fails, get first available URL
            if [ -z "$n8n_ngrok_url" ]; then
                local all_urls=$(echo "$tunnels_json" | grep -o '"public_url":"https://[^"]*"' | cut -d'"' -f4)
                local url_count=$(echo "$all_urls" | wc -l)
                
                if [ "$url_count" -ge 1 ]; then
                    n8n_ngrok_url=$(echo "$all_urls" | head -1)
                fi
            fi
            
            if [ -n "$n8n_ngrok_url" ]; then
                log_success "Found n8n ngrok URL: $n8n_ngrok_url"
                
                # Update .env file
                if [ -f "$env_file" ]; then
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' "s|NGROK_URL=.*|NGROK_URL=$n8n_ngrok_url|" "$env_file"
                    else
                        sed -i "s|NGROK_URL=.*|NGROK_URL=$n8n_ngrok_url|" "$env_file"
                    fi
                    
                    # Restart n8n to pick up new URL
                    log_info "Restarting n8n to use ngrok URL..."
                    cd "$compose_dir"
                    if [ -n "$COMPOSE_CMD" ]; then
                        $COMPOSE_CMD restart n8n
                    fi
                    cd - > /dev/null
                    
                    log_success "n8n configured to use ngrok URL: $n8n_ngrok_url"
                fi
                
                return 0
            fi
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Waiting for ngrok tunnel... (attempt $attempt/$max_attempts)"
        fi
    done
    
    log_warning "Could not automatically get ngrok URL. Please check ngrok status at http://localhost:4040"
    log_info "Once you have the ngrok URL, update .env file:"
    log_info "  NGROK_URL=https://your-n8n-ngrok-url.ngrok.io"
    return 1
}

# Create Docker volume
create_volume() {
    log_info "Creating n8n data volume..."
    if docker volume inspect n8n_data &> /dev/null; then
        log_warning "Data volume n8n_data already exists"
    else
        docker volume create n8n_data
        log_success "Data volume n8n_data created successfully"
    fi
}

# Stop and remove existing containers (if exists)
cleanup_existing_container() {
    local containers=("n8n" "n8n_postgres" "n8n_baserow" "n8n_baserow_db" "n8n_baserow_redis" "n8n_ngrok")
    local found=false
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            if [ "$found" = false ]; then
                log_warning "Found existing containers, will stop and remove..."
                found=true
            fi
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    if [ "$found" = true ]; then
        log_success "Existing containers cleaned up"
    fi
}

# Run n8n container (using docker-compose)
run_n8n_with_compose() {
    local compose_file=$1
    log_info "Starting all services with Docker Compose..."
    
    # Check if ports are already in use
    if netstat -tuln 2>/dev/null | grep -q ":5678 " || ss -tuln 2>/dev/null | grep -q ":5678 "; then
        log_warning "Port 5678 is already in use, will use existing container or need manual handling"
    fi
    if netstat -tuln 2>/dev/null | grep -q ":80 " || ss -tuln 2>/dev/null | grep -q ":80 "; then
        log_warning "Port 80 is already in use (Baserow), will use existing container or need manual handling"
    fi
    
    # Switch to compose file directory
    local compose_dir=$(dirname "$compose_file")
    cd "$compose_dir"
    
    # Setup ngrok configuration
    setup_ngrok "$compose_dir"
    
    # Create .env file
    create_env_file "$compose_dir"
    
    # Start with docker compose
    if [ -n "$COMPOSE_CMD" ]; then
        log_info "Starting PostgreSQL, Baserow, n8n, and ngrok services..."
        $COMPOSE_CMD up -d
        
        if [ $? -eq 0 ]; then
            log_success "All services started successfully (using Docker Compose)"
            
            # Wait a bit for services to start
            log_info "Waiting for services to initialize..."
            sleep 10
            
            # Try to get ngrok URL and update configuration
            get_ngrok_url "$compose_dir"
            
            cd - > /dev/null
            return 0
        else
            log_error "Failed to start services"
            cd - > /dev/null
            return 1
        fi
    else
        cd - > /dev/null
        return 1
    fi
}

# Run n8n container (using docker run)
run_n8n_with_docker() {
    log_info "Starting n8n container with Docker run..."
    
    # Check if port is already in use
    if netstat -tuln 2>/dev/null | grep -q ":5678 " || ss -tuln 2>/dev/null | grep -q ":5678 "; then
        log_warning "Port 5678 is already in use, will use existing container or need manual handling"
    fi
    
    # Run container
    docker run -d \
        --name n8n \
        -p 5678:5678 \
        -e N8N_SECURE_COOKIE=false \
        -v n8n_data:/home/node/.n8n \
        --restart unless-stopped \
        docker.n8n.io/n8nio/n8n
    
    if [ $? -eq 0 ]; then
        log_success "n8n container started successfully (using Docker run)"
        return 0
    else
        log_error "Failed to start n8n container"
        return 1
    fi
}

# Show installation information
show_info() {
    local compose_file=$1
    local use_compose=$2
    
    echo ""
    log_success "=========================================="
    log_success "n8n Installation Completed!"
    log_success "=========================================="
    echo ""
    
    if [ "$use_compose" = "true" ] && [ -n "$compose_file" ]; then
        local compose_dir=$(dirname "$compose_file")
        local env_file="$compose_dir/.env"
        local ngrok_url=""
        
        # Try to get ngrok URL from .env or ngrok API
        if [ -f "$env_file" ]; then
            ngrok_url=$(grep "^NGROK_URL=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        fi
        
        if [ -z "$ngrok_url" ] || [ "$ngrok_url" = "http://localhost:5678" ]; then
            # Try to get from ngrok API
            ngrok_url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"https://[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        
        log_success "Services Status:"
        echo ""
        log_info "📊 n8n:"
        echo "  - Local URL: http://localhost:5678"
        echo "  - Server IP: http://$(hostname -I | awk '{print $1}'):5678"
        if [ -n "$ngrok_url" ] && [ "$ngrok_url" != "http://localhost:5678" ]; then
            echo "  - Ngrok URL: $ngrok_url"
            log_success "  ✓ n8n is accessible via ngrok and configured for webhooks"
        else
            echo "  - Ngrok URL: Not available yet (check http://localhost:4040)"
            log_warning "  ⚠ Please check ngrok status and update .env file with NGROK_URL"
        fi
        echo ""
        log_info "🗄️  PostgreSQL:"
        echo "  - Database: n8n"
        echo "  - Host: postgres (internal)"
        echo "  - Port: 5432 (internal)"
        if [ -f "$env_file" ]; then
            local postgres_pwd=$(grep "^POSTGRES_PASSWORD=" "$env_file" | cut -d'=' -f2-)
            echo "  - Password: (stored in .env file)"
        fi
        echo ""
        log_info "📋 Baserow:"
        echo "  - Local URL: http://localhost:5080"
        echo "  - Server IP: http://$(hostname -I | awk '{print $1}'):5080"
        echo "  - Access: Use local URL or server IP (no ngrok tunnel)"
        echo ""
        log_info "🌐 Ngrok:"
        echo "  - Dashboard: http://localhost:4040"
        echo "  - Status: Check dashboard for tunnel information"
        echo ""
        log_info "Docker Compose file location: $compose_file"
        log_info ".env file location: $env_file"
        echo ""
        log_info "Common commands (Docker Compose):"
        echo "  View all services status: cd $compose_dir && $COMPOSE_CMD ps"
        echo "  View n8n logs: cd $compose_dir && $COMPOSE_CMD logs -f n8n"
        echo "  View all logs: cd $compose_dir && $COMPOSE_CMD logs -f"
        echo "  Stop all services: cd $compose_dir && $COMPOSE_CMD down"
        echo "  Start all services: cd $compose_dir && $COMPOSE_CMD up -d"
        echo "  Restart all services: cd $compose_dir && $COMPOSE_CMD restart"
        echo "  View ngrok dashboard: http://localhost:4040"
        echo ""
        log_warning "Important Notes:"
        echo "  1. Make sure ngrok authtoken is configured in ngrok.yml"
        echo "  2. If ngrok URL changes, update NGROK_URL in .env and restart n8n service"
        echo "  3. Keep your .env file secure - it contains database passwords"
        echo "  4. n8n uses ngrok for webhooks, Baserow uses local access"
    else
        log_info "Access URL: http://localhost:5678"
        log_info "Or use server IP: http://$(hostname -I | awk '{print $1}'):5678"
        echo ""
        log_info "Common commands (Docker run):"
        echo "  View container status: docker ps | grep n8n"
        echo "  View logs: docker logs -f n8n"
        echo "  Stop container: docker stop n8n"
        echo "  Start container: docker start n8n"
        echo "  Restart container: docker restart n8n"
        echo "  Remove container: docker stop n8n && docker rm n8n"
    fi
    echo ""
}

# Check and prompt n8n working directory
check_work_directory() {
    local current_dir=$(pwd)
    local dir_name=$(basename "$current_dir")
    
    if [ "$dir_name" != "n8n" ]; then
        log_warning "It is recommended to run this script in the n8n directory"
        log_info "Current working directory: $current_dir"
        echo ""
        log_info "Before installation, it is recommended to create and enter the n8n directory:"
        echo "  mkdir -p ~/n8n"
        echo "  cd ~/n8n"
        echo ""
        log_info "If docker-compose.yml already exists in the current directory, it will be used directly"
        log_info "Otherwise, installation will continue in the current directory..."
        echo ""
        sleep 2
    else
        log_success "Detected n8n working directory: $current_dir"
    fi
}

# Main function
main() {
    echo ""
    log_info "=========================================="
    log_info "n8n One-Click Installation Script"
    log_info "=========================================="
    echo ""
    
    # Check working directory
    check_work_directory
    
    # Check root privileges
    check_root
    
    # Detect operating system
    detect_os
    
    # Check and install Docker
    if ! check_docker; then
        install_docker
    fi
    
    # Check Docker Compose and find docker-compose.yml file
    USE_COMPOSE=false
    COMPOSE_FILE=""
    
    if check_docker_compose; then
        # Find docker-compose.yml file
        if COMPOSE_FILE=$(find_docker_compose_file); then
            USE_COMPOSE=true
            log_success "Found docker-compose.yml: $COMPOSE_FILE"
        else
            # Try to download docker-compose.yml file
            log_info "docker-compose.yml file not found, attempting to download from GitHub..."
            if COMPOSE_FILE=$(download_docker_compose_file); then
                USE_COMPOSE=true
            else
                log_warning "Download failed, will use docker run"
            fi
        fi
    fi
    
    # Create data volume (if using docker run)
    if [ "$USE_COMPOSE" = "false" ]; then
        create_volume
    fi
    
    # Cleanup existing container
    cleanup_existing_container
    
    # Run n8n
    if [ "$USE_COMPOSE" = "true" ] && [ -n "$COMPOSE_FILE" ]; then
        if ! run_n8n_with_compose "$COMPOSE_FILE"; then
            log_warning "Docker Compose startup failed, trying docker run..."
            USE_COMPOSE=false
            create_volume
            if ! run_n8n_with_docker; then
                log_error "Failed to start n8n container"
                exit 1
            fi
        fi
    else
        if ! run_n8n_with_docker; then
            log_error "Failed to start n8n container"
            exit 1
        fi
    fi
    
    # Wait for container to start
    log_info "Waiting for container to start..."
    sleep 3
    
    # Check container status
    if docker ps | grep -q n8n; then
        show_info "$COMPOSE_FILE" "$USE_COMPOSE"
    else
        log_error "Container startup failed, please check logs: docker logs n8n"
        exit 1
    fi
}

# Execute main function
main

