#!/bin/bash
#
# OpenClaw 一键安装与恢复脚本 v2026.04.02
#

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
    [[ $EUID -ne 0 ]] && { echo "需要 root 权限"; exit 1; }
}

# 安装依赖
install_deps() {
    echo "[1/5] 安装依赖..."
    apt-get update -qq
    apt-get install -y -qq curl git restic ca-certificates fuse tmux > /dev/null 2>&1
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash
    echo "    完成"
}

# 配置备份
setup_backup() {
    mkdir -p "$SCRIPT_DIR"
    cat > "$SCRIPT_DIR/backup-openclaw.sh" << 'SCRIPT'
#!/bin/bash
export RESTIC_PASSWORD="735d591f6831"
restic backup /root/.openclaw --repo /root/.openclaw-backups/restic --tag "openclaw-auto-backup" --host "$(hostname)"
restic forget --repo /root/.openclaw-backups/restic --tag "openclaw-auto-backup" --keep-last 30 --prune
cd /root/.openclaw-backups
git add .
git commit -m "Backup $(date)" 2>/dev/null && git push 2>/dev/null || true
SCRIPT
    chmod +x "$SCRIPT_DIR/backup-openclaw.sh"
    touch /var/log/openclaw-backup.log
    (crontab -l 2>/dev/null | grep -v "backup-openclaw"; echo "*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1") | crontab -
}

# 主菜单
main_menu() {
    clear
    echo ""
    echo "========================================"
    echo "   OpenClaw 安装与恢复向导"
    echo "========================================"
    echo ""
    echo "  1) 全新安装"
    echo "  2) 从备份恢复"
    echo "  3) 手动备份"
    echo "  4) 查看状态"
    echo "  5) Gateway 管理"
    echo "  6) 安全与维护"
    echo "  7) 卸载"
    echo "  0) 退出"
    echo ""
    
    read -p "请选择 [0-7]: " choice
    
    case $choice in
        1) install_flow ;;
        2) restore_flow ;;
        3) backup_flow ;;
        4) status_flow ;;
        5) gateway_flow ;;
        6) security_flow ;;
        7) uninstall_flow ;;
        0) echo "再见!"; exit 0 ;;
        *) echo "无效选择"; sleep 1; main_menu ;;
    esac
}

# 安装流程
install_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   安装 OpenClaw"
    echo "========================================"
    echo ""
    
    PS3="选择安装类型: "
    options=("快速安装 (默认配置)" "自定义安装" "仅安装依赖" "返回")
    
    select opt in "${options[@]}"; do
        case $opt in
            "快速安装 (默认配置)")
                install_deps
                
                echo "[2/5] 创建配置..."
                mkdir -p "$OPENCLAW_DATA"
                cat > "$OPENCLAW_DATA/openclaw.json" << EOF
{
  "gateway": { "mode": "local", "controlUi": { "allowedOrigins": ["*"] } },
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
                
                echo "[3/5] 配置权限..."
                openclaw approvals allowlist add --agent main "**" 2>/dev/null || true
                
                echo "[4/5] 安装微信插件..."
                npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || true
                
                echo "[5/5] 配置备份..."
                setup_backup
                
                tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; exec openclaw gateway"
                
                echo ""
                echo "========================================"
                echo "  安装完成!"
                echo "  访问: http://127.0.0.1:18789"
                echo "========================================"
                read -p "按 Enter 返回..." 
                ;;
                
            "自定义安装")
                read -p "API Key: " api_key; api_key=${api_key:-$DEFAULT_API_KEY}
                read -p "API URL: "; api_url=${REPLY:-$DEFAULT_API_URL}
                read -p "模型: "; model=${REPLY:-$DEFAULT_MODEL}
                
                install_deps
                
                mkdir -p "$OPENCLAW_DATA"
                cat > "$OPENCLAW_DATA/openclaw.json" << EOF
{
  "gateway": { "mode": "local", "controlUi": { "allowedOrigins": ["*"] } },
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
                openclaw approvals allowlist add --agent main "**" 2>/dev/null || true
                setup_backup
                tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$api_key'; exec openclaw gateway"
                echo "安装完成!"; read -p "按 Enter 返回..." 
                ;;
                
            "仅安装依赖")
                install_deps
                echo "完成!"; read -p "按 Enter 返回..." 
                ;;
                
            "返回") break ;;
        esac
        break
    done
    main_menu
}

