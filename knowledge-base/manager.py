#!/usr/bin/env python3
"""
知识管理器 - Python API
提供简洁的 Python 接口管理知识库
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


class KnowledgeManager:
    """知识库管理器"""
    
    def __init__(self, base_path: str = None):
        self.base_path = Path(base_path or os.environ.get('KNOWLEDGE_BASE_PATH', '/workspace/knowledge-base'))
        self.templates_path = self.base_path / 'templates'
        self._ensure_structure()
    
    def _ensure_structure(self):
        """确保目录结构存在"""
        dirs = [
            'rules/behavioral',
            'rules/preferences', 
            'rules/thinking',
            'cases/executions',
            'cases/problems',
            'cases/results',
            'insights',
            'templates'
        ]
        for d in dirs:
            (self.base_path / d).mkdir(parents=True, exist_ok=True)
    
    def _generate_id(self, record_type: str) -> str:
        """生成唯一ID"""
        date_str = datetime.now().strftime('%Y%m%d')
        timestamp = datetime.now().strftime('%H%M%S')
        return f"{date_str}_{record_type}_{timestamp}"
    
    def _load_template(self, template_name: str) -> Dict[str, Any]:
        """加载模板"""
        template_path = self.templates_path / f"{template_name}.json"
        if template_path.exists():
            with open(template_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def _save_record(self, record: Dict[str, Any], record_type: str, subdir: str = None) -> str:
        """保存记录"""
        if record_type in ['behavioral', 'preferences', 'thinking']:
            save_dir = self.base_path / 'rules' / record_type
        elif record_type in ['execution', 'problem', 'result']:
            save_dir = self.base_path / 'cases' / f"{record_type}s"
        else:
            save_dir = self.base_path / 'insights'
        
        save_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"{record['id']}.json"
        file_path = save_dir / filename
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(record, f, indent=2, ensure_ascii=False)
        
        return str(file_path)
    
    # ========== 规则创建 ==========
    
    def create_behavioral_rule(self, rule: str, category: str, context: str = None,
                               priority: str = 'medium', tags: List[str] = None,
                               examples: List[str] = None, counter_examples: List[str] = None,
                               rationale: str = None, created_by: str = 'user') -> str:
        """
        创建行为规则
        
        Args:
            rule: 规则描述
            category: 类别
            context: 适用上下文
            priority: 优先级
            tags: 标签列表
            examples: 正例
            counter_examples: 反例
            rationale: 规则理由
            created_by: 创建者 (user/agent)
        
        Returns:
            保存的文件路径
        """
        template = self._load_template('behavioral')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('behavioral'),
            'rule': rule,
            'category': category,
            'context': context or '',
            'priority': priority,
            'tags': tags or [],
            'examples': examples or [],
            'counter_examples': counter_examples or [],
            'rationale': rationale or '',
            'created_by': created_by,
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'usage_count': 0,
            'last_used': '',
            'effectiveness_score': 0.0
        })
        
        return self._save_record(record, 'behavioral')
    
    def create_preference(self, preference: str, category: str, context: str = None,
                         priority: str = 'medium', tags: List[str] = None,
                         alternatives: List[str] = None, reason: str = None,
                         created_by: str = 'user') -> str:
        """创建偏好设置"""
        template = self._load_template('preferences')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('preference'),
            'preference': preference,
            'category': category,
            'context': context or '',
            'priority': priority,
            'tags': tags or [],
            'alternatives': alternatives or [],
            'reason': reason or '',
            'created_by': created_by,
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'usage_count': 0,
            'last_used': ''
        })
        
        return self._save_record(record, 'preferences')
    
    def create_thinking_pattern(self, pattern: str, category: str, context: str = None,
                                priority: str = 'medium', tags: List[str] = None,
                                steps: List[str] = None, expected_outcome: str = None,
                                created_by: str = 'user') -> str:
        """创建思维模式"""
        template = self._load_template('thinking')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('thinking'),
            'pattern': pattern,
            'category': category,
            'context': context or '',
            'priority': priority,
            'tags': tags or [],
            'steps': steps or [],
            'expected_outcome': expected_outcome or '',
            'created_by': created_by,
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'usage_count': 0,
            'last_used': ''
        })
        
        return self._save_record(record, 'thinking')
    
    # ========== 执行记录 ==========
    
    def create_execution(self, command: str, steps: List[str], outcome: str,
                        context: str = None, tags: List[str] = None,
                        learnings: List[str] = None, issues: List[str] = None,
                        duration_ms: int = 0) -> str:
        """创建执行记录"""
        template = self._load_template('execution')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('execution'),
            'command': command,
            'context': context or '',
            'steps': steps,
            'outcome': outcome,
            'duration_ms': duration_ms,
            'tags': tags or [],
            'learnings': learnings or [],
            'issues': issues or [],
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        return self._save_record(record, 'execution')
    
    def create_problem(self, problem: str, cause: str, solution: str,
                      context: str = None, prevention: str = None,
                      tags: List[str] = None, related_problems: List[str] = None) -> str:
        """创建问题记录"""
        template = self._load_template('problem')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('problem'),
            'problem': problem,
            'context': context or '',
            'cause': cause,
            'solution': solution,
            'prevention': prevention or '',
            'tags': tags or [],
            'related_problems': related_problems or [],
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'effectiveness_score': 0.0
        })
        
        return self._save_record(record, 'problem')
    
    def create_result(self, task: str, output: str, verified: bool = True,
                     context: str = None, quality_score: float = 0.0,
                     tags: List[str] = None, artifacts: List[str] = None) -> str:
        """创建结果记录"""
        template = self._load_template('result')
        record = template.copy()
        
        record.update({
            'id': self._generate_id('result'),
            'task': task,
            'context': context or '',
            'output': output,
            'verified': verified,
            'quality_score': quality_score,
            'tags': tags or [],
            'artifacts': artifacts or [],
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        return self._save_record(record, 'result')
    
    # ========== 查询 ==========
    
    def query_records(self, record_type: str = None, tags: List[str] = None,
                     category: str = None, priority: str = None,
                     limit: int = 10) -> List[Dict[str, Any]]:
        """
        查询记录
        
        Args:
            record_type: 记录类型
            tags: 标签过滤
            category: 类别过滤
            priority: 优先级过滤
            limit: 最大结果数
        
        Returns:
            匹配的记录列表
        """
        results = []
        
        search_paths = []
        if record_type:
            if record_type in ['behavioral', 'preferences', 'thinking']:
                search_paths.append(self.base_path / 'rules' / record_type)
            elif record_type in ['execution', 'problem', 'result']:
                search_paths.append(self.base_path / 'cases' / f"{record_type}s")
        else:
            search_paths.extend([
                self.base_path / 'rules' / 'behavioral',
                self.base_path / 'rules' / 'preferences',
                self.base_path / 'rules' / 'thinking',
                self.base_path / 'cases' / 'executions',
                self.base_path / 'cases' / 'problems',
                self.base_path / 'cases' / 'results'
            ])
        
        for search_path in search_paths:
            if not search_path.exists():
                continue
            
            for file_path in search_path.glob('*.json'):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        record = json.load(f)
                    
                    if tags and not any(tag in record.get('tags', []) for tag in tags):
                        continue
                    
                    if category and record.get('category') != category:
                        continue
                    
                    if priority and record.get('priority') != priority:
                        continue
                    
                    results.append(record)
                    
                    if len(results) >= limit:
                        return results
                except Exception:
                    continue
        
        return results
    
    def get_record(self, record_id: str) -> Optional[Dict[str, Any]]:
        """根据ID获取记录"""
        search_paths = [
            self.base_path / 'rules' / 'behavioral',
            self.base_path / 'rules' / 'preferences',
            self.base_path / 'rules' / 'thinking',
            self.base_path / 'cases' / 'executions',
            self.base_path / 'cases' / 'problems',
            self.base_path / 'cases' / 'results'
        ]
        
        for search_path in search_paths:
            file_path = search_path / f"{record_id}.json"
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
        
        return None
    
    def update_usage(self, record_id: str) -> bool:
        """更新记录的使用次数和最后使用时间"""
        record = self.get_record(record_id)
        if not record:
            return False
        
        record['usage_count'] = record.get('usage_count', 0) + 1
        record['last_used'] = datetime.now().isoformat()
        
        self._save_record(record, record['type'])
        return True


# 便捷函数
_manager = None

def get_manager() -> KnowledgeManager:
    """获取全局管理器实例"""
    global _manager
    if _manager is None:
        _manager = KnowledgeManager()
    return _manager


def create_behavioral_rule(**kwargs) -> str:
    """创建行为规则"""
    return get_manager().create_behavioral_rule(**kwargs)


def create_preference(**kwargs) -> str:
    """创建偏好设置"""
    return get_manager().create_preference(**kwargs)


def create_thinking_pattern(**kwargs) -> str:
    """创建思维模式"""
    return get_manager().create_thinking_pattern(**kwargs)


def create_execution(**kwargs) -> str:
    """创建执行记录"""
    return get_manager().create_execution(**kwargs)


def create_problem(**kwargs) -> str:
    """创建问题记录"""
    return get_manager().create_problem(**kwargs)


def create_result(**kwargs) -> str:
    """创建结果记录"""
    return get_manager().create_result(**kwargs)


def query_records(**kwargs) -> List[Dict[str, Any]]:
    """查询记录"""
    return get_manager().query_records(**kwargs)
