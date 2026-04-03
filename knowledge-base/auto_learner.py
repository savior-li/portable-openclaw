#!/usr/bin/env python3
"""
自动学习集成模块 - 将学习引擎集成到知识库管理器
"""

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from manager import KnowledgeManager
from learner import KnowledgeLearner


class AutoLearningManager:
    """自动学习管理器 - 整合学习引擎和知识库"""
    
    def __init__(self, knowledge_base_path: str = '/workspace/knowledge-base'):
        self.kb_path = Path(knowledge_base_path)
        self.manager = KnowledgeManager(knowledge_base_path)
        self.learner = KnowledgeLearner(knowledge_base_path)
    
    def learn_from_instruction(self, instruction: str, context: str = None,
                               auto_create: bool = True,
                               ask_confirmation: bool = False) -> Dict[str, Any]:
        """
        从用户指令中学习，自动创建规则
        
        Args:
            instruction: 用户指令
            context: 上下文
            auto_create: 是否自动创建规则
            ask_confirmation: 是否需要确认（暂未实现）
        
        Returns:
            学习结果
        """
        result = {
            'instruction': instruction,
            'analysis': None,
            'created_rules': [],
            'suggestions': []
        }
        
        # 分析指令
        analysis = self.learner.analyze_instruction(instruction, context)
        result['analysis'] = analysis
        
        # 自动创建规则
        if auto_create and analysis['extracted_rules']:
            for rule_data in analysis['extracted_rules']:
                # 检查是否存在相似规则
                similar_rules = self._find_similar_rules(rule_data['rule'])
                
                if similar_rules:
                    # 发现相似规则，合并或更新
                    result['suggestions'].append(
                        f"发现相似规则: {similar_rules[0]['rule']}, 建议合并"
                    )
                else:
                    # 创建新规则
                    path = self.manager.create_behavioral_rule(
                        rule=rule_data['rule'],
                        category=rule_data['category'],
                        context=rule_data.get('context', ''),
                        priority=rule_data['priority'],
                        tags=rule_data['tags'],
                        rationale=rule_data.get('rationale', '从用户指令自动学习'),
                        created_by='learner-auto'
                    )
                    result['created_rules'].append(path)
        
        return result
    
    def learn_from_executions(self, days: int = 7, min_occurrences: int = 3) -> Dict[str, Any]:
        """
        从执行记录中学习，发现模式
        
        Args:
            days: 分析最近几天的记录
            min_occurrences: 最小出现次数
        
        Returns:
            学习结果
        """
        result = {
            'patterns_detected': [],
            'rules_suggested': [],
            'created_rules': []
        }
        
        # 获取执行记录
        executions = self.manager.query_records(record_type='execution', limit=100)
        
        if not executions:
            return result
        
        # 检测模式
        patterns = self.learner.detect_pattern(executions, min_occurrences)
        result['patterns_detected'] = patterns
        
        # 从模式创建规则建议
        for pattern in patterns:
            if pattern['type'] == 'frequent_command':
                suggestion = {
                    'type': 'workflow',
                    'pattern': pattern,
                    'suggested_rule': f"执行 {pattern['command']} 时遵循标准流程",
                    'confidence': pattern['confidence']
                }
                result['rules_suggested'].append(suggestion)
                
                # 如果置信度足够高，自动创建
                if pattern['confidence'] >= 0.7:
                    path = self.manager.create_thinking_pattern(
                        pattern=f"执行 {pattern['command']} 的标准流程",
                        category='workflow',
                        context='自动化工作流',
                        priority='medium',
                        tags=['自动学习', '工作流'],
                        created_by='learner-pattern'
                    )
                    result['created_rules'].append(path)
        
        return result
    
    def apply_knowledge_decay(self, days_threshold: int = 30) -> Dict[str, Any]:
        """
        应用知识衰减机制
        
        Args:
            days_threshold: 衰减阈值（天）
        
        Returns:
            衰减结果
        """
        result = {
            'rules_processed': 0,
            'rules_decayed': 0,
            'updated_files': []
        }
        
        # 获取所有行为规则
        rules = self.manager.query_records(record_type='behavioral', limit=1000)
        
        # 应用衰减
        decayed_rules = self.learner.apply_decay(rules, decay_threshold=days_threshold)
        
        # 更新文件
        for rule in decayed_rules:
            if rule.get('decayed'):
                result['rules_decayed'] += 1
                # 更新文件
                self._update_rule_file(rule)
                result['updated_files'].append(rule['id'])
            
            result['rules_processed'] += 1
        
        return result
    
    def resolve_rule_conflicts(self) -> Dict[str, Any]:
        """
        检测并解决规则冲突
        
        Returns:
            冲突解决结果
        """
        result = {
            'conflicts_detected': 0,
            'conflicts_resolved': 0,
            'merged_rules': []
        }
        
        # 获取所有规则
        rules = self.manager.query_records(record_type='behavioral', limit=1000)
        
        # 检测冲突（简单实现：检查规则文本相似度）
        for i, rule1 in enumerate(rules):
            for rule2 in rules[i+1:]:
                if self._are_rules_similar(rule1, rule2):
                    result['conflicts_detected'] += 1
                    
                    # 解决冲突
                    merged = self.learner.resolve_conflict(rule1, rule2)
                    
                    # 保存合并后的规则
                    self._update_rule_file(merged)
                    
                    result['conflicts_resolved'] += 1
                    result['merged_rules'].append({
                        'rule1': rule1['id'],
                        'rule2': rule2['id'],
                        'merged': merged['id']
                    })
        
        return result
    
    def get_learning_stats(self) -> Dict[str, Any]:
        """
        获取学习统计信息
        
        Returns:
            统计信息
        """
        stats = {
            'total_rules': 0,
            'total_preferences': 0,
            'total_executions': 0,
            'total_problems': 0,
            'auto_learned_rules': 0,
            'decayed_rules': 0,
            'avg_effectiveness': 0.0
        }
        
        # 统计各类记录
        stats['total_rules'] = len(self.manager.query_records(record_type='behavioral', limit=1000))
        stats['total_preferences'] = len(self.manager.query_records(record_type='preferences', limit=1000))
        stats['total_executions'] = len(self.manager.query_records(record_type='execution', limit=1000))
        stats['total_problems'] = len(self.manager.query_records(record_type='problem', limit=1000))
        
        # 统计自动学习的规则
        all_rules = self.manager.query_records(record_type='behavioral', limit=1000)
        stats['auto_learned_rules'] = sum(1 for r in all_rules if r.get('created_by') == 'learner-auto')
        stats['decayed_rules'] = sum(1 for r in all_rules if r.get('decayed', False))
        
        # 计算平均效果分数
        if all_rules:
            effectiveness_scores = [r.get('effectiveness_score', 0) for r in all_rules]
            stats['avg_effectiveness'] = sum(effectiveness_scores) / len(effectiveness_scores)
        
        return stats
    
    def _find_similar_rules(self, rule_text: str, threshold: float = 0.8) -> List[Dict[str, Any]]:
        """查找相似规则"""
        similar = []
        all_rules = self.manager.query_records(record_type='behavioral', limit=1000)
        
        for rule in all_rules:
            # 简单的文本相似度（可以后续用更复杂的算法）
            if rule_text.lower() in rule['rule'].lower() or rule['rule'].lower() in rule_text.lower():
                similar.append(rule)
        
        return similar
    
    def _are_rules_similar(self, rule1: Dict[str, Any], rule2: Dict[str, Any]) -> bool:
        """判断两个规则是否相似"""
        # 简单实现：检查关键词重叠
        keywords1 = set(rule1.get('tags', []) + rule1['rule'].split())
        keywords2 = set(rule2.get('tags', []) + rule2['rule'].split())
        
        if not keywords1 or not keywords2:
            return False
        
        overlap = len(keywords1 & keywords2)
        union = len(keywords1 | keywords2)
        
        return overlap / union > 0.5 if union > 0 else False
    
    def _update_rule_file(self, rule: Dict[str, Any]):
        """更新规则文件"""
        if 'behavioral' in rule.get('id', ''):
            file_path = self.kb_path / 'rules' / 'behavioral' / f"{rule['id']}.json"
        elif 'preference' in rule.get('id', ''):
            file_path = self.kb_path / 'rules' / 'preferences' / f"{rule['id']}.json"
        else:
            return
        
        if file_path.exists():
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(rule, f, indent=2, ensure_ascii=False)


# 便捷函数
def learn_from_instruction(instruction: str, context: str = None, auto_create: bool = True) -> Dict[str, Any]:
    """从指令学习"""
    manager = AutoLearningManager()
    return manager.learn_from_instruction(instruction, context, auto_create)


def learn_from_executions(days: int = 7, min_occurrences: int = 3) -> Dict[str, Any]:
    """从执行记录学习"""
    manager = AutoLearningManager()
    return manager.learn_from_executions(days, min_occurrences)


def get_learning_stats() -> Dict[str, Any]:
    """获取学习统计"""
    manager = AutoLearningManager()
    return manager.get_learning_stats()
