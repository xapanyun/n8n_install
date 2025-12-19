#!/bin/bash

# n8n 一键安装脚本
# 支持 Debian、Ubuntu、CentOS 等常见 Linux 系统
# 基于 Docker 安装

# 设置语言环境，避免乱码
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "请使用 root 权限运行此脚本 (使用 sudo)"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# 检查 Docker 是否已安装
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker 已安装: $DOCKER_VERSION"
        return 0
    else
        log_warning "Docker 未安装，将自动安装"
        return 1
    fi
}

# 安装 Docker
install_docker() {
    log_info "开始安装 Docker..."
    
    case $OS in
        ubuntu|debian)
            # 更新包索引
            log_info "更新包索引..."
            apt-get update -qq
            
            # 安装必要的依赖
            log_info "安装必要的依赖..."
            apt-get install -y -qq \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # 添加 Docker 官方 GPG 密钥
            log_info "添加 Docker 官方 GPG 密钥..."
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${OS}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            
            # 设置 Docker 仓库
            log_info "设置 Docker 仓库..."
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} \
              $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装 Docker
            log_info "安装 Docker Engine..."
            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            ;;
        centos|rhel|fedora)
            # 检测包管理器
            if command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
            else
                PKG_MANAGER="yum"
            fi
            
            # 安装必要的依赖
            log_info "安装必要的依赖..."
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $PKG_MANAGER install -y -q dnf-plugins-core
            else
                $PKG_MANAGER install -y -q yum-utils
            fi
            
            # 添加 Docker 仓库
            log_info "添加 Docker 仓库..."
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $PKG_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            else
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            fi
            
            # 安装 Docker
            log_info "安装 Docker Engine..."
            $PKG_MANAGER install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    # 启动 Docker 服务
    log_info "启动 Docker 服务..."
    systemctl start docker
    systemctl enable docker
    
    # 验证 Docker 安装
    if docker --version &> /dev/null; then
        log_success "Docker 安装成功: $(docker --version)"
    else
        log_error "Docker 安装失败"
        exit 1
    fi
}

# 检查 Docker Compose 是否可用
check_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_success "Docker Compose 可用 (新版本)"
        return 0
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        log_success "Docker Compose 可用 (旧版本)"
        return 0
    else
        log_warning "Docker Compose 不可用，将使用 docker run"
        COMPOSE_CMD=""
        return 1
    fi
}

# 查找 docker-compose.yml 文件
find_docker_compose_file() {
    # 首先检查当前目录
    local current_dir=$(pwd)
    if [ -f "$current_dir/docker-compose.yml" ]; then
        echo "$current_dir/docker-compose.yml"
        return 0
    fi
    
    # 检查脚本所在目录
    local script_path="$0"
    # 尝试获取绝对路径
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

# 创建 Docker volume
create_volume() {
    log_info "创建 n8n 数据卷..."
    if docker volume inspect n8n_data &> /dev/null; then
        log_warning "数据卷 n8n_data 已存在"
    else
        docker volume create n8n_data
        log_success "数据卷 n8n_data 创建成功"
    fi
}

# 停止并删除现有容器（如果存在）
cleanup_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^n8n$"; then
        log_warning "发现已存在的 n8n 容器，将停止并删除..."
        docker stop n8n 2>/dev/null || true
        docker rm n8n 2>/dev/null || true
        log_success "已清理现有容器"
    fi
}

# 运行 n8n 容器（使用 docker-compose）
run_n8n_with_compose() {
    local compose_file=$1
    log_info "使用 Docker Compose 启动 n8n 容器..."
    
    # 检查端口是否被占用
    if netstat -tuln 2>/dev/null | grep -q ":5678 " || ss -tuln 2>/dev/null | grep -q ":5678 "; then
        log_warning "端口 5678 已被占用，将使用现有容器或需要手动处理"
    fi
    
    # 切换到 compose 文件所在目录
    local compose_dir=$(dirname "$compose_file")
    cd "$compose_dir"
    
    # 使用 docker compose 启动
    if [ -n "$COMPOSE_CMD" ]; then
        $COMPOSE_CMD up -d
        
        if [ $? -eq 0 ]; then
            log_success "n8n 容器启动成功 (使用 Docker Compose)"
            cd - > /dev/null
            return 0
        else
            log_error "n8n 容器启动失败"
            cd - > /dev/null
            return 1
        fi
    else
        cd - > /dev/null
        return 1
    fi
}

