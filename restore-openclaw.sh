#!/bin/bash
#
# ═══════════════════════════════════════════════════════════════════
#   ____                _         _     ____            _
#  | __ ) _ __ __ _  ___| | __ _  | |_ |  _ \ _ __ ___| |_ ___
#  |  _ \| '__/ _` |/ __| |/ _` | | __|| |_) | '__/ _ \ __/ __|
#  | |_) | | | (_| | (__| | (_| | | |_ |  __/| | |  __/ |_\__ \
#  |____/|_|  \__,_|\___|_|\__,_|  \__||_|   |_|  \___|\__|___/
#
#   OpenClaw 一键安装与恢复脚本 v2026.04.02
#   纯 Bash TUI 菜单 (无需外部依赖)
# ═══════════════════════════════════════════════════════════════════
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# 颜色快捷函数
r() { echo -e "${RED}$1${NC}"; }
g() { echo -e "${GREEN}$1${NC}"; }
y() { echo -e "${YELLOW}$1${NC}"; }
b() { echo -e "${BLUE}$1${NC}"; }
c() { echo -e "${CYAN}$1${NC}"; }
w() { echo -e "${WHITE}$1${NC}"; }
d() { echo -e "${DIM}$1${NC}"; }

# 配置
GITHUB_REPO="https://github.com/savior-li/portable-openclaw.git"
BACKUP_DIR="/root/.openclaw-backups"
RESTIC_REPO="$BACKUP_DIR/restic"
OPENCLAW_DATA="/root/.openclaw"
SCRIPT_DIR="/opt/scripts"
LOG_FILE="/var/log/openclaw-restore.log"

# API 默认配置
DEFAULT_API_KEY="a7369912-cf56-41ed-885e-7e2582a87c43"
DEFAULT_API_URL="https://monkeycode-ai.com/v1"
DEFAULT_MODEL="minimax-m2.7"
DEFAULT_RESTIC_PASSWORD="735d591f6831"

# 全局变量
SELECTED=1
CURRENT_MENU=""

# 日志
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ═══════════════════════════════════════════════════════════════════
#  UI 组件
# ═══════════════════════════════════════════════════════════════════

# 清屏
cls() { clear; }

