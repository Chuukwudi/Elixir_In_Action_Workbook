FROM elixir:1.19.4-otp-27

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    MIX_ENV=dev \
    # Python virtual environment
    VIRTUAL_ENV=/opt/venv \
    # Ensure global npm binaries and Claude's default paths are included
    PATH="/opt/venv/bin:/usr/local/share/npm-global/bin:/root/.claude/bin:${PATH}"

# 1. Install System Dependencies
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    wget \
    gnupg \
    lsb-release \
    build-essential \
    inotify-tools \
    postgresql-client \
    tree \
    htop \
    # Python dependencies
    python3 \
    python3-pip \
    python3-venv \
    python3-dev && \
    # Install Node.js 20 LTS (Required for Phoenix & Claude Code)
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Elixir package managers and Phoenix
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new 1.8.3 --force


# 5. Create Python virtual environment and install packages
RUN python3 -m venv $VIRTUAL_ENV && \
    pip3 install --no-cache-dir \
    jupyter \
    notebook \
    pymupdf \
    pandas \
    PyPDF2 \
    ipykernel

# 6. Install Claude Code
# Using npm -g is the most reliable way to ensure the binary is in the system PATH
RUN npm install -g @anthropic-ai/claude-code

# Set working directory (usually handled by docker-compose, but defined here for safety)
WORKDIR /workspace

CMD ["bash"]