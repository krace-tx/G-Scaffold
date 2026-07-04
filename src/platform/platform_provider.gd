@abstract
class_name PlatformProvider
extends RefCounted

## 所有平台能力 provider 的共同契约:一个可能成功/失败的异步初始化。
##
## 具体能力(广告 / 统计……)在各自子契约里加方法。业务永远不认具体 SDK,
## 只认这些契约;真实现按平台由工厂选择,编辑器 / 不支持的平台注入 Null 实现。
## 见 docs/architecture/decisions/0004-platform-null-providers.md。

## 初始化底层 SDK。返回 true=成功,false=失败(PlatformService 会将其降级为 Null 实现)。
## 可 await(SDK 初始化通常异步)。实现应自带合理的内部超时,不要无限挂起
## ——外层 PlatformService 也有 5s 兜底超时。
@abstract
func initialize() -> bool
