#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REQUIRED_DOCKER_VERSION="20.10"
REQUIRED_COMPOSE_VERSION="2.0"
NVIM_REPO="git@github.com:willtrigo/nvim.config.git"

print_header() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Alpine Development Environment Setup       ║${NC}"
    echo -e "${CYAN}║   Ultra-lightweight • Fast • Professional    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_highlight() {
    echo -e "${CYAN}▶${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

version_compare() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

check_docker() {
    print_info "Checking Docker installation..."
    
    if ! check_command docker; then
        print_error "Docker is not installed"
        echo "Please install Docker:"
        echo "  Alpine: sudo apk add docker"
        echo "  Fedora: sudo dnf install docker"
        echo "  Ubuntu: sudo apt install docker.io"
        echo "  macOS:  brew install docker"
        return 1
    fi
    
    local docker_version=$(docker --version | grep -oP '\d+\.\d+' | head -1)
    if version_compare "$docker_version" "$REQUIRED_DOCKER_VERSION"; then
        print_success "Docker $docker_version is installed"
    else
        print_warning "Docker version $docker_version is older than recommended $REQUIRED_DOCKER_VERSION"
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "User is not in docker group"
        echo "Run: sudo usermod -aG docker \$USER && newgrp docker"
    else
        print_success "User is in docker group"
    fi
    
    return 0
}

check_docker_compose() {
    print_info "Checking Docker Compose installation..."
    
    if ! check_command docker-compose && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        echo "Please install Docker Compose:"
        echo "  Alpine: sudo apk add docker-compose"
        echo "  Fedora: sudo dnf install docker-compose"
        echo "  Ubuntu: sudo apt install docker-compose"
        return 1
    fi
    
    local compose_version
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version --short 2>/dev/null || echo "2.0")
    else
        compose_version=$(docker-compose --version | grep -oP '\d+\.\d+' | head -1)
    fi
    
    print_success "Docker Compose $compose_version is installed"
    return 0
}

check_x11() {
    print_info "Checking X11 availability..."
    
    if [[ -z "${DISPLAY:-}" ]]; then
        print_warning "DISPLAY environment variable is not set"
        echo "GUI applications will not work without X11"
        echo "Set DISPLAY before running: export DISPLAY=:0"
    else
        print_success "X11 is available (DISPLAY=$DISPLAY)"
        
        if check_command xhost; then
            print_info "Configuring X11 access..."
            xhost +local:docker &> /dev/null || true
            print_success "X11 access configured"
        else
            print_warning "xhost command not found"
            echo "Install xhost for GUI support:"
            echo "  Alpine: sudo apk add xhost"
            echo "  Fedora: sudo dnf install xorg-x11-server-utils"
            echo "  Ubuntu: sudo apt install x11-xserver-utils"
        fi
    fi
}

check_make() {
    print_info "Checking Make installation..."
    
    if ! check_command make; then
        print_error "Make is not installed"
        echo "Install make:"
        echo "  Alpine: sudo apk add make"
        echo "  Fedora: sudo dnf install make"
        echo "  Ubuntu: sudo apt install make"
        return 1
    fi
    
    print_success "Make is installed"
    return 0
}

check_ssh_keys() {
    print_info "Checking SSH keys..."
    
    if [[ -f "$HOME/.ssh/id_rsa" ]] || [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        print_success "SSH keys found in ~/.ssh"
        print_info "These will be mounted read-only in the container"
    else
        print_warning "No SSH keys found in ~/.ssh"
        echo "You can generate them later with: make ssh-keygen"
    fi
}

create_directories() {
    print_info "Creating necessary directories..."
    
    mkdir -p backups
    print_success "Created backups directory"
}

show_alpine_benefits() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Why Alpine?${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ 75% smaller${NC} than Fedora (800MB vs 3-5GB)"
    echo -e "${GREEN}✓ 3x faster${NC} package installation"
    echo -e "${GREEN}✓ More secure${NC} - minimal attack surface"
    echo -e "${GREEN}✓ Industry standard${NC} for containers"
    echo -e "${GREEN}✓ Same functionality${NC} as full distributions"
    echo ""
}

build_image() {
    print_highlight "Building Alpine Docker image..."
    echo "This may take 5-8 minutes on first run..."
    echo ""
    
    local start_time=$(date +%s)
    
    if make build; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Docker image built successfully in ${duration}s"
        
        # Show image size
        local image_size=$(docker images alpine-dev:latest --format "{{.Size}}")
        echo ""
        print_highlight "Image size: ${image_size}"
        echo ""
        return 0
    else
        print_error "Failed to build Docker image"
        return 1
    fi
}

start_container() {
    print_info "Starting container..."
    
    if make up; then
        print_success "Container started successfully"
        return 0
    else
        print_error "Failed to start container"
        return 1
    fi
}

clone_nvim_config() {
    print_info "Cloning Neovim configuration..."
    
    read -p "Do you want to clone the Neovim configuration now? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if make clone-nvim; then
            print_success "Neovim configuration cloned"
        else
            print_warning "Failed to clone Neovim configuration"
            echo "You can clone it later with: make clone-nvim"
        fi
    else
        print_info "Skipping Neovim configuration clone"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Setup Complete! 🎉                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your ultra-lightweight Alpine environment is ready!"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo "  make shell              # Access the shell"
    echo "  make nvim               # Start Neovim"
    echo "  make gui                # Start GUI session"
    echo ""
    echo -e "${CYAN}Essential Commands:${NC}"
    echo "  make help               # View all commands"
    echo "  make backup             # Backup your work"
    echo "  make size               # Check image size"
    echo "  make update-packages    # Update packages"
    echo ""
    echo -e "${CYAN}Inside Container:${NC}"
    echo "  cd /workspace           # Your project directory"
    echo "  sudo apk add <pkg>      # Install packages"
    echo "  apk search <term>       # Search packages"
    echo ""
    echo -e "${CYAN}Package Management:${NC}"
    echo "  APK is fast! Try: ${YELLOW}apk search python3${NC}"
    echo "  Install: ${YELLOW}sudo apk add nodejs${NC}"
    echo "  Remove: ${YELLOW}sudo apk del nodejs${NC}"
    echo ""
    echo -e "${GREEN}Happy coding with Alpine! ⛰️${NC}"
    echo ""
}

print_comparison() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Size Comparison${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Alpine:  ${GREEN}~800MB${NC}   ← You're using this! ⚡"
    echo -e "Fedora:  ${YELLOW}~3-5GB${NC}   (4-6x larger)"
    echo -e "Ubuntu:  ${YELLOW}~2-4GB${NC}   (3-5x larger)"
    echo ""
    echo -e "${GREEN}You saved 2-4GB of disk space!${NC}"
    echo ""
}

main() {
    print_header
    show_alpine_benefits
    
    local errors=0
    
    check_docker || ((errors++))
    check_docker_compose || ((errors++))
    check_make || ((errors++))
    check_x11
    check_ssh_keys
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        print_error "Please fix the above errors before continuing"
        exit 1
    fi
    
    echo ""
    read -p "Do you want to proceed with the setup? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Setup cancelled"
        exit 0
    fi
    
    create_directories
    
    echo ""
    print_highlight "Starting Alpine Docker setup..."
    echo ""
    
    build_image || exit 1
    print_comparison
    start_container || exit 1
    clone_nvim_config
    
    print_next_steps
}

main "$@"