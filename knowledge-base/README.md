# Knowledge Base

AI 知识管理系统 - 记录用户教导的规则和执行经验

## 核心理念

**我教AI做人，你帮我做事**

这个知识库系统帮助 AI：
- 学习用户的规则和偏好
- 记录任务执行过程
- 积累问题解决方案
- 持续优化服务质量

## 目录

- [使用指南](docs/USAGE.md)
- [数据模板](templates/)

## 快速开始

```bash
# CLI 方式
python3 cli.py create-behavioral --rule "禁止删除文件" --category deny --priority high

# Python API
from manager import create_behavioral_rule
create_behavioral_rule(rule="禁止删除文件", category="deny", priority="high")
```

## 许可证

MIT
