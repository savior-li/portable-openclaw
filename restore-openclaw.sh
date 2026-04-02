#!/bin/bash
#
# OpenClaw 一键安装与恢复脚本
# 支持 TUI 向导弹导模式和静默模式
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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
RESTIC_PASSWORD=""

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

# 检查并安装 dialog
check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo -e "${YELLOW}[INFO] 安装 dialog...${NC}"
        apt-get update -qq
        apt-get install -y -qq dialog > /dev/null 2>&1
    fi
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    apt-get update -qq
    apt-get install -y -qq dialog curl git restic ca-certificates fuse > /dev/null 2>&1
    
    if ! command -v openclaw &> /dev/null; then
        log_info "安装 OpenClaw..."
        curl -fsSL https://openclaw.ai/install.sh | bash
    fi
    log_success "依赖安装完成"
}

# TUI 向导
tui_wizard() {
    check_dialog
    clear
    
    dialog --backtitle "OpenClaw 安装向导" \
           --title "欢迎" \
           --msgbox "欢迎使用 OpenClaw 一键安装与恢复脚本\n\n此向导将帮助您:\n  • 安装或恢复 OpenClaw\n  • 配置 LLM Provider\n  • 设置自动备份\n\n按任意键继续..." 15 55
    
    CHOICE=$(dialog --backtitle "OpenClaw 安装向导" \
                   --title "选择操作" \
                   --radiolist "请选择要执行的操作:" 17 55 6 \
                   1 "全新安装 OpenClaw" on \
                   2 "从备份恢复数据" off \
                   3 "仅手动备份" off \
                   4 "查看当前状态" off \
                   5 "安全与依赖管理" off \
                   6 "完全卸载 OpenClaw" off \
                   3>&1 1>&2 2>&3)
    
    case $CHOICE in
        1) mode_install ;;
        2) mode_restore ;;
        3) mode_backup_only ;;
        4) mode_status ;;
        5) mode_security ;;
        6) mode_uninstall ;;
        *) exit 0 ;;
    esac
}

# 全新安装
mode_install() {
    API_RESULT=$(dialog --backtitle "OpenClaw 安装向导" \
                       --title "API 配置" \
                       --form "请填写 LLM Provider 配置:" 15 60 5 \
                       "API Key:" 1 1 "$DEFAULT_API_KEY" 1 25 40 100 \
                       "API URL:" 2 1 "$DEFAULT_API_URL" 2 25 40 100 \
                       "模型名称:" 3 1 "$DEFAULT_MODEL" 3 25 40 100 \
                       3>&1 1>&2 2>&3)
    
    [[ -z "$API_RESULT" ]] && exit 0
    
    API_KEY=$(echo "$API_RESULT" | sed -n '1p')
    API_URL=$(echo "$API_RESULT" | sed -n '2p')
    MODEL_NAME=$(echo "$API_RESULT" | sed -n '3p')
    
    dialog --backtitle "OpenClaw 安装向导" \
           --title "确认配置" \
           --yesno "配置信息:\n\nAPI Key: ${API_KEY:0:10}...\nAPI URL: $API_URL\n模型: $MODEL_NAME\n\n确认继续安装?" 12 55
    
    [[ $? -ne 0 ]] && mode_install
    
    perform_install
}

# 执行安装
perform_install() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}正在安装 OpenClaw...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${BLUE}[1/7]${NC} 安装系统依赖..."
    install_dependencies
    
    echo -e "${BLUE}[2/7]${NC} 创建目录..."
    mkdir -p "$OPENCLAW_DATA" "$SCRIPT_DIR" "$BACKUP_DIR"
    
    echo -e "${BLUE}[3/7]${NC} 配置环境变量..."
    cat >> /etc/environment << EOF
MCAI_LLM_API_KEY=$API_KEY
MCAI_LLM_BASE_URL=$API_URL
EOF
    export MCAI_LLM_API_KEY="$API_KEY"
    export MCAI_LLM_BASE_URL="$API_URL"
    
    echo -e "${BLUE}[4/7]${NC} 创建 OpenClaw 配置..."
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
    
    echo -e "${BLUE}[5/7]${NC} 配置 exec 权限..."
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
    
    echo -e "${BLUE}[6/7]${NC} 安装微信插件..."
    npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || true
    
    echo -e "${BLUE}[7/7]${NC} 配置备份..."
    configure_backup
    
    clear
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    安装完成!                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "  Control UI: ${CYAN}http://127.0.0.1:18789${NC}"
    echo -e "  状态检查:   ${CYAN}openclaw gateway status${NC}"
    echo
    read -p "按 Enter 键退出..."
}

