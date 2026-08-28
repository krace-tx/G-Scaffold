# Android 打包与导出环境配置指南

本指南为 **Godot 4 项目在 macOS 平台下的 Android 打包与导出环境** 提供标准的保姆级配置流程。按照以下步骤操作，即可完成从环境准备到一键导出 `.apk` / `.aab` 的全部配置。

---

## 📋 前置准备 (Prerequisites)

在开始前，请确保您的设备已安装以下基础工具：
- **Godot 4.x**（游戏引擎）
- **Homebrew**（macOS 软件包管理器，用于安装标准 OpenJDK 17）
- **Android Studio**（用于提供 Android SDK 与真机调试工具）
- **macOS**（基于 macOS 的 zsh 终端环境）

---

## 步骤一：安装与配置 Java SDK (OpenJDK 17)

> ⚠️ **为什么不推荐直接使用 Android Studio 内置 JDK？**  
> Android Studio 目前内置了超前版本的 JDK 25，而 Android 核心打包工具 Gradle 8.x 会报错 `Unsupported class file major version 69`。因此**官方强制推荐安装标准的 OpenJDK 17**。

### 1.1 通过 Homebrew 安装 OpenJDK 17
打开终端（Terminal），执行：

```bash
brew install openjdk@17
```

### 1.2 写入环境变量
执行以下命令将 OpenJDK 17 写入 `~/.zshrc`：

```bash
cat << 'EOF' >> ~/.zshrc

# Java SDK (OpenJDK 17 for Android Gradle)
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
EOF
```

### 1.3 立即重载配置
```bash
source ~/.zshrc
```

### 1.4 验证 Java 环境
在终端运行：
```bash
javac -version
```
> ✅ **预期输出**：`javac 17.0.x`，说明 OpenJDK 17 配置成功。

---

## 步骤二：安装与配置 Android SDK

### 2.1 在 Android Studio 中安装必要组件
1. 打开 **Android Studio**；
2. 打开 **SDK Manager**；
3. **SDK Platforms** 标签页：
   - 勾选 `Android 14.0 ("UpsideDownCake" / API Level 34)`；
4. **SDK Tools** 标签页：
   - 勾选 `Android SDK Build-Tools 34.0.0`
   - 勾选 `Android SDK Command-line Tools (latest)`
   - 勾选 `Android SDK Platform-Tools`
5. 点击 **Apply ➔ OK** 等待下载安装完成。

### 2.2 写入 Android SDK 环境变量
默认安装路径为 `~/Library/Android/sdk`。在终端中执行：

```bash
cat << 'EOF' >> ~/.zshrc

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
EOF
source ~/.zshrc
```

### 2.3 验证 Android SDK 环境
在终端运行：
```bash
adb --version
```
> ✅ **预期输出**：显示 `Android Debug Bridge version x.x.x`，说明 ADB 与 Platform-Tools 就绪。

---

## 步骤三：签名证书 (Keystore)

Android 打包分为 **调试签名证书 (Debug)** 与 **正式发布签名证书 (Release)**。

### 3.1 团队正式发布证书 (Release Keystore)
为了方便团队多人协作与 CI/CD 自动构建，项目已在 `android/keystore/` 下内置了正式签名证书。团队成员拉取代码后**无需重复生成**，开箱即用。

- **项目内相对路径**：`res://android/keystore/funny_jigsaw_release.keystore`
- **物理路径**：`android/keystore/funny_jigsaw_release.keystore`

> ⚠️ **团队协作与安全须知**：
> - 本项目为**私有私密仓库**，请确保仓库权限仅限团队受信任成员；
> - 证书**绝对不可删除或更换**，否则无法向 Google Play 推送新版本更新。

### 3.2 生成本地调试证书 (Debug Keystore，用于日常开发与一键真机运行)
若本地 `~/.android/debug.keystore` 不存在，执行以下命令一键生成：

