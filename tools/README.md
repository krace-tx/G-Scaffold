# tools/ — 质量收口脚本

> status: active | 最后更新: 2026-07-05

无头可运行、可接 CI / pre-commit 的质量保障脚本。所有脚本退出码即结果(0 = 通过,非 0 = 失败数)。

将下面命令里的 `godot` 换成你本机的 Godot 4.6 可执行文件路径。

## 架构违规检查 · `check_architecture.gd`

按 [directory.md](../docs/conventions/directory.md) 的"违规引用清单"扫描 `src/`,命中即报违规。

```bash
godot --headless --path . --script res://tools/check_architecture.gd
```

规则(见脚本内 `rules`):framework 不引用 game/platform;platform 不引用 game;`change_scene` 仅允许在 SceneService 内;禁止裸 `res://src/assets/` 路径字符串。新增规则改脚本里的 `rules` 数组即可。

## 单元测试 · `tests/`

不依赖 gdUnit4 插件的轻量无头运行器,覆盖纯逻辑路径(Result / SaveService 迁移 / ConfigService 合并 / TimeService 偏移)。

```bash
godot --headless --path . res://tools/tests/test_runner.tscn
```

以**主场景**方式启动(而非 `--script`),这样 autoload(App/Bus)会加载,凡在文件作用域引用 App 的类才能编译。运行器只调用不碰 App 的纯逻辑方法。新增测试:在 [run_tests.gd](tests/run_tests.gd) 加 `_test_xxx()` 并同步更新 `_EXPECTED_CHECKS` 哨兵。

## 注册表常量类生成 · `registry_codegen.gd`

三份权威注册表 .tres(scene_registry / ui_registry / asset_map,Inspector 里拖资源登记)
→ `src/resource/generated/` 下的强类型常量类(`Scenes` / `Uis` / `Assets`)。
编辑器内等价入口:File > Run 跑 [editor_regen_registries.gd](editor_regen_registries.gd)。

```bash
godot --headless --path . res://tools/generate_registries.tscn            # 生成/覆写
godot --headless --path . res://tools/generate_registries.tscn -- check   # 只校验,生成物过期即非 0(CI 用)
```

id 默认取资源文件名,条目 id_override 可覆盖;id 冲突/非法、条目漏拖资源都会报错拒绝生成。
生成类里的加载键是 uid://,登记的文件移动/改名不需要重新生成。

## 接入 pre-commit(可选)

不强制安装钩子。要启用,在仓库根创建 `.githooks/pre-commit`:

```sh
#!/bin/sh
godot --headless --path . --script res://tools/check_architecture.gd || exit 1
godot --headless --path . res://tools/generate_registries.tscn -- check || exit 1
godot --headless --path . res://tools/tests/test_runner.tscn || exit 1
```

然后 `git config core.hooksPath .githooks && chmod +x .githooks/pre-commit`。CI 里直接跑上面两条命令即可。
