# 通信规范

> status: active | 最后更新: 2026-07-04

模块间怎么"说话"是架构腐化最快的地方。只有三种合法通信方式,按优先级:

## 第一层:父子节点 —— Godot 原生方式

**Call down, signal up。** 父节点直接调用子节点方法;子节点通过自己的 signal 向上汇报。这一层**不上总线**。

```gdscript
# ✅ 父调子
$HealthBar.set_value(hp)
# ✅ 子发信号,父连接
signal died
```

## 第二层:命令 —— 调用 App 服务 API

想让某个模块"做一件事",调用 `App.xxx` 的方法。调用链可以 Ctrl+Click 追踪。

```gdscript
# ✅ 命令走 API
App.ui.open(Uis.SETTINGS)
App.audio.play_bgm(&"battle_theme")
App.scenes.replace(Scenes.LEVEL_SELECT)
```

## 第三层:事实 —— Bus 领域事件

某件事**已经发生**,发出者不关心谁听、有没有人听,才用总线。

```gdscript
# ✅ 事实,过去式命名
Bus.purchase_completed.emit(product_id)
Bus.ad_reward_granted.emit(placement)
Bus.player_died.emit()
```

## 铁律

1. **Bus 上的信号一律过去式命名**(`xxx_completed` / `xxx_changed` / `xxx_granted`),表示既成事实。
2. **禁止用 Bus 发"请求/命令"**。`Bus.ui_open_requested` 这种写法是反模式——调用链不可追踪,禁止出现。想让谁做事,调它的 API。
3. **禁止跨模块 `get_node` / 持有其他模块节点引用**。需要通信 = 走上面三层之一。
4. Bus 信号参数必须带类型;复杂载荷定义专门的事件对象(`RefCounted`)。
5. Bus 按领域分组(`game` / `economy` / `platform` / `app`),避免单文件堆几百个 signal。

## 判断口诀

> 我在**要求**别人做事 → 调 API。
> 我在**宣布**发生了什么 → 发 Bus 事件。
> 对方是我的**子节点** → 直接调;我是**子节点** → 发自己的 signal。
