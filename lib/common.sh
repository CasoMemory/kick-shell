#!/usr/bin/env bash
# ==============================================================================
# common.sh - 公共函数库
# 提供日志输出、工具检测、通用安装函数等
# ==============================================================================

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---- 日志函数 ----
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✔]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[✘]${NC} $1"
}

log_step() {
    echo -e "\n${BOLD}${CYAN}==>${NC}${BOLD} $1${NC}"
}

# ---- 检测是否为交互式终端 ----
# 管道执行 (curl | bash) 时 stdin 不是终端，read 会失败
# 返回: 0 (交互式) 或 1 (非交互式/管道)
is_interactive() {
    [ -t 0 ] || [ -e /dev/tty ]
}

# 交互式 read 封装：优先从 /dev/tty 读取，非交互环境返回空
# 用法: interactive_read "prompt" variable_name
interactive_read() {
    local prompt="$1"
    local varname="$2"

    if [ -t 0 ]; then
        # stdin 是终端，直接读
        read -rp "$prompt" "$varname"
    elif [ -e /dev/tty ]; then
        # 管道模式但 /dev/tty 可用（如 curl | bash 在终端中执行）
        read -rp "$prompt" "$varname" < /dev/tty
    else
        # 完全非交互（如 CI 环境），返回空值
        eval "$varname=''"
        return 0
    fi
}

# ---- 检测工具是否已安装 ----
# 用法: is_installed "command_name"
# 返回: 0 (已安装) 或 1 (未安装)
is_installed() {
    command -v "$1" &>/dev/null
}

# ---- 安装前检测，已安装则跳过 ----
# 用法: check_and_skip "command_name" "display_name"
# 返回: 0 (已安装，应跳过) 或 1 (未安装，需要安装)
check_and_skip() {
    local cmd="$1"
    local name="${2:-$1}"
    if is_installed "$cmd"; then
        log_success "${name} 已安装，跳过 ($(command -v "$cmd"))"
        return 0
    fi
    return 1
}

# ---- 安装 nvm ----
install_nvm() {
    log_step "安装 nvm (Node Version Manager)"

    if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"
        if is_installed nvm; then
            log_success "nvm 已安装，跳过 ($(nvm --version))"
            return 0
        fi
    fi

    log_info "正在安装最新版 nvm..."
    # 获取最新版本号
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$latest_version" ]; then
        log_warn "无法获取 nvm 最新版本号，使用 v0.40.1"
        latest_version="v0.40.1"
    fi
    log_info "nvm 版本: ${latest_version}"

    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_version}/install.sh" | bash

    # 立即加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if is_installed nvm; then
        log_success "nvm 安装成功 ($(nvm --version))"
    else
        log_error "nvm 安装失败"
        return 1
    fi
}

# ---- 安装 Node.js LTS ----
install_node_lts() {
    log_step "安装 Node.js LTS"

    # 确保 nvm 已加载
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! is_installed nvm; then
        log_error "nvm 未安装，请先安装 nvm"
        return 1
    fi

    # 检查是否已有 LTS 版本
    if is_installed node; then
        local current_version
        current_version=$(node -v)
        log_success "Node.js 已安装 (${current_version})，跳过"
        return 0
    fi

    log_info "正在安装 Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    if is_installed node; then
        log_success "Node.js 安装成功 ($(node -v))"
    else
        log_error "Node.js 安装失败"
        return 1
    fi
}

# ---- 安装 pnpm ----
install_pnpm() {
    log_step "安装 pnpm"

    if check_and_skip "pnpm" "pnpm"; then
        return 0
    fi

    log_info "正在全局安装 pnpm..."
    npm install -g pnpm

    if is_installed pnpm; then
        log_success "pnpm 安装成功 ($(pnpm -v))"
    else
        log_error "pnpm 安装失败"
        return 1
    fi
}

# ---- 安装 yarn ----
install_yarn() {
    log_step "安装 yarn"

    if check_and_skip "yarn" "yarn"; then
        return 0
    fi

    log_info "正在全局安装 yarn..."
    npm install -g yarn

    if is_installed yarn; then
        log_success "yarn 安装成功 ($(yarn -v))"
    else
        log_error "yarn 安装失败"
        return 1
    fi
}

# ---- 安装 Oh My Zsh ----
install_omz() {
    log_step "安装 Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh 已安装，跳过"
        return 0
    fi

    log_info "正在安装 Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh 安装成功"
    else
        log_error "Oh My Zsh 安装失败"
        return 1
    fi
}

