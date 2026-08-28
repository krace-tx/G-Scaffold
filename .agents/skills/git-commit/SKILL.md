---
name: git-commit
description: Git 代码提交规范与流程指南
---

# Git 提交规范 (Git Commit Skill)

<core_rules>
1. **统一格式**：所有的 commit message 必须使用 `<type>: <subject>` 的格式（不需要 scope，也不需要额外的署名）。
2. **强制英文**：所有的 commit message 必须纯英文编写。
3. **常用的 Type**：
   - `feat`: 新增功能 (feature)
   - `fix`: 修复 Bug
   - `docs`: 仅修改文档 (documentation)
   - `style`: 不影响代码运行的格式调整 (如格式化、分号等)
   - `refactor`: 重构 (既不新增功能，也不修复 bug 的代码改动)
   - `test`: 增加或修改测试用例
   - `chore`: 构建过程或辅助工具的变动
</core_rules>

<workflow>
- 在提交前，先使用 `git status` 和 `git diff` 检查改动内容。
- 确保 Message 的 subject 简洁明了，用英文准确描述本次改动的目的。
- **强制约束（禁止 Push）**：绝不允许执行 `git push` 命令，所有的 push 动作必须由开发者手动执行。
- **强制约束（开发者校验）**：完成 commit 组装或执行 commit 后，必须明确告知开发者检查，等待开发者校验确认。
</workflow>

<commit_example>
**✅ 正确示例 (英文)**
```text
feat: add main menu UI scene
```
```text
fix: resolve occasional offset issue when dragging jigsaw pieces
```
```text
docs: update runtime instructions in README
```

**❌ 错误示例**
```text
feat: 新增主菜单 UI 场景 (错误：使用了中文，必须全英文)
```
```text
feat(ui): add main menu UI scene (错误：不需要 scope)
```
```text
fixed a bug (错误：缺少 type)
```
</commit_example>
