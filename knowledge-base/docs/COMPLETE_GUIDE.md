# Knowledge Base 完整使用指南

## 目录
1. [快速开始](#快速开始)
2. [核心概念](#核心概念)
3. [CLI 使用](#cli-使用)
4. [Python API](#python-api)
5. [自动学习](#自动学习)
6. [最佳实践](#最佳实践)
7. [进阶用法](#进阶用法)

---

## 快速开始

### 安装和初始化
```bash
# 设置知识库路径
export KNOWLEDGE_BASE_PATH="/workspace/knowledge-base"

# 进入知识库目录
cd /workspace/knowledge-base

# 运行测试验证
python3 test_kb.py
```

### 第一个规则
```bash
# CLI 方式
python3 cli.py create-behavioral \
  --rule "提交代码前必须运行测试" \
  --category deny \
  --priority high \
  --tags 测试 工作流

# Python 方式
from manager import create_behavioral_rule

create_behavioral_rule(
    rule="提交代码前必须运行测试",
    category="deny",
    priority="high",
    tags=["测试", "工作流"]
)
```

---

## 核心概念

### 1. 规则类型 (rules/)

#### 行为规则 (behavioral/)
定义 AI 应该或不应该做什么

```json
{
  "category": "deny",           // deny|recommend|prefer|avoid
  "rule": "禁止删除文件",
  "priority": "high",           // high|medium|low
  "rationale": "防止数据丢失",
  "tags": ["安全", "文件操作"]
}
```

**类别说明：**
- `deny`: 严格禁止
- `recommend`: 推荐做法
- `prefer`: 优先选择
- `avoid`: 尽量避免

#### 偏好设置 (preferences/)
记录用户的使用偏好

```json
{
  "preference": "使用 pnpm 而不是 npm",
  "category": "tool",           // tool|style|workflow|communication
  "reason": "pnpm 更高效，节省磁盘空间",
  "alternatives": ["npm", "yarn"]
}
```

#### 思维模式 (thinking/)
记录分析和决策模式

```json
{
  "pattern": "需求分析流程",
  "category": "analysis",       // analysis|decision|problem-solving|planning
  "steps": [
    "理解需求",
    "识别关键点",
    "确认边界条件",
    "设计方案"
  ]
}
```

### 2. 执行记录 (cases/)

#### 执行日志 (executions/)
记录任务执行过程

```json
{
  "command": "OpenClaw 恢复流程",
  "steps": ["安装依赖", "恢复数据", "启动服务"],
  "outcome": "success",         // success|failure|partial
  "learnings": ["restic 备份完整可用"],
  "duration_ms": 180000
}
```

#### 问题记录 (problems/)
记录问题和解决方案

```json
{
  "problem": "API 返回 401 Unauthorized",
  "cause": "API Key 失效或过期",
  "solution": "更新 API Key",
  "prevention": "定期检查 API Key 有效性"
}
```

#### 结果记录 (results/)
记录任务产出

```json
{
  "task": "知识库 Phase 1 实现",
  "output": "完成基础功能实现",
  "verified": true,
  "quality_score": 1.0
}
```

---

## CLI 使用

### 规则管理

```bash
# 创建行为规则
python3 cli.py create-behavioral \
  --rule "规则描述" \
  --category deny \
  --priority high \
  --context "适用上下文" \
  --tags 标签1 标签2 \
  --examples "示例1" "示例2" \
  --rationale "规则理由"

# 创建偏好设置
python3 cli.py create-preference \
  --preference "偏好描述" \
  --category tool \
  --context "适用上下文" \
  --priority high \
  --tags 标签1 标签2 \
  --alternatives "替代方案1" "替代方案2" \
  --reason "选择理由"

# 创建思维模式
python3 cli.py create-thinking \
  --pattern "模式描述" \
  --category analysis \
  --context "适用上下文" \
  --steps "步骤1" "步骤2" "步骤3" \
  --expected-outcome "预期结果"
```

### 执行记录

```bash
# 创建执行日志
python3 cli.py create-execution \
  --command "执行的命令" \
  --steps "步骤1" "步骤2" \
  --outcome success \
  --context "上下文" \
  --tags 标签1 标签2 \
  --learnings "学习点1" "学习点2" \
  --issues "问题1" "问题2" \
  --duration 60000

# 创建问题记录
python3 cli.py create-problem \
  --problem "问题描述" \
  --cause "根本原因" \
  --solution "解决方案" \
  --context "上下文" \
  --prevention "预防措施" \
  --tags 标签1 标签2

# 创建结果记录
python3 cli.py create-result \
  --task "任务描述" \
  --output "产出结果" \
  --verified true \
  --context "上下文" \
  --quality-score 0.95 \
  --tags 标签1 标签2 \
  --artifacts "产物1" "产物2"
```

### 查询

```bash
# 查询所有类型的记录
python3 cli.py query

# 按类型查询
python3 cli.py query --type behavioral
python3 cli.py query --type preferences
python3 cli.py query --type execution

# 按标签查询
python3 cli.py query --tags 安全 测试

# 按类别查询
python3 cli.py query --category deny

# 限制结果数量
python3 cli.py query --limit 20
```

---

## Python API

### 基础 API

```python
from manager import (
    create_behavioral_rule,
    create_preference,
    create_thinking_pattern,
    create_execution,
    create_problem,
    create_result,
    query_records
)

# 创建行为规则
path = create_behavioral_rule(
    rule="禁止删除文件",
    category="deny",
    context="任何涉及文件操作",
    priority="high",
    tags=["安全", "文件操作"],
    examples=["删除日志文件", "清理临时文件"],
    rationale="防止数据丢失"
)

# 查询记录
rules = query_records(
    record_type="behavioral",
    tags=["安全"],
    category="deny",
    limit=10
)

for rule in rules:
    print(f"规则: {rule['rule']}")
    print(f"类别: {rule['category']}")
    print(f"优先级: {rule['priority']}")
```

### 高级 API

```python
from manager import KnowledgeManager

manager = KnowledgeManager()

# 获取单条记录
record = manager.get_record('20260403_behavioral_143025')

# 更新使用次数
manager.update_usage('20260403_behavioral_143025')

# 自定义查询
results = manager.query_records(
    record_type="execution",
    tags=["测试"],
    priority="high"
)
```

---

## 自动学习

### 1. 从指令学习

```python
from auto_learner import learn_from_instruction

# 自动分析并创建规则
result = learn_from_instruction(
    instruction="所有提交前必须运行测试",
    context="代码提交流程",
    auto_create=True
)

print(f"创建了 {len(result['created_rules'])} 条规则")
print(f"建议: {result['suggestions']}")
```

**自动识别：**
- 类别: `deny` (检测到"必须")
- 优先级: `high` (检测到"必须")
- 标签: ["测试", "工作流"]

### 2. 从执行记录学习

```python
from auto_learner import learn_from_executions

# 自动发现模式
result = learn_from_executions(
    days=7,
    min_occurrences=3
)

print(f"检测到 {len(result['patterns_detected'])} 个模式")
print(f"建议 {len(result['rules_suggested'])} 条规则")
```

**自动发现：**
- 高频命令模式
- 高频标签模式
- 工作流优化建议

### 3. 知识衰减

```python
from auto_learner import AutoLearningManager

manager = AutoLearningManager()

# 应用知识衰减
result = manager.apply_knowledge_decay(days_threshold=30)

print(f"处理了 {result['rules_processed']} 条规则")
print(f"衰减了 {result['rules_decayed']} 条规则")
```

**衰减机制：**
- 30天未使用: 效果分数 × 0.9
- 60天未使用: 效果分数 × 0.81
- 90天未使用: 效果分数 × 0.729
- 最低保持: 0.1

### 4. 学习统计

```python
from auto_learner import get_learning_stats

stats = get_learning_stats()

print(f"总规则数: {stats['total_rules']}")
print(f"总偏好数: {stats['total_preferences']}")
print(f"自动学习规则: {stats['auto_learned_rules']}")
print(f"平均效果分数: {stats['avg_effectiveness']}")
```

---

## 最佳实践

### 1. 规则命名规范

**好的规则：**
- ✅ "提交代码前必须运行测试"
- ✅ "使用 pnpm 而不是 npm"
- ✅ "避免在生产环境使用 console.log"

**不好的规则：**
- ❌ "要注意测试"
- ❌ "用那个工具"
- ❌ "不要乱用东西"

### 2. 标签使用

**推荐标签体系：**
- 功能标签: 测试、部署、备份、监控
- 技术标签: Node.js、Python、Git、Docker
- 层级标签: 安全、性能、可维护性
- 项目标签: OpenClaw、知识库、前端

**示例：**
```python
create_behavioral_rule(
    rule="所有 API 端点必须有错误处理",
    tags=["API", "错误处理", "后端", "安全"]
)
```

### 3. 上下文说明

**提供清晰的上下文：**
```python
create_behavioral_rule(
    rule="禁止直接操作生产数据库",
    context="所有涉及数据库操作的场景",
    rationale="防止数据丢失和不可逆操作",
    examples=["删除用户数据", "修改表结构"],
    counter_examples=["通过 API 修改", "使用迁移脚本"]
)
```

### 4. 持续更新

**定期回顾和优化：**
```python
# 每周运行一次
manager = AutoLearningManager()

# 1. 应用知识衰减
manager.apply_knowledge_decay(days_threshold=30)

# 2. 检测新模式
manager.learn_from_executions(days=7)

# 3. 查看统计
stats = manager.get_learning_stats()
```

---

## 进阶用法

### 1. 批量导入

```python
from manager import KnowledgeManager
import json

manager = KnowledgeManager()

# 从 JSON 文件批量导入
with open('rules_backup.json', 'r') as f:
    rules = json.load(f)

for rule_data in rules:
    manager.create_behavioral_rule(**rule_data)
```

### 2. 导出知识库

```python
import json

# 导出所有规则
rules = query_records(record_type="behavioral", limit=1000)

with open('rules_export.json', 'w') as f:
    json.dump(rules, f, indent=2, ensure_ascii=False)
```

### 3. 自定义分析器

```python
from learner import KnowledgeLearner

class CustomLearner(KnowledgeLearner):
    def analyze_instruction(self, instruction, context=None):
        result = super().analyze_instruction(instruction, context)
        
        # 添加自定义逻辑
        if '紧急' in instruction or 'urgent' in instruction.lower():
            result['suggested_priority'] = 'high'
            result['confidence'] = 0.9
        
        return result
```

### 4. 集成到工作流

```python
# 在项目构建脚本中使用
def pre_commit_check():
    rules = query_records(tags=["提交", "测试"])
    
    for rule in rules:
        if rule['category'] == 'deny':
            print(f"⚠️  必须遵守: {rule['rule']}")
            # 执行检查逻辑...
```

---

## 下一步

- 探索 [API 参考](API_REFERENCE.md)
- 查看 [示例代码](examples/)
- 了解 [Phase 3 知识图谱](PHASE3_PLAN.md)
- 加入 [ClawHub 社区](https://clawhub.ai/)

## 获取帮助

- 📖 查看 [FAQ](FAQ.md)
- 💬 加入 [Discord 讨论](https://discord.gg/clawd)
- 🐛 提交 [Issue](https://github.com/your-repo/knowledge-base/issues)
