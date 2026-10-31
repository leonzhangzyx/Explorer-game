# 美术与 UI 资源选型

更新时间：2026-10-31

## 结论

本项目优先采用“写实中古魔幻 2.5D 冒险地图 + 深色皮革/金属/羊皮纸 UI + 英雄实体与军队旗帜”的方向。大地图参考《英雄无敌 III / IV》的冒险地图观感，而不是绘本式世界地图。

这套方向最适合当前原型：世界地图仍然是领地节点与路线，战斗仍然是方格规则；通过背景、面板、旗帜、图标和动效即可明显提升完成度，不必为了套素材而重写玩法。

## 推荐主方案

### 1. 大地图主选：Sova Digital — Medieval Castle Top-Down HD

- 链接：https://sovdigital.itch.io/medieval-castle-tileset
- 免费体验场景：https://sovdigital.itch.io/free-medieval-battle-demo
- 价格：页面当前促销价 12.49 美元，常规标价 24.99 美元；价格可能随促销变化。
- 内容：高分辨率 2.5D 斜俯视地面、道路、森林植物、城堡、村庄、遗迹、墓地、桥梁、火焰、旗帜、天气和昼夜变体。
- 工程适配：原生提供 Godot 4 TileSet、场景、碰撞、导航、法线贴图、灯光遮挡和天气 Shader；同时提供 64 px 与 128 px 两套比例。
- 授权：可用于不限数量的商业或个人游戏并允许修改；不能转售或重新分发素材；无需强制署名。
- 生成式 AI：页面标注为 AI Assisted（Graphics）。使用前需要接受这一点并保留购买与授权记录。
- 选择理由：镜头角度、写实程度、城堡和地貌比例都明显更接近《英雄无敌》式冒险地图；Godot 接入成本也最低。
- 用法：将当前“圆形领地节点”改为场景中的真实城镇、矿点、营地、遗迹和传送门；道路仍由现有世界图数据控制，英雄变为可见实体沿道路移动。

### 1B. 非生成式 AI 备选：Isometric Tiles, Ancient Volume I

- 链接：https://wanderertiles.itch.io/ancient-isometric-tiles-volume-i
- 价格：页面提供下载。
- 内容：500 多张手绘中古魔幻等距素材，PNG、Tiled tileset 和示例关卡。
- 生成式 AI：作者明确说明完全手绘，未使用 AI 或 3D 工具。
- 优点：阴郁、古旧、手绘质感较强，授权风险和视觉同质化更低。
- 缺点：更偏等距 RPG 场景，世界地貌、城镇体系和 Godot 配置不如 Sova 完整，需要我们自己制作 TileSet 与冒险地图规则。
- 决策：2026-10-31 用户选定为大地图主视觉。资源已经下载并解压到 `assets/vendor/ancient_isometric_tiles_v1/`，原始许可证已保留。

### 1C. 暗黑等距备选：Kyndrael — Dark Fantasy Isometric Terrain & Nature

- 链接：https://kyndrael.itch.io/isometric-terrain-nature-darkfantasy-2d-pixelart
- 价格：9.90 美元。
- 内容：64×32 等距地块、泥地、碎石、草地、湖水、森林、岩石、洞穴、植被和动画树，附 Godot 4 TileSet 与演示地图。
- 优点：氛围最黑暗，森林压迫感强，也有同系列中古村庄和地牢资源。
- 缺点：页面明确标注使用了生成式 AI 辅助；像素颗粒感比 Sova 更强。

### 2. UI：Pinewick Studios — Kingdom UI

- 链接：https://pinewickstudios.itch.io/kingdom-ui-fantasy-rpg-ui-kit
- 价格：6.99 美元
- 内容：深色皮革、木材、金属包边、羊皮纸、卷轴、旗帜、按钮、状态条、头像框和小地图框。
- 工程适配：提供 Godot 4 设置说明、九宫格边距表和 PNG 资源。
- 授权：可用于不限数量的商业或免费游戏；无需署名；不能转售或单独再分发素材。
- 生成式 AI：页面标注未使用生成式 AI。
- 用法：主菜单、世界地图左右信息栏、英雄卡、领地详情、事件窗口、战斗 HUD 和结算窗口。

