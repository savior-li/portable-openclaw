#!/bin/bash
#
# OpenClaw 一键安装与恢复脚本
# 纯 Bash TUI 菜单 (无需外部依赖)
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
UNDERLINE='\033[4m'
NC='\033[0m'
BLINK='\033[5m'

# Box drawing characters
BOX_TOP_LEFT="┌"
BOX_TOP_RIGHT="┐"
BOX_BOTTOM_LEFT="└"
BOX_BOTTOM_RIGHT="┘"
BOX_HORIZONTAL="─"
BOX_VERTICAL="│"

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

# 变量
API_KEY=""
API_URL=""
MODEL_NAME=""
CURRENT_MENU=""
SELECTED=0

# 日志
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() { log "${BLUE}[INFO]${NC} $1"; }
log_success() { log "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { log "${YELLOW}[WARN]${NC} $1"; }
log_error() { log "${RED}[ERROR]${NC} $1"; }

# 检查 root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本需要 root 权限${NC}"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 清除屏幕
clear_screen() {
    clear
}

# 打印居中标题
print_title() {
    local text="$1"
    local width=70
    local padding=$(( (width - ${#text} - 2) / 2 ))
    printf "${CYAN}%s%${width}s%s\n${NC}" "$BOX_TOP_LEFT" "" "$BOX_TOP_RIGHT"
    printf "${CYAN}%s${BOLD}%${padding}s%s%${padding}s${NC}%s\n" "$BOX_VERTICAL" "" "$text" "" "$BOX_VERTICAL"
    printf "${CYAN}%s%${width}s%s\n${NC}" "$BOX_BOTTOM_LEFT" "$BOX_HORIZONTAL" "$BOX_BOTTOM_RIGHT"
}

# 打印子标题
print_subtitle() {
    local text="$1"
    local width=70
    printf "${CYAN}%s${BOLD}${WHITE} %s ${NC}%s\n" "$BOX_VERTICAL" "$text" "$BOX_VERTICAL"
}

# 打印分隔线
print_divider() {
    local style="${1:-thin}"
    local width=70
    case $style in
        thick)
            printf "${CYAN}%s%s%s\n${NC}" "$BOX_TOP_LEFT" "$(printf '%.0s─' $(seq 1 $width))" "$BOX_TOP_RIGHT"
            ;;
        bottom)
            printf "${CYAN}%s%${width}s%s\n${NC}" "$BOX_BOTTOM_LEFT" "$(printf '%.0s─' $(seq 1 $width))" "$BOX_BOTTOM_RIGHT"
            ;;
        *)
            printf "${GRAY}%s%s%s\n${NC}" "├──" "$(printf '─%.0s' $(seq 1 66))" "┤"
            ;;
    esac
}

# 打印菜单项
print_menu_item() {
    local num="$1"
    local text="$2"
    local selected="$3"
    local width=68
    
    if [[ "$selected" == "true" ]]; then
        printf "${CYAN}%s ${BOLD}${GREEN}>${NC} ${WHITE}%s${NC}\n" "$BOX_VERTICAL" "$text"
    else
        printf "${CYAN}%s  ${GRAY}%s${NC} %s\n" "$BOX_VERTICAL" "$num" "$text"
    fi
}

# 打印箭头
print_arrow() {
    printf "${GREEN}  ►${NC}"
}

# 主菜单
show_main_menu() {
    CURRENT_MENU="main"
    SELECTED=1
    
    while true; do
        clear_screen
        
        echo
        print_title "OpenClaw 安装向导"
        echo
        print_subtitle "v2026.04.02 - 便携式 AI 网关"
        print_divider "bottom"
        echo
        
        local options=(
            "全新安装 OpenClaw"
            "从备份恢复数据"
            "仅手动备份"
            "查看当前状态"
            "安全与依赖管理"
            "完全卸载 OpenClaw"
        )
        
        local descriptions=(
            "安装新实例，配置 LLM Provider"
            "从 GitHub 备份恢复所有数据"
            "立即执行一次备份"
            "查看 OpenClaw 运行状态"
            "版本检查、更新、审计"
            "删除程序，保留备份数据"
        )
        
        for i in "${!options[@]}"; do
            local num=$((i + 1))
            local selected=""
            [[ $SELECTED -eq $num ]] && selected="true" || selected="false"
            printf "  ${GRAY}%s${NC}  %-20s ${DIM}| %s${NC}\n" "$num)" "${options[$i]}" "${descriptions[$i]}"
        done
        
        echo
        print_divider "bottom"
        echo
        printf "  ${GRAY}↑↓${NC} 选择  ${GRAY}Enter${NC} 确认  ${GRAY}q${NC} 退出\n"
        echo
        
        read -n1 key
        
        case $key in
            $'\e[A'|w) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;  # 上
            $'\e[B'|s) [[ $SELECTED -lt 6 ]] && ((SELECTED++)) ;;  # 下
            ''|$'\r')  # 回车
                case $SELECTED in
                    1) mode_install; break ;;
                    2) mode_restore; break ;;
                    3) mode_backup_only; break ;;
                    4) mode_status; break ;;
                    5) show_security_menu; break ;;
                    6) mode_uninstall; break ;;
                esac
                ;;
            q|Q) exit 0 ;;
        esac
    done
}

