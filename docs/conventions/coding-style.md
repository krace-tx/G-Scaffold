# GDScript 编码规范

> status: active | 最后更新: 2026-07-04

基线遵循 [官方 GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html),以下是本项目的强化条款。

## 1. 静态类型强制

所有变量、参数、返回值必须标注类型;能推断的用 `:=`。

```gdscript
# ✅
var hp: int = 100
var speed := 4.5
func take_damage(amount: int) -> void:

# ❌ 无类型标注
var hp = 100
func take_damage(amount):
```

项目设置中开启 `debug/gdscript/warnings/untyped_declaration = error`(落地框架代码时配置)。

## 2. class_name 必写

所有可复用类声明 `class_name`——这是 GDScript 里获得类型检查、补全与全局可 grep 性的基础。仅场景专属的一次性脚本可豁免。

## 3. 契约用 @abstract

跨实现的接口一律用 `@abstract` 类定义(Godot 4.5+),禁止"约定俗成的鸭子类型接口"。

```gdscript
@abstract class_name AdProvider extends RefCounted
@abstract func show_rewarded(placement: StringName) -> AdResult
```

## 4. 错误处理:Result 风格

GDScript 没有异常。所有可失败操作返回 `Result`(框架提供)或明确文档化的哨兵值,**禁止静默吞错**。

```gdscript
var res := await App.net.post("/rank/list", params)
if res.is_err():
    App.log.warn("rank", "拉取排行失败: %s" % res.error)
    return
_show_rank(res.value)
```

`push_error` 只用于"程序员 bug"(不该发生的状态),不用于可预期失败(网络超时)。

## 5. 禁止魔法字符串

见 [naming.md](naming.md):id 走常量类,同一字符串出现两次即提升为常量。

## 6. 脚本内成员顺序

遵循官方顺序:`@tool/@icon` → `class_name` → `extends` → 文档注释 → `signal` → `enum` → `const` → `@export` → 公有 var → 私有 var → `@onready` → `_init/_ready/内置回调` → 公有方法 → 私有方法。

## 7. 注释

注释只写"代码本身表达不了的约束与原因"(为什么这样做、坑在哪),不写"这行在干什么"。公共 API 用 `##` 文档注释。

## 8. await 纪律

- 所有 `await` 调用点必须考虑:等待期间对象可能已被释放(`is_instance_valid` 保护)或场景已切换
- 服务 API 中会挂起的方法,文档注释必须注明"该方法为异步"
