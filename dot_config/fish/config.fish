# Fish 交互式 Shell 配置
# 定位：低侵入、开箱即用、配合 Zellij 使用

# ==================== 路径（必须在 Starship 之前）====================
fish_add_path $HOME/.local/bin
fish_add_path /opt/homebrew/bin

# ==================== 核心集成 ====================

# Starship 提示符
if command -v starship >/dev/null
    starship init fish | source
end

# Zellij 自动补全（如已安装）
if command -v zellij >/dev/null
    # 让 zellij 的补全文件被 fish 加载
    # zellij completions fish > ~/.config/fish/completions/zellij.fish
end

# ==================== 环境变量 ====================
set -gx EDITOR nano
set -gx VISUAL nano
set -gx LANG en_US.UTF-8

# ==================== 别名 ====================
# 文件操作
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 安全别名
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git 快捷
if command -v git >/dev/null
    alias g='git'
    alias gs='git status'
    alias gl='git log --oneline -10'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
end

# Zellij 快捷
if command -v zellij >/dev/null
    alias zj='zellij'
    alias za='zellij attach'
end

# ==================== SSH 自动 attach Zellij ====================
# 通过 SSH 登录时，自动进入 Zellij session
if status is-interactive
    and set -q SSH_CONNECTION
    and command -v zellij >/dev/null
    and not set -q ZELLIJ
    
    set -l SESSION_NAME "remote"
    
    if zellij list-sessions 2>/dev/null | grep -q "$SESSION_NAME"
        exec zellij attach "$SESSION_NAME"
    else
        exec zellij attach "$SESSION_NAME" --create
    end
end

# ==================== 欢迎语 ====================
function fish_greeting
    if not set -q SSH_CONNECTION
        echo ""
        echo "  🐟 Fish Shell Ready"
        echo "  $(uname -s) $(uname -r)"
        if command -v zellij >/dev/null; and not set -q ZELLIJ
            echo "  💡 提示: 输入 zellij 启动终端复用器"
        end
        echo ""
    end
end
