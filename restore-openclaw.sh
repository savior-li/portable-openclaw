#!/bin/bash
#
# OpenClaw 一键安装与恢复脚本 v2026.04.02
# 使用 Bash select 实现简单可靠的 TUI 菜单
#

set -e

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

# 检查 root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 此脚本需要 root 权限"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 安装依赖
install_deps() {
    echo ">>> 安装系统依赖..."
    apt-get update -qq
    apt-get install -y -qq curl git restic ca-certificates fuse tmux > /dev/null 2>&1
    
    if ! command -v openclaw &> /dev/null; then
        echo ">>> 安装 OpenClaw..."
        curl -fsSL https://openclaw.ai/install.sh | bash
    fi
    echo ">>> 依赖安装完成"
}

# 打印标题
print_header() {
    clear
    echo ""
    echo "========================================"
    echo "   OpenClaw 安装与恢复向导"
    echo "   v2026.04.02"
    echo "========================================"
    echo ""
}

# 打印菜单
print_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "--- $title ---"
    echo ""
    
    PS3="
请选择 [1-$(($#)) q=退出]: "
    
    select opt in "${options[@]}"; do
        if [[ "$opt" == "q" || "$opt" == "Q" ]]; then
            echo "再见!"
            exit 0
        fi
        if [[ -n "$opt" ]]; then
            echo "选择了: $opt"
            break
        fi
    done
    
    REPLY=""
}

# 主菜单
main_menu() {
    print_header
    echo "1) 全新安装 OpenClaw"
    echo "2) 从备份恢复数据"
    echo "3) 手动备份"
    echo "4) 查看当前状态"
    echo "5) Gateway 管理"
    echo "6) 安全与维护"
    echo "7) 卸载 OpenClaw"
    echo ""
    echo "q) 退出"
    echo ""
    
    PS3="
请选择 [1-7 q=退出]: "
    
    options=("全新安装" "从备份恢复" "手动备份" "查看状态" "Gateway管理" "安全维护" "卸载" "退出")
    select opt in "${options[@]}"; do
        case $opt in
            "全新安装") install_menu; break ;;
            "从备份恢复") restore_menu; break ;;
            "手动备份") do_backup; break ;;
            "查看状态") show_status; break ;;
            "Gateway管理") gateway_menu; break ;;
            "安全维护") security_menu; break ;;
            "卸载") do_uninstall; break ;;
            "退出"|"q") echo "再见!"; exit 0 ;;
        esac
    done
}

# 安装菜单
install_menu() {
    print_header
    echo "1) 快速安装 (使用默认配置)"
    echo "2) 自定义安装 (手动输入配置)"
    echo "3) 仅安装依赖"
    echo "b) 返回主菜单"
    echo ""
    
    PS3="
请选择 [1-3 b=返回]: "
    
    options=("快速安装" "自定义安装" "仅安装依赖" "返回")
    select opt in "${options[@]}"; do
        case $opt in
            "快速安装") do_install_default; break ;;
            "自定义安装") do_install_custom; break ;;
            "仅安装依赖") install_deps; echo "完成!"; break ;;
            "返回") main_menu; break ;;
        esac
    done
}

# 快速安装
do_install_default() {
    print_header
    echo ">>> 快速安装开始..."
    echo ""
    
    install_deps
    
    echo ""
    echo ">>> 创建配置..."
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
    
    echo ">>> 配置 exec 权限..."
    openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1 || true
    
    echo ">>> 安装微信插件..."
    npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || true
    
    echo ">>> 配置备份..."
    setup_backup
    
    echo ">>> 启动 Gateway..."
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    echo ""
    echo "========================================"
    echo "  安装完成!"
    echo "  访问地址: http://127.0.0.1:18789"
    echo "========================================"
    echo ""
    
    read -p "按 Enter 键返回主菜单..."
    main_menu
}

# 自定义安装
do_install_custom() {
    print_header
    echo ">>> 自定义安装"
    echo ""
    
    read -p "API Key [$DEFAULT_API_KEY]: " api_key
    api_key=${api_key:-$DEFAULT_API_KEY}
    
    read -p "API URL [$DEFAULT_API_URL]: " api_url
    api_url=${api_url:-$DEFAULT_API_URL}
    
    read -p "模型名称 [$DEFAULT_MODEL]: " model
    model=${model:-$DEFAULT_MODEL}
    
    echo ""
    echo "确认使用以下配置?"
    echo "  API Key: ${api_key:0:10}..."
    echo "  API URL: $api_url"
    echo "  模型: $model"
    echo ""
    
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
    
    echo ""
    echo "安装完成!"
    read -p "按 Enter 键返回..."
    main_menu
}