# ---- 安装 Zsh 插件 ----
install_zsh_plugins() {
    log_step "安装 Zsh 插件"

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        log_success "zsh-autosuggestions 已安装，跳过"
    else
        log_info "正在安装 zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "${zsh_custom}/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions 安装成功"
    fi

    # zsh-syntax-highlighting
    if [ -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        log_success "zsh-syntax-highlighting 已安装，跳过"
    else
        log_info "正在安装 zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "${zsh_custom}/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting 安装成功"
    fi
}

# ---- 配置 Git ----
configure_git() {
    log_step "配置 Git"

    local current_name
    local current_email
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        log_success "Git 已配置: ${current_name} <${current_email}>"
        interactive_read "$(echo -e "${YELLOW}是否要重新配置？(y/N): ${NC}")" reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    echo ""
    interactive_read "$(echo -e "${CYAN}请输入 Git 用户名: ${NC}")" git_name
    interactive_read "$(echo -e "${CYAN}请输入 Git 邮箱: ${NC}")" git_email

    if [ -n "$git_name" ]; then
        git config --global user.name "$git_name"
    fi
    if [ -n "$git_email" ]; then
        git config --global user.email "$git_email"
    fi

    # 设置一些推荐的 Git 全局配置
    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global pull.rebase true
    git config --global push.autoSetupRemote true
    git config --global core.editor "code --wait"

    log_success "Git 配置完成"
}

# ---- 配置 VS Code CLI ----
setup_vscode_cli() {
    log_step "配置 VS Code CLI (code 命令)"

    if is_installed code; then
        log_success "VS Code CLI 已配置，跳过 ($(command -v code))"
        return 0
    fi

    # macOS: VS Code 通常安装在 /Applications
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        local vscode_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
        if [ -d "$vscode_bin" ]; then
            log_info "检测到 VS Code，正在配置 code 命令..."
            # 将会在 .zshrc 中添加 PATH
            return 0
        fi
    fi

    log_warn "未检测到 VS Code 安装，请手动安装 VS Code 后，在 VS Code 中按 Cmd+Shift+P 搜索 'Shell Command: Install code command' 来配置"
    return 0
}

# ---- 安装 Docker CLI ----
install_docker() {
    log_step "安装 Docker CLI"

    if check_and_skip "docker" "Docker"; then
        return 0
    fi

    # 会在各系统的特定脚本中实现
    return 1
}

# ---- 写入 .zshrc 环境变量配置 ----
setup_zshrc() {
    log_step "配置 .zshrc 环境变量"

    local zshrc="$HOME/.zshrc"
    local marker="# >>> kick-shell managed >>>"
    local marker_end="# <<< kick-shell managed <<<"

    # 如果已存在配置块，先删除旧的
    if grep -q "$marker" "$zshrc" 2>/dev/null; then
        log_info "检测到旧的 kick-shell 配置，正在更新..."
        sed -i.bak "/$marker/,/$marker_end/d" "$zshrc"
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local template_file="${script_dir}/../configs/.zshrc.template"

    if [ -f "$template_file" ]; then
        log_info "正在写入环境变量配置到 ~/.zshrc..."
        cat "$template_file" >> "$zshrc"
    else
        log_info "正在写入环境变量配置到 ~/.zshrc..."
        cat >> "$zshrc" << 'ZSHRC_BLOCK'

# >>> kick-shell managed >>>
# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Homebrew (Linux)
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# VS Code CLI (macOS)
if [ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# <<< kick-shell managed <<<
ZSHRC_BLOCK
    fi

    # 更新 Oh My Zsh 插件列表
    if [ -f "$zshrc" ]; then
        if grep -q "^plugins=" "$zshrc"; then
            # 检查是否已经包含我们的插件
            if ! grep -q "zsh-autosuggestions" "$zshrc"; then
                log_info "正在更新 Oh My Zsh 插件列表..."
                sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc"
            fi
        fi
    fi

    log_success ".zshrc 配置完成"
}

# ---- 激活 .zshrc 配置 ----
activate_zshrc() {
    log_step "激活配置"

    if [ ! -f "$HOME/.zshrc" ]; then
        log_warn "未找到 ~/.zshrc，跳过"
        return 0
    fi

    log_info "配置已写入 ~/.zshrc，正在激活..."

    if is_installed zsh; then
        zsh -c "source ~/.zshrc" 2>/dev/null && \
            log_success "~/.zshrc 已通过 zsh 激活" || \
            log_warn "自动激活失败，请手动执行: source ~/.zshrc"
    else
        log_warn "Zsh 未安装，请手动执行: source ~/.zshrc"
    fi
}

# ---- 打印安装摘要 ----
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}============================================${NC}"
    echo -e "${BOLD}${GREEN}   🎉 开发环境初始化完成！${NC}"
    echo -e "${BOLD}${GREEN}============================================${NC}"
    echo ""

    echo -e "${BOLD}已安装的工具:${NC}"

    is_installed git && echo -e "  ${GREEN}✔${NC} Git $(git --version 2>/dev/null | awk '{print $3}')"
    is_installed brew && echo -e "  ${GREEN}✔${NC} Homebrew $(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
    [ -d "$HOME/.nvm" ] && echo -e "  ${GREEN}✔${NC} nvm $(source "$HOME/.nvm/nvm.sh" 2>/dev/null && nvm --version 2>/dev/null)"
    is_installed node && echo -e "  ${GREEN}✔${NC} Node.js $(node -v 2>/dev/null)"
    is_installed pnpm && echo -e "  ${GREEN}✔${NC} pnpm $(pnpm -v 2>/dev/null)"
    is_installed yarn && echo -e "  ${GREEN}✔${NC} yarn $(yarn -v 2>/dev/null)"
    [ -d "$HOME/.oh-my-zsh" ] && echo -e "  ${GREEN}✔${NC} Oh My Zsh"
    is_installed docker && echo -e "  ${GREEN}✔${NC} Docker $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
    is_installed code && echo -e "  ${GREEN}✔${NC} VS Code CLI"

    echo ""
    echo -e "${YELLOW}如果部分工具未生效，请重新打开终端或执行:${NC}"
    echo -e "  ${CYAN}source ~/.zshrc${NC}"
    echo ""
}
