# GDScript 编码规范与设计思想

> status: active | 最后更新: 2026-07-04

基线遵循 [官方 GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)。本文是本项目的强化条款,目标只有一个:

**让任意一段代码在 6 个月后、由另一个人(或忘了细节的你)打开时,认知成本尽可能低。**

面条代码和嵌套地狱不是"写得丑",而是"读一遍要在脑子里同时压住 5 个变量和 4 层缩进"——认知成本随规模指数上升。下面的规则全部服务于压平这条曲线。

---

## 一、设计思想(先想清楚,再动手)

写每个脚本 / 函数前,先过一遍这几问:

1. **单一职责**:这个脚本只有一个"变更理由"吗?一个类同时管"数据存储 + 网络请求 + UI 刷新",就是三个类挤在一起,拆。
2. **一个函数一件事**:函数名能用一个动词短语说清吗?说不清(要用"和 / 并 / 然后")就是该拆的信号。
3. **一个函数一个抽象层级**:高层函数只调用别的函数、不混入位运算细节;别在"处理一局游戏结算"里突然出现 `rect.position.x + 3`。
4. **依赖显式化**:依赖通过 `_init` / `setup()` 参数或 `App.xxx` 传入,不在方法内部到处 `get_node("../../X")` 反向抓取。横向通信走 [communication.md](../architecture/communication.md) 的三层规范。
5. **组合优于继承**:Godot 是节点组合的引擎。能用子节点 / 组件解决的,不要靠三层 `extends` 继承。继承深度超过 2 层就要警惕。

这五条是"为什么",下面的规则是"怎么落地"。

---

## 二、脚本骨架:强制 #region 分块

每个**非平凡脚本**(超过约 40 行,或含 3 个以上方法)必须用 `#region` 分块,块的划分与顺序**固定如下**,不允许自创命名或乱序。这样任何人打开任何脚本,folding 起来看到的都是同一张目录。

```gdscript
@tool
class_name FooService
extends Node

## 一句话说清这个脚本的职责。详见 docs/modules/foo-service.md。

#region Signals
signal something_happened(payload: int)
#endregion

#region Constants & Enums
enum State { IDLE, RUNNING, DONE }
const MAX_RETRY: int = 3
#endregion

#region Exports & State
@export var speed: float = 4.5
var _state: State = State.IDLE          # 私有状态加 _ 前缀
@onready var _timer: Timer = $Timer
#endregion

#region Lifecycle
func _ready() -> void:
	pass

func _notification(what: int) -> void:
	pass
#endregion

#region Public API
## 对外稳定方法,带 ## 文档注释。
func start() -> void:
	pass
#endregion

#region Internal
func _do_the_thing() -> void:
	pass
#endregion
```

规则:

- **六个区块的相对顺序固定**:Signals → Constants & Enums → Exports & State → Lifecycle → Public API → Internal。用不到的区块直接省略,不留空壳。
- **`class_name` / `extends` / 文档注释在所有 region 之外**,置于文件顶部。
- **区块内部再按官方成员顺序**排列(见规则七)。
- 平凡脚本(只有几行的一次性场景脚本、两三行的小工具类)可豁免分块。判断标准:分块后是否真的更好读,而不是徒增噪声。有 3 个以上方法的类,即使短(如 [result.gd](../../src/framework/core/result.gd) 仅用了 3 个区块),也建议分块以保持统一目录。

---

## 三、反嵌套地狱:缩进是预算,不是免费的

**函数内缩进硬上限 3 层。** 超过就必须重构。三种武器:

### 1. 卫语句(Guard Clause):把异常/边界情况前置 return

```gdscript
# ❌ 箭头形代码,主逻辑被推到最里层
func use_item(item: Item) -> void:
	if item != null:
		if item.is_usable:
			if _has_space():
				_apply(item)

# ✅ 边界先挡掉,主逻辑留在最外层平铺
func use_item(item: Item) -> void:
	if item == null: return
	if not item.is_usable: return
	if not _has_space(): return
	_apply(item)
```

### 2. 提前 continue / return 拆循环

循环体里第一步就 `if not 条件: continue`,而不是把整段包在 `if 条件:` 里。

### 3. 提炼函数:一段需要注释才能看懂的块,就是一个该起名字的函数

