#!/usr/bin/env python3
"""
知识库 CLI 工具
用于管理规则、执行记录、问题和结果
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


class KnowledgeBaseCLI:
    """知识库命令行工具"""
    
    def __init__(self, base_path: str = None):
        self.base_path = Path(base_path or os.environ.get('KNOWLEDGE_BASE_PATH', '/workspace/knowledge-base'))
        self.templates_path = self.base_path / 'templates'
        
    def _generate_id(self, record_type: str) -> str:
        """生成唯一ID"""
        date_str = datetime.now().strftime('%Y%m%d')
        timestamp = datetime.now().strftime('%H%M%S')
        return f"{date_str}_{record_type}_{timestamp}"
    
    def _get_save_path(self, record_type: str, category: str = None) -> Path:
        """获取保存路径"""
        if record_type in ['behavioral', 'preferences', 'thinking']:
            return self.base_path / 'rules' / record_type
        elif record_type in ['execution', 'problem', 'result']:
            return self.base_path / 'cases' / f"{record_type}s"
        else:
            return self.base_path / 'insights'
    
    def _load_template(self, template_name: str) -> Dict[str, Any]:
        """加载模板"""
        template_path = self.templates_path / f"{template_name}.json"
        if not template_path.exists():
            raise FileNotFoundError(f"Template not found: {template_name}")
        
        with open(template_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def _save_record(self, record: Dict[str, Any], record_type: str, filename: str) -> str:
        """保存记录"""
        save_dir = self._get_save_path(record_type, record.get('category'))
        save_dir.mkdir(parents=True, exist_ok=True)
        
        file_path = save_dir / f"{filename}.json"
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(record, f, indent=2, ensure_ascii=False)
        
        self._update_index(record_type, filename, record)
        return str(file_path)
    
    def _update_index(self, record_type: str, filename: str, record: Dict[str, Any]):
        """更新索引文件"""
        index_path = self._get_save_path(record_type, record.get('category')) / 'INDEX.md'
        
        index_entry = f"- [{filename}]({filename}.json) - {record.get('rule', record.get('problem', record.get('task', '')))} ({record.get('timestamp', '')})\n"
        
        if not index_path.exists():
            with open(index_path, 'w', encoding='utf-8') as f:
                f.write(f"# {record_type.title()} Index\n\n")
        
        with open(index_path, 'a', encoding='utf-8') as f:
            f.write(index_entry)
    
    def create_behavioral(self, rule: str, category: str, context: str = None, 
                         priority: str = 'medium', tags: List[str] = None,
                         examples: List[str] = None, rationale: str = None) -> str:
        """创建行为规则"""
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
            'rationale': rationale or '',
            'created_by': 'user',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        filename = record['id']
        return self._save_record(record, 'behavioral', filename)
    
    def create_preference(self, preference: str, category: str, context: str = None,
                         priority: str = 'medium', tags: List[str] = None,
                         alternatives: List[str] = None, reason: str = None) -> str:
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
            'created_by': 'user',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        filename = record['id']
        return self._save_record(record, 'preferences', filename)
    
    def create_thinking(self, pattern: str, category: str, context: str = None,
                       priority: str = 'medium', tags: List[str] = None,
                       steps: List[str] = None, expected_outcome: str = None) -> str:
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
            'created_by': 'user',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        filename = record['id']
        return self._save_record(record, 'thinking', filename)
    
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
        
        filename = record['id']
        return self._save_record(record, 'execution', filename)
    
    def create_problem(self, problem: str, cause: str, solution: str,
                      context: str = None, prevention: str = None,
                      tags: List[str] = None) -> str:
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
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        })
        
        filename = record['id']
        return self._save_record(record, 'problem', filename)
    
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
        
        filename = record['id']
        return self._save_record(record, 'result', filename)
    
    def query(self, record_type: str = None, tags: List[str] = None,
              category: str = None, limit: int = 10) -> List[Dict[str, Any]]:
        """查询记录"""
        results = []
        
        search_paths = []
        if record_type:
            search_paths.append(self._get_save_path(record_type, category))
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
                if file_path.name == 'INDEX.md':
                    continue
                
                with open(file_path, 'r', encoding='utf-8') as f:
                    record = json.load(f)
                
                if tags:
                    if not any(tag in record.get('tags', []) for tag in tags):
                        continue
                
                if category and record.get('category') != category:
                    continue
                
                results.append(record)
                
                if len(results) >= limit:
                    break
            
            if len(results) >= limit:
                break
        
        return results


def main():
    parser = argparse.ArgumentParser(description='Knowledge Base CLI')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # create-behavioral
    behavioral_parser = subparsers.add_parser('create-behavioral', help='Create behavioral rule')
    behavioral_parser.add_argument('--rule', required=True, help='Rule description')
    behavioral_parser.add_argument('--category', required=True, choices=['deny', 'recommend', 'prefer', 'avoid'], help='Rule category')
    behavioral_parser.add_argument('--context', help='Context')
    behavioral_parser.add_argument('--priority', default='medium', choices=['high', 'medium', 'low'], help='Priority')
    behavioral_parser.add_argument('--tags', nargs='*', help='Tags')
    behavioral_parser.add_argument('--examples', nargs='*', help='Examples')
    behavioral_parser.add_argument('--rationale', help='Rationale')
    
    # create-preference
    preference_parser = subparsers.add_parser('create-preference', help='Create preference')
    preference_parser.add_argument('--preference', required=True, help='Preference description')
    preference_parser.add_argument('--category', required=True, choices=['tool', 'style', 'workflow', 'communication'], help='Preference category')
    preference_parser.add_argument('--context', help='Context')
    preference_parser.add_argument('--priority', default='medium', choices=['high', 'medium', 'low'], help='Priority')
    preference_parser.add_argument('--tags', nargs='*', help='Tags')
    preference_parser.add_argument('--alternatives', nargs='*', help='Alternatives')
    preference_parser.add_argument('--reason', help='Reason')
    
    # create-thinking
    thinking_parser = subparsers.add_parser('create-thinking', help='Create thinking pattern')
    thinking_parser.add_argument('--pattern', required=True, help='Pattern description')
    thinking_parser.add_argument('--category', required=True, choices=['analysis', 'decision', 'problem-solving', 'planning'], help='Pattern category')
    thinking_parser.add_argument('--context', help='Context')
    thinking_parser.add_argument('--priority', default='medium', choices=['high', 'medium', 'low'], help='Priority')
    thinking_parser.add_argument('--tags', nargs='*', help='Tags')
    thinking_parser.add_argument('--steps', nargs='*', help='Steps')
    thinking_parser.add_argument('--expected-outcome', help='Expected outcome')
    
    # create-execution
    execution_parser = subparsers.add_parser('create-execution', help='Create execution log')
    execution_parser.add_argument('--command', required=True, help='Command executed')
    execution_parser.add_argument('--steps', nargs='*', required=True, help='Execution steps')
    execution_parser.add_argument('--outcome', required=True, choices=['success', 'failure', 'partial'], help='Outcome')
    execution_parser.add_argument('--context', help='Context')
    execution_parser.add_argument('--tags', nargs='*', help='Tags')
    execution_parser.add_argument('--learnings', nargs='*', help='Learnings')
    execution_parser.add_argument('--issues', nargs='*', help='Issues')
    execution_parser.add_argument('--duration', type=int, default=0, help='Duration in milliseconds')
    
    # create-problem
    problem_parser = subparsers.add_parser('create-problem', help='Create problem record')
    problem_parser.add_argument('--problem', required=True, help='Problem description')
    problem_parser.add_argument('--cause', required=True, help='Root cause')
    problem_parser.add_argument('--solution', required=True, help='Solution')
    problem_parser.add_argument('--context', help='Context')
    problem_parser.add_argument('--prevention', help='Prevention measures')
    problem_parser.add_argument('--tags', nargs='*', help='Tags')
    
    # create-result
    result_parser = subparsers.add_parser('create-result', help='Create result record')
    result_parser.add_argument('--task', required=True, help='Task description')
    result_parser.add_argument('--output', required=True, help='Output')
    result_parser.add_argument('--verified', type=lambda x: x.lower() == 'true', default=True, help='Verified')
    result_parser.add_argument('--context', help='Context')
    result_parser.add_argument('--quality-score', type=float, default=0.0, help='Quality score')
    result_parser.add_argument('--tags', nargs='*', help='Tags')
    result_parser.add_argument('--artifacts', nargs='*', help='Artifacts')
    
    # query
    query_parser = subparsers.add_parser('query', help='Query records')
    query_parser.add_argument('--type', choices=['behavioral', 'preferences', 'thinking', 'execution', 'problem', 'result'], help='Record type')
    query_parser.add_argument('--tags', nargs='*', help='Tags to filter')
    query_parser.add_argument('--category', help='Category to filter')
    query_parser.add_argument('--limit', type=int, default=10, help='Maximum results')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    cli = KnowledgeBaseCLI()
    
    try:
        if args.command == 'create-behavioral':
            path = cli.create_behavioral(
                rule=args.rule,
                category=args.category,
                context=args.context,
                priority=args.priority,
                tags=args.tags,
                examples=args.examples,
                rationale=args.rationale
            )
            print(f"Created behavioral rule: {path}")
        
        elif args.command == 'create-preference':
            path = cli.create_preference(
                preference=args.preference,
                category=args.category,
                context=args.context,
                priority=args.priority,
                tags=args.tags,
                alternatives=args.alternatives,
                reason=args.reason
            )
            print(f"Created preference: {path}")
        
        elif args.command == 'create-thinking':
            path = cli.create_thinking(
                pattern=args.pattern,
                category=args.category,
                context=args.context,
                priority=args.priority,
                tags=args.tags,
                steps=args.steps,
                expected_outcome=args.expected_outcome
            )
            print(f"Created thinking pattern: {path}")
        
        elif args.command == 'create-execution':
            path = cli.create_execution(
                command=args.command,
                steps=args.steps,
                outcome=args.outcome,
                context=args.context,
                tags=args.tags,
                learnings=args.learnings,
                issues=args.issues,
                duration_ms=args.duration
            )
            print(f"Created execution log: {path}")
        
        elif args.command == 'create-problem':
            path = cli.create_problem(
                problem=args.problem,
                cause=args.cause,
                solution=args.solution,
                context=args.context,
                prevention=args.prevention,
                tags=args.tags
            )
            print(f"Created problem record: {path}")
        
        elif args.command == 'create-result':
            path = cli.create_result(
                task=args.task,
                output=args.output,
                verified=args.verified,
                context=args.context,
                quality_score=args.quality_score,
                tags=args.tags,
                artifacts=args.artifacts
            )
            print(f"Created result record: {path}")
        
        elif args.command == 'query':
            results = cli.query(
                record_type=args.type,
                tags=args.tags,
                category=args.category,
                limit=args.limit
            )
            
            for result in results:
                print(json.dumps(result, indent=2, ensure_ascii=False))
                print()
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
