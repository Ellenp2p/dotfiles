#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Dotfiles 容器测试入口脚本
# 用于 wslc / Docker 中一键测试本仓库配置
# ============================================================

echo "========================================"
echo "  Dotfiles 容器测试"
echo "========================================"
echo ""

# 检测是否在容器内
if [[ ! -f /.dockerenv ]] && ! grep -qE '(docker|lxc|containerd|wslc)' /proc/1/cgroup 2>/dev/null; then
    echo "⚠ 警告: 未检测到容器环境，建议在隔离容器内运行此脚本"
    echo ""
fi

# 安装基础依赖
echo "[1/3] 安装基础工具 (curl, git, sudo)..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y curl git sudo
elif command -v pacman &>/dev/null; then
    pacman -Sy --needed --noconfirm curl git sudo
elif command -v dnf &>/dev/null; then
    dnf install -y curl git sudo
else
    echo "❌ 不支持的包管理器，请手动安装 curl, git, sudo"
    exit 1
fi

# 运行安装脚本
echo ""
echo "[2/3] 运行 install.sh..."
cd /dotfiles
bash install.sh

# 进入交互式 Fish
echo ""
echo "[3/3] 进入 Fish Shell，尽情体验..."
echo ""
echo "常用命令:"
echo "  fish --version     查看 Fish 版本"
echo "  zellij --version   查看 Zellij 版本"
echo "  starship --version 查看 Starship 版本"
echo "  zellij             启动终端复用器"
echo "  exit               退出 Fish"
echo ""

exec fish -l
