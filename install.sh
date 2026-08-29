#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 终端环境一键配置脚本（增强版）
# 支持: macOS / Ubuntu / Debian / Arch / Fedora / WSL2
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR=""
FAILED_PACKAGES=()
SKIPPED_PACKAGES=()

# -------------------- 工具函数 --------------------

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}" >&2
}

ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 检测架构
get_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) echo "unsupported" ;;
    esac
}

# 检测网络连通性
check_network() {
    local url="$1"
    local name="$2"
    if curl -fsSL --max-time 10 "$url" >/dev/null 2>&1; then
        return 0
    else
        error "无法访问 $name ($url)，请检查网络或代理设置"
        return 1
    fi
}

# 检测 sudo 权限
have_sudo() {
    sudo -n true 2>/dev/null
}

# 检测是否在 WSL
is_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

# 检测发行版
get_distro() {
    # 优先读取 /etc/os-release 精确识别
    if [[ -f /etc/os-release ]]; then
        local id id_like
        id=$(source /etc/os-release && echo "$ID")
        id_like=$(source /etc/os-release && echo "$ID_LIKE" 2>/dev/null)
        
        case "$id" in
            ubuntu) echo "ubuntu"; return ;;
            debian) echo "debian"; return ;;
            arch|manjaro) echo "arch"; return ;;
            fedora|rhel|centos|rocky|almalinux) echo "fedora"; return ;;
            alpine) echo "alpine"; return ;;
        esac
        
        # fallback: ID_LIKE
        case "$id_like" in
            *ubuntu*) echo "ubuntu"; return ;;
            *debian*) echo "debian"; return ;;
            *arch*) echo "arch"; return ;;
            *fedora*|*rhel*) echo "fedora"; return ;;
        esac
    fi
    
    # 回退到包管理器检测
    if [[ "$OS" == "macos" ]]; then
        echo "macos"
    elif command -v apt &>/dev/null; then
        echo "debian"
    elif command -v pacman &>/dev/null; then
        echo "arch"
    elif command -v dnf &>/dev/null; then
        echo "fedora"
    elif command -v apk &>/dev/null; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

# -------------------- 主流程 --------------------

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  终端环境一键配置 (Fish + Zellij + ...)${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# === 前置检测 ===
echo -e "${YELLOW}--- 系统检测 ---${NC}"

OS=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    error "不支持的操作系统: $OSTYPE"
    exit 1
fi

ARCH=$(get_arch)
if [[ "$ARCH" == "unsupported" ]]; then
    error "不支持的架构: $(uname -m)，目前仅支持 x86_64 和 arm64"
    exit 1
fi

DISTRO=$(get_distro)

info "操作系统: $OS"
[[ "$OS" == "linux" ]] && info "发行版: $DISTRO"
info "架构: $ARCH"

if is_wsl; then
    info "检测到 WSL2 环境"
fi

# 检测网络
if ! check_network "https://github.com" "GitHub"; then
    warn "GitHub 访问失败，后续二进制下载可能受影响"
fi

# Linux 下检测 sudo
if [[ "$OS" == "linux" && "$DISTRO" != "unknown" ]]; then
    if ! have_sudo; then
        warn "当前用户无 sudo 权限，部分软件需手动安装"
    fi
fi

echo ""

# === 创建临时目录 ===
TMP_DIR=$(mktemp -d)

# === 安装 chezmoi ===
echo -e "${YELLOW}--- 步骤 1: 安装 chezmoi ---${NC}"

if command -v chezmoi &>/dev/null; then
    ok "chezmoi 已安装 ($(chezmoi --version | head -1))"
else
    if check_network "https://get.chezmoi.io" "chezmoi 安装源"; then
        echo "  正在安装 chezmoi..."
        mkdir -p "$HOME/.local/bin"
        if sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null 2>&1; then
            export PATH="$HOME/.local/bin:$PATH"
            ok "chezmoi 安装成功"
        else
            error "chezmoi 安装失败"
            FAILED_PACKAGES+=("chezmoi")
        fi
    else
        FAILED_PACKAGES+=("chezmoi")
    fi
fi
echo ""

# === 安装 Fish ===
echo -e "${YELLOW}--- 步骤 2: 安装 Fish Shell ---${NC}"

if command -v fish &>/dev/null; then
    ok "Fish 已安装 ($(fish --version | awk '{print $3}'))"
else
    case "$DISTRO" in
        macos)
            if command -v brew &>/dev/null; then
                brew install fish 2>/dev/null && ok "Fish 安装成功" || FAILED_PACKAGES+=("fish")
            else
                warn "未检测到 Homebrew，跳过 Fish 安装"
                SKIPPED_PACKAGES+=("fish")
            fi
            ;;
        debian)
            if have_sudo; then
                sudo apt-get update -qq >/dev/null 2>&1
                sudo apt-get install -y fish >/dev/null 2>&1 && ok "Fish 安装成功" || FAILED_PACKAGES+=("fish")
            else
                SKIPPED_PACKAGES+=("fish")
            fi
            ;;
        arch)
            if have_sudo; then
                sudo pacman -S --needed --noconfirm fish >/dev/null 2>&1 && ok "Fish 安装成功" || FAILED_PACKAGES+=("fish")
            else
                SKIPPED_PACKAGES+=("fish")
            fi
            ;;
        fedora)
            if have_sudo; then
                sudo dnf install -y fish >/dev/null 2>&1 && ok "Fish 安装成功" || FAILED_PACKAGES+=("fish")
            else
                SKIPPED_PACKAGES+=("fish")
            fi
            ;;
        *)
            SKIPPED_PACKAGES+=("fish")
            ;;
    esac
