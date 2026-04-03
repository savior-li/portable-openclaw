# Knowledge Base 使用指南

## 理念

**我教AI做人，你帮我做事**

知识库用于记录：
- 用户教导的规则和偏好（做人）
- 执行任务的过程和结果（做事）

## 目录结构

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
├── templates/          # 数据模板
└── docs/               # 文档
```

## 快速开始

### CLI 使用

```bash
# 创建行为规则
python3 cli.py create-behavioral \
  --rule "禁止删除文件" \
  --category deny \
  --priority high \
  --tags 安全 文件操作

# 创建偏好设置
python3 cli.py create-preference \
  --preference "使用 pnpm 而不是 npm" \
  --category tool \
  --context "Node.js 项目" \
  --priority high

# 创建思维模式
python3 cli.py create-thinking \
  --pattern "需求分析流程" \
  --category analysis \
  --steps "理解需求" "识别关键点" "确认边界"

# 记录执行
python3 cli.py create-execution \
  --command "npm install openclaw" \
  --steps "执行安装" "验证版本" \
  --outcome success \
  --tags 工具安装

# 记录问题
python3 cli.py create-problem \
  --problem "go mod download 401 错误" \
  --cause "私有模块需要认证" \
  --solution "配置 .netrc 凭据"

# 查询记录
python3 cli.py query --type behavioral --tags 安全
python3 cli.py query --type execution --limit 20
```

### Python API 使用

```python
from manager import (
    create_behavioral_rule,
    create_preference,
    create_execution,
    create_problem,
    query_records
)

# 创建规则
create_behavioral_rule(
    rule="使用 pnpm 而不是 npm",
    category="recommend",
    context="Node.js 项目",
    priority="high"
)

# 记录执行
create_execution(
    command="npm install openclaw",
    steps=["npm install", "验证版本"],
    outcome="success"
)

# 查询
results = query_records(tags=["备份"], limit=10)
```

## 数据模型

### 行为规则 (behavioral)

```json
{
  "id": "20260403_behavioral_143025",
  "type": "behavioral",
  "category": "deny",
  "rule": "禁止删除文件",
  "context": "任何涉及删除操作",
  "priority": "high",
  "tags": ["安全"],
  "examples": ["删除日志文件", "清理临时文件"],
  "counter_examples": ["创建备份"],
  "rationale": "防止数据丢失",
  "created_by": "user",
  "timestamp": "2026-04-03T14:30:25",
  "version": "1.0.0",
  "usage_count": 0,
  "last_used": "",
  "effectiveness_score": 0.0
}
```

### 偏好设置 (preferences)

```json
{
  "id": "20260403_preference_143025",
  "type": "preferences",
  "category": "tool",
  "preference": "使用 pnpm 而不是 npm",
  "context": "Node.js 项目",
  "priority": "high",
  "tags": ["Node.js", "包管理"],
  "alternatives": ["npm", "yarn"],
  "reason": "pnpm 更高效，节省磁盘空间",
  "created_by": "user",
  "timestamp": "2026-04-03T14:30:25",
  "version": "1.0.0",
  "usage_count": 0,
  "last_used": ""
}
```

### 执行记录 (execution)

```json
{
  "id": "20260403_execution_143025",
  "type": "execution",
  "command": "npm install -g openclaw",
  "context": "安装 OpenClaw 工具",
  "steps": ["npm install", "验证版本"],
  "outcome": "success",
  "duration_ms": 180000,
  "tags": ["工具安装"],
  "learnings": ["安装过程需要较长时间"],
  "issues": [],
  "timestamp": "2026-04-03T14:30:25",
  "version": "1.0.0"
}
```

### 问题记录 (problem)

```json
{
  "id": "20260403_problem_143025",
  "type": "problem",
  "problem": "go mod download 401 错误",
  "context": "下载私有模块",
  "cause": "私有模块需要认证",
  "solution": "配置 .netrc 凭据",
  "prevention": "提前配置认证信息",
  "tags": ["golang", "权限"],
  "related_problems": [],
  "timestamp": "2026-04-03T14:30:25",
  "version": "1.0.0",
  "effectiveness_score": 0.0
}
```

## 记录时机

### 执行任务前
```bash
python3 cli.py create-execution --command "用户指令" --steps "..."
```

### 执行任务后
```bash
python3 cli.py create-result --task "任务描述" --output "结果" --verified true
```

### 遇到问题时
```bash
python3 cli.py create-problem --problem "问题" --cause "原因" --solution "解决方案"
```

## 最佳实践

1. **及时记录**：完成任务后立即记录，避免遗忘细节
2. **使用标签**：合理使用标签便于后续查询
3. **完整描述**：提供充分的上下文信息
4. **定期回顾**：定期回顾和优化已有规则

## 下一步计划

- [ ] 实现自动学习引擎
- [ ] 实现规则冲突检测
- [ ] 实现知识衰减机制
- [ ] 构建知识关联图
- [ ] 集成向量搜索
- [ ] 打包成 ClawHub Skill
