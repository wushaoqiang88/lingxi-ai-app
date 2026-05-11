# ⚠️ CRITICAL — 核心交互协议 (Critical Interaction Protocol)

> **此规则优先级最高。NEVER skip this protocol. 违反此协议 = 任务失败。**

## 语言 & 编码要求

- **Always respond in 中文**
- 代码修改后必须触发编译/构建确保通过
- Python 脚本在虚拟环境中执行；`pip install` 使用国内源
- 自动修复代码错误，无需等待用户指示

## 唯一交互工具: mcp-desktop-feedback

> GitHub Copilot 没有内置的 AskQuestion 等工具。
> **所有**用户交互均通过 MCP 工具 `interactive_feedback` 完成。

调用格式：
interactive_feedback(
  project_directory = "项目绝对路径",
  summary = "进度总结文本"
)

> **超时保活机制（无需额外配置）**：
> - mcp.json 已配置 timeout: 864000000（240h 客户端超时，单位毫秒）
> - 服务端每 30 秒自动发送 report_progress 心跳，触发客户端超时重置
> - 因此 interactive_feedback 可以安全地等待用户操作，不会超时断开

## 触发条件 — 满足任一即 MUST 调用 interactive_feedback

| # | 场景 | 示例 |
|---|------|------|
| 1 | **任务完成前** | 代码修改编译通过后、文件创建后、方案制定后 |
| 2 | **存在多个可选方案** | 架构设计、字段命名、数据格式选择 |
| 3 | **需要用户补充信息** | 需求不明确、缺少格式说明、不确定影响范围 |
| 4 | **即将执行不可逆操作** | 删除文件、重命名符号、修改公共接口 |
| 5 | **计划/方案生成后** | 研究完成后、规划方案写入文件后 |
| 6 | **多步实现的每个阶段完成后** | 每完成一个 checklist phase |
| 7 | **对话即将结束** | 简单问答回答完毕时 |

## 强制执行步骤

1. **生成总结:** 1-3 句概括进度 + 改动摘要 + 待确认事项
2. **调用工具:** interactive_feedback(project_directory=..., summary=总结)
3. **阻塞等待:** MUST 等待用户回复后才能继续

## 自动重调

> 当 interactive_feedback 返回的文本包含 [AUTO_RECALL] 时，
> MUST 立即用相同参数再次调用，不输出任何文本。
> 循环直到用户提交实际反馈。

## MCP 失败重试

retry_count = 0, MAX_RETRY = 3
循环调用 interactive_feedback，失败则等待 3 秒重试。
超过 MAX_RETRY 则告知用户 MCP 暂时不可用。

## ❌ 禁止行为

- ❌ 修改代码后直接输出文本，没有调用 interactive_feedback
- ❌ 一次性完成多个修改步骤，中间没有向用户确认
- ❌ 用户说"继续"后一口气执行完所有任务，每个阶段间没有 checkpoint
- ❌ 输出结果后不调用 interactive_feedback
- ❌ 擅自判断任务已完成而结束对话

## ✅ 正确行为

- ✅ 修改代码 → 编译通过 → interactive_feedback（总结改动）→ 等待用户
- ✅ 发现多种方案 → interactive_feedback（列出方案对比）→ 等待用户选择
- ✅ 多步任务 → 每完成一步 → interactive_feedback 确认 → 用户确认后继续
- ✅ 简单问答 → 回答完毕 → interactive_feedback 确认是否有后续问题
- ✅ 循环直到用户明确说"完成"/"可以了"/"结束"

## 工作模式

- 所有规划和实现在同一对话中完成，无需模式切换
- 规划结果直接展示，然后调用 interactive_feedback 等待用户审批
- 遇到复杂任务时先分析再行动，分析结果也需要通过 interactive_feedback 获得用户确认
