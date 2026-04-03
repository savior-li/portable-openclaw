#!/usr/bin/env python3
"""
示例 1: 基础使用 - 创建和查询规则
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from manager import (
    create_behavioral_rule,
    create_preference,
    query_records
)

def example_basic_usage():
    """基础使用示例"""
    
    print("=" * 60)
    print("示例 1: 基础使用")
    print("=" * 60)
    print()
    
    # 1. 创建行为规则
    print("[1] 创建行为规则...")
    path1 = create_behavioral_rule(
        rule="所有 API 调用必须有错误处理",
        category="deny",
        context="后端 API 开发",
        priority="high",
        tags=["API", "错误处理", "后端"],
        examples=[
            "使用 try-catch 包裹 API 调用",
            "返回统一的错误响应格式"
        ],
        rationale="确保系统稳定性和用户体验"
    )
    print(f"✓ 创建规则: {path1}")
    print()
    
    # 2. 创建偏好设置
    print("[2] 创建偏好设置...")
    path2 = create_preference(
        preference="使用 TypeScript 而不是 JavaScript",
        category="style",
        context="前端项目开发",
        priority="high",
        tags=["前端", "TypeScript", "代码质量"],
        alternatives=["JavaScript", "Flow"],
        reason="TypeScript 提供更好的类型安全和开发体验"
    )
    print(f"✓ 创建偏好: {path2}")
    print()
    
    # 3. 查询规则
    print("[3] 查询规则...")
    rules = query_records(record_type="behavioral", tags=["API"])
    
    print(f"找到 {len(rules)} 条关于 API 的规则:")
    for rule in rules:
        print(f"  - {rule['rule']} ({rule['category']})")
    print()
    
    print("=" * 60)
    print("示例完成")
    print("=" * 60)

if __name__ == '__main__':
    example_basic_usage()
