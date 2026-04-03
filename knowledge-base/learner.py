#!/usr/bin/env python3
"""
知识学习引擎 - 自动从用户交互中学习规则和偏好
"""

import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from collections import Counter


class KnowledgeLearner:
    """智能知识学习引擎"""
    
    def __init__(self, knowledge_base_path: str = '/workspace/knowledge-base'):
        self.kb_path = Path(knowledge_base_path)
        self.rules_path = self.kb_path / 'rules'
        self.cases_path = self.kb_path / 'cases'
    
    def analyze_instruction(self, instruction: str, context: str = None) -> Dict[str, Any]:
        """
        分析用户指令，自动提取规则
        
        Args:
            instruction: 用户指令文本
            context: 上下文信息
        
        Returns:
            提取的规则信息
        """
        result = {
            'original_instruction': instruction,
            'extracted_rules': [],
            'extracted_preferences': [],
            'keywords': [],
            'suggested_category': None,
            'suggested_priority': 'medium',
            'confidence': 0.0
        }
        
        # 关键词模式检测
        patterns = {
            'deny': [
                r'不要|禁止|不能|不允许|千万别',
                r'never|don\'t|do not|forbidden|must not',
            ],
            'recommend': [
                r'建议|推荐|最好|应该|记得',
                r'recommend|suggest|should|better to|remember to',
            ],
            'prefer': [
                r'优先|更喜欢|倾向于|prefer|favor',
                r'prefer|favor|rather|more likely',
            ],
            'avoid': [
                r'避免|尽量不要|少用|avoid|try not',
                r'avoid|try not|minimize|reduce',
            ]
        }
        
        # 检测类别
        detected_categories = []
        for category, pattern_list in patterns.items():
            for pattern in pattern_list:
                if re.search(pattern, instruction, re.IGNORECASE):
                    detected_categories.append(category)
                    break
        
        if detected_categories:
            result['suggested_category'] = detected_categories[0]
            result['confidence'] = 0.8
        
        # 优先级检测
        if any(keyword in instruction for keyword in ['必须', '重要', '关键', '紧急', 'must', 'important', 'critical', 'urgent']):
            result['suggested_priority'] = 'high'
        elif any(keyword in instruction for keyword in ['可选', '尽量', 'optional', 'nice to have']):
            result['suggested_priority'] = 'low'
        
        # 提取关键词
        keywords = self._extract_keywords(instruction)
        result['keywords'] = keywords
        
        # 自动标签建议
        tags = self._suggest_tags(instruction, keywords)
        
        # 提取规则
        if result['suggested_category']:
            rule = {
                'rule': instruction,
                'category': result['suggested_category'],
                'priority': result['suggested_priority'],
                'tags': tags,
                'context': context or '',
                'rationale': '从用户指令自动提取',
                'created_by': 'learner'
            }
            result['extracted_rules'].append(rule)
        
        return result
    
    def detect_pattern(self, execution_records: List[Dict[str, Any]], 
                       min_occurrences: int = 3) -> List[Dict[str, Any]]:
        """
        检测重复行为模式，自动生成规则
        
        Args:
            execution_records: 执行记录列表
            min_occurrences: 最小出现次数
        
        Returns:
            检测到的模式列表
        """
        patterns = []
        
        # 统计命令频率
        command_counter = Counter()
        tag_counter = Counter()
        
        for record in execution_records:
            if 'command' in record:
                command_counter[record['command']] += 1
            if 'tags' in record:
                for tag in record['tags']:
                    tag_counter[tag] += 1
        
        # 检测高频命令
        for command, count in command_counter.most_common():
            if count >= min_occurrences:
                pattern = {
                    'type': 'frequent_command',
                    'command': command,
                    'occurrences': count,
                    'suggested_rule': f"当执行 {command} 时，使用标准流程",
                    'confidence': min(count / 10.0, 1.0)
                }
                patterns.append(pattern)
        
        # 检测高频标签
        for tag, count in tag_counter.most_common(5):
            if count >= min_occurrences:
                pattern = {
                    'type': 'frequent_tag',
                    'tag': tag,
                    'occurrences': count,
                    'suggested_rule': f"在涉及 {tag} 的任务中，注意相关规范",
                    'confidence': min(count / 10.0, 1.0)
                }
                patterns.append(pattern)
        
        return patterns
    
    def resolve_conflict(self, old_rule: Dict[str, Any], 
                        new_rule: Dict[str, Any]) -> Dict[str, Any]:
        """
        解决规则冲突，智能合并
        
        Args:
            old_rule: 旧规则
            new_rule: 新规则
        
        Returns:
            合并后的规则
        """
        # 检测冲突类型
        if old_rule.get('category') != new_rule.get('category'):
            # 类别冲突
            conflict_type = 'category_mismatch'
            # 优先保留更严格的规则
            priority_order = {'deny': 4, 'avoid': 3, 'recommend': 2, 'prefer': 1}
            if priority_order.get(old_rule.get('category'), 0) >= priority_order.get(new_rule.get('category'), 0):
                merged = old_rule.copy()
                merged['rationale'] = f"保留更严格的规则: {old_rule.get('category')}"
            else:
                merged = new_rule.copy()
                merged['rationale'] = f"采用更严格的新规则: {new_rule.get('category')}"
        
        elif old_rule.get('priority') != new_rule.get('priority'):
            # 优先级冲突
            conflict_type = 'priority_mismatch'
            priority_order = {'high': 3, 'medium': 2, 'low': 1}
            if priority_order.get(old_rule.get('priority'), 0) >= priority_order.get(new_rule.get('priority'), 0):
                merged = old_rule.copy()
            else:
                merged = new_rule.copy()
        
        else:
            # 内容冲突，合并标签和示例
            conflict_type = 'content_overlap'
            merged = old_rule.copy()
            merged['tags'] = list(set(old_rule.get('tags', []) + new_rule.get('tags', [])))
            merged['examples'] = list(set(old_rule.get('examples', []) + new_rule.get('examples', [])))
            merged['rationale'] = '合并两条相似规则'
        
        merged['conflict_resolved'] = True
        merged['conflict_type'] = conflict_type
        merged['merged_at'] = datetime.now().isoformat()
        merged['version'] = f"{old_rule.get('version', '1.0.0')} -> merged"
        
        return merged
    
    def apply_decay(self, rules: List[Dict[str, Any]], 
                   decay_threshold: int = 30,
                   decay_factor: float = 0.9) -> List[Dict[str, Any]]:
        """
        应用知识衰减机制，降低长期未使用规则的影响
        
        Args:
            rules: 规则列表
            decay_threshold: 衰减阈值（天）
            decay_factor: 衰减因子
        
        Returns:
            更新后的规则列表
        """
        updated_rules = []
        now = datetime.now()
        
        for rule in rules:
            last_used_str = rule.get('last_used', '')
            if last_used_str:
                try:
                    last_used = datetime.fromisoformat(last_used_str)
                    days_unused = (now - last_used).days
                    
                    if days_unused > decay_threshold:
                        # 应用衰减
                        effectiveness = rule.get('effectiveness_score', 1.0)
                        decay_times = days_unused // decay_threshold
                        new_effectiveness = effectiveness * (decay_factor ** decay_times)
                        
                        rule['effectiveness_score'] = max(new_effectiveness, 0.1)
                        rule['decayed'] = True
                        rule['decay_days'] = days_unused
                except Exception:
                    pass
            
            updated_rules.append(rule)
        
        return updated_rules
    
    def _extract_keywords(self, text: str) -> List[str]:
        """提取关键词"""
        # 简单的关键词提取（可以后续用 NLP 增强）
        stop_words = {'的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这'}
        
        # 中文分词（简单版）
        words = []
        # 提取中文词汇
        chinese_pattern = re.compile(r'[\u4e00-\u9fa5]+')
        chinese_words = chinese_pattern.findall(text)
        
        # 提取英文词汇
        english_pattern = re.compile(r'\b[a-zA-Z]+\b')
        english_words = english_pattern.findall(text)
        
        words.extend([w for w in chinese_words if w not in stop_words and len(w) > 1])
        words.extend([w.lower() for w in english_words if len(w) > 2])
        
        return list(set(words))
    
    def _suggest_tags(self, instruction: str, keywords: List[str]) -> List[str]:
        """建议标签"""
        tags = []
        
        # 基于关键词的标签映射
        tag_mapping = {
            '删除': '文件操作',
            'delete': '文件操作',
            '安装': '工具安装',
            'install': '工具安装',
            'git': '版本控制',
            'npm': 'Node.js',
            'python': 'Python',
            '备份': '备份',
            'backup': '备份',
            '测试': '测试',
            'test': '测试',
            '安全': '安全',
            'security': '安全',
        }
        
        for keyword in keywords:
            if keyword in tag_mapping:
                tags.append(tag_mapping[keyword])
        
        return list(set(tags))
    
    def learn_from_feedback(self, record_id: str, feedback: str, 
                           rating: int = None) -> Dict[str, Any]:
        """
        从反馈中学习
        
        Args:
            record_id: 记录ID
            feedback: 反馈内容
            rating: 评分 (1-5)
        
        Returns:
            学习结果
        """
        result = {
            'record_id': record_id,
            'feedback': feedback,
            'rating': rating,
            'action_taken': None,
            'suggestions': []
        }
        
        # 根据反馈类型采取行动
        if rating and rating < 3:
            # 低评分，建议删除或修改规则
            result['action_taken'] = 'mark_for_review'
            result['suggestions'].append('该规则效果不佳，建议审查或删除')
        
        elif rating and rating >= 4:
            # 高评分，增强规则
            result['action_taken'] = 'reinforce'
            result['suggestions'].append('该规则效果良好，可以扩展应用范围')
        
        # 从反馈文本中提取改进建议
        if '应该' in feedback or '建议' in feedback:
            analysis = self.analyze_instruction(feedback)
            result['suggestions'].extend([f"建议添加规则: {rule['rule']}" for rule in analysis['extracted_rules']])
        
        return result


# 便捷函数
def analyze_instruction(instruction: str, context: str = None) -> Dict[str, Any]:
    """分析用户指令"""
    learner = KnowledgeLearner()
    return learner.analyze_instruction(instruction, context)


def detect_pattern(execution_records: List[Dict[str, Any]], min_occurrences: int = 3) -> List[Dict[str, Any]]:
    """检测重复模式"""
    learner = KnowledgeLearner()
    return learner.detect_pattern(execution_records, min_occurrences)


def resolve_conflict(old_rule: Dict[str, Any], new_rule: Dict[str, Any]) -> Dict[str, Any]:
    """解决规则冲突"""
    learner = KnowledgeLearner()
    return learner.resolve_conflict(old_rule, new_rule)