```bash
keytool -genkey -v -keystore ~/.android/debug.keystore \
  -storepass android -alias androiddebugkey -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

---

## 步骤四：在 Godot 编辑器中配置路径 (Editor Settings)

打开 Godot 4 项目，进行编辑器全局基础路径绑定：

1. 顶部菜单点击 **Editor (编辑器) ➔ Editor Settings (编辑器设置)**；
2. 左侧栏向下滚动，展开并点击 **Export (导出) ➔ Android**；
3. 在右侧填入以下对应路径：

| 配置项 (Setting) | 填入路径 / 值 | 说明 |
| :--- | :--- | :--- |
| **Java SDK Path** | `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` | 指向 OpenJDK 17 根目录 |
| **Android SDK Path** | `/Users/{your_username}/Library/Android/sdk` | 指向 Android SDK 根目录 |
| **Debug Keystore** | `/Users/{your_username}/.android/debug.keystore` | 日常调试签名文件绝对路径 |
| **Debug Keystore User** | `androiddebugkey` | 调试证书别名 |
| **Debug Keystore Pass** | `android` | 调试证书密码 |

---

## 步骤五：安装 Android 构建模板 (Gradle Build)

本项目如需集成原生 Android 插件（广告、内购、Spine 原生库等），需要使用 Gradle 原生构建模板：

1. 在 Godot 顶部菜单栏点击 **Project (项目) ➔ Install Android Build Template (安装 Android 构建模板)**；
2. 确认安装后，项目根目录下会自动生成 `android/build` 目录；
3. 该目录由 Gradle 接管，供引擎编译原生 Java/Kotlin 与打包 APK。

---

## 步骤六：项目导出预设配置 (Export Presets)

打开 Godot 顶部菜单 **Project (项目) ➔ Export (导出)**，确保 Android 预设配置如下：

### 6.1 核心包体与签名
- **Package ➔ Unique Name**：`com.coralplanet.funnyjigsaw`
- **Package ➔ Name**：`funnyjigsaw`
- **Keystore ➔ Release / Keystore**：`res://android/keystore/funny_jigsaw_release.keystore`
- **Keystore ➔ Release / User**：`funny_jigsaw`
- **Keystore ➔ Release / Password**：`{your_password}`

### 6.2 必备权限开启（防止网络与震动失效）
- **Permissions ➔ Internet**：`On`（必须开启，否则网络请求会报 `_sock == -1`）
- **Permissions ➔ Access Network State**：`On`
- **Permissions ➔ Vibrate**：`On`
- **Permissions ➔ Custom Permissions**：`com.google.android.gms.permission.AD_ID`

---

## 步骤七：导出验证与打包

### 7.1 一键真机/模拟器调试 (One-Click Deploy)
1. 手机开启 **开发者模式 + USB 调试** 并连接电脑（或启动 Android 模拟器）；
2. Godot 窗口右上角会出现 **Android 设备小图标**；
3. 点击图标，Godot 会自动编译并在手机上安装启动游戏！

### 7.2 导出正式发布 APK / AAB
1. 顶部菜单点击 **Project (项目) ➔ Export (导出)**；
2. 格式选择：
   - **APK 包（测试机直装）**：保持 `Export AAB` 未勾选；
   - **AAB 包（Google Play 上架）**：勾选 `Export AAB = true`；
3. 点击底部 **Export Project (导出项目)** ➔ 导出安装包。

---

## ❓ 常见问题排查 (FAQ)

### Q1: 报错 `Unsupported class file major version 69`？
- **原因**：使用了 JDK 25，Gradle 8.x 无法支持该字节码版本。
- **解决**：安装 `brew install openjdk@17`，并将 Godot 的 `Java SDK Path` 改为 `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`。

### Q2: 启动游戏报 `Condition "_sock == -1" is true` 网络错误？
- **原因**：APK 打包时未勾选网络权限。
- **解决**：在导出面板中勾选 `Permissions ➔ Internet = On` 后重新导出。

### Q3: 提示 `Android SDK Path is invalid`？
- **原因**：找不到 `platform-tools`。
- **解决**：确保在 Android Studio 的 SDK Manager 中安装了 `Android SDK Platform-Tools` 与 `Build-Tools`。

### Q4: 找不到连接的 Android 设备？
- **解决**：
  1. 在终端运行 `adb devices` 查看是否有授权弹窗；
  2. 手机端插拔 USB 并勾选“始终允许这台电脑进行调试”。
