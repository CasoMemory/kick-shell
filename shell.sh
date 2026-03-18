#!/usr/bin/env bash
# ==============================================================================
# shell.sh - 向后兼容入口（已弃用，请使用 install.sh）
#
# 此文件保留是为了兼容旧的 curl 命令：
#   curl -o- https://raw.githubusercontent.com/CasoMemory/kick-shell/main/shell.sh | bash
#
# 推荐使用新的入口：
#   curl -o- https://raw.githubusercontent.com/CasoMemory/kick-shell/main/install.sh | bash
# ==============================================================================

echo "⚠️  shell.sh 已弃用，正在重定向到 install.sh..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

if [ -f "${SCRIPT_DIR}/install.sh" ]; then
    bash "${SCRIPT_DIR}/install.sh"
else
    # 如果是通过 curl 管道执行，直接下载新的 install.sh
    curl -o- https://raw.githubusercontent.com/CasoMemory/kick-shell/main/install.sh | bash
fi