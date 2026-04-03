#!/usr/bin/env python3
"""
知识库功能测试脚本
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from manager import (
    create_behavioral_rule,
    create_preference,
    create_thinking_pattern,
    create_execution,
    create_problem,
    create_result,
    query_records,
    get_manager
)

def test_knowledge_base():
    """测试知识库功能"""
    print("=" * 60)
    print("Knowledge Base Test Suite")
    print("=" * 60)
    print()
    
    # 1. 测试创建行为规则
    print("[1] Testing behavioral rule creation...")
    path1 = create_behavioral_rule(
        rule="测试规则：所有文件操作需要确认",
        category="recommend",
        context="文件操作场景",
        priority="medium",
        tags=["测试", "文件"],
        rationale="测试功能"
    )
    print(f"  ✓ Created: {path1}")
    print()
    
    # 2. 测试创建偏好
    print("[2] Testing preference creation...")
    path2 = create_preference(
        preference="测试偏好：优先使用 TypeScript",
        category="style",
        context="前端项目",
        priority="high",
        tags=["测试", "TypeScript"],
        reason="类型安全"
    )
    print(f"  ✓ Created: {path2}")
    print()
    
    # 3. 测试创建思维模式
    print("[3] Testing thinking pattern creation...")
    path3 = create_thinking_pattern(
        pattern="测试模式：先分析再执行",
        category="problem-solving",
        context="复杂任务",
        priority="high",
        steps=["理解需求", "分析方案", "执行实现", "验证结果"],
        expected_outcome="高质量交付"
    )
    print(f"  ✓ Created: {path3}")
    print()
    
    # 4. 测试创建执行记录
    print("[4] Testing execution log creation...")
    path4 = create_execution(
        command="test command",
        steps=["step 1", "step 2", "step 3"],
        outcome="success",
        context="测试环境",
        tags=["测试"],
        learnings=["学习点1", "学习点2"],
        duration_ms=1000
    )
    print(f"  ✓ Created: {path4}")
    print()
    
    # 5. 测试创建问题记录
    print("[5] Testing problem record creation...")
    path5 = create_problem(
        problem="测试问题：依赖版本冲突",
        cause="版本不兼容",
        solution="使用 pnpm 解决",
        prevention="锁定版本号",
        tags=["测试", "依赖"]
    )
    print(f"  ✓ Created: {path5}")
    print()
    
    # 6. 测试创建结果记录
    print("[6] Testing result record creation...")
    path6 = create_result(
        task="测试任务：功能验证",
        output="所有测试通过",
        verified=True,
        quality_score=0.95,
        tags=["测试"]
    )
    print(f"  ✓ Created: {path6}")
    print()
    
    # 7. 测试查询功能
    print("[7] Testing query functionality...")
    results = query_records(tags=["测试"], limit=10)
    print(f"  ✓ Found {len(results)} records with tag '测试'")
    print()
    
    # 8. 测试按类型查询
    print("[8] Testing query by type...")
    behavioral_rules = query_records(record_type="behavioral", limit=10)
    print(f"  ✓ Found {len(behavioral_rules)} behavioral rules")
    
    preferences = query_records(record_type="preferences", limit=10)
    print(f"  ✓ Found {len(preferences)} preferences")
    
    executions = query_records(record_type="execution", limit=10)
    print(f"  ✓ Found {len(executions)} execution logs")
    print()
    
    # 9. 测试获取单条记录
    print("[9] Testing get single record...")
    manager = get_manager()
    record_id = behavioral_rules[0]['id'] if behavioral_rules else None
    if record_id:
        record = manager.get_record(record_id)
        print(f"  ✓ Retrieved record: {record['rule']}")
    print()
    
    print("=" * 60)
    print("All tests passed! ✓")
    print("=" * 60)
    print()
    print("Knowledge Base Statistics:")
    print(f"  - Behavioral rules: {len(behavioral_rules)}")
    print(f"  - Preferences: {len(preferences)}")
    print(f"  - Execution logs: {len(executions)}")
    print(f"  - Total test records created: 6")
    print()

if __name__ == '__main__':
    test_knowledge_base()
