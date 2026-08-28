# Assets

## 核心

游戏内资源落在本目录。从 Figma 源 **copy 进仓库**，不要只引用外部路径。

贴图画质由导入参数 `compress/mode` 决定，开发期用无损。本目录不管导入 hash（`.import` 由编辑器生成），也不管切语言（那是 `LocaleService`）。

---

## 细节

- App icon 例外：源文件 `app_icon_raw.png` 覆盖项目根 `icon.png`，`project.godot` 的 `config/icon` 指向 `res://icon.png`。
- `audio/` 按播放通道建二级目录：`bgm/` 循环曲，`sfx/` 一次性音效。文件名带通道前缀和用途，`{kind}_{system}_{slot}`。循环曲用 mp3，音效用 wav。不要按扩展名再套一层。
- `textures/` 按场景建二级目录；文件名带场景前缀和用途。不要用短名 `bg.png`。从 Figma 拷进来时，无意义导出名先改成约定再复制。
- `fonts/` 按家族建二级目录，小写蛇形。静态和可变字体都放在家族根下，不要再套发行包里的 `static/`。文件名 `{family}_{width}_{weight}[_italic].ttf`，可变体 `{family}_variable[_italic].ttf`。
- `translations/i18n.csv` 的 key 同样用 `{scene}_{slot}`，且只保留仍被引用的行。规则见 `locale_service/_doc_locale_service.md`。
- 画质入口是 `compress/mode`，不是 `run/low_processor_mode`。`0` 为 Lossless；`2` 为 VRAM Compressed（桌面 DXT/S3TC、手机 ETC2）。小尺寸 UI 用 `2` 会出 4×4 色块和边缘溢色。
- 新图跟 `project.godot` 的 `[importer_defaults] texture compress/mode`（当前 `0`）。已导入的图以各自 `.import` 的 `[params] compress/mode` 为准；改默认不会改旧文件。
- 改某张图只动它的 `compress/mode`，打开编辑器让它重导。不要手写 hash / `dest_files`。出包压低配时把同一字段改回 `2`。
- `textures/lossless_compression/force_png=true` 只在无损时决定落地格式。`textures/vram_compression/import_etc2_astc=true` 只在 VRAM 模式下额外出手机格式。

```
src/assets/
├── audio/           音效、BGM
│   ├── bgm/         bgm_<slot>.mp3
│   └── sfx/         sfx_<system>_<slot>.wav
├── fonts/           字体
│   └── <family>/    <family>_<width>_<weight>.ttf
├── icons/           编辑器 / 工具图标
├── models/          模型
├── textures/        贴图、场景图、UI 图
│   └── <scene>/     <scene>_<role>.png
└── translations/    i18n.csv 与引擎生成的 .translation
```

---

## 样例

```
src/assets/textures/launcher/launcher_bg.png
src/assets/fonts/roboto/roboto_black.ttf
src/assets/audio/bgm/bgm_main.mp3
src/assets/audio/sfx/sfx_ui_button_click.wav

# 新图默认：project.godot
[importer_defaults]
texture={
&"compress/mode": 0
}

# 单张已导入图：*.png.import
[params]
compress/mode=0
```
