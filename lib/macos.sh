#!/usr/bin/env bash
# ==============================================================================
# macos.sh - macOS 专属安装逻辑
# ==============================================================================

# 获取当前脚本所在目录
MACOS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载公共函数
source "${MACOS_SCRIPT_DIR}/common.sh"

# ---- 安装 Xcode Command Line Tools ----
install_xcode_cli() {
    log_step "安装 Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        log_success "Xcode CLI Tools 已安装，跳过 ($(xcode-select -p))"
        return 0
    fi

    log_info "正在安装 Xcode Command Line Tools..."
    xcode-select --install

    # 等待用户完成安装
    log_warn "请在弹出窗口中点击「安装」，安装完成后按回车继续..."
    read -r

    if xcode-select -p &>/dev/null; then
        log_success "Xcode CLI Tools 安装成功"
    else
        log_error "Xcode CLI Tools 安装失败，请手动运行: xcode-select --install"
        return 1
    fi
}

# ---- 安装 Homebrew ----
install_homebrew_macos() {
    log_step "安装 Homebrew"

    if check_and_skip "brew" "Homebrew"; then
        return 0
    fi

    log_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon Mac 需要额外配置 PATH
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if is_installed brew; then
        log_success "Homebrew 安装成功 ($(brew --version | head -1))"
    else
        log_error "Homebrew 安装失败"
        return 1
    fi
}

# ---- 通过 Homebrew 安装 Git ----
install_git_macos() {
    log_step "安装 Git"

    if check_and_skip "git" "Git"; then
        return 0
    fi

    log_info "正在通过 Homebrew 安装 Git..."
    brew install git

    if is_installed git; then
        log_success "Git 安装成功 ($(git --version))"
    else
        log_error "Git 安装失败"
        return 1
    fi
}

# ---- 安装 Docker CLI (macOS) ----
install_docker_macos() {
    log_step "安装 Docker CLI"

    if check_and_skip "docker" "Docker"; then
        return 0
    fi

    if is_installed brew; then
        log_info "正在通过 Homebrew 安装 Docker CLI..."
        brew install docker

        if is_installed docker; then
            log_success "Docker CLI 安装成功 ($(docker --version))"
        else
            log_error "Docker CLI 安装失败"
            return 1
        fi
    else
        log_warn "Homebrew 未安装，无法自动安装 Docker CLI"
        log_warn "请手动安装 Docker Desktop: https://www.docker.com/products/docker-desktop/"
        return 1
    fi
}

# ---- macOS 安装主流程 ----
run_macos_install() {
    echo ""
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}   🍎 macOS 开发环境初始化${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo ""

    # 1. Xcode CLI Tools
    install_xcode_cli

    # 2. Homebrew
    install_homebrew_macos

    # 3. Git
    install_git_macos

    # 4. Git 配置
    configure_git

    # 5. Zsh (macOS 自带，无需安装)
    log_step "检查 Zsh"
    if is_installed zsh; then
        log_success "Zsh 已可用 ($(zsh --version))"
    fi

    # 6. Oh My Zsh
    install_omz

    # 7. Zsh 插件
    install_zsh_plugins

    # 8. nvm
    install_nvm

    # 9. Node.js LTS
    install_node_lts

    # 10. pnpm
    install_pnpm

    # 11. yarn
    install_yarn

    # 12. Docker CLI
    install_docker_macos

    # 13. VS Code CLI
    setup_vscode_cli

    # 14. 配置 .zshrc
    setup_zshrc

    # 15. source .zshrc
    log_step "激活配置"
    if [ -f "$HOME/.zshrc" ]; then
        # 在当前 bash 中 source zshrc 可能有 zsh 专用语法问题，这里只提示用户
        log_info "配置已写入 ~/.zshrc"
    fi

    # 打印摘要
    print_summary
}
