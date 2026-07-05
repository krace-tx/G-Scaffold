# 指南:新增一个 UI

> status: active | 最后更新: 2026-07-05

适用:添加新的界面/弹窗(依赖 UIService 落地后,本指南描述目标流程)。

## 五步流程

### 1. 创建 UI 场景

`src/game/ui/` 下建 `settings_panel.tscn` + 同名脚本,根节点脚本继承 `BaseUI`:

```gdscript
extends BaseUI

func _on_open(params: Dictionary) -> void:  # 每次打开,接收参数
    pass

func _on_close() -> void:                   # 关闭前清理(断开外部信号!)
    pass
```

### 2. 在 ui_registry.tres 注册

`resource/data/ui_registry.tres` 中添加一条 `UIRegistryEntry`:

| 字段 | 说明 |
|---|---|
| scene | 直接把 `settings_panel.tscn` **拖进来**(UID 追踪,之后改名/移动不断链) |
| id_override | 可选;留空则 id = 场景文件名(`settings_panel`),想叫 `&"settings"` 就填它 |
| layer | HUD / Window / Popup / Toast / Loading(决定 CanvasLayer 与栈) |
| cache | `KEEP`(常驻内存,高频 UI)/ `DESTROY`(关闭即毁,低频大 UI) |

### 3. 重新生成 Uis 常量类

编辑器里 File > Run 跑 `tools/editor_regen_registries.gd`(或命令行
`godot --headless --path . res://tools/generate_registries.tscn`),
`Uis.SETTINGS` 常量就有了。**不要手改** `src/resource/generated/` 下的文件。

### 4. 打开与关闭

```gdscript
App.ui.open(Uis.SETTINGS, {"tab": "audio"})
App.ui.close(Uis.SETTINGS)
```

### 5. 确认 Android 返回键行为

返回键默认关闭栈顶弹窗。若该 UI 需要拦截(如"有未保存修改"),在 BaseUI 中覆写:

```gdscript
func _on_back() -> bool:   # 返回 true = 已消费,不再向下传递
    _show_confirm_discard()
    return true
```

## 自查清单

- [ ] UI 脚本里没有 `get_node` 到 UI 树以外的节点(数据经 params 传入或监听 Bus 事件)
- [ ] `_on_close` 断开了所有对外信号连接(否则 KEEP 缓存的 UI 会重复响应)
- [ ] 打开入口用的是生成的 `Uis` 常量,不是裸字符串;注册后重跑过生成器
- [ ] 在编辑器 F5 验证过打开/关闭/返回键三条路径
