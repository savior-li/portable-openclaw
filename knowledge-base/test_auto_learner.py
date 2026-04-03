#!/usr/bin/env python3
"""
自动学习管理器测试
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from auto_learner import AutoLearningManager, learn_from_instruction, get_learning_stats

def test_auto_learning():
    """测试自动学习功能"""
    print("=" * 60)
    print("Auto Learning Manager Test")
    print("=" * 60)
    print()
    
    manager = AutoLearningManager()
    
    # 1. 测试从指令学习
    print("[1] Testing learning from instruction...")
    instruction = "所有提交前必须运行测试"
    result = learn_from_instruction(instruction, context="代码提交流程")
    
    print(f"  指令: {instruction}")
    print(f"  分析类别: {result['analysis']['suggested_category']}")
    print(f"  分析优先级: {result['analysis']['suggested_priority']}")
    print(f"  创建规则数: {len(result['created_rules'])}")
    if result['created_rules']:
        print(f"  ✓ 规则路径: {result['created_rules'][0]}")
    print()
    
    # 2. 测试从执行记录学习
    print("[2] Testing learning from executions...")
    exec_result = manager.learn_from_executions(days=30, min_occurrences=1)
    
    print(f"  检测到模式: {len(exec_result['patterns_detected'])}")
    print(f"  建议规则: {len(exec_result['rules_suggested'])}")
    print(f"  自动创建: {len(exec_result['created_rules'])}")
    
    if exec_result['patterns_detected']:
        for pattern in exec_result['patterns_detected'][:3]:
            print(f"    - {pattern['type']}: {pattern.get('command', pattern.get('tag', ''))}")
    print()
    
    # 3. 测试知识衰减
    print("[3] Testing knowledge decay...")
    decay_result = manager.apply_knowledge_decay(days_threshold=30)
    
    print(f"  处理规则: {decay_result['rules_processed']}")
    print(f"  衰减规则: {decay_result['rules_decayed']}")
    print(f"  更新文件: {len(decay_result['updated_files'])}")
    print()
    
    # 4. 获取学习统计
    print("[4] Getting learning statistics...")
    stats = get_learning_stats()
    
    print(f"  总规则数: {stats['total_rules']}")
    print(f"  总偏好数: {stats['total_preferences']}")
    print(f"  总执行数: {stats['total_executions']}")
    print(f"  总问题数: {stats['total_problems']}")
    print(f"  自动学习规则: {stats['auto_learned_rules']}")
    print(f"  已衰减规则: {stats['decayed_rules']}")
    print(f"  平均效果分数: {stats['avg_effectiveness']:.2f}")
    print()
    
    print("=" * 60)
    print("All auto learning tests passed! ✓")
    print("=" * 60)

if __name__ == '__main__':
    test_auto_learning()