# ASCII Art Logo
print_logo() {
    cat << 'EOF'
${CYAN}
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   ${WHITE}  ____                _         _     ____            ${CYAN}║
    ║   ${WHITE} | __ ) _ __ __ _  ___| | __ _  | |_ |  _ \ _ __ ___| |_${CYAN}║
    ║   ${WHITE} |  _ \| '__/ _\` |/ __| |/ _\` | | __|| |_) | '__/ _ \ __|${CYAN}║
    ║   ${WHITE} | |_) | | | (_| | (__| | (_| | | |_ |  __/| | |  __/ |_${CYAN}║
    ║   ${WHITE} |____/|_|  \__,_|\___|_|\__,_|  \__||_|   |_|  \___|\__|${CYAN}║
    ║                                                           ║
    ║   ${DIM}~ Portable AI Gateway ~${CYAN}                                  ║
    ║   ${DIM}v2026.04.02${CYAN}                                               ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
}

# 打印分隔线
print_line() {
    echo -e "${CYAN}  ${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}${1:─<}${1:->}  ${NC}"
}

# 打印标题
print_header() {
    echo
    print_logo | sed -e "s/\${CYAN}/$CYAN/g" -e "s/\${WHITE}/$WHITE/g" -e "s/\${DIM}/$DIM/g"
    echo
}

# 打印选中项
print_opt() {
    local num="$1"
    local text="$2"
    local desc="$3"
    local n=$(($num))
    
    if [[ $SELECTED -eq $n ]]; then
        echo -e "  ${GREEN}●${NC} ${WHITE}${BOLD}$num. $text${NC}"
        [[ -n "$desc" ]] && echo -e "      ${DIM}$desc${NC}"
    else
        echo -e "  ${GRAY}○${NC} ${CYAN}$num.$NC $text"
        [[ -n "$desc" ]] && echo -e "      ${GRAY}$desc${NC}"
    fi
}

# 底部提示
print_footer() {
    echo
    print_line "="
    echo -e "  ${GRAY} [↑↓] 导航   [Enter] 选择   [Q] 退出   [R] 刷新${NC}"
    echo
}

# 暂停
pause() {
    echo
    echo -en "  ${GRAY}按 Enter 继续...${NC}"
    read -n1
}

# 确认对话框
confirm() {
    local msg="$1"
    echo
    print_line "-"
    echo -e "  ${WHITE}$msg${NC}"
    echo
    echo -ne "  ${GREEN}[Y]${NC} 是    ${RED}[N]${NC} 否"
    echo
    while read -n1 -s key; do
        [[ "$key" == "y" || "$key" == "Y" ]] && return 0
        [[ "$key" == "n" || "$key" == "N" || "$key" == "q" ]] && return 1
    done
}

# ═══════════════════════════════════════════════════════════════════
#  核心函数
# ═══════════════════════════════════════════════════════════════════

# 检查 root
check_root() {
    [[ $EUID -ne 0 ]] && {
        echo -e "${RED}错误: 此脚本需要 root 权限${NC}"
        echo "请使用: sudo $0"
        exit 1
    }
}

# 安装依赖
install_deps() {
    echo -e "  ${CYAN}▶ 安装系统依赖...${NC}"
    apt-get update -qq
    apt-get install -y -qq curl git restic ca-certificates fuse tmux > /dev/null 2>&1
    
    if ! command -v openclaw &> /dev/null; then
        echo -e "  ${CYAN}▶ 安装 OpenClaw...${NC}"
        curl -fsSL https://openclaw.ai/install.sh | bash
    fi
    echo -e "  ${GREEN}✓${NC} 依赖安装完成"
}

# ═══════════════════════════════════════════════════════════════════
#  菜单定义
# ═══════════════════════════════════════════════════════════════════

# 主菜单
show_main_menu() {
    CURRENT_MENU="main"
    SELECTED=1
    
    while true; do
        cls
        print_header
        
        echo -e "  ${BOLD}${WHITE}主菜单${NC}"
        print_line "-"
        echo
        
        print_opt 1 "全新安装 OpenClaw" "安装新实例，配置 LLM Provider"
        print_opt 2 "从备份恢复" "从 GitHub 备份恢复所有数据"
        print_opt 3 "手动备份" "立即执行一次备份"
        print_opt 4 "查看状态" "查看 OpenClaw 运行状态"
        print_opt 5 "Gateway 管理" "启动/停止/重启 Gateway"
        print_opt 6 "安全与维护" "版本检查、更新、审计"
        print_opt 7 "卸载" "删除程序，保留备份数据"
        
        print_footer
        
        read -n1 key
        case $key in
            $'\e[A'|[w]) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;
            $'\e[B'|[s]) [[ $SELECTED -lt 7 ]] && ((SELECTED++)) ;;
            ''|[ENTER])
                case $SELECTED in
                    1) show_install_menu; break ;;
                    2) do_restore; break ;;
                    3) do_backup; break ;;
                    4) show_status; break ;;
                    5) show_gateway_menu; break ;;
                    6) show_security_menu; break ;;
                    7) do_uninstall; break ;;
                esac
                ;;
            q|Q) exit 0 ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════
#  功能实现
# ═══════════════════════════════════════════════════════════════════

# Gateway 管理菜单
show_gateway_menu() {
    CURRENT_MENU="gateway"
    SELECTED=1
    
    while true; do
        cls
        print_header
        
        echo -e "  ${BOLD}${WHITE}Gateway 管理${NC}"
        print_line "-"
        echo
        
        # 检测状态
        local tmux_status="${GRAY}未运行${NC}"
        local process_status="${GRAY}未运行${NC}"
        
        tmux has-session -t openclaw 2>/dev/null && tmux_status="${GREEN}运行中${NC}"
        pgrep -f "openclaw gateway" > /dev/null && process_status="${YELLOW}运行中${NC}"
        
        print_opt 1 "启动 Gateway" "在 tmux 会话中启动 (后台运行)"
        print_opt 2 "停止 Gateway" "停止 tmux 会话"
        print_opt 3 "查看日志" "查看 Gateway 日志"
        print_opt 4 "重启 Gateway" "重启 Gateway 服务"
        
        echo
        echo -e "  ${WHITE}当前状态:${NC}"
        echo -e "    tmux 会话: $tmux_status"
        echo -e "    进程: $process_status"
        
        print_footer
        
        read -n1 key
        case $key in
            $'\e[A'|[w]) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;
            $'\e[B'|[s]) [[ $SELECTED -lt 4 ]] && ((SELECTED++)) ;;
            ''|[ENTER])
                case $SELECTED in
                    1) do_start_gateway; break ;;
                    2) do_stop_gateway; break ;;
                    3) show_gateway_log; break ;;
                    4) do_restart_gateway; break ;;
                esac
                ;;
            q|Q) show_main_menu; break ;;
        esac
    done
}

