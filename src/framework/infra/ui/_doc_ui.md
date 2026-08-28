# UI (基础控件)

## 核心

提供项目中所有游戏与系统界面的基类封装。
收拢重复的视觉反馈逻辑（如按钮按压缩放、全局点击音效），规范场景 UI 的挂载层级，分离表现逻辑与业务控制。

---

## 细节

- **BaseUI**：作为业务逻辑里的画面承载者，规定固定挂靠在 `BaseScene` 根节点下且节点名必须为 `UI`。将 UI 排版与场景的生命周期彻底剥离。
- **BaseTextureButton**：接管按钮按下、弹起、离开时的默认缩放补间。点击时会自动触发 `play_sfx_by_path` 与跨平台震动反馈，无需每次手动连线处理。
- **属性开放**：所有的基础属性（如缩放倍率、是否播音效、音量分贝等）均作为 `@export` 暴露，可在 Godot 检查器里直接调节，方便策划或 TA 微调手感。

```text
src/framework/infra/ui/
├── base_ui.gd                # 场景内顶级 UI 编排根的基类，负责承载本场景的控件树
└── base_texture_button.gd    # 通用贴图按钮基类，自带点击音效、震动反馈与补间动画缩放
```

---

## 样例

```gdscript
# 业务场景的 UI 层继承 BaseUI 即可，不写换场逻辑
class_name MainMenuUI extends BaseUI

@onready var start_btn: BaseTextureButton = $StartButton

func _ready() -> void:
    # 只需要关心业务回调，不用再手写按钮的缩放和播放音效，它们会在基类自动处理
    start_btn.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
    App.scene.push("res://src/game/level_select.tscn")
```
