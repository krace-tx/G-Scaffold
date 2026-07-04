# Git 工作流规范

> status: active | 最后更新: 2026-07-04

## 分支

| 分支 | 用途 |
|---|---|
| `main` | 随时可出包 |
| `feature/xxx` | 功能开发,完成即合入删除 |
| `fix/xxx` | 缺陷修复 |

## Commit 格式

```
type(scope): 一句话说清做了什么

type: feat / fix / refactor / docs / chore / perf
scope: 模块名,如 ui、scene、platform、save
```

示例:`feat(ui): UIService 支持按层级栈式管理弹窗`

## Godot 专属注意事项

1. **`.tscn` / `.tres` 是文本但极难手工合并**:两人同时改同一场景几乎必然冲突。约定——**一个场景同一时间只由一个人改**;大场景尽量拆成子场景(既是架构要求也是防冲突手段)。
2. **`.godot/` 目录永不入库**(已在 .gitignore)。
3. **`*.import` 文件要入库**,否则他人拉取后资源导入参数不一致。
4. 提交前自查:不提交编辑器临时改动(如误拖节点导致的 .tscn 大 diff——diff 里看到大量与本次改动无关的行,先还原再提交)。