# 启动 Gateway
do_start_gateway() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}启动 Gateway${NC}"
    print_line "-"
    echo
    
    # 检查是否已运行
    if tmux has-session -t openclaw 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ tmux 会话 'openclaw' 已存在${NC}"
        if confirm "是否重新创建会话?"; then
            tmux kill-session -t openclaw 2>/dev/null
        else
            pause
            return
        fi
    fi
    
    echo -e "  ${CYAN}▶ 在 tmux 中启动 Gateway...${NC}"
    
    # 启动 tmux 会话
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    sleep 2
    
    if tmux has-session -t openclaw 2>/dev/null; then
        echo
        echo -e "  ${GREEN}✓ Gateway 启动成功!${NC}"
        echo
        echo -e "  ${WHITE}访问地址:${NC} ${CYAN}http://127.0.0.1:18789${NC}"
        echo -e "  ${WHITE}tmux 会话:${NC} ${CYAN}openclaw${NC}"
        echo
        echo -e "  ${WHITE}常用命令:${NC}"
        echo -e "    ${GRAY}tmux attach -t openclaw${NC}  ${DIM}- 进入会话${NC}"
        echo -e "    ${GRAY}Ctrl+b d${NC}            ${DIM}- 分离会话(后台运行)${NC}"
        echo -e "    ${GRAY}tmux kill-session -t openclaw${NC}  ${DIM}- 停止${NC}"
    else
        echo -e "  ${RED}✗ 启动失败${NC}"
    fi
    
    pause
}

# 停止 Gateway
do_stop_gateway() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}停止 Gateway${NC}"
    print_line "-"
    echo
    
    local stopped=false
    
    # 停止 tmux
    if tmux has-session -t openclaw 2>/dev/null; then
        echo -e "  ${CYAN}▶ 停止 tmux 会话...${NC}"
        tmux kill-session -t openclaw 2>/dev/null
        stopped=true
    fi
    
    # 停止进程
    if pgrep -f "openclaw gateway" > /dev/null; then
        echo -e "  ${CYAN}▶ 停止进程...${NC}"
        pkill -f "openclaw gateway"
        stopped=true
    fi
    
    echo
    $stopped && echo -e "  ${GREEN}✓ Gateway 已停止${NC}" || echo -e "  ${GRAY}Gateway 未运行${NC}"
    
    pause
}

# 重启 Gateway
do_restart_gateway() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}重启 Gateway${NC}"
    print_line "-"
    echo
    
    echo -e "  ${CYAN}▶ 重启中...${NC}"
    
    tmux kill-session -t openclaw 2>/dev/null || true
    pkill -f "openclaw gateway" 2>/dev/null || true
    
    sleep 1
    
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    sleep 2
    
    echo
    tmux has-session -t openclaw 2>/dev/null && echo -e "  ${GREEN}✓ Gateway 重启成功${NC}" || echo -e "  ${RED}✗ 重启失败${NC}"
    
    pause
}

# 查看 Gateway 日志
show_gateway_log() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}Gateway 日志${NC}"
    print_line "-"
    echo
    
    if [[ -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log ]]; then
        tail -30 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | sed 's/^/  /'
    elif tmux has-session -t openclaw 2>/dev/null; then
        echo -e "  ${CYAN}捕获 tmux 会话日志...${NC}"
        tmux capture-pane -t openclaw -p | tail -30 | sed 's/^/  /'
    else
        echo -e "  ${GRAY}暂无日志${NC}"
    fi
    
    pause
}

