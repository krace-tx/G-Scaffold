# 指南:新增一个 UI

> status: active | 最后更新: 2026-07-04

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

### 2. 在 Asset Groups 面板登记

打开编辑器底部的 **Asset Groups** 面板(插件,见 [asset-groups.md](../modules/asset-groups.md)),在 **UIs** 分区里「快速载入」或从 FileSystem 拖入 `settings_panel.tscn`(id 与 path 自动注入),声明三件事:

| 字段 | 说明 |
|---|---|
| 场景路径 | `res://src/game/ui/settings_panel.tscn`(拖入/快速载入自动填) |
| 层级 | HUD / Window / Popup / Toast / Loading(决定 CanvasLayer 与栈) |
| 缓存策略 | `KEEP`(常驻内存,高频 UI)/ `DESTROY`(关闭即毁,低频大 UI) |

### 3. 点「导出」

面板「导出」会一并写出 `asset_manifest.tres` 并**自动生成** `UIIds` 常量(`UIIds.SETTINGS`),无需手改 `ui_ids.gd`。

### 4. 打开与关闭

```gdscript
App.ui.open(UIIds.SETTINGS, {"tab": "audio"})
App.ui.close(UIIds.SETTINGS)
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
- [ ] 打开入口用的是 `UIIds` 常量,不是裸字符串
- [ ] 在编辑器 F5 验证过打开/关闭/返回键三条路径
