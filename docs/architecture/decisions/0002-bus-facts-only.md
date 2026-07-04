# ADR-0002: 信号总线只承载事实,命令走 API

> status: accepted | 日期: 2026-07-04

## 背景

引入全局 SignalBus 解耦模块后,总线极易膨胀成"什么都往上发"的新意大利面:`ui_open_requested`、`play_sound_requested` 这类"请求型"信号让调用链完全不可追踪——你不知道谁会响应、有几个响应者、响应顺序如何。

## 决策

`Bus` 上只允许**过去式命名的领域事件**(已发生的事实):`purchase_completed`、`player_died`、`scene_changed`。任何"让某模块做事"的意图必须直接调用 `App.xxx` 的方法。

## 考虑过的替代方案

- **全事件驱动(命令也走总线)**:解耦最彻底,但调试地狱,移动端小团队维护不起,弃用。

## 后果

- 正面:命令链路可 Ctrl+Click 追踪;总线信号数量天然受控。
- 负面:模块对 `App` 有显式依赖,接受(依赖聚合根 ≠ 依赖具体实现)。
- 新约束:Code Review 见到 `*_requested` 信号上总线一律打回。详见 [communication.md](../communication.md)。
