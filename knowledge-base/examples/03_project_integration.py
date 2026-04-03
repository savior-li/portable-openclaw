#!/usr/bin/env python3
"""
示例 3: 项目集成 - 将知识库集成到实际项目
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from manager import query_records, create_execution
from learner import KnowledgeLearner

def check_pre_commit_rules():
    """检查提交前的规则"""
    print("[Pre-commit Check] 检查提交前规则...")
    
    # 查询所有 deny 类别的规则
    rules = query_records(category="deny", priority="high")
    
    violations = []
    for rule in rules:
        print(f"  检查: {rule['rule']}")
        
        # 这里可以添加实际的检查逻辑
        # 例如：检查测试是否通过、代码风格是否符合等
        
        # 示例：检查是否有测试
        if "测试" in rule['rule'] or "test" in rule['rule'].lower():
            print(f"    ✓ 需要运行测试")
        
        # 示例：检查代码注释
        if "注释" in rule['rule']:
            print(f"    ✓ 需要检查代码注释")
    
    return len(violations) == 0

def analyze_code_review(comment: str):
    """分析代码审查意见，自动学习"""
    print(f"\n[Code Review Analysis] 分析: {comment}")
    
    learner = KnowledgeLearner()
    result = learner.analyze_instruction(comment)
    
    if result['suggested_category']:
        print(f"  检测到规则类别: {result['suggested_category']}")
        print(f"  建议优先级: {result['suggested_priority']}")
        print(f"  关键词: {', '.join(result['keywords'])}")
        
        # 如果置信度足够高，可以自动创建规则
        if result['confidence'] >= 0.8:
            print(f"  ✓ 建议创建规则")
            return result
    
    return None

def record_project_milestone(task: str, outcome: str):
    """记录项目里程碑"""
    print(f"\n[Milestone] 记录: {task}")
    
    path = create_execution(
        command=f"项目里程碑: {task}",
        steps=["规划", "执行", "验证"],
        outcome=outcome,
        tags=["里程碑", "项目"],
        learnings=["完成阶段目标"]
    )
    
    print(f"  ✓ 已记录: {path}")
    return path

def example_project_integration():
    """项目集成示例"""
    
    print("=" * 60)
    print("示例 3: 项目集成")
    print("=" * 60)
    print()
    
    # 1. Pre-commit 检查
    print("[1] Pre-commit 检查...")
    if check_pre_commit_rules():
        print("✓ 所有规则检查通过，可以提交代码")
    else:
        print("✗ 存在规则违反，请修复后再提交")
    print()
    
    # 2. 代码审查学习
    print("[2] 代码审查学习...")
    review_comments = [
        "这个函数太长了，建议拆分",
        "这里缺少错误处理",
        "变量命名不够清晰"
    ]
    
    for comment in review_comments:
        suggestion = analyze_code_review(comment)
        if suggestion:
            print(f"  可以创建规则: {comment}")
    print()
    
    # 3. 记录里程碑
    print("[3] 记录项目里程碑...")
    record_project_milestone(
        task="完成用户认证模块",
        outcome="success"
    )
    
    record_project_milestone(
        task="完成 API 文档",
        outcome="success"
    )
    print()
    
    # 4. 生成项目报告
    print("[4] 项目知识库报告...")
    
    all_rules = query_records(limit=100)
    behavioral = [r for r in all_rules if r['type'] == 'behavioral']
    preferences = [r for r in all_rules if r['type'] == 'preferences']
    executions = [r for r in all_rules if r['type'] == 'execution']
    
    print(f"  总规则数: {len(behavioral)}")
    print(f"  总偏好数: {len(preferences)}")
    print(f"  总执行记录: {len(executions)}")
    
    # 高优先级规则
    high_priority = [r for r in behavioral if r.get('priority') == 'high']
    print(f"  高优先级规则: {len(high_priority)}")
    
    # 打印高优先级规则
    if high_priority:
        print("\n  高优先级规则列表:")
        for i, rule in enumerate(high_priority[:5], 1):
            print(f"    {i}. {rule['rule']}")
    
    print()
    print("=" * 60)
    print("示例完成")
    print("=" * 60)

if __name__ == '__main__':
    example_project_integration()