# 安全菜单
show_security_menu() {
    CURRENT_MENU="security"
    SELECTED=1
    
    while true; do
        clear_screen
        
        echo
        print_title "安全与依赖管理"
        echo
        print_subtitle "系统维护与安全审计"
        print_divider "bottom"
        echo
        
        local options=(
            "检查依赖版本"
            "更新 OpenClaw"
            "安全审计报告"
            "验证备份完整性"
            "查看备份日志"
            "重置 exec 权限"
            "返回主菜单"
        )
        
        for i in "${!options[@]}"; do
            local num=$((i + 1))
            local selected=""
            [[ $SELECTED -eq $num ]] && selected="true" || selected="false"
            printf "  ${GRAY}%s${NC}  %s\n" "$num)" "${options[$i]}"
        done
        
        echo
        print_divider "bottom"
        echo
        printf "  ${GRAY}↑↓${NC} 选择  ${GRAY}Enter${NC} 确认  ${GRAY}q${NC} 返回\n"
        echo
        
        read -n1 key
        
        case $key in
            $'\e[A'|w) [[ $SELECTED -gt 1 ]] && ((SELECTED--)) ;;
            $'\e[B'|s) [[ $SELECTED -lt 7 ]] && ((SELECTED++)) ;;
            ''|$'\r')
                case $SELECTED in
                    1) sec_check_versions; break ;;
                    2) sec_update; break ;;
                    3) sec_audit; break ;;
                    4) sec_verify_backup; break ;;
                    5) sec_view_logs; break ;;
                    6) sec_reset_exec; break ;;
                    7) show_main_menu; break ;;
                esac
                ;;
            q|Q) show_main_menu; break ;;
        esac
    done
}

# 暂停
pause() {
    echo
    printf "  ${GRAY}按 Enter 键继续...${NC}"
    read -n1
}

# 输入表单
input_form() {
    local title="$1"
    shift
    local fields=("$@")
    local values=()
    local selected=0
    
    while true; do
        clear_screen
        
        echo
        print_title "$title"
        echo
        
        for i in "${!fields[@]}"; do
            if [[ $selected -eq $i ]]; then
                printf "  ${GREEN}►${NC} ${WHITE}%s:${NC} ${BOLD}%s${NC}\n" "${fields[$i]}" "${values[$i]:-}"
            else
                printf "  ${GRAY} ○${NC} ${GRAY}%s:${NC} %s\n" "${fields[$i]}" "${values[$i]:-}"
            fi
        done
        
        echo
        print_divider "bottom"
        echo
        printf "  ${GRAY}↑↓${NC} 选择字段  ${GRAY}Enter${NC} 编辑  ${GRAY}s${NC} 保存  ${GRAY}q${NC} 取消\n"
        echo
        
        read -n1 key
        
        case $key in
            $'\e[A'|w) [[ $selected -gt 0 ]] && ((selected--)) ;;
            $'\e[B'|s) [[ $selected -lt $((${#fields[@]} - 1)) ]] && ((selected++)) ;;
            ''|$'\r')
                printf "  %s: " "${fields[$selected]}"
                read -r values[$selected]
                ;;
            s|S)
                echo "${values[@]}"
                return 0
                ;;
            q|Q) return 1 ;;
        esac
    done
}

# 确认对话框
confirm_dialog() {
    local message="$1"
    local selected=1
    
    while true; do
        clear_screen
        
        echo
        print_title "确认"
        echo
        printf "  ${WHITE}%s${NC}\n" "$message"
        echo
        
        if [[ $selected -eq 1 ]]; then
            printf "  ${GREEN}► 是${NC}    ${GRAY}否${NC}\n"
        else
            printf "  ${GRAY}是    ${RED}► 否${NC}\n"
        fi
        
        echo
        printf "  ${GRAY}←→${NC} 选择  ${GRAY}Enter${NC} 确认\n"
        echo
        
        read -n1 key
        
        case $key in
            $'\e[C'|l) selected=2 ;;
            $'\e[D'|h) selected=1 ;;
            ''|$'\r') [[ $selected -eq 1 ]] && return 0 || return 1 ;;
        esac
    done
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    apt-get update -qq
    apt-get install -y -qq curl git restic ca-certificates fuse > /dev/null 2>&1
    
    if ! command -v openclaw &> /dev/null; then
        log_info "安装 OpenClaw..."
        curl -fsSL https://openclaw.ai/install.sh | bash
    fi
    log_success "依赖安装完成"
}