```gdscript
# ❌ 一个函数里三段"需要注释分隔"的逻辑 = 三个函数
func on_turn_end() -> void:
	# 结算伤害
	...15 行...
	# 刷新 UI
	...12 行...
	# 存档
	...8 行...

# ✅
func on_turn_end() -> void:
	_settle_damage()
	_refresh_hud()
	_save_progress()
```

配套硬指标(超过即代码异味,Review 关注):

- 函数体 **软上限 ~30 行**,50 行是明确异味
- 函数参数 **≤ 4 个**;再多就传一个配置对象 / Dictionary
- 长 `if / elif` 链(3 个以上分支)改用 `match`
- 避免嵌套 lambda / 回调金字塔;异步用 `await`,跨模块用信号

---

## 四、语言级强化条款

### 1. 静态类型强制

所有变量、参数、返回值必须标注类型;能推断的用 `:=`。

```gdscript
# ✅
var hp: int = 100
var speed := 4.5
func take_damage(amount: int) -> void:

# ❌
var hp = 100
func take_damage(amount):
```

项目设置开启 `debug/gdscript/warnings/untyped_declaration = error`。

### 2. class_name 必写

所有可复用类声明 `class_name`——GDScript 获得类型检查、补全与全局可 grep 性的基础。仅场景专属一次性脚本可豁免。注意:F5 前需 `--import` 一次让编辑器注册全局类。

### 3. 契约用 @abstract

跨实现的接口一律用 `@abstract`(Godot 4.5+),禁止"约定俗成的鸭子类型接口"。

```gdscript
@abstract class_name AdProvider extends RefCounted
@abstract func show_rewarded(placement: StringName) -> AdResult
```

### 4. 参数遮蔽用 p_ 前缀

构造 / setter 方法的参数若与成员变量同名,加 `p_` 前缀避免 `SHADOWED_VARIABLE` 警告(Godot 引擎源码惯例):

```gdscript
static func ok(p_value: Variant = null) -> Result:
	var r := Result.new()
	r.value = p_value
	return r
```

### 4.1 遮蔽内置全局标识符:@warning_ignore + 注释说明

成员名与 GDScript 内置全局函数/常量同名(如 `log`、`name`、`error` 前缀冲突等)时,**优先换名**;只有当这个名字本身就是项目统一约定(如 `App.log` 已是全项目认知)、换名反而降低可读性时,才保留原名,并用 `@warning_ignore` 精确忽略,附一行注释说明"为什么故意遮蔽、不会误用":

```gdscript
## `log` 与内置全局函数 log()(自然对数)同名,此处刻意遮蔽:
## `App.log` 这个命名在全项目统一且更常用,不会被误认成数学函数。
@warning_ignore("shadowed_global_identifier")
var log: LogService
```

禁止为图省事把整类警告在项目设置里全局关掉——只在真正冲突的那一行局部忽略。

### 5. 错误处理:Result 风格

GDScript 没有异常。所有可失败操作返回 `Result` 或明确文档化的哨兵值,**禁止静默吞错**。

```gdscript
var res := await App.net.post("/rank/list", params)
if res.is_err():
	App.log.warn("rank", "拉取失败: %s" % res.error)
	return
_show_rank(res.value)
```

`push_error` 只用于"程序员 bug"(不该发生的状态),不用于可预期失败(网络超时)。

### 6. 禁止魔法字符串 / 数字

id 走常量类,同一字面量出现两次即提升为常量(见 [naming.md](naming.md))。数值魔法数同理提为 `const`。

### 7. 成员顺序(区块内部)

`@tool/@icon` → `class_name` → `extends` → 文档注释 → `signal` → `enum` → `const` → `@export` → 公有 var → 私有 var → `@onready` → `_init/_ready/内置回调` → 公有方法 → 私有方法。

### 8. 注释:写"为什么",不写"是什么"

行内注释(`#`)只写代码本身表达不了的约束与原因(为什么这样、坑在哪、边界条件),**不复述代码在干什么**——那是命名的职责。看到 `hp -= 1  # 血量减一` 这种就删掉。

### 9. 方法文档注释(`##`)

用 `##` 写在方法正上方,Godot 会把它解析进内置文档(`F1` 查类、补全悬浮提示都能看到),是"文档即代码"的一环。规则按可见性分档:

