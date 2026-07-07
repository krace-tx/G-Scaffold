# 指南:Windows GDExtension Stub

> status: active | 最后更新: 2026-07-06

适用:在 **Windows** 上用 Godot 编辑器开发,但项目包含 **仅提供 iOS/macOS 二进制** 的 GDExtension 插件(如 `apple_sign_in`、`godot-iap`)。

## 背景

Godot 启动时会扫描项目中所有 `.gdextension` 文件,并尝试为**当前操作系统**加载对应动态库。若配置里没有 `windows.x86_64` 条目,编辑器会反复报错:

```
No GDExtension library found for current OS and architecture (windows.x86_64)
```

这是引擎已知行为([godotengine/godot#105615](https://github.com/godotengine/godot/issues/105615)),与插件本身是否正常无关。Mac 上通常不报错,是因为部分插件自带 macOS 库。

本项目的做法是:为 Windows 提供 **no-op stub DLL**,让编辑器能安静加载扩展;**不影响** iOS/Android 导出时使用的真实原生库。

## 涉及插件

| 插件 | GDExtension 配置 | Stub 源码 |
|---|---|---|
| `apple_sign_in` | `addons/apple_sign_in/AppleSignInLibrary.gdextension` | `addons/apple_sign_in/stubs/windows/stub.c` |
| `godot-iap` | `addons/godot-iap/bin/godot_iap.gdextension` | `addons/godot-iap/stubs/windows/stub.c` |

两个 stub 仅导出各自 `.gdextension` 里声明的 `entry_symbol`,不注册任何 Godot 类。插件 GDScript 层已有降级逻辑(`ClassDB.class_exists` / mock mode),Windows 上行为与加 stub 前一致,只是不再刷屏报错。

## 前置条件

- Windows 10/11,x86_64
- **Visual Studio** 且已安装 **「使用 C++ 的桌面开发」** 工作负载(提供 `cl.exe`)

## 一键编译

在项目根目录执行:

```bat
scripts\gdextension-stubs\build_win.bat
```

成功后生成:

- `addons/apple_sign_in/stubs/windows/apple_sign_in.windows.stub.x86_64.dll`
- `addons/godot-iap/stubs/windows/godot_iap.windows.stub.x86_64.dll`

重启 Godot 编辑器即可。

## 单独编译某个插件

进入对应 `stubs/windows/` 目录,调用本地脚本:

```bat
cd addons\apple_sign_in\stubs\windows
compile_stub_win.bat apple_sign_in.windows.stub.x86_64.dll

cd addons\godot-iap\stubs\windows
compile_stub_win.bat godot_iap.windows.stub.x86_64.dll
```

## 新增同类插件时

若再引入仅移动端可用的 GDExtension,按同样模式扩展:

1. 在 `addons/<plugin>/stubs/windows/` 放置 `stub.c`,导出与 `.gdextension` 一致的 `entry_symbol`。
2. 复制 `compile_stub_win.bat` 到该目录。
3. 在插件 `.gdextension` 的 `[libraries]` 中**仅追加** Windows 条目,不要改动原有 iOS/macOS 路径。
4. 在 `scripts/gdextension-stubs/build_win.bat` 中增加一次 `pushd` / `call` / `popd`。

## 常见问题

### 报错:Visual Studio C++ tools not found

安装 [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) 或完整 VS,勾选 **MSVC** 与 **Windows SDK**,然后重试。

### 已有 DLL 仍报错

1. 确认 `.gdextension` 中 `windows.x86_64` 路径指向的 DLL 文件存在。
2. 删除项目根目录 `.godot/` 缓存后重新打开项目(会触发扩展列表重建)。
3. 确认 DLL 是脚本编译产物,而非空文件占位(空 DLL 会触发 `not a valid Win32 application`)。

### Mac 同事需要 stub 吗?

不需要。stub 仅供 Windows 编辑器开发;Mac 直接使用插件自带的 macOS / iOS 库即可。

## 相关文件

```
scripts/
└── gdextension-stubs/
    └── build_win.bat          # 一键编译入口

addons/
├── apple_sign_in/
│   ├── AppleSignInLibrary.gdextension
│   └── stubs/windows/
│       ├── stub.c
│       ├── compile_stub_win.bat
│       └── apple_sign_in.windows.stub.x86_64.dll
└── godot-iap/
    ├── bin/godot_iap.gdextension
    └── stubs/windows/
        ├── stub.c
        ├── compile_stub_win.bat
        └── godot_iap.windows.stub.x86_64.dll
```
