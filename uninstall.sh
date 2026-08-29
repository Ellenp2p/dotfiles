#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  移除终端环境配置${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "这将使用 chezmoi destroy 移除所有由本工具管理的配置文件。"
echo ""
read -p "确定继续? [y/N]: " -n 1 -r

echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

if command -v chezmoi &>/dev/null; then
    echo ""
    echo -e "${YELLOW}执行 chezmoi destroy...${NC}"
    chezmoi destroy || true
    echo -e "${GREEN}配置已移除${NC}"
else
    echo -e "${YELLOW}未检测到 chezmoi，尝试手动清理...${NC}"
    rm -rf "$HOME/.config/fish" "$HOME/.config/zellij" "$HOME/.config/wezterm" "$HOME/.config/starship.toml" 2>/dev/null || true
    echo -e "${GREEN}已清理配置文件${NC}"
fi

echo ""
echo -e "${YELLOW}是否恢复默认 Shell 为 Bash?${NC}"
read -p "[y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if grep -qx "/bin/bash" /etc/shells 2>/dev/null; then
        chsh -s /bin/bash
        echo -e "${GREEN}已恢复默认 Shell 为 Bash，重新登录后生效${NC}"
    elif grep -qx "/usr/bin/bash" /etc/shells 2>/dev/null; then
        chsh -s /usr/bin/bash
        echo -e "${GREEN}已恢复默认 Shell 为 Bash，重新登录后生效${NC}"
    fi
fi

echo ""
echo -e "${GREEN}完成。${NC}"