# 查看状态
show_status() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}OpenClaw 状态${NC}"
    print_line "-"
    echo
    
    # OpenClaw
    echo -e "  ${WHITE}OpenClaw:${NC}"
    if command -v openclaw &> /dev/null; then
        echo -e "    ${GREEN}✓${NC} 已安装  ${CYAN}$(openclaw --version 2>/dev/null | head -1)${NC}"
        
        if tmux has-session -t openclaw 2>/dev/null; then
            echo -e "    ${GREEN}✓${NC} Gateway: 运行中 (tmux)"
        elif pgrep -f "openclaw gateway" > /dev/null; then
            echo -e "    ${YELLOW}◑${NC} Gateway: 运行中 (进程)"
        else
            echo -e "    ${GRAY}○${NC} Gateway: 未运行"
        fi
    else
        echo -e "    ${RED}✗${NC} 未安装"
    fi
    
    echo
    
    # 备份状态
    echo -e "  ${WHITE}备份状态:${NC}"
    if [[ -d "$RESTIC_REPO" ]]; then
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        local count=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | grep -c "openclaw" || echo "0")
        echo -e "    ${GREEN}✓${NC} Restic 仓库: 已配置"
        echo -e "    ${CYAN}  快照数量:${NC} $count"
    else
        echo -e "    ${GRAY}○${NC} Restic 仓库: 未配置"
    fi
    
    echo
    
    # Cron
    echo -e "  ${WHITE}定时任务:${NC}"
    local cron_count=$(crontab -l 2>/dev/null | grep -c "backup-openclaw" || echo "0")
    if [[ $cron_count -gt 0 ]]; then
        echo -e "    ${GREEN}✓${NC} 自动备份: 已配置 (每10分钟)"
    else
        echo -e "    ${GRAY}○${NC} 自动备份: 未配置"
    fi
    
    echo
    
    # 依赖
    echo -e "  ${WHITE}依赖版本:${NC}"
    command -v node &> /dev/null && echo -e "    ${GREEN}✓${NC} Node.js: $(node --version)"
    command -v npm &> /dev/null && echo -e "    ${GREEN}✓${NC} npm: $(npm --version)"
    command -v restic &> /dev/null && echo -e "    ${GREEN}✓${NC} restic: $(restic version 2>/dev/null | head -1)"
    command -v git &> /dev/null && echo -e "    ${GREEN}✓${NC} Git: $(git --version | cut -d' ' -f3)"
    command -v tmux &> /dev/null && echo -e "    ${GREEN}✓${NC} tmux: $(tmux -V)"
    
    echo
    pause
}

# 安装菜单
show_install_menu() {
    CURRENT_MENU="install"
    SELECTED=1
    
    while true; do
        cls
        print_header
        
        echo -e "  ${BOLD}${WHITE}安装选项${NC}"
        print_line "-"
        echo
        
        print_opt 1 "快速安装 (默认配置)" "使用预设的 API 配置"
        print_opt 2 "自定义安装" "手动输入 API Key 和 URL"
        print_opt 3 "仅安装依赖" "不配置 OpenClaw"
        
        print_footer
        
        read -n1 key
        case $key in
            $'\e[A'|[w]) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;
            $'\e[B'|[s]) [[ $SELECTED -lt 3 ]] && ((SELECTED++)) ;;
            ''|[ENTER])
                case $SELECTED in
                    1) do_install_default; break ;;
                    2) do_install_custom; break ;;
                    3) do_install_deps_only; break ;;
                esac
                ;;
            q|Q) show_main_menu; break ;;
        esac
    done
}

