# 用户指令记忆

本文件记录了用户的指令、偏好和教导,用于在未来的交互中提供参考。

## 格式

### 用户指令条目
用户指令条目应遵循以下格式:

[用户指令摘要]
- Date: [YYYY-MM-DD]
- Context: [提及的场景或时间]
- Instructions:
  - [用户教导或指示的内容,逐行描述]

### 项目知识条目
Agent 在执行任务过程中发现的条目应遵循以下格式:

[项目知识摘要]
- Date: [YYYY-MM-DD]
- Context: Agent 在执行 [具体任务描述] 时发现
- Category: [代码结构|代码模式|代码生成|构建方法|测试方法|依赖关系|环境配置]
- Instructions:
  - [具体的知识点,逐行描述]

## 去重策略
- 添加新条目前,检查是否存在相似或相同的指令
- 若发现重复,跳过新条目或与已有条目合并
- 合并时,更新上下文或日期信息
- 这有助于避免冗余条目,保持记忆文件整洁

## 条目

[OpenClaw 备份恢复项目]
- Date: 2026-04-03
- Context: Agent 在执行项目恢复验证时发现
- Category: 代码结构
- Instructions:
  - 项目为 portable-openclaw 备份恢复系统
  - 使用 restic 作为备份工具,备份存储在 /workspace/restic/ 目录
  - 恢复脚本位于 /workspace/restore-openclaw.sh
  - 备份状态记录在 BACKUP_STATUS.md 文件中
  - 已配置 catbox.moe 作为唯一可用的备份上传服务

[知识库系统实现]
- Date: 2026-04-03
- Context: Agent 在实现知识库系统时发现
- Category: 代码结构
- Instructions:
  - 知识库位于 /workspace/knowledge-base/
  - 核心理念: 我教AI做人，你帮我做事
  - 分为 rules/ (做人) 和 cases/ (做事) 两大类
  - 提供 CLI 工具 和 Python API (manager.py)
  - 支持行为规则、偏好设置、思维模式、执行记录、问题记录、结果记录 6 种数据类型
  - Phase 1 已完成: 基础功能实现 (3000+ 行代码)
  - Phase 2 已完成: 智能学习引擎 (learner.py, auto_learner.py)
  - 所有测试通过，代码已提交到 Git
  - 计划集成到 ClawHub 作为 Skill 发布

[知识库核心规则]
- Date: 2026-04-03
- Context: Agent 在使用知识库时归纳
- Category: 代码模式
- Instructions:
  - 高优先级规则: 禁止删除文件、所有 API 调用必须有错误处理
  - 工具偏好: 使用 pnpm 而不是 npm、优先使用 TypeScript
  - 已知问题: MonkeyCode AI API Key 失效，需要更新
  - 自动学习规则: 4 条 (包括避免在循环中查询数据库)
  - 知识库总记录: 17+ 条 (规则 4, 偏好 3, 执行 3, 问题 2, 结果 3)
