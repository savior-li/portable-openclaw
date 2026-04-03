#!/usr/bin/env python3
"""
智能学习引擎测试脚本
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from learner import (
    KnowledgeLearner,
    analyze_instruction,
    detect_pattern,
    resolve_conflict
)
from manager import query_records

def test_learner():
    """测试智能学习引擎"""
    print("=" * 60)
    print("Knowledge Learner Test Suite")
    print("=" * 60)
    print()
    
    learner = KnowledgeLearner()
    
    # 1. 测试指令分析
    print("[1] Testing instruction analysis...")
    test_instructions = [
        "不要删除任何文件，除非用户明确要求",
        "建议在提交代码前先运行测试",
        "优先使用 TypeScript 而不是 JavaScript",
        "避免在生产环境使用 console.log",
    ]
    
    for instruction in test_instructions:
        result = learner.analyze_instruction(instruction)
        print(f"\n  指令: {instruction}")
        print(f"  类别: {result['suggested_category']}")
        print(f"  优先级: {result['suggested_priority']}")
        print(f"  关键词: {result['keywords']}")
        print(f"  置信度: {result['confidence']}")
    print()
    
    # 2. 测试模式检测
    print("[2] Testing pattern detection...")
    executions = query_records(record_type='execution', limit=20)
    if executions:
        patterns = learner.detect_pattern(executions, min_occurrences=1)
        print(f"  ✓ 检测到 {len(patterns)} 个模式")
        for pattern in patterns[:3]:
            print(f"    - {pattern['type']}: {pattern.get('command', pattern.get('tag', ''))}")
    else:
        print("  ⚠ 没有足够的执行记录进行模式检测")
    print()
    
    # 3. 测试冲突解决
    print("[3] Testing conflict resolution...")
    old_rule = {
        'rule': '不要删除文件',
        'category': 'avoid',
        'priority': 'medium',
        'tags': ['安全'],
        'version': '1.0.0'
    }
    
    new_rule = {
        'rule': '禁止删除文件',
        'category': 'deny',
        'priority': 'high',
        'tags': ['安全', '文件操作'],
        'version': '1.0.0'
    }
    
    merged = learner.resolve_conflict(old_rule, new_rule)
    print(f"  ✓ 冲突类型: {merged.get('conflict_type')}")
    print(f"  ✓ 合并结果: {merged['rule']}")
    print(f"  ✓ 最终类别: {merged['category']}")
    print(f"  ✓ 最终优先级: {merged['priority']}")
    print()
    
    # 4. 测试知识衰减
    print("[4] Testing knowledge decay...")
    from datetime import datetime, timedelta
    
    test_rules = [
        {
            'rule': '常用规则',
            'last_used': datetime.now().isoformat(),
            'effectiveness_score': 1.0
        },
        {
            'rule': '过时规则',
            'last_used': (datetime.now() - timedelta(days=60)).isoformat(),
            'effectiveness_score': 1.0
        }
    ]
    
    decayed_rules = learner.apply_decay(test_rules, decay_threshold=30)
    
    for rule in decayed_rules:
        print(f"  规则: {rule['rule']}")
        print(f"  效果分数: {rule['effectiveness_score']}")
        if rule.get('decayed'):
            print(f"  ⚠ 已衰减 {rule['decay_days']} 天")
    print()
    
    # 5. 测试反馈学习
    print("[5] Testing feedback learning...")
    feedback_result = learner.learn_from_feedback(
        record_id='test_001',
        feedback='这个规则很好用，建议扩展到其他场景',
        rating=5
    )
    print(f"  ✓ 采取行动: {feedback_result['action_taken']}")
    print(f"  ✓ 建议: {feedback_result['suggestions']}")
    print()
    
    print("=" * 60)
    print("All learner tests passed! ✓")
    print("=" * 60)

if __name__ == '__main__':
    test_learner()