### 3. 单位与功能图标：Game-icons.net

- 链接：https://game-icons.net/
- 价格：免费。
- 内容：大量单色 SVG 游戏图标，可在线修改颜色、尺寸、旋转和阴影。
- 授权：CC BY 3.0，发布时必须按作者进行署名。
- 用法：英雄职业、兵种、资源、移动、攻击、防御、状态效果、任务和地点图标。统一处理成“浅金图标 + 深色圆形底 + 阵营色描边”。

### 4. 字体

- 中文正文：Noto Sans SC — https://fonts.google.com/noto/specimen/Noto%2BSans%2BSC
- 英文标题及数字：Cinzel — https://fonts.google.com/specimen/Cinzel
- 使用原则：中文界面必须以 Noto Sans SC 为主，Cinzel 只用于英文标志、章节名、数字或短标题，避免中文缺字。

### 5. 界面与战斗音效：Kenney

- Interface Sounds：https://kenney.nl/assets/interface-sounds
- Impact Sounds：https://kenney.nl/assets/impact-sounds
- 价格：免费。
- 授权：CC0，可用于商业项目且不要求署名。
- 用法：按钮悬停、确认、关闭、选择领地，以及近战命中、护甲碰撞和战斗反馈。

### 6. 临时音乐：OpenGameArt CC0

- 地图/菜单候选 Medieval: Exploration：https://opengameart.org/content/medieval-exploration
- 城镇候选 Medieval: The Bard's Tale：https://opengameart.org/content/medieval-the-bards-tale
- 战斗候选 Division By Zero：https://opengameart.org/content/creeping-orcs-division-by-zero
- 授权：上述页面均标注为 CC0。
- 用法：先用于原型和测试版。正式版可以继续使用，也可以在整体音频方向确定后替换为定制音乐。

## 零预算备选

如果暂时不购买素材，先用以下组合验证完整界面：

- UI：Free Pixel RPG UI — Parchment Theme  
  https://topdigitalforge.itch.io/free-pixel-rpg-ui-parchment
- 战斗地块：Tiny Top Down Pack（CC0）  
  https://screamingbrainstudios.itch.io/tiny-top-down-pack
- 地图：Fantasy: Overworld Strategy Tileset 免费版  
  https://ivess.itch.io/ivesss-top-down-strategy-tileset
- 图标、字体和声音：继续使用 Game-icons.net、Google Fonts 与 Kenney。

零预算组合的缺点是像素风会更明显，和最终推荐的手绘地图方向不完全一致。因此它更适合做布局、交互和动效验证，不建议直接作为最终美术。

## 不建议直接混用的资源

- 写实高分辨率 UI 与 16×16 像素地图不要同时作为主视觉。
- 六角地图包不直接套到当前方格战斗系统，以免美术网格和规则网格产生冲突。
- 不优先采用来源不明、授权表述含糊或只写“copyright free”的资源。
- 生成式 AI 素材若要使用，必须单独记录来源和授权；主方案目前可以做到关键视觉资源均标注为非生成式 AI。

## 接入顺序

1. 先接入免费字体、Game-icons 图标和 Kenney 音效，建立统一资源目录与授权清单。
2. 使用临时色块制作新的世界地图布局和战斗 HUD，确认信息密度与交互。
3. 购买并导入 Kingdom UI，制作 Godot Theme、九宫格面板和按钮状态。
4. 先导入 Sova 免费战斗演示，验证镜头、比例、性能与 Godot 4.7 兼容性；确认后再决定是否购买完整地图包。
5. 增加选择高亮、路线流光、领地旗帜、伤害数字、镜头轻震和结算转场。
6. 最后统一音量、色板、字体字号和署名页面。

## 资源目录建议

```text
assets/
  art/
    map/
    ui/
    icons/
    units/
    vfx/
  audio/
    music/
    sfx_ui/
    sfx_battle/
  fonts/
  licenses/
```

每个第三方资源包都在 `assets/licenses/` 中保留原始许可证，并在 `THIRD_PARTY_NOTICES.md` 记录作者、来源链接、授权、购买日期和修改说明。
