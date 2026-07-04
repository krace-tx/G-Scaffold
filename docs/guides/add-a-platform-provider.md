# 指南:对接一个平台 SDK

> status: active | 最后更新: 2026-07-04

适用:接入广告、内购、统计、推送等任何第三方/平台能力。核心原则见 [ADR-0004](../architecture/decisions/0004-platform-null-providers.md):**业务代码永远不知道 SDK 的存在。**

## 五步流程(以广告为例)

### 1. 定义 @abstract 契约

```gdscript
# src/platform/ads/ad_provider.gd
@abstract class_name AdProvider extends RefCounted

@abstract func initialize() -> void                                # 异步,内部带超时
@abstract func show_rewarded(placement: StringName) -> AdResult    # 异步
func is_ready(placement: StringName) -> bool: return false
```

契约只表达**业务需要什么**,不映射 SDK 的 API 形状(防止 SDK 概念泄漏)。

### 2. 编写各平台真实现

```
src/platform/ads/admob_android_provider.gd   # 封装 JNISingleton 调用
src/platform/ads/admob_ios_provider.gd
```

SDK 回调转成 `await` 可等待的信号;所有调用带超时,超时视为失败。

### 3. 编写 Null 实现

```gdscript
# src/platform/ads/null_ad_provider.gd
class_name NullAdProvider extends AdProvider

func show_rewarded(placement: StringName) -> AdResult:
    await App.tree_timer(1.0)          # 模拟观看
    return AdResult.rewarded()         # 编辑器里直接发奖
```

**Null 实现不是可选项**——它决定了你能否在编辑器里跑通全流程、CI 能否无头运行。

### 4. 工厂接线

```gdscript
static func create() -> AdProvider:
    if OS.has_feature("editor"): return NullAdProvider.new()
    match OS.get_name():
        "Android": return AdmobAndroidProvider.new()
        "iOS":     return AdmobIOSProvider.new()
        _:         return NullAdProvider.new()
```

Bootstrap 第 3 阶段初始化;初始化失败 → 原地替换为 Null 实现(降级,不阻断启动)。

### 5. 业务侧使用

```gdscript
var res := await App.platform.ads.show_rewarded(&"double_coins")
if res.is_rewarded():
    Bus.ad_reward_granted.emit(&"double_coins")
```

## 自查清单

- [ ] `game/` 里 grep 不到 SDK 类名
- [ ] 编辑器 F5 能走通"请求→展示→发奖"全流程(Null 路径)
- [ ] SDK 初始化失败时游戏照常可玩(手动断网验证)
- [ ] 写了模块文档,登记到 `modules/README.md`
