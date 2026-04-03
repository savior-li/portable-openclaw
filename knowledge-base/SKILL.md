---
name: knowledge-base
description: AI learning and knowledge management skill - Teach AI how to behave and help you get things done
version: 1.0.0
author: harrylili
metadata:
  openclaw:
    requires:
      env:
        - KNOWLEDGE_BASE_PATH
      bins:
        - python3
    primaryEnv: KNOWLEDGE_BASE_PATH
    config:
      requiredEnv:
        - KNOWLEDGE_BASE_PATH
      stateDirs:
        - ".knowledge-base"
      example: 'export KNOWLEDGE_BASE_PATH="/workspace/knowledge-base"'
tags:
  - learning
  - knowledge-management
  - behavioral-rules
  - execution-logging
---

# Knowledge Base Skill

**我教AI做人，你帮我做事**

这是一个 AI 知识管理技能，帮助 AI 学习用户的规则和偏好，记录任务执行过程，持续优化服务质量。

## Features

- **规则学习**: 自动从用户指令中学习行为规则
- **偏好管理**: 记录和查询用户的使用偏好
- **执行日志**: 记录所有任务执行过程和结果
- **问题追踪**: 记录问题和解决方案
- **智能查询**: 支持标签、类别、优先级等多维度查询

## Quick Start

### CLI Usage

```bash
# 创建行为规则
/kb learn "禁止删除文件" --category deny --priority high

# 创建偏好设置
/kb prefer "使用 pnpm 而不是 npm" --category tool --priority high

# 记录执行
/kb log --command "npm install" --outcome success

# 查询知识
/kb query --type behavioral --tags 安全
```

### Python API

```python
from manager import (
    create_behavioral_rule,
    create_preference,
    create_execution,
    query_records
)

# 创建规则
create_behavioral_rule(
    rule="禁止删除文件",
    category="deny",
    priority="high"
)

# 查询知识
results = query_records(tags=["安全"], limit=10)
```

## Directory Structure

```
knowledge-base/
├── rules/              # 做人：规则和偏好
│   ├── behavioral/     # 行为规则
│   ├── preferences/    # 偏好设置
│   └── thinking/       # 思维模式
├── cases/              # 做事：执行和结果
│   ├── executions/     # 执行日志
│   ├── problems/       # 问题解决
│   └── results/        # 产出结果
├── insights/           # 洞察和总结
└── templates/          # 数据模板
```

## Data Models

### Behavioral Rule

```json
{
  "id": "20260403_behavioral_143025",
  "type": "behavioral",
  "category": "deny|recommend|prefer|avoid",
  "rule": "禁止删除文件",
  "context": "任何涉及删除操作",
  "priority": "high|medium|low",
  "tags": ["安全"],
  "rationale": "防止数据丢失"
}
```

### Execution Log

```json
{
  "id": "20260403_execution_143025",
  "type": "execution",
  "command": "npm install openclaw",
  "steps": ["npm install", "验证版本"],
  "outcome": "success|failure|partial",
  "learnings": ["安装过程需要较长时间"]
}
```

## Usage Examples

### Scenario 1: Teaching AI New Rules

```
User: "以后不要删除任何文件，除非我明确要求"
AI: [Creates behavioral rule]
/kb learn "禁止删除文件" --category deny --priority high --rationale "用户明确要求"
```

### Scenario 2: Recording Execution

```
AI: [Executes task]
/kb log --command "OpenClaw 恢复" --steps "安装依赖,恢复数据,启动服务" --outcome success --learnings "restic 备份完整可用"
```

### Scenario 3: Problem Solving

```
AI: [Encounters error]
/kb problem "go mod 401 错误" --cause "私有模块需要认证" --solution "配置 .netrc"
```

## Best Practices

1. **及时记录**: 完成任务后立即记录，避免遗忘细节
2. **使用标签**: 合理使用标签便于后续查询
3. **完整描述**: 提供充分的上下文信息
4. **定期回顾**: 定期回顾和优化已有规则

## CLI Commands

```bash
# 规则管理
python3 cli.py create-behavioral --rule "规则" --category deny --priority high
python3 cli.py create-preference --preference "偏好" --category tool
python3 cli.py create-thinking --pattern "模式" --category analysis

# 执行记录
python3 cli.py create-execution --command "命令" --steps "步骤" --outcome success
python3 cli.py create-problem --problem "问题" --cause "原因" --solution "解决方案"
python3 cli.py create-result --task "任务" --output "结果" --verified true

# 查询
python3 cli.py query --type behavioral --tags 安全
python3 cli.py query --type execution --limit 20
```

## Roadmap

- [x] Phase 1: 基础功能
  - [x] 创建目录结构
  - [x] 实现 CLI 工具
  - [x] 实现 Python API
  - [x] 基础数据模板

- [ ] Phase 2: 智能学习
  - [ ] 自动学习引擎
  - [ ] 规则冲突检测
  - [ ] 知识衰减机制

- [ ] Phase 3: 知识图谱
  - [ ] 构建知识关联图
  - [ ] 上下文感知
  - [ ] 智能推荐

- [ ] Phase 4: ClawHub 集成
  - [ ] 向量搜索
  - [ ] 版本管理
  - [ ] 社区共享

## Contributing

欢迎贡献新的规则模板、最佳实践和功能改进！

## License

MIT
