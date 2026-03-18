#!/usr/bin/env bash
# ==============================================================================
# install.sh - Easy Install 入口文件
# 一键初始化前端/全栈开发环境 (macOS / CentOS)
#
# 使用方法:
#   curl -o- https://raw.githubusercontent.com/CasoMemory/kick-shell/main/install.sh | bash
#   或者:
#   git clone https://github.com/CasoMemory/kick-shell.git && cd kick-shell && bash install.sh
# ==============================================================================

set -e

# 获取脚本所在目录（支持 clone 和 curl 两种方式）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 如果是通过 curl 管道执行，需要先下载整个项目
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "检测到通过管道执行，正在下载完整脚本..."

    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/CasoMemory/kick-shell.git "$TEMP_DIR/kick-shell" 2>/dev/null

    if [ -f "$TEMP_DIR/kick-shell/lib/common.sh" ]; then
        SCRIPT_DIR="$TEMP_DIR/kick-shell"
    else
        echo "错误: 无法下载脚本文件，请使用 git clone 方式:"
        echo "  git clone https://github.com/CasoMemory/kick-shell.git && cd kick-shell && bash install.sh"
        exit 1
    fi

    # 清理临时目录（在脚本退出时）
    trap "rm -rf $TEMP_DIR" EXIT
fi

# 加载系统对应的安装脚本
SYS_TYPE=$(uname -s)

case "$SYS_TYPE" in
    Darwin)
        source "${SCRIPT_DIR}/lib/macos.sh"
        run_macos_install
        ;;
    Linux)
        # 检测是否是 CentOS / RHEL 系列
        if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
            source "${SCRIPT_DIR}/lib/centos.sh"
            run_centos_install
        else
            # 尝试从 os-release 文件判断
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    centos|rhel|fedora|rocky|alma)
                        source "${SCRIPT_DIR}/lib/centos.sh"
                        run_centos_install
                        ;;
                    *)
                        echo -e "\033[0;31m[✘]\033[0m 不支持的 Linux 发行版: $ID ($PRETTY_NAME)"
                        echo "    当前仅支持 CentOS / RHEL / Fedora / Rocky Linux / AlmaLinux"
                        exit 1
                        ;;
                esac
            else
                echo -e "\033[0;31m[✘]\033[0m 无法检测 Linux 发行版，当前仅支持 CentOS 系列"
                exit 1
            fi
        fi
        ;;
    *)
        echo -e "\033[0;31m[✘]\033[0m 不支持的操作系统: $SYS_TYPE"
        echo "    当前仅支持 macOS 和 CentOS"
        exit 1
        ;;
esac