# 恢复流程
restore_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   从备份恢复"
    echo "========================================"
    echo ""
    
    echo "[1/5] 安装依赖..."
    install_deps
    
    echo "[2/5] 克隆备份..."
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR"
    [[ -d ".git" ]] && git pull origin main --rebase > /dev/null 2>&1 || git clone "$GITHUB_REPO" . > /dev/null 2>&1
    
    echo "[3/5] 恢复数据..."
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    restic restore latest --repo "$RESTIC_REPO" --target / > /dev/null 2>&1 || echo "    跳过"
    
    echo "[4/5] 启动 Gateway..."
    command -v openclaw &> /dev/null || curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
    tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; exec openclaw gateway"
    
    echo "[5/5] 配置备份..."
    setup_backup
    
    echo ""
    echo "恢复完成! 访问: http://127.0.0.1:18789"
    read -p "按 Enter 返回..." 
    main_menu
}

# 备份流程
backup_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   手动备份"
    echo "========================================"
    echo ""
    
    export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
    
    echo "创建快照..."
    restic backup /root/.openclaw --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --host "$(hostname)"
    
    echo "清理旧快照..."
    restic forget --repo "$RESTIC_REPO" --tag "openclaw-auto-backup" --keep-last 30 --prune > /dev/null 2>&1
    
    cd "$BACKUP_DIR"
    git add .
    if ! git diff --cached --quiet; then
        git commit -m "Manual $(date)" > /dev/null 2>&1
        git push > /dev/null 2>&1 && echo "已推送" || echo "推送失败"
    else
        echo "无变更"
    fi
    
    echo "完成!"
    read -p "按 Enter 返回..." 
    main_menu
}

# 状态流程
status_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   OpenClaw 状态"
    echo "========================================"
    echo ""
    
    if command -v openclaw &> /dev/null; then
        echo "OpenClaw: 已安装 ($(openclaw --version 2>/dev/null | head -1))"
        tmux has-session -t openclaw 2>/dev/null && echo "Gateway: 运行中 (tmux)" || \
        pgrep -f "openclaw gateway" > /dev/null && echo "Gateway: 运行中" || echo "Gateway: 未运行"
    else
        echo "OpenClaw: 未安装"
    fi
    
    echo ""
    
    if [[ -d "$RESTIC_REPO" ]]; then
        export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
        count=$(restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | grep -c "openclaw" || echo "0")
        echo "Restic: 已配置 (快照: $count)"
    else
        echo "Restic: 未配置"
    fi
    
    echo ""
    crontab -l 2>/dev/null | grep -q "backup-openclaw" && echo "自动备份: 已配置" || echo "自动备份: 未配置"
    
    echo ""
    read -p "按 Enter 返回..." 
    main_menu
}

# Gateway 流程
gateway_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   Gateway 管理"
    echo "========================================"
    echo ""
    
    tmux has-session -t openclaw 2>/dev/null && gw_status="运行中" || gw_status="未运行"
    pgrep -f "openclaw gateway" > /dev/null && gw_status="运行中 (进程)" || true
    
    echo "当前状态: $gw_status"
    echo ""
    echo "  1) 启动"
    echo "  2) 停止"
    echo "  3) 重启"
    echo "  4) 查看日志"
    echo "  0) 返回"
    echo ""
    
    read -p "选择 [0-4]: " choice
    
    case $choice in
        1)
            tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; exec openclaw gateway"
            echo "已启动"; sleep 1; gateway_flow
            ;;
        2)
            tmux kill-session -t openclaw 2>/dev/null; pkill -f "openclaw gateway" 2>/dev/null
            echo "已停止"; sleep 1; gateway_flow
            ;;
        3)
            tmux kill-session -t openclaw 2>/dev/null; pkill -f "openclaw gateway" 2>/dev/null
            sleep 1
            tmux new-session -d -s openclaw "export MCAI_LLM_API_KEY='$DEFAULT_API_KEY'; exec openclaw gateway"
            echo "已重启"; sleep 1; gateway_flow
            ;;
        4)
            tmux has-session -t openclaw 2>/dev/null && tmux capture-pane -t openclaw -p | tail -15 || echo "Gateway 未运行"
            read -p "按 Enter 返回..."; gateway_flow
            ;;
        0) main_menu ;;
        *) gateway_flow ;;
    esac
}