fi
echo ""

# === 安装 Zellij ===
echo -e "${YELLOW}--- 步骤 3: 安装 Zellij ---${NC}"

if command -v zellij &>/dev/null; then
    ok "Zellij 已安装 ($(zellij --version))"
else
    # 优先用包管理器，不行再下静态二进制
    INSTALLED=false
    case "$DISTRO" in
        macos)
            if command -v brew &>/dev/null; then
                brew install zellij 2>/dev/null && INSTALLED=true
            fi
            ;;
        arch)
            if have_sudo; then
                sudo pacman -S --needed --noconfirm zellij >/dev/null 2>&1 && INSTALLED=true
            fi
            ;;
    esac
    
    if [[ "$INSTALLED" == false ]]; then
        # 静态二进制安装
        info "从 GitHub 下载 Zellij 二进制..."
        
        zellij_arch="$ARCH"
        [[ "$ARCH" == "aarch64" && "$OS" == "macos" ]] && zellij_arch="aarch64"
        
        ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-${zellij_arch}-unknown-linux-musl.tar.gz"
        
        if [[ "$OS" == "macos" ]]; then
            ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-${zellij_arch}-apple-darwin.tar.gz"
        fi
        
        if curl -fsSL --max-time 60 "$ZELLIJ_URL" -o "$TMP_DIR/zellij.tar.gz" 2>/dev/null; then
            tar -xzf "$TMP_DIR/zellij.tar.gz" -C "$TMP_DIR" 2>/dev/null
            if [[ -x "$TMP_DIR/zellij" ]]; then
                if have_sudo; then
                    sudo mv "$TMP_DIR/zellij" /usr/local/bin/zellij
                    sudo chmod +x /usr/local/bin/zellij
                else
                    mkdir -p "$HOME/.local/bin"
                    mv "$TMP_DIR/zellij" "$HOME/.local/bin/zellij"
                    chmod +x "$HOME/.local/bin/zellij"
                    export PATH="$HOME/.local/bin:$PATH"
                fi
                ok "Zellij 安装成功"
                INSTALLED=true
            fi
        fi
    fi
    
    if [[ "$INSTALLED" == false ]]; then
        FAILED_PACKAGES+=("zellij")
    fi
fi
echo ""

# === 安装 Starship ===
echo -e "${YELLOW}--- 步骤 4: 安装 Starship ---${NC}"

if command -v starship &>/dev/null; then
    ok "Starship 已安装 ($(starship --version | head -1))"
else
    if check_network "https://starship.rs" "Starship"; then
        if curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1; then
            export PATH="$HOME/.local/bin:$PATH"
            ok "Starship 安装成功"
        else
            FAILED_PACKAGES+=("starship")
        fi
    else
        FAILED_PACKAGES+=("starship")
    fi
fi
# === 配置 Bash 的 Starship ===
# 即使 Fish 不是默认 shell，Bash 里也能看到 Starship 提示符
if command -v starship &>/dev/null; then
    if [[ -f "$HOME/.bashrc" ]] && ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        ok "Bash 已配置 Starship"
    fi
fi
echo ""

# === 安装 WezTerm ===
echo ""
echo -e "${YELLOW}--- 步骤 5: 安装 WezTerm ---${NC}"

if command -v wezterm &>/dev/null; then
    ok "WezTerm 已安装 ($(wezterm --version | head -1))"
else
    case "$DISTRO" in
        macos)
            if command -v brew &>/dev/null; then
                brew install --cask wezterm 2>/dev/null && ok "WezTerm 安装成功" || warn "WezTerm 安装失败，请手动从 https://wezfurlong.org/wezterm/installation.html 下载"
            else
                SKIPPED_PACKAGES+=("wezterm")
            fi
            ;;
        debian)
            if have_sudo && check_network "https://apt.fury.io" "WezTerm APT 源"; then
                echo "  添加 WezTerm APT 源..."
                curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg 2>/dev/null || true
                echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
                sudo apt-get update -qq >/dev/null 2>&1
                sudo apt-get install -y wezterm >/dev/null 2>&1 && ok "WezTerm 安装成功" || warn "WezTerm 安装失败"
            else
                SKIPPED_PACKAGES+=("wezterm")
            fi
            ;;
        arch)
            if have_sudo; then
                sudo pacman -S --needed --noconfirm wezterm >/dev/null 2>&1 && ok "WezTerm 安装成功" || warn "WezTerm 安装失败"
            else
                SKIPPED_PACKAGES+=("wezterm")
            fi
            ;;
        fedora)
            if have_sudo; then
                sudo dnf copr enable -y wezfurlong/wezterm-nightly 2>/dev/null || true
                sudo dnf install -y wezterm >/dev/null 2>&1 && ok "WezTerm 安装成功" || warn "WezTerm 安装失败"
            else
                SKIPPED_PACKAGES+=("wezterm")
            fi
            ;;
        *)
            SKIPPED_PACKAGES+=("wezterm")
            ;;
    esac
