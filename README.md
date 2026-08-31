# Dotfiles

基于 [chezmoi](https://www.chezmoi.io/) 管理的跨平台终端环境配置。

## 包含工具

| 工具 | 作用 |
|------|------|
| **Fish** | 交互式 Shell，自动补全/语法高亮开箱即用 |
| **Zellij** | 终端复用器（tmux 替代品），支持鼠标操作 |
| **WezTerm** | GPU 加速终端模拟器，跨平台配置统一 |
| **Starship** | 极简提示符，显示 Git 分支/状态/执行时间 |

## 快速开始

### 方式一：用 chezmoi 一键应用配置（推荐）

```bash
# 安装 chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 应用配置文件（fish/zellij/starship/wezterm 配置）
chezmoi init --apply https://github.com/Ellenp2p/dotfiles.git

# 安装 Fish / Zellij / Starship / WezTerm 等软件
cd ~/.local/share/chezmoi
bash install.sh
```

> chezmoi 只管理配置文件（dotfiles），不自动安装软件。`install.sh` 负责检测系统并安装 Fish、Zellij、Starship、WezTerm。

### 方式二：手动克隆 + 安装脚本

```bash
git clone https://github.com/Ellenp2p/dotfiles.git
cd dotfiles
bash install.sh
```

```bash
# 安装 chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 应用本仓库配置
chezmoi init --apply https://github.com/Ellenp2p/dotfiles.git
```

### 方式二：手动克隆 + 安装脚本

```bash
git clone https://github.com/Ellenp2p/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

## 系统要求

| 系统 | 要求 |
|------|------|
| macOS | macOS 11+，需安装 [Homebrew](https://brew.sh) |
| Ubuntu/Debian | 20.04+，`sudo` 权限 |
| Arch Linux | `sudo` 权限 |
| Fedora | `sudo` 权限 |
| WSL2 | Ubuntu 20.04+ 或其他支持发行版 |

## 使用方法

### 日常操作

```bash
# 启动 WezTerm（GUI 终端，需从应用程序菜单打开）

# 在 WezTerm 内启动 Zellij
zellij

# 或 attach 到已有会话
zellij attach
```

### SSH 自动 attach

通过 SSH 登录到已部署本配置的服务器时，Fish 会自动 attach 到 Zellij session，无需手动操作。

### 配置管理

```bash
# 查看当前配置与仓库的差异
chezmoi diff

# 编辑配置
chezmoi edit ~/.config/fish/config.fish

# 重新应用配置
chezmoi apply
```

## 容器测试（wslc / Docker）

在干净的容器里测试本配置，不影响主机环境。

### 使用 wslc（推荐 Windows 用户）

```powershell
# 一键测试：自动安装并进入交互式 Fish
wslc run -it --rm `
  -v "${env:USERPROFILE}\Documents\Kimi\Workspaces\工作环境\终端环境配置:/dotfiles" `
  ubuntu:latest bash /dotfiles/test-entry.sh
```

### 使用 Docker

```bash
# 一键测试
docker run -it --rm \
  -v "$(pwd):/dotfiles" \
  ubuntu:latest bash /dotfiles/test-entry.sh
```

### 手动测试（保留容器调试）

```powershell
# 1. 启动容器（不自动删除）
wslc run -it --name dotfiles-test `
  -v "${env:USERPROFILE}\Documents\Kimi\Workspaces\工作环境\终端环境配置:/dotfiles" `
  ubuntu:latest bash

# 2. 容器里手动执行
cd /dotfiles
bash install.sh
fish

# 3. 退出后清理
wslc container stop dotfiles-test
wslc container rm dotfiles-test
```

> **注意**：WezTerm 是 GUI 应用，容器内无法安装，会被自动跳过。其他核心组件（Fish、Zellij、Starship）会正常安装。

## 卸载

```bash
cd ~/.local/share/chezmoi
./uninstall.sh
```

原有配置备份在 `~/.dotfiles-backup-时间戳/`，可手动恢复。

## 字体建议

为了 Starship 的图标正常显示，建议安装 [Nerd Font](https://www.nerdfonts.com)（如 JetBrainsMono Nerd Font）。

未安装 Nerd Font 时，图标会显示为方块，但不影响功能。

## Windows + WSL2 说明

1. 在 Windows 上安装 WezTerm：`winget install wez.wezterm`
2. 在 WSL2 内部执行 `chezmoi init --apply ...` 或 `./install.sh`
3. WezTerm 可配置默认进入 WSL2（见 `dot_config/wezterm/wezterm.lua` 中的 WSL 配置注释）

## 仓库结构

```
.
├── dot_config/
│   ├── fish/
│   │   └── config.fish
│   ├── zellij/
│   │   └── config.kdl
│   ├── wezterm/
│   │   └── wezterm.lua
│   └── starship.toml
├── .chezmoiignore      # chezmoi 忽略文件
├── install.sh          # 辅助安装脚本
├── uninstall.sh        # 卸载脚本
└── README.md
```

## 许可证

MIT