# 全新安装
mode_install() {
    API_KEY="$DEFAULT_API_KEY"
    API_URL="$DEFAULT_API_URL"
    MODEL_NAME="$DEFAULT_MODEL"
    
    clear_screen
    echo
    print_title "API 配置"
    echo
    
    printf "  ${WHITE}请填写 LLM Provider 配置:${NC}\n\n"
    
    printf "  ${GRAY}API Key:${NC}\n  "
    printf "  > ${GREEN}%s${NC}\n" "${API_KEY:0:15}..."
    
    printf "\n  ${GRAY}API URL:${NC}\n  "
    printf "  > ${GREEN}%s${NC}\n" "$API_URL"
    
    printf "\n  ${GRAY}模型名称:${NC}\n  "
    printf "  > ${GREEN}%s${NC}\n" "$MODEL_NAME"
    
    echo
    if confirm_dialog "确认使用上述配置继续安装?"; then
        perform_install
    fi
}

# 执行安装
perform_install() {
    clear_screen
    echo
    print_title "正在安装 OpenClaw"
    echo
    
    echo -e "  ${BLUE}[1/7]${NC} 安装系统依赖..."
    install_dependencies
    
    echo -e "  ${BLUE}[2/7]${NC} 创建目录..."
    mkdir -p "$OPENCLAW_DATA" "$SCRIPT_DIR" "$BACKUP_DIR"
    
    echo -e "  ${BLUE}[3/7]${NC} 配置环境变量..."
    cat >> /etc/environment << EOF
MCAI_LLM_API_KEY=$API_KEY
MCAI_LLM_BASE_URL=$API_URL
EOF
    export MCAI_LLM_API_KEY="$API_KEY"
    export MCAI_LLM_BASE_URL="$API_URL"
    
    echo -e "  ${BLUE}[4/7]${NC} 创建 OpenClaw 配置..."
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
        "baseUrl": "$API_URL",
        "apiKey": "$API_KEY",
        "models": [{"id": "$MODEL_NAME", "name": "$MODEL_NAME"}]
      }
    }
  }
}
EOF
    
    echo -e "  ${BLUE}[5/7]${NC} 配置 exec 权限..."
    mkdir -p "$OPENCLAW_DATA"
    cat > "$OPENCLAW_DATA/exec-approvals.json" << 'EOF'
{
  "version": 1,
  "agents": {
    "main": {
      "allowlist": [{"pattern": "**", "lastUsedAt": 0}]
    }
  }
}
EOF
    openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1 || true
    
    echo -e "  ${BLUE}[6/7]${NC} 安装微信插件..."
    npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || true
    
    echo -e "  ${BLUE}[7/7]${NC} 配置备份..."
    configure_backup
    
    clear_screen
    echo
    print_title "安装完成!"
    echo
    printf "  ${GREEN}✓${NC} OpenClaw 已成功安装\n\n"
    printf "  ${WHITE}访问地址:${NC} ${CYAN}http://127.0.0.1:18789${NC}\n"
    printf "  ${WHITE}状态检查:${NC} ${CYAN}openclaw gateway status${NC}\n"
    echo
    pause
}

