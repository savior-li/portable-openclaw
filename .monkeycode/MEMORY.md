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