# 快速安装
do_install_default() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}快速安装${NC}"
    print_line "-"
    echo
    
    echo -e "  ${CYAN}▶ 开始安装...${NC}"
    echo
    echo -e "  ${WHITE}使用配置:${NC}"
    echo -e "    API URL: ${CYAN}$DEFAULT_API_URL${NC}"
    echo -e "    Model:   ${CYAN}$DEFAULT_MODEL${NC}"
    echo
    
    install_deps
    
    echo -e "  ${CYAN}▶ 创建配置...${NC}"
    mkdir -p "$OPENCLAW_DATA"
    
    cat > "$OPENCLAW_DATA/openclaw.json" << EOF
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "allowedOrigins": ["*"]
    }
  },
  "models": {
    "providers": {
      "monkeycode-ai": {
        "baseUrl": "$DEFAULT_API_URL",
        "apiKey": "$DEFAULT_API_KEY",
        "models": [{"id": "$DEFAULT_MODEL", "name": "$DEFAULT_MODEL"}]
      }
    }
  }
}
EOF
    
    echo -e "  ${CYAN}▶ 配置 exec 权限...${NC}"
    openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1 || true
    
    echo -e "  ${CYAN}▶ 安装微信插件...${NC}"
    npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || true
    
    echo -e "  ${CYAN}▶ 配置备份...${NC}"
    setup_backup
    
    echo -e "  ${CYAN}▶ 启动 Gateway...${NC}"
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    echo
    print_line "="
    echo -e "  ${GREEN}${BOLD}✓ 安装完成!${NC}"
    echo -e "  ${WHITE}访问地址:${NC} ${CYAN}http://127.0.0.1:18789${NC}"
    print_line "="
    echo
    
    pause
}

# 自定义安装
do_install_custom() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}自定义安装${NC}"
    print_line "-"
    echo
    
    echo -en "  ${WHITE}API Key:${NC} "
    read -r api_key
    [[ -z "$api_key" ]] && api_key="$DEFAULT_API_KEY"
    
    echo -en "  ${WHITE}API URL:${NC} "
    read -r api_url
    [[ -z "$api_url" ]] && api_url="$DEFAULT_API_URL"
    
    echo -en "  ${WHITE}模型名称:${NC} "
    read -r model
    [[ -z "$model" ]] && model="$DEFAULT_MODEL"
    
    if confirm "确认使用上述配置?"; then
        install_deps
        
        mkdir -p "$OPENCLAW_DATA"
        
        cat > "$OPENCLAW_DATA/openclaw.json" << EOF
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "allowedOrigins": ["*"]
    }
  },
  "models": {
    "providers": {
      "custom": {
        "baseUrl": "$api_url",
        "apiKey": "$api_key",
        "models": [{"id": "$model", "name": "$model"}]
      }
    }
  }
}
EOF
        
        openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1 || true
        setup_backup
        
        tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$api_key'; export MCAI_LLM_BASE_URL='$api_url'; exec openclaw gateway"
        
        echo
        echo -e "  ${GREEN}✓ 安装完成!${NC}"
    fi
    
    pause
}

# 仅安装依赖
do_install_deps_only() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}安装依赖${NC}"
    print_line "-"
    echo
    
    install_deps
    
    echo
    echo -e "  ${GREEN}✓ 依赖安装完成${NC}"
    pause
}

# 恢复
do_restore() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}从备份恢复${NC}"
    print_line "-"
    echo
    
    echo -e "  ${CYAN}▶ 步骤 1/5: 安装依赖...${NC}"
    install_deps
    
    echo -e "  ${CYAN}▶ 步骤 2/5: 克隆备份...${NC}"
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR"
    [[ -d ".git" ]] && git pull origin main --rebase > /dev/null 2>&1 || git clone "$GITHUB_REPO" . > /dev/null 2>&1
    
    echo -e "  ${CYAN}▶ 步骤 3/5: 恢复数据...${NC}"
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic restore latest --repo "$RESTIC_REPO" --target / > /dev/null 2>&1 || echo -e "    ${YELLOW}跳过恢复${NC}"
    
    echo -e "  ${CYAN}▶ 步骤 4/5: 启动 Gateway...${NC}"
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    echo -e "  ${CYAN}▶ 步骤 5/5: 配置备份...${NC}"
    setup_backup
    
    echo
    print_line "="
    echo -e "  ${GREEN}${BOLD}✓ 恢复完成!${NC}"
    echo -e "  ${WHITE}访问地址:${NC} ${CYAN}http://127.0.0.1:18789${NC}"
    print_line "="
    echo
    
    pause
}

