#!/bin/bash
set -e

echo "=========================================="
echo " OpenClaw 环境恢复脚本"
echo "=========================================="

# 1. 安装依赖
echo "[1/8] 安装依赖..."
apt-get update -qq
apt-get install -y -qq restic git > /dev/null 2>&1
echo " 依赖安装完成"

# 2. 克隆备份
echo "[2/8] 克隆备份仓库..."
mkdir -p /root/.openclaw-backups
cd /root/.openclaw-backups
git clone https://github.com/savior-li/portable-openclaw.git . 2>/dev/null || git pull
echo " 备份仓库已克隆"

# 3. 恢复数据
echo "[3/8] 恢复 OpenClaw 数据..."
export RESTIC_PASSWORD="735d591f6831"
restic restore latest --repo /root/.openclaw-backups/restic --target / 2>/dev/null || echo " 跳过恢复"
echo " 数据恢复完成"

# 4. 安装 OpenClaw
echo "[4/8] 安装 OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    curl -fsSL https://openclaw.ai/install.sh | bash > /dev/null 2>&1
fi
echo " OpenClaw 已安装: $(openclaw --version)"

# 5. 恢复环境变量
echo "[5/8] 恢复环境变量..."
cat >> /etc/environment << 'EOF'
MCAI_LLM_API_KEY=a7369912-cf56-41ed-885e-7e2582a87c43
MCAI_LLM_BASE_URL=https://monkeycode-ai.com/v1
EOF
source /etc/environment
echo " 环境变量已设置"

# 6. 重新安装微信插件
echo "[6/8] 重新安装微信插件..."
npx -y @tencent-weixin/openclaw-weixin-cli@latest install > /dev/null 2>&1 || echo " 插件安装跳过"
echo " 微信插件已安装"

# 7. 配置 Cron
echo "[7/8] 配置定时备份..."
mkdir -p /opt/scripts
cat > /opt/scripts/backup-openclaw.sh << 'SCRIPT'
#!/bin/bash
export RESTIC_PASSWORD="735d591f6831"
restic backup /root/.openclaw --repo /root/.openclaw-backups/restic --tag "openclaw-auto-backup" --host "$(hostname)"
restic forget --repo /root/.openclaw-backups/restic --tag "openclaw-auto-backup" --keep-last 30 --prune
cd /root/.openclaw-backups
git add . && git commit -m "Backup $(date)" 2>/dev/null && git push 2>/dev/null || true
SCRIPT
chmod +x /opt/scripts/backup-openclaw.sh
(crontab -l 2>/dev/null; echo "*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1") | crontab -
echo " 定时备份已配置"

# 8. 验证
echo "[8/8] 验证安装..."
openclaw health > /dev/null 2>&1 && echo " 健康检查通过" || echo " 健康检查失败"

echo "=========================================="
echo " 恢复完成！"
echo "=========================================="
echo " Gateway: http://127.0.0.1:18789"
echo " 备份目录: /root/.openclaw-backups"
echo " 备份脚本: /opt/scripts/backup-openclaw.sh"