# 恢复模式
mode_restore() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}正在从备份恢复...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${BLUE}[1/6]${NC} 安装依赖..."
    install_dependencies
    
    echo -e "${BLUE}[2/6]${NC} 克隆备份..."
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR"
    [[ -d ".git" ]] && git pull origin main --rebase > /dev/null 2>&1 || git clone "$GITHUB_REPO" . > /dev/null 2>&1
    
    echo -e "${BLUE}[3/6]${NC} 恢复数据..."
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic restore latest --repo "$RESTIC_REPO" --target / > /dev/null 2>&1 || true
    
    echo -e "${BLUE}[4/6]${NC} 安装 OpenClaw..."
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
    
    echo -e "${BLUE}[5/6]${NC} 配置备份..."
    configure_backup
    
    echo -e "${BLUE}[6/6]${NC} 验证..."
    openclaw health > /dev/null 2>&1 && HEALTH="${GREEN}通过${NC}" || HEALTH="${RED}失败${NC}"
    
    clear
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    恢复完成!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "  健康检查: $HEALTH"
    echo -e "  Gateway: ${CYAN}http://127.0.0.1:18789${NC}"
    echo
    read -p "按 Enter 键退出..."
}

# 手动备份
mode_backup_only() {
    clear
    echo -e "${CYAN}正在执行手动备份...${NC}"
    echo
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    export RESTIC_REPO="/root/.openclaw-backups/restic"
    
    restic backup /root/.openclaw --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --host "$(hostname)"
    restic forget --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --keep-last 30 --prune
    
    cd /root/.openclaw-backups
    git add .
    git commit -m "Manual backup $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1 || echo "无变更"
    git push > /dev/null 2>&1 || log_warn "推送失败"
    
    log_success "备份完成!"
    read -p "按 Enter 键退出..."
}

# 查看状态
mode_status() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    OpenClaw 状态${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${BOLD}[OpenClaw]${NC}"
    if command -v openclaw &> /dev/null; then
        echo -e "  版本: ${GREEN}$(openclaw --version 2>/dev/null | head -1)${NC}"
        openclaw gateway status 2>/dev/null | grep -E "RPC probe|Listening" | sed 's/^/  /'
    else
        echo -e "  ${RED}未安装${NC}"
    fi
    
    echo
    echo -e "${BOLD}[备份状态]${NC}"
    if [[ -d "/root/.openclaw-backups/restic" ]]; then
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        COUNT=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | grep -c "openclaw" || echo "0")
        echo -e "  快照数量: ${GREEN}$COUNT${NC}"
    else
        echo -e "  ${YELLOW}未配置${NC}"
    fi
    
    echo
    echo -e "${BOLD}[Cron 任务]${NC}"
    CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "backup-openclaw" || echo "0")
    [[ $CRON_COUNT -gt 0 ]] && echo -e "  状态: ${GREEN}已配置${NC}" || echo -e "  状态: ${YELLOW}未配置${NC}"
    
    echo
    echo -e "${BOLD}[访问地址]${NC}"
    echo -e "  Control UI: ${CYAN}http://127.0.0.1:18789${NC}"
    echo
    read -p "按 Enter 键继续..."
}

# 安全与依赖管理
mode_security() {
    check_dialog
    clear
    
    SEC_CHOICE=$(dialog --backtitle "OpenClaw 安全管理" \
                       --title "安全与依赖管理" \
                       --radiolist "请选择操作:" 17 60 7 \
                       1 "检查依赖版本" on \
                       2 "更新 OpenClaw" off \
                       3 "安全审计" off \
                       4 "验证备份完整性" off \
                       5 "查看安全日志" off \
                       6 "重置 exec 权限" off \
                       7 "返回上级菜单" off \
                       3>&1 1>&2 2>&3)
    
    case $SEC_CHOICE in
        1) sec_check_versions ;;
        2) sec_update ;;
        3) sec_audit ;;
        4) sec_verify_backup ;;
        5) sec_view_logs ;;
        6) sec_reset_exec ;;
        7) tui_wizard ;;
    esac
}

