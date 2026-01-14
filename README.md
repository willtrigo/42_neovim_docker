# 42_neovim_docker

## Alpine Development Environment (Docker)

Ultra-lightweight, professional development environment using Alpine Linux with Neovim, GUI support, and comprehensive tooling.

## Table of Contents

- [Why Alpine Linux?](#why-alpine-linux)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Volume Management](#volume-management)
- [GUI Applications](#gui-applications)
- [Package Management](#package-management)
- [Neovim Configuration](#neovim-configuration)
- [Makefile Commands](#makefile-commands)
- [Size Comparison](#size-comparison)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)

---

## Why Alpine Linux?

**1. Extreme Lightweight**
- Base image: ~5MB
- Final image: ~800MB
- Container memory: 100-300MB
- Startup: Instant

**2. Security**
- Minimal attack surface
- Musl libc instead of glibc
- Security-focused by design
- Rapid security updates

**3. Package Manager**
- APK is blazingly fast
- Smaller package sizes
- No unnecessary dependencies
- Clean package management

**4. Professional Use**
- Industry standard for containers
- Used by Docker, Kubernetes, CI/CD pipelines
- Proven in production environments
- Better for microservices architecture

---

## Features

### System Components
- **Base**: Alpine Linux 3.19 (musl, busybox)
- **Shell**: Zsh with Oh My Zsh
- **GUI**: Openbox + Terminator (X11 forwarding)
- **Editor**: Neovim with full plugin support

### Development Tools
- **Languages**: C/C++ (gcc, g++, clang), Python, Rust, Node.js, Lua/LuaJIT
- **Version Control**: Git, LazyGit
- **Search Tools**: ripgrep, fd-find, fzf
- **Formatters/Linters**: clang-format, norminette, ruff, luacheck
- **LSPs**: pyright, clangd, ast-grep

### Integrated Features
- Nerd Fonts (Inconsolata LGC)
- LaTeX support (texlive)
- Image processing (ImageMagick, Ghostscript)
- Mermaid diagrams
- SQLite support
- File manager (pcmanfm)

---

## Prerequisites

### Required
- Docker Engine 20.10+
- Docker Compose 2.0+
- X11 server (for GUI applications)

### Installation

**Fedora/RHEL:**
```bash
sudo dnf install docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Ubuntu/Debian:**
```bash
sudo apt install docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Alpine (host):**
```bash
sudo apk add docker docker-compose
sudo rc-update add docker boot
sudo service docker start
sudo addgroup $USER docker
```

**⚠️ Re-login after adding yourself to docker group**

---

## Quick Start

### Automated Installation

```bash
# Run setup script
chmod +x setup.sh
./setup.sh
```

### Manual Installation

```bash
# Build the image (~5 minutes first time)
make build

# Start the container
make up

# Clone your Neovim configuration
make clone-nvim

# Access the shell
make shell
```

### First Commands Inside Container

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "dande-je@student.42sp.org.br"

# Navigate to workspace
cd /workspace

# Start coding
nvim
```

---

## Volume Management

### Three Persistent Volumes

1. **alpine-dev-workspace** (`/workspace`)
   - Your project files and code
   - Survives container recreation
   - Independently backed up

2. **alpine-dev-nvim-config** (`~/.config/nvim`)
   - Neovim plugins and configuration
   - Persists across rebuilds

3. **alpine-dev-home-data** (`/home/developer`)
   - Shell history, dotfiles
   - User configuration

### Volume Operations

```bash
# Backup all volumes
make backup

# Restore from backup
make restore BACKUP_FILE=workspace-20240113_120000.tar.gz

# Inspect volumes
make inspect

# Check status
make status
```

---

## GUI Applications

### X11 Forwarding

**Setup (run on host):**
```bash
xhost +local:docker
```

**Start GUI session:**
```bash
make gui
```

**Run individual GUI apps:**
```bash
docker-compose exec alpine-dev terminator &
docker-compose exec alpine-dev pcmanfm &
```

---

## Package Management

### APK Commands Inside Container

```bash
# Update package index
sudo apk update

# Upgrade all packages
sudo apk upgrade

# Install package
sudo apk add package-name

# Search for package
apk search keyword

# List installed packages
apk list --installed

# Get package info
apk info package-name

# Remove package
sudo apk del package-name
```

### Common Package Names (Alpine vs Others)

| Tool | Alpine | Fedora/Ubuntu |
|------|--------|---------------|
| C compiler | `gcc` | `gcc` |
| C++ compiler | `g++` | `gcc-c++` / `g++` |
| Python | `python3` | `python3` |
| Node.js | `nodejs` | `nodejs` |
| Development headers | `-dev` | `-devel` / `-dev` |

### Adding Packages to Dockerfile

Edit the `Dockerfile`:

```dockerfile
RUN apk add --no-cache \
    your-package \
    another-package
```

Then rebuild:
```bash
make rebuild
```

---

## Neovim Configuration

### Clone Your Configuration

```bash
# Automatic via Makefile
make clone-nvim

# Manual
docker-compose exec alpine-dev bash -c \
  'git clone git@github.com:willtrigo/nvim.config.git ~/.config/nvim'
```

### Install Plugins

```bash
# Inside container
nvim
# Then use your plugin manager (e.g., :Lazy sync)
```

### Treesitter Considerations

Alpine uses musl instead of glibc. Most Treesitter parsers work fine, but if you encounter issues:

```lua
-- In your Neovim config
require('nvim-treesitter.install').compilers = { "gcc" }
```

---

## Makefile Commands

### Essential Commands

```bash
make help           # Display all commands
make build          # Build Docker image
make up             # Start container
make down           # Stop container
make restart        # Restart container
make shell          # Open zsh shell
make nvim           # Start Neovim
make size           # Show image/container size
```

### Development Commands

```bash
make install        # Complete setup
make clone-nvim     # Clone Neovim config
make exec CMD="ls"  # Execute command
make logs           # View logs
make gui            # Start GUI session
```

### Maintenance Commands

```bash
make backup         # Backup volumes
make restore        # Restore from backup
make clean          # Remove volumes (⚠️  destructive)
make prune          # Clean Docker resources
make update-packages # Update system packages
make list-installed  # List installed packages
```

---

## Size Comparison

### Image Sizes

```bash
# Check your image size
make size

# Compare with other distros
docker images
```

**Typical sizes:**
- Alpine-based: ~800MB - 1.2GB (with all tools)
- Fedora-based: ~3GB - 5GB (with same tools)
- Ubuntu-based: ~2GB - 4GB (with same tools)

**That's 60-80% smaller!**

### Runtime Footprint

```bash
# Check container resource usage
docker stats alpine-dev-workspace
```

**Typical Alpine container:**
- Memory: 100-300MB (vs 500MB-1GB for Fedora)
- CPU: Minimal overhead
- Disk: 800MB (vs 3-5GB)

---

## Troubleshooting

### Common Issues

#### "Package not found"

Alpine package names differ from Fedora/Ubuntu:

```bash
# Search for package
docker-compose exec alpine-dev apk search <keyword>

# Example: finding development headers
apk search -v 'dev$'  # Lists all *-dev packages
```

#### Treesitter Parser Compilation Fails

```bash
# Inside container, install build dependencies
sudo apk add build-base

# Or add to Dockerfile
RUN apk add --no-cache build-base
```

#### musl vs glibc Compatibility

Most code works identically. If you encounter issues:

```bash
# Install gcompat (glibc compatibility layer)
sudo apk add gcompat
```

#### GUI Not Working

```bash
# Setup X11
make setup-x11

# Check DISPLAY
echo $DISPLAY

# Test X11
docker-compose exec alpine-dev xrandr
```

### Performance Issues

Alpine is faster, but if you notice issues:

```bash
# Check resource usage
docker stats alpine-dev-workspace

# Update packages
make update-packages

# Rebuild from scratch
make rebuild
```

---

## Architecture

```
alpine-dev/
├── Dockerfile                    # Alpine-based image
├── docker-compose.yml            # Orchestration
├── Makefile                      # Automation
├── configs/                      # Configuration files
│   ├── terminator.config
│   ├── openbox-rc.xml
│   └── openbox-theme.xml
├── setup.sh                      # Automated setup
└── README.md                     # This file

Docker Volumes:
├── alpine-dev-workspace          # /workspace
├── alpine-dev-nvim-config        # ~/.config/nvim
└── alpine-dev-home-data          # /home/developer
```

---

## Alpine vs Other Distros

### Performance Metrics

| Metric | Alpine | Fedora | Ubuntu |
|--------|--------|--------|--------|
| Build Time | 5-8 min | 10-15 min | 8-12 min |
| Image Size | 800MB | 3-5GB | 2-4GB |
| Boot Time | <1s | 1-2s | 1-2s |
| Memory Usage | 100-300MB | 500MB-1GB | 400-800MB |
| Package Install | Fast | Medium | Medium |

### When to Use Alpine

✅ **Use Alpine for:**
- Containerized development
- CI/CD pipelines
- Microservices
- Resource-constrained environments
- Production containers
- Learning container best practices

❌ **Consider alternatives for:**
- Kernel development
- Testing distro-specific features
- Applications requiring glibc-specific features (rare)
- Heavy GUI-focused development (though Alpine works fine)

---

## Best Practices

### DO

✅ Use Alpine for containers (industry standard)  
✅ Keep images minimal (only install what you need)  
✅ Use multi-stage builds for complex apps  
✅ Regular `make backup` for your work  
✅ Use named volumes for data persistence  
✅ Update packages: `make update-packages`

### DON'T

❌ Install unnecessary packages  
❌ Use Alpine on bare metal (use full distro)  
❌ Ignore security updates  
❌ Mix development data in volumes  
❌ Run containers as root  

---

## Security

Alpine is security-focused:

- **Musl libc**: Memory-safe C library
- **Minimal packages**: Smaller attack surface
- **Fast updates**: Security patches quickly available
- **Non-root user**: Container runs as `developer`
- **Read-only mounts**: SSH keys mounted RO
- **No privileged mode**: Limited capabilities

---

## Contributing to This Setup

1. Edit `Dockerfile` for system packages
2. Update `docker-compose.yml` for runtime config
3. Add commands to `Makefile` for workflows
4. Document changes in this README

---

## Package Finding Tips

### Finding Alpine Package Names

```bash
# Search by name
apk search nodejs

# Search with description
apk search -v -d 'python'

# Find which package provides a file
apk search --exact libssl.so.3

# Get package info
apk info nodejs
```

### Common Patterns

- Development headers: `package-dev` (e.g., `python3-dev`)
- Documentation: `package-doc` (e.g., `openbox-doc`)
- Static libraries: `package-static`
- Tools: Usually same name as other distros

---

## Performance Tips

1. **Layer Caching**: Group related `RUN` commands
2. **APK Cache**: Use `--no-cache` to keep images small
3. **Multi-stage Builds**: Use for production images
4. **Volume Performance**: Named volumes are fastest
5. **Update Regularly**: `make update-packages`

---

## Support

For issues:

1. Check `make logs`
2. Review [Troubleshooting](#troubleshooting)
3. Search Alpine packages: `apk search <term>`
4. Check Alpine wiki: https://wiki.alpinelinux.org
5. Rebuild: `make rebuild`

---

## Comparison Summary

### Alpine (This Setup)
- ⚡ Ultra-fast
- 💾 Minimal size (~800MB)
- 🔒 Security-focused
- 🚀 Industry standard
- ✅ Professional choice

### Fedora
- 📦 Largest package repository
- 🔴 Red Hat ecosystem
- 📏 Larger size (~3-5GB)
- 🐢 Slower package management

**Recommendation**: Use Alpine for containerized development. It's faster, smaller, and more professional.

---

## Quick Reference

```bash
# Daily workflow
make up              # Start
make shell           # Access
make nvim            # Code
make backup          # Save work

# Package management
sudo apk add pkg     # Install
sudo apk del pkg     # Remove
apk search keyword   # Search

# Troubleshooting
make logs            # View logs
make rebuild         # Fresh start
make size            # Check size
```

---

**Happy Coding with Alpine! ⛰️🚀**

*Ultra-lightweight. Production-ready. Professional.*