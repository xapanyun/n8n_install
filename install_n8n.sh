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

# Stop and remove existing container (if exists)
cleanup_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^n8n$"; then
        log_warning "Found existing n8n container, will stop and remove..."
        docker stop n8n 2>/dev/null || true
        docker rm n8n 2>/dev/null || true
        log_success "Existing container cleaned up"
    fi
}

# Run n8n container (using docker-compose)
run_n8n_with_compose() {
    local compose_file=$1
    log_info "Starting n8n container with Docker Compose..."
    
    # Check if port is already in use
    if netstat -tuln 2>/dev/null | grep -q ":5678 " || ss -tuln 2>/dev/null | grep -q ":5678 "; then
        log_warning "Port 5678 is already in use, will use existing container or need manual handling"
    fi
    
    # Switch to compose file directory
    local compose_dir=$(dirname "$compose_file")
    cd "$compose_dir"
    
    # Start with docker compose
    if [ -n "$COMPOSE_CMD" ]; then
        $COMPOSE_CMD up -d
        
        if [ $? -eq 0 ]; then
            log_success "n8n container started successfully (using Docker Compose)"
            cd - > /dev/null
            return 0
        else
            log_error "Failed to start n8n container"
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
    log_success "n8n installation completed!"
    log_success "=========================================="
    echo ""
    log_info "Access URL: http://localhost:5678"
    log_info "Or use server IP: http://$(hostname -I | awk '{print $1}'):5678"
    echo ""
    
    if [ "$use_compose" = "true" ] && [ -n "$compose_file" ]; then
        log_info "Docker Compose file location: $compose_file"
        echo ""
        log_info "Common commands (Docker Compose):"
        echo "  View container status: cd $(dirname $compose_file) && $COMPOSE_CMD ps"
        echo "  View logs: cd $(dirname $compose_file) && $COMPOSE_CMD logs -f"
        echo "  Stop containers: cd $(dirname $compose_file) && $COMPOSE_CMD down"
        echo "  Start containers: cd $(dirname $compose_file) && $COMPOSE_CMD up -d"
        echo "  Restart containers: cd $(dirname $compose_file) && $COMPOSE_CMD restart"
    else
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

