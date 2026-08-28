# Resource (渲染材质与动效资源库)

## 核心

集中管理游戏内所有派生型渲染资源、自定义着色器（[code].gdshader[/code]）与材质实例（[code].tres[/code]）。
涵盖 UI 高性能 SDF 独立四角圆角裁切、对角线扫光高亮、置灰淡化 Shader 以及 Spine 骨骼动画资产。
原始位图与音频文件存放于 `src/assets/`，纯数据实体存放于 `src/game/entities/`，本目录专注于 GPU 渲染材质与动画资源的数据封装。

---

## 细节

- **设计与开发约束**：
  - **GPU Shader Modulate 继承**：所有自定义 CanvasItem 着色器输出 `COLOR` 时，Alpha 通道**必须**乘以 `COLOR.a`（例如 `COLOR = vec4(final_rgb, col.a * alpha * COLOR.a)`），确保场景转场与父级透明度淡变能够无缝渗透。
  - **动态参数材质独立化 (Duplicate)**：对于运行时需动态修改参数的材质（如拼图卡牌根据连通关系动态修改 `radii`、相册封面补间 `shine_progress`），各节点实例在 `_ready` 时必须调用 `material = material.duplicate()`，杜绝材质共享导致的状态污染。
  - **路径常量路由**：所有材质与 Spine 骨骼资源路径统一收拢于 `MaterialCatalog` 与 `SpineCatalog`，禁止在业务代码中硬编码字符串路径。
- **资源分类**：
  - `animation/`：预装配的 `SpineSkeletonDataResource` 资源，将 `assets/` 中的 `.atlas` 与 `.spine-json` 封装为可直接挂载到 `SpineSprite` 的强类型资源。
  - `shader/components/`：基础通用材质，包含精确四角 SDF 独立抗锯齿圆角（`rounded_rect`）与状态置灰（`grayscale`）。
  - `shader/lobby/`：大厅与画廊相册专属特效，包含对角线投影扫光高光材质（`album_sweep_light`）。
  - `shader/popup/`：弹窗通用视觉材质，包含基于距离场的纯抗锯齿高精度圆环（`popup_ring`）。

```text
src/resource/
├── _doc_resource.md                               # 本模块架构与使用文档
├── animation/                                    # Spine 骨骼动画已配置资源 (.tres)
│   ├── level_pass_piece_anim.tres                # 关卡拼图归位金光 Spine 特效
│   ├── loading_anim.tres                         # 通用加载菊花旋转动画
│   └── piece_correct_blur_anim.tres              # 单块拼图拼对时的微光 Spine 动画
└── shader/                                       # 自定义 GPU 着色器与材质
    ├── components/                               # 通用基础组件着色器
    │   ├── grayscale.gdshader                    # 节点灰度与淡化着色器 (用于锁态/禁用)
    │   ├── grayscale.tres                        # 灰度材质实例
    │   ├── rounded_rect.gdshader                 # 高性能 SDF 独立四角平滑圆角/描边着色器
    │   ├── rounded_rect.tres                     # 通用圆角材质实例
    │   ├── rounded_rect_level_picture.tres       # 关卡缩略图专用圆角材质
    │   └── rounded_rect_theme_cover.tres         # 相册封面专用圆角材质
    ├── lobby/                                    # 大厅专属着色器
    │   ├── album_sweep_light.gdshader            # 相册圆角裁切与对角线扫光材质
    │   └── album_sweep_light.tres                # 相册扫光材质实例
    └── popup/                                    # 弹窗专属着色器
        ├── popup_ring.gdshader                   # 纯 SDF 距离场抗锯齿圆环着色器
        └── popup_ring.tres                       # 圆环材质实例
```

---

## 样例

```gdscript
# 1. 动态加载材质并独立化参数 (设置四角独立圆角)
var mat_res := await App.asset.load(MaterialCatalog.ROUNDED_RECT)
if mat_res.is_ok():
    var shader_mat := (mat_res.value as ShaderMaterial).duplicate()
    $CardTexture.material = shader_mat
    # 设置左上、右上、右下、左下独立圆角半径 (Vector4)
    shader_mat.set_shader_parameter("radii", Vector4(16, 0, 0, 16))
    shader_mat.set_shader_parameter("rect_size", $CardTexture.size)

# 2. 扫光材质进度补间动画 (Shine Sweep)
var shine_mat := $Cover.material as ShaderMaterial
if shine_mat:
    var tween := create_tween()
    tween.tween_property(shine_mat, "shader_parameter/shine_progress", 1.0, 0.8)\
        .from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

# 3. Spine 特效预热与播放
SpineUtils.warmup([SpineCatalog.LEVEL_PASS_PIECE], self)
SpineUtils.play_oneshot(SpineCatalog.LEVEL_PASS_PIECE, $VFXContainer, Vector2(540, 960))
```