# 备份
do_backup() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}手动备份${NC}"
    print_line "-"
    echo
    
    echo -e "  ${CYAN}▶ 执行备份...${NC}"
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    if restic backup /root/.openclaw --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --host "$(hostname)"; then
        echo -e "  ${GREEN}✓${NC} 快照创建成功"
    else
        echo -e "  ${RED}✗${NC} 备份失败"
    fi
    
    restic forget --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --keep-last 30 --prune > /dev/null 2>&1
    
    cd "$BACKUP_DIR"
    git add .
    if ! git diff --cached --quiet; then
        git commit -m "Manual backup $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1
        git push > /dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} 已推送到 GitHub" || echo -e "  ${YELLOW}⚠${NC} 推送失败"
    else
        echo -e "  ${GRAY}○${NC} 无变更"
    fi
    
    echo
    pause
}

# 配置备份
setup_backup() {
    mkdir -p "$SCRIPT_DIR"
    
    cat > "$SCRIPT_DIR/backup-openclaw.sh" << 'SCRIPT'
#!/bin/bash
export RESTIC_PASSWORD="735d591f6831"
BACKUP_SOURCE="/root/.openclaw"
BACKUP_REPO="/root/.openclaw-backups/restic"
TAG="openclaw-auto-backup"
LOG_FILE="/var/log/openclaw-backup.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup..." >> "$LOG_FILE"

restic backup "$BACKUP_SOURCE" --repo "$BACKUP_REPO" --tag "$TAG" --host "$(hostname)" >> "$LOG_FILE" 2>&1
restic forget --repo "$BACKUP_REPO" --tag "$TAG" --keep-last 30 --prune >> "$LOG_FILE" 2>&1

cd /root/.openclaw-backups
git add .
if ! git diff --cached --quiet; then
    git commit -m "Backup $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1
    git push >> "$LOG_FILE" 2>&1 || echo "Push skipped" >> "$LOG_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed" >> "$LOG_FILE"
SCRIPT
    
    chmod +x "$SCRIPT_DIR/backup-openclaw.sh"
    touch /var/log/openclaw-backup.log
    
    (crontab -l 2>/dev/null | grep -v "backup-openclaw"; echo "*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1") | crontab -
}

# 安全菜单
show_security_menu() {
    CURRENT_MENU="security"
    SELECTED=1
    
    while true; do
        cls
        print_header
        
        echo -e "  ${BOLD}${WHITE}安全与维护${NC}"
        print_line "-"
        echo
        
        print_opt 1 "版本检查" "查看所有依赖版本"
        print_opt 2 "更新 OpenClaw" "更新到最新版本"
        print_opt 3 "安全审计" "检查配置和权限"
        print_opt 4 "验证备份" "测试备份可恢复性"
        print_opt 5 "查看日志" "查看备份日志"
        print_opt 6 "重置权限" "重置 exec 权限为 **"
        
        print_footer
        
        read -n1 key
        case $key in
            $'\e[A'|[w]) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;
            $'\e[B'|[s]) [[ $SELECTED -lt 6 ]] && ((SELECTED++)) ;;
            ''|[ENTER])
                case $SELECTED in
                    1) sec_versions; break ;;
                    2) sec_update; break ;;
                    3) sec_audit; break ;;
                    4) sec_verify; break ;;
                    5) sec_logs; break ;;
                    6) sec_reset_exec; break ;;
                esac
                ;;
            q|Q) show_main_menu; break ;;
        esac
    done
}

sec_versions() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}依赖版本${NC}"
    print_line "-"
    echo
    
    command -v node &> /dev/null && echo -e "  ${GREEN}✓${NC} Node.js: $(node --version)"
    command -v npm &> /dev/null && echo -e "  ${GREEN}✓${NC} npm: $(npm --version)"
    command -v openclaw &> /dev/null && echo -e "  ${GREEN}✓${NC} OpenClaw: $(openclaw --version 2>/dev/null | head -1)"
    command -v restic &> /dev/null && echo -e "  ${GREEN}✓${NC} restic: $(restic version 2>/dev/null | head -1)"
    command -v git &> /dev/null && echo -e "  ${GREEN}✓${NC} Git: $(git --version | cut -d' ' -f3)"
    command -v tmux &> /dev/null && echo -e "  ${GREEN}✓${NC} tmux: $(tmux -V)"
    
    echo
    pause
}