# 恢复
restore_menu() {
    print_header
    echo ">>> 从备份恢复"
    echo ""
    
    echo "[1/5] 安装依赖..."
    install_deps
    
    echo ""
    echo "[2/5] 克隆备份..."
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR"
    if [[ -d ".git" ]]; then
        git pull origin main --rebase > /dev/null 2>&1 || true
    else
        git clone "$GITHUB_REPO" . > /dev/null 2>&1
    fi
    
    echo "[3/5] 恢复数据..."
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic restore latest --repo "$RESTIC_REPO" --target / > /dev/null 2>&1 || echo "跳过恢复"
    
    echo "[4/5] 启动 Gateway..."
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    
    echo "[5/5] 配置备份..."
    setup_backup
    
    echo ""
    echo "========================================"
    echo "  恢复完成!"
    echo "  访问地址: http://127.0.0.1:18789"
    echo "========================================"
    echo ""
    
    read -p "按 Enter 键返回..."
    main_menu
}

# 备份
do_backup() {
    print_header
    echo ">>> 手动备份"
    echo ""
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo "创建快照..."
    restic backup /root/.openclaw --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --host "$(hostname)"
    
    echo "清理旧快照..."
    restic forget --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --keep-last 30 --prune > /dev/null 2>&1
    
    cd "$BACKUP_DIR"
    git add .
    if ! git diff --cached --quiet; then
        git commit -m "Manual backup $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1
        git push > /dev/null 2>&1 && echo "已推送到 GitHub" || echo "推送失败"
    else
        echo "无变更"
    fi
    
    echo "完成!"
    read -p "按 Enter 键返回..."
    main_menu
}

# 查看状态
show_status() {
    print_header
    echo ">>> OpenClaw 状态"
    echo ""
    
    echo "[OpenClaw]"
    if command -v openclaw &> /dev/null; then
        echo "  状态: 已安装"
        echo "  版本: $(openclaw --version 2>/dev/null | head -1)"
        
        if tmux has-session -t openclaw 2>/dev/null; then
            echo "  Gateway: 运行中 (tmux)"
        elif pgrep -f "openclaw gateway" > /dev/null; then
            echo "  Gateway: 运行中 (进程)"
        else
            echo "  Gateway: 未运行"
        fi
    else
        echo "  状态: 未安装"
    fi
    
    echo ""
    echo "[备份状态]"
    if [[ -d "$RESTIC_REPO" ]]; then
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        count=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | grep -c "openclaw" || echo "0")
        echo "  Restic: 已配置"
        echo "  快照数: $count"
    else
        echo "  Restic: 未配置"
    fi
    
    echo ""
    echo "[定时任务]"
    if crontab -l 2>/dev/null | grep -q "backup-openclaw"; then
        echo "  自动备份: 已配置 (每10分钟)"
    else
        echo "  自动备份: 未配置"
    fi
    
    echo ""
    read -p "按 Enter 键返回..."
    main_menu
}

# Gateway 管理菜单
gateway_menu() {
    print_header
    echo ">>> Gateway 管理"
    echo ""
    
    # 检测状态
    tmux_status="未运行"
    process_status="未运行"
    
    tmux has-session -t openclaw 2>/dev/null && tmux_status="运行中"
    pgrep -f "openclaw gateway" > /dev/null && process_status="运行中"
    
    echo "当前状态:"
    echo "  tmux 会话: $tmux_status"
    echo "  进程: $process_status"
    echo ""
    echo "1) 启动 Gateway"
    echo "2) 停止 Gateway"
    echo "3) 重启 Gateway"
    echo "4) 查看日志"
    echo "b) 返回主菜单"
    echo ""
    
    PS3="
请选择 [1-4 b=返回]: "
    
    options=("启动" "停止" "重启" "日志" "返回")
    select opt in "${options[@]}"; do
        case $opt in
            "启动") do_start_gateway; break ;;
            "停止") do_stop_gateway; break ;;
            "重启") do_restart_gateway; break ;;
            "日志") show_gateway_log; break ;;
            "返回") main_menu; break ;;
        esac
    done
}

do_start_gateway() {
    print_header
    echo ">>> 启动 Gateway"
    echo ""
    
    if tmux has-session -t openclaw 2>/dev/null; then
        echo "Gateway 已在 tmux 会话中运行"
    else
        echo "启动中..."
        tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
        sleep 2
        echo "启动完成!"
    fi
    
    echo ""
    echo "访问地址: http://127.0.0.1:18789"
    echo ""
    read -p "按 Enter 键返回..."
    gateway_menu
}

do_stop_gateway() {
    print_header
    echo ">>> 停止 Gateway"
    echo ""
    
    tmux kill-session -t openclaw 2>/dev/null && echo "tmux 会话已停止"
    pkill -f "openclaw gateway" 2>/dev/null && echo "进程已停止"
    
    echo ""
    read -p "按 Enter 键返回..."
    gateway_menu
}

do_restart_gateway() {
    print_header
    echo ">>> 重启 Gateway"
    echo ""
    
    tmux kill-session -t openclaw 2>/dev/null || true
    pkill -f "openclaw gateway" 2>/dev/null || true
    
    sleep 1
    
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; export MCAI_LLM_BASE_URL='$DEFAULT_API_URL'; exec openclaw gateway"
    sleep 2
    
    echo "重启完成!"
    echo ""
    read -p "按 Enter 键返回..."
    gateway_menu
}