# 运行 n8n 容器（使用 docker run）
run_n8n_with_docker() {
    log_info "使用 Docker run 启动 n8n 容器..."
    
    # 检查端口是否被占用
    if netstat -tuln 2>/dev/null | grep -q ":5678 " || ss -tuln 2>/dev/null | grep -q ":5678 "; then
        log_warning "端口 5678 已被占用，将使用现有容器或需要手动处理"
    fi
    
    # 运行容器
    docker run -d \
        --name n8n \
        -p 5678:5678 \
        -v n8n_data:/home/node/.n8n \
        --restart unless-stopped \
        docker.n8n.io/n8nio/n8n
    
    if [ $? -eq 0 ]; then
        log_success "n8n 容器启动成功 (使用 Docker run)"
        return 0
    else
        log_error "n8n 容器启动失败"
        return 1
    fi
}

# 显示安装信息
show_info() {
    local compose_file=$1
    local use_compose=$2
    
    echo ""
    log_success "=========================================="
    log_success "n8n 安装完成！"
    log_success "=========================================="
    echo ""
    log_info "访问地址: http://localhost:5678"
    log_info "或使用服务器 IP: http://$(hostname -I | awk '{print $1}'):5678"
    echo ""
    
    if [ "$use_compose" = "true" ] && [ -n "$compose_file" ]; then
        log_info "Docker Compose 文件位置: $compose_file"
        echo ""
        log_info "常用命令 (Docker Compose):"
        echo "  查看容器状态: cd $(dirname $compose_file) && $COMPOSE_CMD ps"
        echo "  查看日志: cd $(dirname $compose_file) && $COMPOSE_CMD logs -f"
        echo "  停止容器: cd $(dirname $compose_file) && $COMPOSE_CMD down"
        echo "  启动容器: cd $(dirname $compose_file) && $COMPOSE_CMD up -d"
        echo "  重启容器: cd $(dirname $compose_file) && $COMPOSE_CMD restart"
    else
        log_info "常用命令 (Docker run):"
        echo "  查看容器状态: docker ps | grep n8n"
        echo "  查看日志: docker logs -f n8n"
        echo "  停止容器: docker stop n8n"
        echo "  启动容器: docker start n8n"
        echo "  重启容器: docker restart n8n"
        echo "  删除容器: docker stop n8n && docker rm n8n"
    fi
    echo ""
}

# 检查并提示 n8n 工作目录
check_work_directory() {
    local current_dir=$(pwd)
    local dir_name=$(basename "$current_dir")
    
    if [ "$dir_name" != "n8n" ]; then
        log_warning "建议在 n8n 目录中运行此脚本"
        log_info "当前工作目录: $current_dir"
        echo ""
        log_info "安装前建议先创建并进入 n8n 目录："
        echo "  mkdir -p ~/n8n"
        echo "  cd ~/n8n"
        echo ""
        log_info "如果当前目录已有 docker-compose.yml，将直接使用"
        log_info "否则将在当前目录继续安装..."
        echo ""
        sleep 2
    else
        log_success "检测到 n8n 工作目录: $current_dir"
    fi
}

# 主函数
main() {
    echo ""
    log_info "=========================================="
    log_info "n8n 一键安装脚本"
    log_info "=========================================="
    echo ""
    
    # 检查工作目录
    check_work_directory
    
    # 检查 root 权限
    check_root
    
    # 检测操作系统
    detect_os
    
    # 检查并安装 Docker
    if ! check_docker; then
        install_docker
    fi
    
    # 检查 Docker Compose 并查找 docker-compose.yml 文件
    USE_COMPOSE=false
    COMPOSE_FILE=""
    
    if check_docker_compose; then
        # 查找 docker-compose.yml 文件
        if COMPOSE_FILE=$(find_docker_compose_file); then
            USE_COMPOSE=true
            log_success "找到 docker-compose.yml: $COMPOSE_FILE"
        else
            log_warning "未找到 docker-compose.yml 文件，将使用 docker run"
        fi
    fi
    
    # 创建数据卷（如果使用 docker run）
    if [ "$USE_COMPOSE" = "false" ]; then
        create_volume
    fi
    
    # 清理现有容器
    cleanup_existing_container
    
    # 运行 n8n
    if [ "$USE_COMPOSE" = "true" ] && [ -n "$COMPOSE_FILE" ]; then
        if ! run_n8n_with_compose "$COMPOSE_FILE"; then
            log_warning "Docker Compose 启动失败，尝试使用 docker run..."
            USE_COMPOSE=false
            create_volume
            if ! run_n8n_with_docker; then
                log_error "n8n 容器启动失败"
                exit 1
            fi
        fi
    else
        if ! run_n8n_with_docker; then
            log_error "n8n 容器启动失败"
            exit 1
        fi
    fi
    
    # 等待容器启动
    log_info "等待容器启动..."
    sleep 3
    
    # 检查容器状态
    if docker ps | grep -q n8n; then
        show_info "$COMPOSE_FILE" "$USE_COMPOSE"
    else
        log_error "容器启动失败，请检查日志: docker logs n8n"
        exit 1
    fi
}

# 执行主函数
main