sec_update() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}更新 OpenClaw${NC}"
    print_line "-"
    echo
    
    if confirm "确定更新 OpenClaw 到最新版本?"; then
        echo -e "  ${CYAN}▶ 更新中...${NC}"
        npm update -g openclaw@latest > /dev/null 2>&1
        echo
        echo -e "  ${GREEN}✓${NC} 更新完成: $(openclaw --version 2>/dev/null | head -1)"
    fi
    
    pause
}

sec_audit() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}安全审计${NC}"
    print_line "-"
    echo
    
    echo -e "  ${WHITE}文件权限:${NC}"
    ls -la "$OPENCLAW_DATA/openclaw.json" 2>/dev/null | sed 's/^/    /' || echo -e "    ${GRAY}未找到${NC}"
    
    echo
    echo -e "  ${WHITE}exec 权限配置:${NC}"
    cat "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null | sed 's/^/    /' || echo -e "    ${GRAY}未找到${NC}"
    
    echo
    echo -e "  ${WHITE}环境变量:${NC}"
    grep "MCAI_LLM" /etc/environment 2>/dev/null | sed 's/^/    /' || echo -e "    ${GRAY}未设置${NC}"
    
    echo
    echo -e "  ${WHITE}备份快照:${NC}"
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5 | sed 's/^/    /' || echo -e "    ${GRAY}无快照${NC}"
    
    echo
    pause
}

sec_verify() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}验证备份${NC}"
    print_line "-"
    echo
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo -e "  ${CYAN}▶ 检查仓库...${NC}"
    if restic check --repo "$RESTIC_REPO" 2>&1 | grep -q "no errors"; then
        echo -e "  ${GREEN}✓${NC} 仓库完整"
    else
        echo -e "  ${RED}✗${NC} 发现错误"
    fi
    
    echo
    echo -e "  ${CYAN}▶ 快照列表:${NC}"
    restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5 | sed 's/^/    /'
    
    echo
    pause
}

sec_logs() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}备份日志${NC}"
    print_line "-"
    echo
    
    if [[ -f /var/log/openclaw-backup.log ]]; then
        tail -20 /var/log/openclaw-backup.log | sed 's/^/    /'
    else
        echo -e "  ${GRAY}暂无日志${NC}"
    fi
    
    echo
    pause
}

sec_reset_exec() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}重置 exec 权限${NC}"
    print_line "-"
    echo
    
    if confirm "确定重置 exec 权限为 ** (最高权限)?"; then
        openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1
        echo
        echo -e "  ${GREEN}✓${NC} exec 权限已重置为 **"
    fi
    
    pause
}

# 卸载
do_uninstall() {
    cls
    print_header
    echo -e "  ${BOLD}${WHITE}卸载 OpenClaw${NC}"
    print_line "-"
    echo
    
    if confirm "警告: 将删除程序和配置，保留备份数据。确定继续?"; then
        echo -e "  ${RED}▶ 卸载中...${NC}"
        
        tmux kill-session -t openclaw 2>/dev/null || true
        pkill -f openclaw 2>/dev/null || true
        npm uninstall -g openclaw > /dev/null 2>&1 || true
        rm -rf "$OPENCLAW_DATA" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/backup-openclaw.sh" 2>/dev/null || true
        rm -f /var/log/openclaw-backup.log 2>/dev/null || true
        crontab -l 2>/dev/null | grep -v "backup-openclaw" | crontab - 2>/dev/null || true
        
        echo
        echo -e "  ${GREEN}✓${NC} 卸载完成"
        echo -e "  ${WHITE}备份数据保留在:${NC} ${CYAN}$BACKUP_DIR${NC}"
    fi
    
    pause
}

# ═══════════════════════════════════════════════════════════════════
#  入口
# ═══════════════════════════════════════════════════════════════════

main() {
    check_root
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        --silent|-s)
            install_deps
            do_install_default
            ;;
        --help|-h)
            echo -e "${BOLD}OpenClaw 一键安装与恢复脚本${NC}"
            echo
            echo -e "用法: $0 [选项]"
            echo -e "  (无参数)   启动 TUI 菜单"
            echo -e "  --silent   静默安装(使用默认配置)"
            echo -e "  --help     显示帮助"
            ;;
        *)
            show_main_menu
            ;;
    esac
}

main "$@"