# 安全流程
security_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   安全与维护"
    echo "========================================"
    echo ""
    
    echo "  1) 版本检查"
    echo "  2) 更新 OpenClaw"
    echo "  3) 安全审计"
    echo "  4) 验证备份"
    echo "  5) 查看日志"
    echo "  6) 重置权限"
    echo "  0) 返回"
    echo ""
    
    read -p "选择 [0-6]: " choice
    
    case $choice in
        1)
            clear
            echo "依赖版本:"
            command -v node &> /dev/null && echo "  Node.js: $(node --version)"
            command -v npm &> /dev/null && echo "  npm: $(npm --version)"
            command -v openclaw &> /dev/null && echo "  OpenClaw: $(openclaw --version 2>/dev/null | head -1)"
            command -v restic &> /dev/null && echo "  restic: $(restic version 2>/dev/null | head -1)"
            command -v git &> /dev/null && echo "  Git: $(git --version | cut -d' ' -f3)"
            command -v tmux &> /dev/null && echo "  tmux: $(tmux -V)"
            read -p "按 Enter 返回..."; security_flow
            ;;
        2)
            npm update -g openclaw@latest > /dev/null 2>&1
            echo "更新完成: $(openclaw --version 2>/dev/null | head -1)"
            read -p "按 Enter 返回..."; security_flow
            ;;
        3)
            clear
            echo "配置文件:"
            ls -la "$OPENCLAW_DATA/openclaw.json" 2>/dev/null | tail -1 || echo "未找到"
            echo ""
            echo "exec 权限:"
            cat "$OPENCLAW_DATA/exec-approvals.json" 2>/dev/null || echo "未找到"
            echo ""
            echo "环境变量:"
            grep MCAI_LLM /etc/environment 2>/dev/null || echo "未设置"
            read -p "按 Enter 返回..."; security_flow
            ;;
        4)
            clear
            export RESTIC_PASSWORD="$DEFAULT_RESTIC_PASSWORD"
            echo "检查仓库..."
            restic check --repo "$RESTIC_REPO" 2>&1 | grep -q "no errors" && echo "仓库完整" || echo "发现问题"
            echo ""
            echo "快照:"
            restic snapshots --repo "$RESTIC_REPO" 2>/dev/null | head -5
            read -p "按 Enter 返回..."; security_flow
            ;;
        5)
            clear
            [[ -f /var/log/openclaw-backup.log ]] && tail -10 /var/log/openclaw-backup.log || echo "无日志"
            read -p "按 Enter 返回..."; security_flow
            ;;
        6)
            openclaw approvals allowlist add --agent main "**" 2>/dev/null || true
            echo "权限已重置为 **"
            read -p "按 Enter 返回..."; security_flow
            ;;
        0) main_menu ;;
        *) security_flow ;;
    esac
}

# 卸载流程
uninstall_flow() {
    clear
    echo ""
    echo "========================================"
    echo "   卸载 OpenClaw"
    echo "========================================"
    echo ""
    echo "警告: 将删除程序和配置，保留备份数据"
    echo ""
    read -p "确认卸载? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        tmux kill-session -t openclaw 2>/dev/null || true
        pkill -f openclaw 2>/dev/null || true
        npm uninstall -g openclaw > /dev/null 2>&1 || true
        rm -rf "$OPENCLAW_DATA" 2>/dev/null || true
        rm -f "$SCRIPT_DIR/backup-openclaw.sh" 2>/dev/null || true
        rm -f /var/log/openclaw-backup.log 2>/dev/null || true
        crontab -l 2>/dev/null | grep -v "backup-openclaw" | crontab - 2>/dev/null || true
        echo "卸载完成! 备份保留在: $BACKUP_DIR"
    else
        echo "取消"
    fi
    
    read -p "按 Enter 返回..." 
    main_menu
}

# 入口
main() {
    check_root
    mkdir -p "$(dirname "$LOG_FILE")"
    main_menu
}

main "$@"
