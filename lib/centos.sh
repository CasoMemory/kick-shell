#!/usr/bin/env bash
# ==============================================================================
# centos.sh - CentOS 专属安装逻辑
# ==============================================================================

# 获取当前脚本所在目录
CENTOS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载公共函数
source "${CENTOS_SCRIPT_DIR}/common.sh"

# ---- 检测包管理器 (yum/dnf) ----
get_pkg_manager() {
    if is_installed dnf; then
        echo "dnf"
    elif is_installed yum; then
        echo "yum"
    else
        log_error "未找到 yum 或 dnf 包管理器"
        exit 1
    fi
}

# ---- 安装基础依赖 ----
install_base_deps_centos() {
    log_step "安装基础依赖"

    local pkg_mgr
    pkg_mgr=$(get_pkg_manager)

    log_info "使用 ${pkg_mgr} 安装基础工具..."

    # 安装常用的构建工具和依赖
    local packages=("curl" "wget" "gcc" "gcc-c++" "make" "openssl-devel")

    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            log_success "${pkg} 已安装，跳过"
        else
            log_info "正在安装 ${pkg}..."
            sudo "$pkg_mgr" install -y "$pkg"
        fi
    done
}

# ---- 安装 Git (CentOS) ----
install_git_centos() {
    log_step "安装 Git"

    if check_and_skip "git" "Git"; then
        return 0
    fi

    local pkg_mgr
    pkg_mgr=$(get_pkg_manager)

    log_info "正在通过 ${pkg_mgr} 安装 Git..."
    sudo "$pkg_mgr" install -y git

    if is_installed git; then
        log_success "Git 安装成功 ($(git --version))"
    else
        log_error "Git 安装失败"
        return 1
    fi
}

# ---- 安装 sudo ----
install_sudo_centos() {
    if is_installed sudo; then
        return 0
    fi

    log_info "正在安装 sudo..."
    local pkg_mgr
    pkg_mgr=$(get_pkg_manager)
    "$pkg_mgr" install -y sudo
}

# ---- 安装 Zsh (CentOS) ----
install_zsh_centos() {
    log_step "安装 Zsh"

    if check_and_skip "zsh" "Zsh"; then
        return 0
    fi

    local pkg_mgr
    pkg_mgr=$(get_pkg_manager)

    log_info "正在通过 ${pkg_mgr} 安装 Zsh..."
    sudo "$pkg_mgr" install -y zsh

    # 安装 chsh (用于切换默认 shell)
    if ! is_installed chsh; then
        log_info "正在安装 util-linux-user (chsh)..."
        sudo "$pkg_mgr" install -y util-linux-user
    fi

    if is_installed zsh; then
        log_success "Zsh 安装成功 ($(zsh --version))"

        # 设置 zsh 为默认 shell
        log_info "正在将 Zsh 设置为默认 Shell..."
        if is_installed chsh; then
            sudo chsh -s "$(command -v zsh)" "$(whoami)" 2>/dev/null || true
            log_success "Zsh 已设置为默认 Shell (重新登录后生效)"
        else
            log_warn "chsh 不可用，请手动设置 Zsh 为默认 Shell"
        fi
    else
        log_error "Zsh 安装失败"
        return 1
    fi
}

# ---- 安装 Homebrew (Linuxbrew) ----
install_homebrew_centos() {
    log_step "安装 Homebrew (Linuxbrew)"

    if check_and_skip "brew" "Homebrew"; then
        return 0
    fi

    log_info "正在安装 Linuxbrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置 Linuxbrew 环境
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    if is_installed brew; then
        log_success "Homebrew (Linuxbrew) 安装成功 ($(brew --version | head -1))"
    else
        log_warn "Homebrew (Linuxbrew) 安装失败，跳过（非关键依赖）"
        return 1
    fi
}

# ---- 安装 Docker CLI (CentOS) ----
install_docker_centos() {
    log_step "安装 Docker CLI"

    if check_and_skip "docker" "Docker"; then
        return 0
    fi

    local pkg_mgr
    pkg_mgr=$(get_pkg_manager)

    log_info "正在添加 Docker 官方 yum 仓库..."
    sudo "$pkg_mgr" install -y yum-utils 2>/dev/null || true
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || true

    log_info "正在安装 Docker CLI..."
    sudo "$pkg_mgr" install -y docker-ce-cli

    if is_installed docker; then
        log_success "Docker CLI 安装成功 ($(docker --version))"
    else
        log_error "Docker CLI 安装失败"
        log_warn "可以稍后手动安装: https://docs.docker.com/engine/install/centos/"
        return 1
    fi
}

# ---- 配置 VS Code CLI (CentOS) ----
setup_vscode_cli_centos() {
    log_step "配置 VS Code CLI (code 命令)"

    if is_installed code; then
        log_success "VS Code CLI 已配置，跳过 ($(command -v code))"
        return 0
    fi

    # 检查 VS Code 是否通过 snap 或 rpm 安装
    if [ -f "/usr/bin/code" ] || [ -f "/usr/share/code/bin/code" ]; then
        log_success "VS Code CLI 已可用"
        return 0
    fi

    log_warn "未检测到 VS Code 安装。"
    log_info "如需安装 VS Code，可参考: https://code.visualstudio.com/docs/setup/linux"
    return 0
}

# ---- CentOS 安装主流程 ----
run_centos_install() {
    echo ""
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}   🐧 CentOS 开发环境初始化${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo ""

    # 1. sudo
    install_sudo_centos

    # 2. 基础依赖
    install_base_deps_centos

    # 3. Git
    install_git_centos

    # 4. Git 配置
    configure_git

    # 5. Zsh
    install_zsh_centos

    # 6. Oh My Zsh
    install_omz

    # 7. Zsh 插件
    install_zsh_plugins

    # 8. Homebrew (Linuxbrew) - 非关键，失败不阻塞
    install_homebrew_centos || true

    # 9. nvm
    install_nvm

    # 10. Node.js LTS
    install_node_lts

    # 11. pnpm
    install_pnpm

    # 12. yarn
    install_yarn

    # 13. Docker CLI
    install_docker_centos

    # 14. VS Code CLI
    setup_vscode_cli_centos

    # 15. 配置 .zshrc
    setup_zshrc

    # 16. 激活配置
    log_step "激活配置"
    if [ -f "$HOME/.zshrc" ]; then
        log_info "配置已写入 ~/.zshrc"
    fi

    # 打印摘要
    print_summary
}