show_gateway_log() {
    print_header
    echo ">>> Gateway 日志"
    echo ""
    
    if tmux has-session -t openclaw 2>/dev/null; then
        tmux capture-pane -t openclaw -p | tail -20
    else
        echo "Gateway 未运行"
    fi
    
    echo ""
    read -p "按 Enter 键返回..."
    gateway_menu
}

# 安全菜单
security_menu() {
    print_header
    echo ">>> 安全与维护"
    echo ""
    
    echo "1) 版本检查"
    echo "2) 更新 OpenClaw"
    echo "3) 安全审计"
    echo "4) 验证备份"
    echo "5) 查看备份日志"
    echo "6) 重置 exec 权限"
    echo "b) 返回主菜单"
    echo ""
    
    PS3="
请选择 [1-6 b=返回]: "
    
    options=("版本检查" "更新" "审计" "验证备份" "日志" "重置权限" "返回")
    select opt in "${options[@]}"; do
        case $opt in
            "版本检查") sec_versions; break ;;
            "更新") sec_update; break ;;
            "审计") sec_audit; break ;;
            "验证备份") sec_verify; break ;;
            "日志") sec_logs; break ;;
            "重置权限") sec_reset_exec; break ;;
            "返回") main_menu; break ;;
        esac
    done
}

sec_versions() {
    print_header
    echo ">>> 依赖版本"
    echo ""
    
    command -v node &> /dev/null && echo "Node.js: $(node --version)"
    command -v npm &> /dev/null && echo "npm: $(npm --version)"
    command -v openclaw &> /dev/null && echo "OpenClaw: $(openclaw --version 2>/dev/null | head -1)"
    command -v restic &> /dev/null && echo "restic: $(restic version 2>/dev/null | head -1)"
    command -v git &> /dev/null && echo "Git: $(git --version | cut -d' ' -f3)"
    command -v tmux &> /dev/null && echo "tmux: $(tmux -V)"
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
}

sec_update() {
    print_header
    echo ">>> 更新 OpenClaw"
    echo ""
    
    echo "更新中..."
    npm update -g openclaw@latest > /dev/null 2>&1
    echo "完成!"
    echo "新版本: $(openclaw --version 2>/dev/null | head -1)"
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
}

sec_audit() {
    print_header
    echo ">>> 安全审计"
    echo ""
    
    echo "[配置文件]"
    ls -la "$OPENCLAW_DATA/openclaw.json" 2>/dev/null | tail -1 || echo "未找到"
    
    echo ""
    echo "[exec 权限]"
    cat "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null || echo "未找到"
    
    echo ""
    echo "[环境变量]"
    grep "MCAI_LLM" /etc/environment 2>/dev/null || echo "未设置"
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
}

sec_verify() {
    print_header
    echo ">>> 验证备份"
    echo ""
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo "检查仓库..."
    if restic check --repo "$RESTIC_REPO" 2>&1 | grep -q "no errors"; then
        echo "仓库完整"
    else
        echo "发现问题"
    fi
    
    echo ""
    echo "快照列表:"
    restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
}

sec_logs() {
    print_header
    echo ">>> 备份日志"
    echo ""
    
    if [[ -f /var/log/openclaw-backup.log ]]; then
        tail -15 /var/log/openclaw-backup.log
    else
        echo "暂无日志"
    fi
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
}

sec_reset_exec() {
    print_header
    echo ">>> 重置 exec 权限"
    echo ""
    
    openclaw approvals allowlist add --agent main "**" > /dev/null 2>&1
    echo "exec 权限已重置为 **"
    
    echo ""
    read -p "按 Enter 键返回..."
    security_menu
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

# 卸载
do_uninstall() {
    print_header
    echo ">>> 卸载 OpenClaw"
    echo ""
    echo "警告: 将删除程序和配置，保留备份数据"
    echo ""
    
    read -p "确认卸载? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        echo "卸载中..."
        
        tmux kill-session -t openclaw 2>/dev/null || true
        pkill -f openclaw 2>/dev/null || true
        npm uninstall -g openclaw > /dev/null 2>&1 || true
        rm -rf "$OPENCLAW_DATA" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/backup-openclaw.sh" 2>/dev/null || true
        rm -f /var/log/openclaw-backup.log 2>/dev/null || true
        crontab -l 2>/dev/null | grep -v "backup-openclaw" | crontab - 2>/dev/null || true
        
        echo ""
        echo "卸载完成!"
        echo "备份数据保留在: $BACKUP_DIR"
    else
        echo "取消卸载"
    fi
    
    echo ""
    read -p "按 Enter 键返回..."
    main_menu
}

# 帮助
usage() {
    echo "OpenClaw 一键安装与恢复脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  (无参数)   启动交互式菜单"
    echo "  --help     显示帮助"
}

# 主入口
main() {
    check_root
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        --help|-h) usage ;;
        *) main_menu ;;
    esac
}

main "$@"