**公开 API(Public API 区块)—— 必写 `##`,并满足:**

1. **首行一句话说清意图**,动词短语开头("拉取"、"切换"、"构造"),不复述签名。禁止 `## 一个返回 void 的函数`。
2. **非显而易见的信息才补充**,按需写,不凑格式:
   - 参数含义不能从名字看出时,用 `[param 名]` 引用说明
   - 返回值语义(尤其返回 `Result` / 可空 / 哨兵值时,说明成功与失败各代表什么)
   - **副作用**(会改状态、发信号、写盘、切场景)
   - **失败与异步**:可失败要说明失败条件;会挂起的方法**必须**标注"异步"(见规则 10)
3. 用 GDScript 文档标记增强可读性:`[param x]`、`[method 名]`、`[member 名]`、`[code]...[/code]`、`[codeblock]...[/codeblock]`、`[br]` 换行。

```gdscript
## 向后端提交一次带鉴权的 POST 请求。[br]
## [param path] 相对业务根路径,如 [code]/rank/list[/code];[param body] 会被序列化为 JSON。[br]
## 该方法为异步。返回 [Result]:成功时 [member Result.value] 为解析后的字典,
## 失败(超时 / 非 2xx / 解析错)时 [member Result.error] 为原因字符串,调用方禁止静默吞错。
func post(path: String, body: Dictionary) -> Result:
```

**私有方法(Internal 区块)—— 默认不写文档注释。** 命名讲清就够了。只有当"为什么这么实现"不明显时(有坑、有非直觉的顺序依赖、绕过了某个 bug),才用普通 `#` 注释写原因,而不是 `##`。

**信号 / 导出变量 / 常量** 同理:对外可见或含义不直观的,用 `##` 一句话说明。参见 [result.gd](../../src/framework/core/result.gd)、[log_service.gd](../../src/framework/core/log_service.gd) 的写法。

### 10. await 纪律

- 每个 `await` 点都要想:等待期间对象可能已被释放(`is_instance_valid` 保护)或场景已切换
- 会挂起的方法,文档注释**必须**注明"该方法为异步"(见规则 9)

### 11. lambda 闭包捕获局部变量是按值快照,不是按引用

用 fire-and-forget 的匿名函数配合"完成标记"做超时竞速(常见于给某个 `await` 操作加超时保护)时,**不要用 bool/int 等值类型**做跨闭包的可变状态——lambda 捕获到的是创建那一刻的快照,内部赋值不会反映到外层作用域,外层的判断条件永远看不到变化,轻则逻辑失效,重则协程空转到你设的超时上限才罢休(在无头测试里会表现为进程假死 + `ObjectDB instances leaked at exit`,非常难查)。

```gdscript
# ❌ finished 是 bool,lambda 内部的赋值只改了闭包自己的快照
var finished := false
(func() -> void:
	await do_something_async()
	finished = true
).call()
while not finished:   # 永远是 false,直到外部超时兜底(如果有的话)
	await get_tree().process_frame

# ✅ 用单元素 Array(引用类型),lambda 与外层共享同一份底层数据
var finished := [false]
(func() -> void:
	await do_something_async()
	finished[0] = true
).call()
while not finished[0]:
	await get_tree().process_frame
```

真实案例见 [scene_service.gd](../../src/framework/managers/scene_service.gd) 的 `_run_on_enter`——这个坑当时让 `_on_enter` 超时保护在 headless 测试里空转到 10 秒才暴露。

---

## 五、Code Review 速查清单

对着 diff 逐条问:

- [ ] 非平凡脚本用了标准 `#region` 六块,顺序正确
- [ ] 没有超过 3 层缩进的函数
- [ ] 没有超过 ~50 行 / 4 参数的函数
- [ ] 没有"需要注释分段"的长函数(该提炼)
- [ ] 全部类型标注,无裸魔法字符串/数字
- [ ] 可失败操作走 Result,没静默吞错
- [ ] 注释在讲"为什么"而不是复述代码
- [ ] 每个公开方法有 `##` 文档注释,交代意图 / 副作用 / 失败 / 异步
- [ ] 没有跨层 / 反向 `get_node` 抓取依赖