# 恢复模式
mode_restore() {
    clear_screen
    echo
    print_title "从备份恢复"
    echo
    
    echo -e "  ${BLUE}[1/6]${NC} 安装依赖..."
    install_dependencies
    
    echo -e "  ${BLUE}[2/6]${NC} 克隆备份..."
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR"
    [[ -d ".git" ]] && git pull origin main --rebase > /dev/null 2>&1 || git clone "$GITHUB_REPO" . > /dev/null 2>&1
    
    echo -e "  ${BLUE}[3/6]${NC} 恢复数据..."
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic restore latest --repo "$RESTIC_REPO" --target / > /dev/null 2>&1 || true
    
    echo -e "  ${BLUE}[4/6]${NC} 安装 OpenClaw..."
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
    
    echo -e "  ${BLUE}[5/6]${NC} 配置备份..."
    configure_backup
    
    echo -e "  ${BLUE}[6/6]${NC} 验证..."
    openclaw health > /dev/null 2>&1 && HEALTH="${GREEN}通过${NC}" || HEALTH="${RED}失败${NC}"
    
    clear_screen
    echo
    print_title "恢复完成!"
    echo
    printf "  ${GREEN}✓${NC} 数据已恢复\n\n"
    printf "  ${WHITE}健康检查:${NC} $HEALTH\n"
    printf "  ${WHITE}访问地址:${NC} ${CYAN}http://127.0.0.1:18789${NC}\n"
    echo
    pause
}

# 手动备份
mode_backup_only() {
    clear_screen
    echo
    print_title "手动备份"
    echo
    
    echo -e "  ${BLUE}正在执行备份...${NC}\n"
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    export RESTIC_REPO="/root/.openclaw-backups/restic"
    
    if restic backup /root/.openclaw --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --host "$(hostname)"; then
        echo
        echo -e "  ${GREEN}✓${NC} 备份成功"
    else
        echo
        echo -e "  ${RED}✗${NC} 备份失败"
    fi
    
    restic forget --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --keep-last 30 --prune > /dev/null 2>&1
    
    cd /root/.openclaw-backups
    git add .
    git commit -m "Manual backup $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1 || echo -e "  ${GRAY}无变更${NC}"
    git push > /dev/null 2>&1 || echo -e "  ${YELLOW}推送失败${NC}"
    
    echo
    pause
}

# 查看状态
mode_status() {
    clear_screen
    echo
    print_title "OpenClaw 状态"
    echo
    
    echo -e "  ${BOLD}[OpenClaw]${NC}"
    if command -v openclaw &> /dev/null; then
        printf "  %-15s ${GREEN}%s${NC}\n" "版本:" "$(openclaw --version 2>/dev/null | head -1)"
        openclaw gateway status 2>/dev/null | grep -E "RPC probe|Listening" | sed 's/^/  /'
    else
        printf "  %-15s ${RED}未安装${NC}\n" "状态:"
    fi
    
    echo
    echo -e "  ${BOLD}[备份状态]${NC}"
    if [[ -d "/root/.openclaw-backups/restic" ]]; then
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        COUNT=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | grep -c "openclaw" || echo "0")
        printf "  %-15s ${GREEN}%s${NC}\n" "快照数量:" "$COUNT"
    else
        printf "  %-15s ${YELLOW}未配置${NC}\n" "状态:"
    fi
    
    echo
    echo -e "  ${BOLD}[Cron 任务]${NC}"
    CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "backup-openclaw" || echo "0")
    [[ $CRON_COUNT -gt 0 ]] && printf "  %-15s ${GREEN}已配置${NC}\n" "状态:" || printf "  %-15s ${YELLOW}未配置${NC}\n" "状态:"
    
    echo
    echo -e "  ${BOLD}[访问地址]${NC}"
    printf "  ${CYAN}http://127.0.0.1:18789${NC}\n"
    echo
    pause
}

# 配置备份
configure_backup() {
    mkdir -p "$SCRIPT_DIR"
    
    cat > "$SCRIPT_DIR/backup-openclaw.sh" << 'BACKUP_SCRIPT'
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
BACKUP_SCRIPT
    
    chmod +x "$SCRIPT_DIR/backup-openclaw.sh"
    touch /var/log/openclaw-backup.log
    
    (crontab -l 2>/dev/null | grep -v "backup-openclaw"; echo "*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1") | crontab -
}

# 安全: 检查版本
sec_check_versions() {
    clear_screen
    echo
    print_title "依赖版本检查"
    echo
    
    command -v node &> /dev/null && printf "  %-15s ${GREEN}%s${NC}\n" "Node.js:" "$(node --version)"
    command -v npm &> /dev/null && printf "  %-15s ${GREEN}%s${NC}\n" "npm:" "$(npm --version)"
    command -v openclaw &> /dev/null && printf "  %-15s ${GREEN}%s${NC}\n" "OpenClaw:" "$(openclaw --version 2>/dev/null | head -1)"
    command -v restic &> /dev/null && printf "  %-15s ${GREEN}%s${NC}\n" "restic:" "$(restic version 2>/dev/null | head -1)"
    command -v git &> /dev/null && printf "  %-15s ${GREEN}%s${NC}\n" "Git:" "$(git --version)"
    
    echo
    pause
}