# 安全: 检查版本
sec_check_versions() {
    check_dialog
    clear
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    依赖版本检查${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    ITEMS=()
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VER=$(node --version)
        ITEMS+=("Node.js" "$NODE_VER" "on")
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        NPM_VER=$(npm --version)
        ITEMS+=("npm" "v$NPM_VER" "on")
    fi
    
    # OpenClaw
    if command -v openclaw &> /dev/null; then
        OC_VER=$(openclaw --version 2>/dev/null | head -1)
        ITEMS+=("OpenClaw" "$OC_VER" "on")
    fi
    
    # Restic
    if command -v restic &> /dev/null; then
        RESTIC_VER=$(restic version 2>/dev/null | head -1)
        ITEMS+=("restic" "$RESTIC_VER" "on")
    fi
    
    # Git
    if command -v git &> /dev/null; then
        GIT_VER=$(git --version)
        ITEMS+=("Git" "$GIT_VER" "on")
    fi
    
    # Dialog
    if command -v dialog &> /dev/null; then
        DIALOG_VER=$(dialog --version 2>&1 | head -1)
        ITEMS+=("dialog" "$DIALOG_VER" "on")
    fi
    
    dialog --title "依赖版本" \
           --msgbox "当前已安装的依赖版本:\n\n$(for i in $(seq 0 2 $(( ${#ITEMS[@]} - 1 ))); do echo "  • ${ITEMS[$i]}: ${ITEMS[$((i+1))]}"; done)\n\n按任意键返回..." 15 50
    
    mode_security
}

# 安全: 更新
sec_update() {
    check_dialog
    clear
    
    dialog --title "更新 OpenClaw" \
           --yesno "确定要更新 OpenClaw 到最新版本吗?\n\n当前版本将保留备份。" 10 50
    
    [[ $? -ne 0 ]] && mode_security
    
    echo -e "${CYAN}正在更新 OpenClaw...${NC}"
    
    if command -v openclaw &> /dev/null; then
        npm update -g openclaw@latest > /dev/null 2>&1
        NEW_VER=$(openclaw --version 2>/dev/null | head -1)
        dialog --title "更新完成" \
               --msgbox "OpenClaw 已更新到最新版本:\n\n$NEW_VER\n\n按任意键返回..." 10 50
    else
        curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
        dialog --title "安装完成" \
               --msgbox "OpenClaw 已安装:\n\n$(openclaw --version 2>/dev/null | head -1)" 10 50
    fi
    
    mode_security
}

# 安全: 审计
sec_audit() {
    check_dialog
    clear
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    安全审计${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    AUDIT_OUTPUT="/tmp/openclaw-audit-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "OpenClaw 安全审计报告"
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================"
        echo
        
        echo "[1] 文件权限检查"
        echo "------------------------"
        ls -la "$OPENCLAW_DATA/openclaw.json" 2>/dev/null || echo "配置文件不存在"
        ls -la "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null || echo "权限配置文件不存在"
        echo
        
        echo "[2] exec 权限配置"
        echo "------------------------"
        cat "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null || echo "权限配置不存在"
        echo
        
        echo "[3] 环境变量检查"
        echo "------------------------"
        grep -E "MCAI_LLM_API_KEY|MCAI_LLM_BASE_URL" /etc/environment 2>/dev/null || echo "未设置相关环境变量"
        echo
        
        echo "[4] 备份完整性"
        echo "------------------------"
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -10 || echo "无备份快照"
        echo
        
        echo "[5] 插件安全"
        echo "------------------------"
        ls -la "$OPENCLAW_DATA/extensions/" 2>/dev/null || echo "无插件目录"
        echo
        
        echo "[6] 日志检查"
        echo "------------------------"
        tail -20 /var/log/openclaw-backup.log 2>/dev/null || echo "无备份日志"
        echo
        
        echo "================================"
        echo "审计完成"
    } > "$AUDIT_OUTPUT"
    
    dialog --title "安全审计" \
           --textbox "$AUDIT_OUTPUT" 22 70
    
    rm -f "$AUDIT_OUTPUT"
    mode_security
}

# 安全: 验证备份
sec_verify_backup() {
    check_dialog
    clear
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    验证备份完整性${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo -e "${BLUE}[1/3]${NC} 检查 restic 仓库..."
    if restic check --repo "$RESTIC_REPO" 2>&1 | tee /tmp/restic-check.txt; then
        echo -e "  ${GREEN}restic 仓库完整${NC}"
    else
        echo -e "  ${RED}发现错误${NC}"
    fi
    
    echo
    echo -e "${BLUE}[2/3]${NC} 查看快照..."
    SNAPSHOT_LIST=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null)
    echo "$SNAPSHOT_LIST" | head -20
    
    echo
    echo -e "${BLUE}[3/3]${NC} 测试恢复..."
    TEST_DIR="/tmp/openclaw-restore-test"
    mkdir -p "$TEST_DIR"
    restic restore latest --repo "$RESTIC_REPO" --target "$TEST_DIR" 2>/dev/null
    if [[ -d "$TEST_DIR/root/.openclaw" ]]; then
        echo -e "  ${GREEN}恢复测试成功${NC}"
        rm -rf "$TEST_DIR"
    else
        echo -e "  ${RED}恢复测试失败${NC}"
    fi
    
    dialog --title "备份验证" \
           --msgbox "备份完整性验证完成!\n\n详情已显示在上方。\n\n按任意键返回..." 12 50
    
    mode_security
}

# 安全: 查看日志
sec_view_logs() {
    check_dialog
    
    dialog --title "OpenClaw 日志" \
           --textbox /var/log/openclaw-backup.log 22 70
    
    mode_security
}

# 安全: 重置 exec
sec_reset_exec() {
    check_dialog
    
    dialog --title "重置 exec 权限" \
           --yesno "确定要重置 exec 权限为 ** (最高权限) 吗?" 10 50
    
    [[ $? -ne 0 ]] && mode_security
    
    openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1
    
    dialog --title "完成" \
           --msgbox "exec 权限已重置为 **\n\n按任意键返回..." 10 50
    
    mode_security
}

# 完全卸载
mode_uninstall() {
    check_dialog
    
    dialog --title "卸载 OpenClaw" \
           --yesno "警告: 此操作将删除:\n\n  • OpenClaw 程序\n  • 配置文件\n  • 插件\n  • 备份脚本\n\n但保留 /root/.openclaw-backups 备份数据\n\n确定要继续吗?" 15 55
    
    [[ $? -ne 0 ]] && tui_wizard
    
    echo -e "${RED}正在卸载 OpenClaw...${NC}"
    
    # 停止服务
    pkill -f openclaw 2>/dev/null || true
    
    # 卸载 npm 包
    npm uninstall -g openclaw > /dev/null 2>&1 || true
    
    # 保留备份数据，删除其他文件
    rm -rf "$OPENCLAW_DATA" 2>/dev/null || true
    rm -f "$SCRIPT_DIR/backup-openclaw.sh" 2>/dev/null || true
    rm -f /var/log/openclaw-backup.log 2>/dev/null || true
    
    # 移除 cron
    crontab -l 2>/dev/null | grep -v "backup-openclaw" | crontab - 2>/dev/null || true
    
    dialog --title "卸载完成" \
           --msgbox "OpenClaw 已完全卸载\n\n备份数据保留在:\n$BACKUP_DIR\n\n按任意键退出..." 12 50
    
    exit 0
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
    echo -e "  $0              启动 TUI 向导弹导"
    echo -e "  $0 --silent     静默模式（使用默认配置）"
    echo -e "  $0 --help       显示帮助"
    echo
    echo -e "${BOLD}示例:${NC}"
    echo -e "  sudo $0              # 启动向导"
    echo -e "  sudo $0 --silent    # 静默安装"
}

main() {
    check_root
    mkdir -p "$(dirname "$LOG_FILE")"
    
    if ! command -v dialog &> /dev/null && [[ "${1:-}" != "--silent" && "${1:-}" != "-s" ]]; then
        echo -e "${YELLOW}dialog 未安装，使用命令行模式${NC}"
        echo
        echo "请选择操作:"
        echo "  1) 全新安装 OpenClaw"
        echo "  2) 从备份恢复数据"
        echo "  3) 仅手动备份"
        echo "  4) 查看当前状态"
        echo "  5) 安全与依赖管理"
        echo "  6) 卸载 OpenClaw"
        echo "  7) 静默安装(使用默认配置)"
        read -p "请输入选项 [1-7]: " choice
        case $choice in
            1) mode_install ;;
            2) mode_restore ;;
            3) mode_backup_only ;;
            4) mode_status ;;
            5) mode_security ;;
            6) mode_uninstall ;;
            7) silent_mode ;;
            *) exit 0 ;;
        esac
    else
        case "${1:-}" in
            --silent|-s) silent_mode ;;
            --help|-h) usage ;;
            *) tui_wizard ;;
        esac
    fi
}

main "$@"
