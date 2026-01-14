FROM alpine:3.23.2

LABEL maintainer="dande-je@student.42sp.org.br"
LABEL description="Alpine Linux development environment with Neovim, GUI support, and development tools"
LABEL version="1.0.0"

# Install base system utilities and dependencies
RUN apk add --no-cache \
    bash \
    zsh \
    shadow \
    sudo \
    curl \
    wget \
    git \
    vim \
    neovim \
    htop \
    tree \
    procps \
    coreutils \
    grep \
    sed \
    findutils \
    util-linux

# Development tools and compilers
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    cmake \
    ninja \
    clang \
    clang-extra-tools \
    clang-dev \
    musl-dev \
    linux-headers

# Build tools for npm packages and native modules
RUN apk add --no-cache \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    gettext-dev \
    build-base

# X11 and GUI components
RUN apk add --no-cache \
    xorg-server \
    xf86-video-dummy \
    xf86-input-libinput \
    xinit \
    xrandr \
    openbox \
    openbox-doc \
    xterm \
    pcmanfm \
    dbus \
    mesa-dri-gallium \
    mesa-gl

# Terminator terminal
RUN apk add --no-cache \
    terminator \
    python3 \
    py3-cairo \
    py3-gobject3 \
    vte3

# Development utilities
RUN apk add --no-cache \
    ripgrep \
    fd \
    fzf \
    lazygit \
    sqlite \
    sqlite-dev \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz

# Node.js, npm, and Chromium dependencies (for mermaid-cli)
RUN apk add --no-cache \
    nodejs \
    npm \
    # chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    udev \
    ttf-liberation

# Python and pip
RUN apk add --no-cache \
    python3 \
    python3-dev \
    py3-pip \
    py3-setuptools

# Rust and Cargo
# RUN apk add --no-cache \
    # rust \
    # cargo

# Lua and LuaRocks
RUN apk add --no-cache \
    lua5.3 \
    lua5.3-dev \
    luarocks5.3 \
    luajit \
    luajit-dev

# Graphics and document processing
# RUN apk add --no-cache \
    # imagemagick \
    # ghostscript \
    # texlive \
    # texmf-dist-most

# Additional utilities
RUN apk add --no-cache \
    openssh-client \
    rsync \
    less \
    nano \
    ca-certificates \
    tzdata

# Create symlinks for lua and luarocks
RUN ln -sf /usr/bin/lua5.3 /usr/bin/lua \
    && ln -sf /usr/bin/luarocks-5.3 /usr/bin/luarocks

# Install Python development packages
RUN pip3 install --no-cache-dir --break-system-packages \
    norminette \
    pynvim \
    c-formatter-42 \
    compiledb-plus \
    ruff

# Configure Puppeteer to use system chromium
# ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    # PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install npm packages - stage 1: essential packages
RUN npm install -g --no-fund --no-audit \
    neovim \
    pyright
    # @ast-grep/cli

# Install npm packages - stage 2: mermaid-cli (optional, might fail)
# RUN npm install -g --no-fund --no-audit @mermaid-js/mermaid-cli || \
    # echo "Warning: mermaid-cli installation failed. You can install it later if needed."

# Lua packages via luarocks
RUN luarocks install luacheck \
    && luarocks install lsqlite3complete

# Create non-root user with sudo privileges
ARG USERNAME=dande-je
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN addgroup -g ${USER_GID} ${USERNAME} \
    && adduser -D -u ${USER_UID} -G ${USERNAME} -s /bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Switch to non-root user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Nerd Fonts
RUN mkdir -p ~/Downloads ~/.local/share/fonts \
    && cd ~/Downloads \
    && wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/InconsolataLGC.zip \
    && unzip -q InconsolataLGC.zip -d InconsolataLGC \
    && cp InconsolataLGC/*.ttf ~/.local/share/fonts/ \
    && fc-cache -fv \
    && cd ~ \
    && rm -rf ~/Downloads/*

# Install Rust cargo packages
# RUN cargo install --quiet viu ast-grep

# Configure X11 initialization
RUN echo "openbox-session &" > ~/.xinitrc \
    && echo "exec terminator" >> ~/.xinitrc

# Configure auto-startx
RUN echo 'if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then' >> ~/.zprofile \
    && echo '    startx' >> ~/.zprofile \
    && echo 'fi' >> ~/.zprofile

# Create configuration directories
RUN mkdir -p \
    ~/.config/nvim \
    ~/.config/terminator \
    ~/.config/openbox

RUN mkdir -p /home/dande-je/workspace && chown ${USERNAME}:${USERNAME} /home/dande-je/workspace

RUN git clone https://github.com/willtrigo/nvim.config.git home/dande-je/.config/nvim

RUN mkdir -p ~/.local/share/nvim/lazy

COPY --chown=dande-je:dande-je config/openbox/theme.xml /home/dande-je/.config/openbox/theme.xml
COPY --chown=dande-je:dande-je config/openbox/rc.xml /home/dande-je/.config/openbox/rc.xml

# Configure Git
RUN git config --global user.name "dande-je" \
    && git config --global user.email "dande-je@student.42sp.org.br" \
    && git config --global core.editor "nvim"

# Set environment variables
ENV DISPLAY=:0
ENV EDITOR=nvim
ENV VISUAL=nvim
ENV TERM=xterm-256color
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cargo/bin:${PATH}"

WORKDIR /home/dande-je/workspace

# Default command
CMD ["/bin/zsh"]