# 安全: 更新
sec_update() {
    clear_screen
    echo
    print_title "更新 OpenClaw"
    echo
    
    if confirm_dialog "确定要更新 OpenClaw 到最新版本吗?"; then
        echo -e "  ${BLUE}正在更新...${NC}"
        npm update -g openclaw@latest > /dev/null 2>&1
        echo
        echo -e "  ${GREEN}✓${NC} 更新完成"
        echo -e "  ${WHITE}新版本:${NC} $(openclaw --version 2>/dev/null | head -1)"
    fi
    
    echo
    pause
}

# 安全: 审计
sec_audit() {
    clear_screen
    echo
    print_title "安全审计报告"
    echo
    
    echo -e "  ${BOLD}[文件权限]${NC}"
    ls -la "$OPENCLAW_DATA/openclaw.json" 2>/dev/null | sed 's/^/  /'
    echo
    
    echo -e "  ${BOLD}[exec 权限配置]${NC}"
    cat "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null | sed 's/^/  /'
    echo
    
    echo -e "  ${BOLD}[环境变量]${NC}"
    grep -E "MCAI_LLM" /etc/environment 2>/dev/null | sed 's/^/  /' || echo "  ${GRAY}未设置${NC}"
    echo
    
    echo -e "  ${BOLD}[备份快照]${NC}"
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5 | sed 's/^/  /'
    echo
    
    pause
}

# 安全: 验证备份
sec_verify_backup() {
    clear_screen
    echo
    print_title "验证备份完整性"
    echo
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo -e "  ${BLUE}检查 restic 仓库...${NC}"
    if restic check --repo "$RESTIC_REPO" 2>&1 | grep -q "no errors"; then
        echo -e "  ${GREEN}✓${NC} 仓库完整"
    else
        echo -e "  ${RED}✗${NC} 发现错误"
    fi
    
    echo
    echo -e "  ${BLUE}快照列表:${NC}"
    restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5 | sed 's/^/  /'
    
    echo
    pause
}

# 安全: 查看日志
sec_view_logs() {
    clear_screen
    echo
    print_title "备份日志"
    echo
    
    if [[ -f /var/log/openclaw-backup.log ]]; then
        tail -20 /var/log/openclaw-backup.log | sed 's/^/  /'
    else
        echo -e "  ${GRAY}暂无日志${NC}"
    fi
    
    echo
    pause
}

# 安全: 重置 exec
sec_reset_exec() {
    clear_screen
    echo
    print_title "重置 exec 权限"
    echo
    
    if confirm_dialog "确定要重置 exec 权限为 ** (最高权限) 吗?"; then
        openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1
        echo
        echo -e "  ${GREEN}✓${NC} exec 权限已重置为 **"
    fi
    
    echo
    pause
}

# 完全卸载
mode_uninstall() {
    clear_screen
    echo
    print_title "卸载 OpenClaw"
    echo
    
    if confirm_dialog "警告: 此操作将删除程序和配置，但保留备份数据。确定继续?"; then
        echo -e "  ${RED}正在卸载...${NC}"
        
        pkill -f openclaw 2>/dev/null || true
        npm uninstall -g openclaw > /dev/null 2>&1 || true
        rm -rf "$OPENCLAW_DATA" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/backup-openclaw.sh" 2>/dev/null || true
        rm -f /var/log/openclaw-backup.log 2>/dev/null || true
        crontab -l 2>/dev/null | grep -v "backup-openclaw" | crontab - 2>/dev/null || true
        
        echo
        echo -e "  ${GREEN}✓${NC} 卸载完成"
        echo -e "  ${WHITE}备份数据保留在:${NC} $BACKUP_DIR"
    fi
    
    echo
    pause
}

# 静默模式
silent_mode() {
    log_info "执行静默安装..."
    API_KEY="$DEFAULT_API_KEY"
    API_URL="$DEFAULT_API_URL"
    MODEL_NAME="$DEFAULT_MODEL"
    perform_install
}

# 帮助
usage() {
    echo -e "${BOLD}OpenClaw 一键安装与恢复脚本${NC}"
    echo
    echo -e "${BOLD}用法:${NC}"
    echo -e "  $0              启动 TUI 菜单"
    echo -e "  $0 --silent     静默模式（使用默认配置）"
    echo -e "  $0 --help       显示帮助"
}

main() {
    check_root
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        --silent|-s) silent_mode ;;
        --help|-h) usage ;;
        *) show_main_menu ;;
    esac
}

main "$@"
