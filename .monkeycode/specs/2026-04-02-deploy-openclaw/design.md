# OpenClaw 部署技术方案

需求名称：deploy-openclaw
更新日期：2026-04-02

## 描述

在 monkeycode-ai 开发环境中部署 OpenClaw，配置 monkeycode-ai provider 和 minimax-m2.7 model，实现数据持久化和跨域访问。

## 概述

OpenClaw 是一个 AI 模型网关和管理平台，支持多种 LLM Provider 的统一接入。本方案旨在开发环境中部署 OpenClaw，实现：

- OpenClaw 核心服务部署 (v2026.4.1)
- monkeycode-ai Provider 和 minimax-m2.7 Model 配置
- CORS 跨域访问配置
- 微信插件集成 (@tencent-weixin/openclaw-weixin)
- 数据自动备份与快照机制 (restic + git + GitHub)

## 架构

```mermaid
graph TB
    subgraph OpenClaw["OpenClaw 环境"]
        OC[OpenClaw Gateway<br/>:18789]
        OCData["/root/.openclaw"]
    end
    
    subgraph Providers["Provider 配置"]
        MCA[monkeycode-ai Provider]
        M27[minimax-m2.7 Model]
    end
    
    subgraph Backup["备份机制 (每10分钟)"]
        Cron[Cron Job]
        Restic[restic snapshot]
        GitLocal["/root/.openclaw-backups"]
        GitHub[GitHub Repo<br/>savior-li/portable-openclaw-backups]
    end
    
    OC <--> MCA
    MCA --> M27
    OC -->|CORS *| Browser
    
    Cron -->|backup| Restic
    Restic -->|git commit| GitLocal
    GitLocal -->|git push| GitHub

    subgraph Env["环境变量"]
        API_KEY[MCAI_LLM_API_KEY]
        BASE_URL[MCAI_LLM_BASE_URL]
    end
    
    MCA -.->|引用| API_KEY
    MCA -.->|引用| BASE_URL
```

## 环境变量

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `MCAI_LLM_API_KEY` | `a7369912-cf56-41ed-885e-7e2582a87c43` | monkeycode-ai API Key |
| `MCAI_LLM_BASE_URL` | `https://monkeycode-ai.com/v1` | monkeycode-ai API Base URL |
| `RESTIC_PASSWORD` | `735d591f6831` | restic 仓库加密密码 |
| `GH_TOKEN` | (需配置) | GitHub Personal Access Token |

## 组件与接口

### 1. OpenClaw Core

| 组件 | 说明 | 默认端口 |
|------|------|---------|
| Gateway | OpenClaw 网关服务 | 18789 |
| Control UI | Web 控制界面 | 与 Gateway 共用 |

### 2. Provider 配置

实际配置文件 `/root/.openclaw/openclaw.json`:

```json
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
        "baseUrl": "https://monkeycode-ai.com/v1",
        "apiKey": "a7369912-cf56-41ed-885e-7e2582a87c43",
        "models": [
          {
            "id": "minimax-m2.7",
            "name": "minimax-m2.7"
          }
        ]
      }
    }
  }
}
```

### 3. CORS 配置

Control UI 允许所有来源跨域访问：

```json
"gateway": {
  "controlUi": {
    "allowedOrigins": ["*"]
  }
}
```

### 4. 微信插件

```bash
npx -y @tencent-weixin/openclaw-weixin-cli@latest install
```

已安装版本: 2.1.3

## 数据目录

```
/root/.openclaw/                    # OpenClaw 数据目录
├── openclaw.json                   # 主配置文件
├── agents/                         # Agent 配置
│   └── main/
│       └── sessions/               # 会话数据
├── extensions/                     # 插件目录
│   └── openclaw-weixin/           # 微信插件
└── logs/                          # 日志目录

/root/.openclaw-backups/           # 备份目录
└── restic/                        # restic 快照仓库
    ├── config
    ├── data/
    ├── index/
    ├── keys/
    └── snapshots/
```

## 备份机制

### 备份流程

1. **restic 快照**: 增量备份 `/root/.openclaw` 到 `/root/.openclaw-backups/restic`
2. **git 提交**: 将 restic 仓库变化提交到本地 git
3. **GitHub 推送**: 推送到 GitHub (需要 `GH_TOKEN` 环境变量)

### 备份脚本

```bash
#!/bin/bash
# /opt/scripts/backup-openclaw.sh

export RESTIC_REPOSITORY="/root/.openclaw-backups/restic"
export RESTIC_PASSWORD="735d591f6831"
BACKUP_SOURCE="/root/.openclaw"
TAG="openclaw-auto-backup"

restic backup "$BACKUP_SOURCE" --repo "$RESTIC_REPOSITORY" --tag "$TAG" --host "$(hostname)"
restic forget --repo "$RESTIC_REPOSITORY" --tag "$TAG" --keep-last 30 --prune

cd /root/.openclaw-backups
git add .
git commit -m "Backup $(date)" 
[ -n "$GH_TOKEN" ] && git push || echo "GH_TOKEN not set"
```

### Cron 配置

```cron
# 每10分钟执行一次备份
*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1
```

### 快照管理

```bash
# 列出快照
restic snapshots --repo /root/.openclaw-backups/restic

# 恢复最新快照
restic restore latest --repo /root/.openclaw-backups/restic --target /

# 手动触发备份
/opt/scripts/backup-openclaw.sh
```

## 实施状态

| 任务 | 状态 |
|------|------|
| 安装 OpenClaw | ✅ 完成 |
| 配置环境变量 | ✅ 完成 |
| 配置 Provider 和 CORS | ✅ 完成 |
| 安装微信插件 | ✅ 完成 |
| 安装 restic | ✅ 完成 |
| 初始化 restic 仓库 | ✅ 完成 |
| 部署备份脚本 | ✅ 完成 |
| 配置 Cron | ✅ 完成 |
| 配置 GitHub 推送 | ⚠️ 待配置 GH_TOKEN |

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 网络中断 | Cron 下次执行时自动重试 |
| GitHub Token 缺失 | 跳过 push，保留本地备份 |
| 磁盘空间不足 | 清理旧快照后重试 |
| Restic 仓库损坏 | 从 GitHub 拉取恢复 |

## 待配置事项

### 配置 GitHub Token (用于自动推送备份)

```bash
# 方式1: 设置环境变量
export GH_TOKEN="your-github-pat"

# 方式2: 添加到 git credentials
echo "https://username:${GH_TOKEN}@github.com" >> ~/.git-credentials
git config --global credential.helper store
```

## 恢复流程

在新环境中恢复数据：

```bash
# 1. 安装依赖
apt-get install -y restic git

# 2. 克隆备份仓库
git clone https://github.com/savior-li/portable-openclaw-backups.git /root/.openclaw-backups

# 3. 恢复数据
export RESTIC_PASSWORD="735d591f6831"
restic restore latest --repo /root/.openclaw-backups/restic --target /

# 4. 重新安装 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 5. 重新安装微信插件
npx -y @tencent-weixin/openclaw-weixin-cli@latest install

# 6. 配置 cron
echo "*/10 * * * * /opt/scripts/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1" | crontab -
```

## 验证命令

```bash
# 验证 OpenClaw
openclaw doctor
openclaw health

# 验证 Gateway
openclaw gateway status

# 验证备份
/opt/scripts/backup-openclaw.sh
restic snapshots --repo /root/.openclaw-backups/restic
```

## 引用链接

- [OpenClaw 官方文档](https://docs.openclaw.ai/install)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Restic 文档](https://restic.readthedocs.io/)
- [备份仓库](https://github.com/savior-li/portable-openclaw-backups)