fi
echo ""

# === 备份现有配置 ===
echo -e "${YELLOW}--- 步骤 6: 备份现有配置 ---${NC}"

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

CONFIG_ITEMS=(
    "$HOME/.config/fish"
    "$HOME/.config/zellij"
    "$HOME/.config/wezterm"
    "$HOME/.config/starship.toml"
)

for item in "${CONFIG_ITEMS[@]}"; do
    if [[ -e "$item" ]]; then
        cp -rL "$item" "$BACKUP_DIR/" 2>/dev/null || true
        info "已备份: $(basename "$item")"
    fi
done

ok "备份完成 → $BACKUP_DIR"
echo ""

# === 应用 chezmoi 配置 ===
echo -e "${YELLOW}--- 步骤 7: 应用 dotfiles 配置 ---${NC}"

if command -v chezmoi &>/dev/null; then
    if chezmoi init --source="$SCRIPT_DIR" --apply 2>/dev/null; then
        ok "配置应用完成"
    else
        error "chezmoi apply 失败，请检查: chezmoi init --source=$SCRIPT_DIR --apply"
        exit 1
    fi
else
    error "chezmoi 不可用，无法应用配置"
    exit 1
fi
echo ""

# === 设置默认 Shell ===
echo -e "${YELLOW}--- 步骤 8: 设置默认 Shell ---${NC}"

FISH_PATH=""
for path in /opt/homebrew/bin/fish /usr/local/bin/fish /usr/bin/fish "$HOME/.linuxbrew/bin/fish"; do
    if [[ -x "$path" ]]; then
        FISH_PATH="$path"
        break
    fi
done

if [[ -z "$FISH_PATH" && -x "$HOME/.local/bin/fish" ]]; then
    FISH_PATH="$HOME/.local/bin/fish"
fi

if [[ -n "$FISH_PATH" ]]; then
    # 确保 fish 在 /etc/shells 中
    if ! grep -qx "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
    fi
    
    CURRENT_SHELL="$SHELL"
    if [[ "$CURRENT_SHELL" != "$FISH_PATH" ]]; then
        echo ""
        read -p "是否将 Fish 设为默认 Shell? [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if chsh -s "$FISH_PATH" 2>/dev/null; then
                ok "已设置 Fish 为默认 Shell，重新登录后生效"
            else
                warn "chsh 失败，请手动执行: chsh -s $FISH_PATH"
            fi
        else
            info "跳过（保持当前 Shell: $CURRENT_SHELL）"
            info "以后可随时执行: chsh -s $FISH_PATH"
        fi
    else
        ok "Fish 已是默认 Shell"
    fi
else
    warn "未找到 Fish 路径，跳过 Shell 设置"
fi
echo ""

# === 安装报告 ===
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}          安装报告                      ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if [[ ${#FAILED_PACKAGES[@]} -eq 0 && ${#SKIPPED_PACKAGES[@]} -eq 0 ]]; then
    echo -e "${GREEN}🎉 全部安装成功！${NC}"
else
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${RED}安装失败的包:${NC}"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo -e "  ${RED}  ✗ $pkg${NC}"
        done
        echo ""
    fi
    
    if [[ ${#SKIPPED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}跳过的包（需手动安装）:${NC}"
        for pkg in "${SKIPPED_PACKAGES[@]}"; do
            echo -e "  ${YELLOW}  ⊘ $pkg${NC}"
        done
        echo ""
    fi
    
    if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]]; then
        echo -e "${GREEN}核心配置已应用，部分软件需手动安装。${NC}"
    fi
fi

echo ""
echo "备份位置: $BACKUP_DIR"
echo ""
echo "下一步:"
echo "  1. 重新登录，或打开新终端"
echo "  2. 启动 WezTerm（从应用程序菜单）"
echo "  3. 输入 zellij 体验终端复用器"
echo ""
echo "常用命令:"
echo "  chezmoi diff       查看配置差异"
echo "  chezmoi edit       修改配置"
echo "  ./uninstall.sh     完全移除这套配置"
echo ""

if is_wsl; then
    echo -e "${YELLOW}[WSL2 提示] WezTerm 请在 Windows 端安装，配置会自动生效${NC}"
    echo ""
fi
