#!/usr/bin/env python3
"""
示例 2: 自动学习 - 从指令和执行记录学习
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from auto_learner import (
    learn_from_instruction,
    learn_from_executions,
    get_learning_stats
)
from manager import create_execution

def example_auto_learning():
    """自动学习示例"""
    
    print("=" * 60)
    print("示例 2: 自动学习")
    print("=" * 60)
    print()
    
    # 1. 从指令学习
    print("[1] 从用户指令自动学习...")
    
    instructions = [
        "所有函数必须有注释",
        "建议使用 pnpm 而不是 npm",
        "禁止在生产环境使用 debug 模式",
        "避免在循环中进行数据库查询"
    ]
    
    for instruction in instructions:
        result = learn_from_instruction(
            instruction=instruction,
            auto_create=True
        )
        
        print(f"\n指令: {instruction}")
        print(f"  类别: {result['analysis']['suggested_category']}")
        print(f"  优先级: {result['analysis']['suggested_priority']}")
        print(f"  创建了 {len(result['created_rules'])} 条规则")
    
    print()
    
    # 2. 创建一些执行记录
    print("[2] 创建执行记录...")
    
    create_execution(
        command="npm test",
        steps=["运行单元测试", "检查覆盖率"],
        outcome="success",
        tags=["测试", "CI"],
        learnings=["测试覆盖率 85%"]
    )
    
    create_execution(
        command="npm run build",
        steps=["编译 TypeScript", "打包资源"],
        outcome="success",
        tags=["构建", "CI"]
    )
    
    print("✓ 创建了 2 条执行记录")
    print()
    
    # 3. 从执行记录学习
    print("[3] 从执行记录自动学习...")
    result = learn_from_executions(days=7, min_occurrences=1)
    
    print(f"检测到 {len(result['patterns_detected'])} 个模式")
    for pattern in result['patterns_detected']:
        print(f"  - {pattern['type']}: {pattern}")
    print()
    
    # 4. 查看学习统计
    print("[4] 学习统计...")
    stats = get_learning_stats()
    
    print(f"总规则数: {stats['total_rules']}")
    print(f"总偏好数: {stats['total_preferences']}")
    print(f"总执行数: {stats['total_executions']}")
    print(f"自动学习规则: {stats['auto_learned_rules']}")
    print()
    
    print("=" * 60)
    print("示例完成")
    print("=" * 60)

if __name__ == '__main__':
    example_auto_learning()
