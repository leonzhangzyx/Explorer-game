# 单英雄领地冒险 MVP

这是依据《GDD 单英雄领地冒险 MVP》和《实现指导提示词套件》制作的 Godot 4.7.2 项目。

## 启动

打开以下程序：

```text
tools/Godot-4.7.2/Godot_v4.7.2-stable_win64.exe
```

在 Godot 项目管理器中导入本目录的 `project.godot`，然后运行项目。

## 当前进度

- 阶段 0 已完成：工程骨架、主场景、实施蓝图和测试入口。
- 阶段 1 已完成：核心状态、八种兵种数据、内容注册表和验证。
- 阶段 2 已完成：确定性随机流、顶层状态和安全存读档。
- 阶段 3 已完成：可操作世界地图、行动点、地形费用、战争迷雾、资源采集和结束回合。
- 阶段 4 已完成：10 × 8 战场、部署、行动顺序、移动、近战、反击、防御、等待、AI、英雄倒地和胜负。
- 阶段 5 已完成：远程、地形、夹击、状态、净化、士气、三项英雄战技和八种兵种特性。
- 下一阶段：英雄成长、装备与军队管理。

详细进度见 `docs/实现状态.md`。

## 自动验证

使用 Godot 控制台程序以无界面模式运行：

```text
--headless --path . --script res://tests/smoke_test.gd
--headless --path . --script res://tests/content_model_test.gd
--headless --path . --script res://tests/session_save_test.gd
--headless --path . --script res://tests/world_map_test.gd
--headless --path . --script res://tests/battle_core_test.gd
--headless --path . --script res://tests/advanced_battle_test.gd
```

